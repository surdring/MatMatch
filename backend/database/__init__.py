"""
数据库模块初始化
提供数据库相关功能的统一入口

对应 [I.4] 命名规范承诺 - 模块化组织
"""

from .session import db_manager, get_db, get_test_session
from .migrations import migration_manager, run_full_migration

__all__ = [
    "db_manager",
    "get_db", 
    "get_test_session",
    "migration_manager",
    "run_full_migration"
]
