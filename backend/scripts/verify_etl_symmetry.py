"""
对称性验证脚本 - ETL vs 在线处理一致性验证

验证目标：
- ETL处理结果 vs 在线处理结果
- 一致性率 ≥ 99.9%
- 样本量：1000个随机样本

这是Task 1.3的核心验证项 ⭐⭐⭐
"""

import asyncio
import sys
import logging
from pathlib import Path
from datetime import datetime
from typing import Dict, Any, List, Tuple

# 添加项目根目录到Python路径
project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from sqlalchemy.orm import sessionmaker

from backend.core.config import database_config
from backend.etl.material_processor import SimpleMaterialProcessor

# 配置日志
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


class SymmetryVerifier:
    """对称性验证器"""
    
    def __init__(self, sample_size: int = 1000):
        """
        初始化验证器
        
        Args:
            sample_size: 样本数量（默认1000）
        """
        self.sample_size = sample_size
        self.engine = None
        self.async_session = None
        
    async def initialize(self):
        """初始化数据库连接"""
        logger.info("Initializing database connection...")
        
        # 创建异步引擎
        database_url = database_config.database_url
        self.engine = create_async_engine(
            database_url,
            echo=False,
            future=True
        )
        
        # 创建异步会话工厂
        async_session_factory = sessionmaker(
            self.engine,
            class_=AsyncSession,
            expire_on_commit=False
        )
        self.async_session = async_session_factory
        
        logger.info("✅ Database connection initialized")
    
    async def close(self):
        """关闭数据库连接"""
        if self.engine:
            await self.engine.dispose()
            logger.info("Database connection closed")
    
    async def verify_symmetry(self) -> Dict[str, Any]:
        """
        执行对称性验证
        
        Returns:
            验证报告字典
        """
        logger.info("="*80)
        logger.info("⭐⭐⭐ 开始对称性验证")
        logger.info("="*80)
        
        async with self.async_session() as session:
            # 1. 随机抽取样本
            logger.info(f"Step 1: 从materials_master随机抽取{self.sample_size}个样本...")
            samples = await self._fetch_samples(session)
            
            if not samples:
                logger.error("❌ 没有找到样本数据")
                return {
                    'status': 'error',
                    'message': 'No samples found in materials_master table'
                }
            
            actual_sample_size = len(samples)
            logger.info(f"✅ 成功抽取{actual_sample_size}个样本")
            
            # 2. 初始化SimpleMaterialProcessor
            logger.info("Step 2: 初始化SimpleMaterialProcessor...")
            processor = SimpleMaterialProcessor(session)
            await processor.load_knowledge_base()
            logger.info("✅ 知识库加载完成")
            
            # 3. 逐条重新处理并对比
            logger.info("Step 3: 逐条重新处理并对比...")
            matched_count = 0
            consistency_details = []
            
            for i, sample in enumerate(samples, 1):
                if i % 100 == 0:
                    logger.info(f"Progress: {i}/{actual_sample_size} samples processed")
                
                # 构建原始数据
                raw_data = {
                    'erp_code': sample['erp_code'],
                    'material_name': sample['material_name'],
                    'specification': sample['specification'],
                    'model': sample['model']
                }
                
                # 在线重新处理
                try:
                    online_result = processor.process_material(raw_data)
                    
                    # 对比ETL结果 vs 在线结果
                    is_consistent = self._compare_results(sample, online_result)
                    
                    if is_consistent:
                        matched_count += 1
                    else:
                        # 记录不一致的样本
                        consistency_details.append({
                            'erp_code': sample['erp_code'],
                            'etl_normalized': sample['normalized_name'],
                            'online_normalized': online_result.normalized_name,
                            'etl_category': sample['detected_category'],
                            'online_category': online_result.detected_category,
                            'etl_attrs': sample['attributes'],
                            'online_attrs': online_result.attributes
                        })
                        
                except Exception as e:
                    logger.error(f"Failed to process sample {sample['erp_code']}: {str(e)}")
                    consistency_details.append({
                        'erp_code': sample['erp_code'],
                        'error': str(e)
                    })
            
            # 4. 计算一致性率
            consistency_rate = (matched_count / actual_sample_size) * 100
            
            # 5. 生成报告
            report = self._generate_report(
                actual_sample_size,
                matched_count,
                consistency_rate,
                consistency_details
            )
            
            return report
    
    async def _fetch_samples(self, session: AsyncSession) -> List[Dict[str, Any]]:
        """
        从materials_master随机抽取样本
        
        Args:
            session: 数据库会话
            
        Returns:
            样本数据列表
        """
        query = text("""
            SELECT 
                id,
                erp_code,
                material_name,
                specification,
                model,
                normalized_name,
                attributes,
                detected_category,
                category_confidence,
                full_description
            FROM materials_master
            WHERE sync_status = 'synced'
              AND normalized_name IS NOT NULL
            ORDER BY RANDOM()
            LIMIT :sample_size
        """)
        
        result = await session.execute(query, {'sample_size': self.sample_size})
        rows = result.fetchall()
        
        # 转换为字典列表
        samples = []
        for row in rows:
            samples.append({
                'id': row[0],
                'erp_code': row[1],
                'material_name': row[2],
                'specification': row[3],
                'model': row[4],
                'normalized_name': row[5],
                'attributes': row[6],
                'detected_category': row[7],
                'category_confidence': row[8],
                'full_description': row[9]
            })
        
        return samples
    
    def _compare_results(
        self,
        etl_sample: Dict[str, Any],
        online_result: Any
    ) -> bool:
        """
        对比ETL结果和在线处理结果
        
        Args:
            etl_sample: ETL处理的样本
            online_result: 在线处理的结果
            
        Returns:
            是否一致
        """
        # 对比normalized_name
        normalized_name_match = (
            etl_sample['normalized_name'] == online_result.normalized_name
        )
        
        # 对比detected_category
        category_match = (
            etl_sample['detected_category'] == online_result.detected_category
        )
        
        # 对比attributes（JSONB字段）
        etl_attrs = etl_sample['attributes'] or {}
        online_attrs = online_result.attributes or {}
        attributes_match = (etl_attrs == online_attrs)
        
        # 全部匹配才算一致
        return normalized_name_match and category_match and attributes_match
    
    def _generate_report(
        self,
        total_samples: int,
        matched_count: int,
        consistency_rate: float,
        consistency_details: List[Dict[str, Any]]
    ) -> Dict[str, Any]:
        """
        生成验证报告
        
        Args:
            total_samples: 总样本数
            matched_count: 一致样本数
            consistency_rate: 一致性率
            consistency_details: 不一致样本详情
            
        Returns:
            报告字典
        """
        target_rate = 99.9
        passed = consistency_rate >= target_rate
        
        report = {
            'status': 'success',
            'timestamp': datetime.now().isoformat(),
            'total_samples': total_samples,
            'matched_count': matched_count,
            'inconsistent_count': total_samples - matched_count,
            'consistency_rate': consistency_rate,
            'target_rate': target_rate,
            'passed': passed,
            'inconsistent_samples': consistency_details[:10]  # 只显示前10个
        }
        
        # 打印报告
        self._print_report(report)
        
        return report
    
    def _print_report(self, report: Dict[str, Any]):
        """打印验证报告"""
        print("\n" + "="*80)
        print("⭐⭐⭐ 对称处理验证报告")
        print("="*80)
        print(f"验证时间: {report['timestamp']}")
        print(f"总样本数: {report['total_samples']}")
        print(f"一致样本数: {report['matched_count']}")
        print(f"不一致样本数: {report['inconsistent_count']}")
        print(f"一致性率: {report['consistency_rate']:.2f}%")
        print(f"目标一致性: {report['target_rate']}%")
        print(f"验证结果: {'✅ PASS' if report['passed'] else '❌ FAIL'}")
        
        if not report['passed']:
            print("\n" + "-"*80)
            print("不一致样本（前10个）:")
            print("-"*80)
            
            for i, detail in enumerate(report['inconsistent_samples'], 1):
                if 'error' in detail:
                    print(f"\n样本 {i}: {detail['erp_code']}")
                    print(f"  错误: {detail['error']}")
                else:
                    print(f"\n样本 {i}: {detail['erp_code']}")
                    
                    # 对比normalized_name
                    if detail['etl_normalized'] != detail['online_normalized']:
                        print(f"  ❌ normalized_name不一致:")
                        print(f"     ETL:    {detail['etl_normalized']}")
                        print(f"     在线:   {detail['online_normalized']}")
                    
                    # 对比detected_category
                    if detail['etl_category'] != detail['online_category']:
                        print(f"  ❌ detected_category不一致:")
                        print(f"     ETL:    {detail['etl_category']}")
                        print(f"     在线:   {detail['online_category']}")
                    
                    # 对比attributes
                    if detail['etl_attrs'] != detail['online_attrs']:
                        print(f"  ❌ attributes不一致:")
                        print(f"     ETL:    {detail['etl_attrs']}")
                        print(f"     在线:   {detail['online_attrs']}")
        
        print("="*80 + "\n")


async def main():
    """主函数"""
    # 创建验证器
    verifier = SymmetryVerifier(sample_size=1000)
    
    try:
        # 初始化
        await verifier.initialize()
        
        # 执行验证
        report = await verifier.verify_symmetry()
        
        # 返回退出码
        exit_code = 0 if report.get('passed', False) else 1
        
    except Exception as e:
        logger.error(f"❌ Verification failed: {str(e)}")
        exit_code = 1
    
    finally:
        # 关闭连接
        await verifier.close()
    
    sys.exit(exit_code)


if __name__ == '__main__':
    asyncio.run(main())

