"""
完整的对称处理验证流程（一键执行）

执行步骤：
1. ETL全量同步 - 清空表并应用最新的13条清洗规则
2. 知识库生成并导入 - 基于PostgreSQL清洗后数据直接生成到数据库（一步到位）

使用方法：
    python run_complete_pipeline.py [--skip-etl]
    
参数：
    --skip-etl: 跳过ETL同步（如果数据已是最新）
    
注意：
    - 全量同步会清空materials_master表
    - 所有逻辑集成在一个脚本中，无需调用外部脚本
"""

import asyncio
import sys
from pathlib import Path

# 添加项目路径
project_root = Path(__file__).parent
sys.path.insert(0, str(project_root))

from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from sqlalchemy import text

from backend.core.config import oracle_config, database_config
from backend.adapters.oracle_adapter import OracleConnectionAdapter
from backend.etl.material_processor import SimpleMaterialProcessor
from backend.etl.etl_pipeline import ETLPipeline


async def truncate_materials_table():
    """清空materials_master表"""
    print("\n" + "=" * 80)
    print("📊 步骤1a: 清空materials_master表")
    print("=" * 80)
    
    engine = create_async_engine(
        database_config.database_url,
        echo=False,
        pool_pre_ping=True
    )
    
    async_session_maker = sessionmaker(
        engine,
        class_=AsyncSession,
        expire_on_commit=False
    )
    
    try:
        async with async_session_maker() as session:
            # 查询当前数量
            result = await session.execute(
                text('SELECT COUNT(*) FROM materials_master')
            )
            current_count = result.scalar()
            print(f"📊 当前物料数量: {current_count:,}")
            
            if current_count > 0:
                print(f"⚠️  即将删除 {current_count:,} 条物料数据")
                print("⏳ 正在清空表...")
                
                # 清空表
                await session.execute(
                    text('TRUNCATE TABLE materials_master CASCADE')
                )
                await session.commit()
                
                # 验证清空成功
                result = await session.execute(
                    text('SELECT COUNT(*) FROM materials_master')
                )
                after_count = result.scalar()
                
                print(f"✅ 表已清空，当前数量: {after_count}")
            else:
                print("ℹ️  表已经是空的，无需清空")
        
        await engine.dispose()
        return True
        
    except Exception as e:
        print(f"❌ 清空表失败: {e}")
        await engine.dispose()
        return False


async def run_full_sync():
    """执行全量ETL同步"""
    print("\n" + "=" * 80)
    print("📊 步骤1b: 执行全量ETL同步")
    print("=" * 80)
    
    # 创建PostgreSQL会话
    print("🔧 初始化PostgreSQL会话...")
    engine = create_async_engine(
        database_config.database_url,
        echo=False,
        pool_size=10,
        max_overflow=20
    )
    
    async_session_maker = sessionmaker(
        engine,
        class_=AsyncSession,
        expire_on_commit=False
    )
    
    try:
        async with async_session_maker() as pg_session:
            # 初始化Oracle连接适配器
            print("🔧 初始化Oracle连接...")
            oracle_adapter = OracleConnectionAdapter(
                config=oracle_config,
                use_pool=False,
                enable_cache=True,
                cache_ttl=300
            )
            
            # 初始化SimpleMaterialProcessor
            print("🔧 初始化物料处理器...")
            processor = SimpleMaterialProcessor(pg_session)
            await processor.load_knowledge_base()
            print(f"   ✅ 知识库加载完成:")
            print(f"      - 提取规则: {len(processor.extraction_rules)}条")
            print(f"      - 同义词: {len(processor.synonyms):,}个")
            print(f"      - 分类关键词: {len(processor.category_keywords):,}个")
            
            # 初始化ETL管道
            print("🔧 初始化ETL管道...")
            pipeline = ETLPipeline(
                oracle_adapter=oracle_adapter,
                pg_session=pg_session,
                material_processor=processor
            )
            
            # 执行全量同步
            print("\n🚀 开始全量同步...")
            print("   批处理大小: 1000")
            print("   模式: 全量同步（所有启用状态）")
            print("   处理逻辑: 13条清洗规则 + 同义词替换 + 属性提取")
            print("")
            
            result = await pipeline.run_full_sync(
                batch_size=1000,
                progress_callback=lambda current, total: print(
                    f"   进度: {current:,}/{total:,} ({current/total*100:.1f}%)"
                )
            )
            
            # 输出结果
            print("\n" + "=" * 80)
            print("✅ 全量同步完成！")
            print("=" * 80)
            print(f"📊 同步统计:")
            print(f"   - 处理总数: {result['total_records']:,}")
            print(f"   - 成功数量: {result['processed_records']:,}")
            print(f"   - 失败数量: {result['failed_records']:,}")
            print(f"   - 处理耗时: {result['duration_seconds']:.2f}秒")
            print(f"   - 平均速度: {result['records_per_minute']:.1f}条/分钟")
            
            return True
            
    except Exception as e:
        print(f"\n❌ 全量同步失败: {e}")
        import traceback
        traceback.print_exc()
        return False
        
    finally:
        await engine.dispose()


async def run_knowledge_generation():
    """执行知识库生成并导入"""
    print("\n" + "=" * 80)
    print("🔧 步骤2: 知识库生成并导入 - 基于PostgreSQL清洗后数据")
    print("=" * 80)
    
    try:
        # 导入知识库生成模块
        from database.generate_and_import_knowledge import main as generate_knowledge
        
        # 执行知识库生成
        await generate_knowledge()
        return True
        
    except Exception as e:
        print(f"\n❌ 知识库生成失败: {e}")
        import traceback
        traceback.print_exc()
        return False


async def main():
    """主流程"""
    import argparse
    
    parser = argparse.ArgumentParser(description='完整的对称处理验证流程')
    parser.add_argument('--skip-etl', action='store_true',
                       help='跳过ETL同步（如果数据已是最新）')
    
    args = parser.parse_args()
    
    print("\n" + "="*80)
    print("🚀 完整对称处理验证流程启动")
    print("="*80)
    
    # 步骤1: ETL同步（可选）
    if not args.skip_etl:
        # 步骤1a: 清空表
        truncate_success = await truncate_materials_table()
        if not truncate_success:
            print("\n❌ 清空表失败，终止操作")
            return 1
        
        # 步骤1b: 全量同步
        sync_success = await run_full_sync()
        if not sync_success:
            print("\n❌ 全量同步失败")
            return 1
    else:
        print("\n⏭️  步骤1: 跳过ETL同步（使用现有数据）")
    
    # 步骤2: 知识库生成并导入
    kb_success = await run_knowledge_generation()
    if not kb_success:
        print("\n💥 知识库生成并导入失败！")
        return 1
    
    # 完成
    print("\n" + "="*80)
    print("✅ 完整流程执行成功！")
    print("="*80)
    print("\n📋 后续步骤：")
    print("1. 启动后端服务：python -m uvicorn backend.main:app --reload")
    print("2. 启动前端服务：cd frontend && npm run dev")
    print("3. 访问 http://localhost:5173 进行测试")
    print("\n🎯 验证要点：")
    print("- 上传Excel文件，检查查重结果")
    print("- 验证重复判定逻辑（完全重复/疑似重复/不重复）")
    print("- 检查清洗后的数据是否正确对比")
    print("- 观察后端日志中的processing_steps")
    
    return 0


if __name__ == "__main__":
    exit_code = asyncio.run(main())
    sys.exit(exit_code)

