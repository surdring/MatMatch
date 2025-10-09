"""
MatMatch FastAPI主应用

智能物料查重系统的API服务入口
"""

import logging
import sys
from contextlib import asynccontextmanager
from pathlib import Path

from fastapi import FastAPI
from fastapi.responses import JSONResponse

# 添加项目根目录到Python路径
project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

from backend.api import __version__
from backend.api.routers import health, materials, admin
from backend.api.exception_handlers import register_exception_handlers
from backend.api.middleware import register_middlewares
from backend.api.dependencies import get_material_processor, reset_material_processor
from backend.core.config import app_config

# 配置日志（同时输出到控制台和文件）
log_dir = project_root / 'logs'
log_dir.mkdir(exist_ok=True)

from datetime import datetime
log_file = log_dir / f'backend_app_{datetime.now().strftime("%Y%m%d_%H%M%S")}.log'

# 创建日志格式
log_format = '%(asctime)s - %(name)s - %(levelname)s - [%(filename)s:%(lineno)d] - %(message)s'

# 配置根日志器
logging.basicConfig(
    level=logging.DEBUG,  # 改为DEBUG级别以获取更多信息
    format=log_format,
    handlers=[
        logging.StreamHandler(sys.stdout),  # 控制台输出
        logging.FileHandler(log_file, encoding='utf-8')  # 文件输出
    ]
)

logger = logging.getLogger(__name__)
logger.info(f"日志文件: {log_file}")


@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    应用生命周期管理
    
    在应用启动和关闭时执行必要的初始化和清理操作
    """
    # ========== 启动事件 ==========
    logger.info("="*80)
    logger.info("MatMatch API Server Starting...")
    logger.info("="*80)
    
    try:
        # 1. 数据库连接验证
        logger.info("Verifying database connection...")
        from backend.database.session import get_session
        from sqlalchemy import text
        async for db in get_session():
            await db.execute(text("SELECT 1"))
            logger.info("[OK] Database connection verified")
            
            # 2. 预热物料处理器（加载知识库）
            logger.info("[预热] 正在加载知识库...")
            processor = await get_material_processor(db)
            # 强制触发知识库加载（_ensure_cache_fresh）
            await processor._ensure_cache_fresh()
            logger.info(f"[OK] 知识库预热完成 - 规则数: {len(processor._extraction_rules)}, "
                       f"同义词数: {len(processor._synonyms)}, "
                       f"分类数: {len(processor._category_keywords)}")
            break
        
        logger.info("="*80)
        logger.info(f"MatMatch API Server v{__version__} is ready!")
        logger.info(f"Swagger UI: http://localhost:8000/docs")
        logger.info(f"ReDoc: http://localhost:8000/redoc")
        logger.info(f"Health Check: http://localhost:8000/health")
        logger.info("="*80)
        
    except Exception as e:
        logger.error(f"Failed to initialize server: {str(e)}", exc_info=True)
        raise
    
    # 应用运行期间
    yield
    
    # ========== 关闭事件 ==========
    logger.info("="*80)
    logger.info("MatMatch API Server Shutting Down...")
    logger.info("="*80)
    
    try:
        # 清理资源
        await reset_material_processor()
        logger.info("[OK] Resources cleaned up")
        
    except Exception as e:
        logger.error(f"Error during shutdown: {str(e)}", exc_info=True)
    
    logger.info("MatMatch API Server stopped")


# 创建FastAPI应用实例
app = FastAPI(
    title="MatMatch API",
    description="""
    ## 智能物料查重系统 API
    
    ### 功能特性
    
    -  **智能物料查重**: 基于多字段加权相似度算法，精准匹配物料
    -  **批量文件处理**: 支持Excel文件批量上传查重
    - 🧠 **知识库管理**: 动态维护规则和同义词词典
    - 📈 **处理透明化**: 完整展示标准化和属性提取过程
    
    ### 核心算法
    
    - **标准化算法**: Hash表同义词替换 (O(1)复杂度)
    - **结构化算法**: 正则表达式属性提取
    - **相似度算法**: PostgreSQL Trigram模糊匹配
    - **分类检测**: 加权关键词匹配
    
    ### 快速开始
    
    1. 访问 [Health Check](/health) 确认服务状态
    2. 查看 [API文档](/docs) 了解接口详情
    3. 使用批量查重接口上传Excel文件
    
    ### 技术栈
    
    - **后端**: Python + FastAPI + SQLAlchemy
    - **数据库**: PostgreSQL + pg_trgm扩展
    - **算法**: Trigram相似度 + 多字段加权
    """,
    version=__version__,
    docs_url="/docs",
    redoc_url="/redoc",
    openapi_url="/openapi.json",
    lifespan=lifespan
)

# 注册中间件
register_middlewares(
    app,
    cors_origins=app_config.cors_origins,
    max_request_size=app_config.max_file_size
)

# 注册异常处理器
register_exception_handlers(app)

# 注册路由
app.include_router(health.root_router)  # 根路径
app.include_router(health.router)       # 健康检查API
app.include_router(materials.router)    # Task 3.2: 批量查重API
app.include_router(admin.router)        # Task 3.4: 管理后台API


# ========== 开发辅助端点 ==========

@app.get("/ping", include_in_schema=False)
async def ping():
    """简单的ping端点，用于快速检查服务是否在线"""
    return {"message": "pong"}


# ========== 应用入口 ==========

if __name__ == "__main__":
    import uvicorn
    
    logger.info("Starting development server...")
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=True,
        log_level="info",
        timeout_keep_alive=300  # 增加到300秒（5分钟）
    )

