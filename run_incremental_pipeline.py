"""
增量同步流程（一键执行）

执行步骤：
1. ETL增量同步 - 同步自上次同步以来修改的物料（应用13条清洗规则）
2. 知识库生成并导入 - 基于PostgreSQL全部清洗后数据重新生成知识库（一步到位）

使用方法：
    # 增量同步（自动获取上次同步时间）
    python run_incremental_pipeline.py
    
    # 指定起始时间
    python run_incremental_pipeline.py --since "2025-10-07 00:00:00"
    
    # 仅更新知识库（跳过ETL同步）
    python run_incremental_pipeline.py --skip-etl
    
注意：
    - 增量同步后会基于PostgreSQL中的**全部数据**重新生成知识库
    - 确保数据一致性和知识库的完整性
"""

import asyncio
import sys
from pathlib import Path
from datetime import datetime, timedelta

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


async def get_last_sync_time():
    """
    获取上次同步时间
    从PostgreSQL的materials_master表中获取最新的oracle_modified_time
    """
    try:
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
        
        async with async_session_maker() as session:
            result = await session.execute(
                text('SELECT MAX(oracle_modified_time) FROM materials_master')
            )
            last_time = result.scalar()
            
        await engine.dispose()
        
        if last_time:
            # 返回格式化的时间字符串
            return last_time.strftime('%Y-%m-%d %H:%M:%S')
        else:
            # 如果没有数据，返回7天前
            default_time = datetime.now() - timedelta(days=7)
            return default_time.strftime('%Y-%m-%d %H:%M:%S')
            
    except Exception as e:
        print(f"⚠️ 无法获取上次同步时间: {e}")
        # 默认使用7天前
        default_time = datetime.now() - timedelta(days=7)
        return default_time.strftime('%Y-%m-%d %H:%M:%S')


async def run_incremental_sync(since_time: str):
    """执行增量ETL同步"""
    print("\n" + "=" * 80)
    print(f"📊 步骤1/2: ETL增量同步 - 同步 {since_time} 之后的变更")
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
            
            # 执行增量同步
            print(f"\n🚀 开始增量同步...")
            print(f"   起始时间: {since_time}")
            print("   批处理大小: 1000")
            print("   模式: 增量同步（UPSERT）")
            print("   处理逻辑: 13条清洗规则 + 同义词替换 + 属性提取")
            print("")
            
            result = await pipeline.run_incremental_sync(
                since_time=since_time,
                batch_size=1000,
                progress_callback=lambda current, total: print(
                    f"   进度: {current:,} 条已处理"
                )
            )
            
            # 输出结果
            print("\n" + "=" * 80)
            print("✅ 增量同步完成！")
            print("=" * 80)
            print(f"📊 同步统计:")
            print(f"   - 处理总数: {result['total_records']:,}")
            print(f"   - 成功数量: {result['processed_records']:,}")
            print(f"   - 失败数量: {result['failed_records']:,}")
            print(f"   - 处理耗时: {result['duration_seconds']:.2f}秒")
            if result['total_records'] > 0:
                print(f"   - 平均速度: {result['records_per_minute']:.1f}条/分钟")
            else:
                print("   💡 没有新增或修改的数据")
            
            return True
            
    except Exception as e:
        print(f"\n❌ 增量同步失败: {e}")
        import traceback
        traceback.print_exc()
        return False
        
    finally:
        await engine.dispose()


async def run_knowledge_generation():
    """执行知识库生成并导入"""
    print("\n" + "=" * 80)
    print("🔧 步骤2/2: 知识库生成并导入 - 基于PostgreSQL全部清洗后数据")
    print("=" * 80)
    print("💡 注意: 即使是增量同步，也会基于全部数据重新生成知识库以确保完整性")
    
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
    
    parser = argparse.ArgumentParser(description='增量同步流程')
    parser.add_argument('--skip-etl', action='store_true',
                       help='跳过ETL同步（仅更新知识库）')
    parser.add_argument('--since', type=str,
                       help='起始时间（格式：YYYY-MM-DD HH:MM:SS）')
    
    args = parser.parse_args()
    
    print("\n" + "="*80)
    print("🔄 增量同步流程启动")
    print("="*80)
    
    # 步骤1: ETL增量同步（可选）
    if not args.skip_etl:
        # 确定起始时间
        if args.since:
            since_time = args.since
            print(f"\n📅 使用指定时间: {since_time}")
        else:
            print("\n🔍 正在获取上次同步时间...")
            since_time = await get_last_sync_time()
            print(f"📅 上次同步时间: {since_time}")
        
        # 执行增量同步
        sync_success = await run_incremental_sync(since_time)
        if not sync_success:
            print("\n💥 增量同步失败！")
            return 1
    else:
        print("\n⏭️  步骤1/2: 跳过ETL同步（仅更新知识库）")
    
    # 步骤2: 知识库生成并导入
    kb_success = await run_knowledge_generation()
    if not kb_success:
        print("\n💥 知识库生成并导入失败！")
        return 1
    
    # 完成
    print("\n" + "="*80)
    print("✅ 增量同步流程执行成功！")
    print("="*80)
    print("\n📊 同步总结：")
    print("  - 增量ETL: 仅同步变更的物料（高效）")
    print("  - 知识库: 基于全部数据重新生成（完整）")
    print("\n💡 提示：")
    print("  - 后端服务会在5秒后自动刷新知识库缓存")
    print("  - 无需重启服务即可使用最新知识库")
    
    return 0


if __name__ == "__main__":
    exit_code = asyncio.run(main())
    sys.exit(exit_code)

