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
from backend.api.routers import health, materials
from backend.api.exception_handlers import register_exception_handlers
from backend.api.middleware import register_middlewares
from backend.api.dependencies import get_material_processor, reset_material_processor
from backend.core.config import app_config

# 配置日志
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(sys.stdout)
    ]
)

logger = logging.getLogger(__name__)


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
        # 1. 预热物料处理器（加载知识库）
        logger.info("Initializing Material Processor...")
        processor = await get_material_processor()
        logger.info(f"✓ Material Processor initialized")
        logger.info(f"  - Knowledge base loaded: {processor._knowledge_base_loaded}")
        
        # 2. 数据库连接验证
        logger.info("Verifying database connection...")
        from backend.database.session import get_session
        async for db in get_session():
            await db.execute("SELECT 1")
            logger.info("✓ Database connection verified")
            break
        
        logger.info("="*80)
        logger.info(f"MatMatch API Server v{__version__} is ready!")
        logger.info(f"📚 Swagger UI: http://localhost:8000/docs")
        logger.info(f"📖 ReDoc: http://localhost:8000/redoc")
        logger.info(f"💚 Health Check: http://localhost:8000/health")
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
        logger.info("✓ Resources cleaned up")
        
    except Exception as e:
        logger.error(f"Error during shutdown: {str(e)}", exc_info=True)
    
    logger.info("MatMatch API Server stopped")


# 创建FastAPI应用实例
app = FastAPI(
    title="MatMatch API",
    description="""
    ## 智能物料查重系统 API
    
    ### 功能特性
    
    - 🔍 **智能物料查重**: 基于多字段加权相似度算法，精准匹配物料
    - 📊 **批量文件处理**: 支持Excel文件批量上传查重
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
app.include_router(health.router)
app.include_router(materials.router)  # Task 3.2: 批量查重API


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
        log_level="info"
    )

