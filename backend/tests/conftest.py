"""
Pytest配置文件

本文件包含pytest的全局配置和共享夹具。
所有测试模块都可以使用这里定义的夹具。

符合GEMINI.md测试规范
"""

import pytest
import asyncio
from typing import Generator


# ============================================================================
# Pytest配置
# ============================================================================

def pytest_configure(config):
    """
    Pytest配置钩子
    
    在测试运行前执行，用于设置全局配置
    """
    # 注册自定义标记
    config.addinivalue_line(
        "markers", "asyncio: mark test as an asyncio test"
    )
    config.addinivalue_line(
        "markers", "slow: mark test as slow running"
    )
    config.addinivalue_line(
        "markers", "performance: mark test as performance test"
    )
    config.addinivalue_line(
        "markers", "admin: mark test as admin API test"
    )


# ============================================================================
# Asyncio事件循环配置
# ============================================================================

@pytest.fixture(scope="session")
def event_loop() -> Generator:
    """
    创建一个全局的事件循环
    
    确保所有异步测试使用同一个事件循环
    """
    loop = asyncio.get_event_loop_policy().new_event_loop()
    yield loop
    loop.close()


# ============================================================================
# 导入共享夹具
# ============================================================================

# 从fixtures模块导入所有夹具
pytest_plugins = [
    "backend.tests.fixtures.admin_fixtures",
]


# ============================================================================
# 测试报告配置
# ============================================================================

@pytest.hookimpl(tryfirst=True, hookwrapper=True)
def pytest_runtest_makereport(item, call):
    """
    为测试报告添加额外信息
    """
    outcome = yield
    rep = outcome.get_result()
    
    # 添加测试持续时间
    if rep.when == "call":
        setattr(item, f"rep_{rep.outcome}", rep)


# ============================================================================
# 测试前置/后置钩子
# ============================================================================

@pytest.fixture(autouse=True)
async def setup_teardown():
    """
    全局测试前置/后置夹具
    
    在每个测试前后自动执行
    """
    # 测试前：设置
    # 可以在这里添加全局设置逻辑
    
    yield
    
    # 测试后：清理
    # 可以在这里添加全局清理逻辑


# ============================================================================
# 性能测试辅助
# ============================================================================

@pytest.fixture
def benchmark_timer():
    """
    性能测试计时器夹具
    
    提供一个简单的计时器，用于测量执行时间
    
    使用示例:
    ```python
    def test_performance(benchmark_timer):
        with benchmark_timer.measure() as timer:
            # 执行需要测量的代码
            ...
        
        assert timer.duration_ms < 200  # 验证性能
    ```
    """
    import time
    from contextlib import contextmanager
    
    class Timer:
        def __init__(self):
            self.duration_ms = 0
        
        @contextmanager
        def measure(self):
            start = time.time()
            yield self
            self.duration_ms = (time.time() - start) * 1000
    
    return Timer()
