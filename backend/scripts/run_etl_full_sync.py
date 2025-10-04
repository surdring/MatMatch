"""
ETL全量同步脚本

从Oracle导入物料数据到PostgreSQL的materials_master表
使用SimpleMaterialProcessor进行对称处理

使用方法：
    python backend/scripts/run_etl_full_sync.py [--batch-size 1000] [--sample-size 5000]
"""

import asyncio
import sys
import logging
import argparse
import time
from pathlib import Path
from datetime import datetime

# 添加项目根目录到Python路径
project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

from sqlalchemy.ext.asyncio import create_async_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.ext.asyncio import AsyncSession

from backend.core.config import oracle_config, database_config
from backend.adapters.oracle_adapter import OracleConnectionAdapter
from backend.etl.etl_pipeline import ETLPipeline
from backend.etl.material_processor import SimpleMaterialProcessor
from backend.etl.etl_config import ETLConfig

# 配置日志
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(sys.stdout),
        logging.FileHandler(
            f'logs/etl_full_sync_{datetime.now().strftime("%Y%m%d_%H%M%S")}.log',
            encoding='utf-8'
        )
    ]
)
logger = logging.getLogger(__name__)


async def run_etl_sync(batch_size: int = 1000, sample_size: int = None):
    """
    运行ETL全量同步
    
    Args:
        batch_size: 批处理大小
        sample_size: 样本大小（用于测试，None表示全量）
    """
    logger.info("="*80)
    logger.info("⭐ 开始ETL全量同步")
    logger.info("="*80)
    
    # 1. 初始化Oracle连接适配器
    logger.info("Step 1: 初始化Oracle连接适配器...")
    oracle_adapter = OracleConnectionAdapter(
        config=oracle_config,
        use_pool=False,
        enable_cache=True,
        cache_ttl=300
    )
    
    # 2. 初始化PostgreSQL会话
    logger.info("Step 2: 初始化PostgreSQL会话...")
    engine = create_async_engine(
        database_config.database_url,
        echo=False,
        pool_size=10,
        max_overflow=20
    )
    AsyncSessionLocal = sessionmaker(
        engine, class_=AsyncSession, expire_on_commit=False
    )
    
    try:
        async with AsyncSessionLocal() as pg_session:
            # 3. 初始化SimpleMaterialProcessor
            logger.info("Step 3: 初始化SimpleMaterialProcessor...")
            processor = SimpleMaterialProcessor(pg_session)
            
            logger.info("   加载知识库数据...")
            await processor.load_knowledge_base()
            logger.info(f"   ✅ 知识库加载完成:")
            logger.info(f"      - 提取规则: {len(processor.extraction_rules)}条")
            logger.info(f"      - 同义词: {len(processor.synonyms)}个")
            logger.info(f"      - 分类关键词: {len(processor.category_keywords)}个")
            
            # 4. 初始化ETLPipeline
            logger.info("Step 4: 初始化ETL管道...")
            etl_config = ETLConfig(
                batch_size=batch_size,
                load_batch_size=500,
                skip_failed_records=True
            )
            
            pipeline = ETLPipeline(
                oracle_adapter=oracle_adapter,
                pg_session=pg_session,
                material_processor=processor,
                config=etl_config
            )
            
            # 5. 运行ETL同步
            logger.info("Step 5: 开始ETL数据同步...")
            logger.info(f"   批处理大小: {batch_size}")
            if sample_size:
                logger.info(f"   样本大小: {sample_size}条（测试模式）")
            else:
                logger.info("   模式: 全量同步")
            
            # 记录开始时间用于计算进度
            start_time = time.time()
            
            def progress_callback(processed, total):
                """进度回调 - 接收2个参数: (已处理数, 总数)"""
                elapsed = time.time() - start_time
                rate = processed / (elapsed / 60) if elapsed > 0 else 0
                logger.info(
                    f"   进度: 已处理 {processed}条, "
                    f"耗时 {elapsed:.1f}秒, 速率 {rate:.1f}条/分钟"
                )
            
            # 运行全量同步
            if sample_size:
                # 测试模式：只处理指定数量
                logger.info(f"   ⚠️  测试模式：只处理前{sample_size}条数据")
            
            result = await pipeline.run_full_sync(
                batch_size=batch_size,
                progress_callback=progress_callback
            )
            
            # 6. 输出结果
            logger.info("="*80)
            logger.info("⭐ ETL同步完成")
            logger.info("="*80)
            logger.info(f"状态: {result['status']}")
            logger.info(f"处理记录数: {result['processed_records']}")
            logger.info(f"失败记录数: {result['failed_records']}")
            logger.info(f"耗时: {result['duration_seconds']:.2f}秒")
            logger.info(f"处理速率: {result['records_per_minute']:.2f}条/分钟")
            
            if result['job_id']:
                logger.info(f"任务ID: {result['job_id']}")
            
            logger.info("="*80)
            
            # 提交事务
            await pg_session.commit()
            
            return result
            
    except Exception as e:
        logger.error(f"❌ ETL同步失败: {str(e)}")
        import traceback
        traceback.print_exc()
        raise
    finally:
        # 关闭连接
        await oracle_adapter.disconnect()
        await engine.dispose()
        logger.info("数据库连接已关闭")


def main():
    """主函数"""
    parser = argparse.ArgumentParser(description='ETL全量同步脚本')
    parser.add_argument(
        '--batch-size',
        type=int,
        default=1000,
        help='批处理大小（默认: 1000）'
    )
    parser.add_argument(
        '--sample-size',
        type=int,
        default=None,
        help='样本大小，用于测试（默认: None表示全量）'
    )
    
    args = parser.parse_args()
    
    # 创建日志目录
    Path('logs').mkdir(exist_ok=True)
    
    try:
        # 运行ETL同步
        result = asyncio.run(run_etl_sync(
            batch_size=args.batch_size,
            sample_size=args.sample_size
        ))
        
        if result['status'] == 'success':
            logger.info("✅ ETL同步成功完成")
            sys.exit(0)
        else:
            logger.error("❌ ETL同步失败")
            sys.exit(1)
            
    except KeyboardInterrupt:
        logger.warning("⚠️  用户中断")
        sys.exit(130)
    except Exception as e:
        logger.error(f"❌ 发生错误: {str(e)}")
        sys.exit(1)


if __name__ == '__main__':
    main()

