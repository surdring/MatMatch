"""
完整的知识库导入和验证脚本

功能：
1. 自动生成SQL导入脚本
2. 执行SQL导入（方式一）
3. 清空数据库
4. 执行Python异步导入（方式二）
5. 运行对称性验证
6. 生成完整的测试报告

使用方法：
    python run_full_import_verification.py
"""

import asyncio
import subprocess
import sys
import os
import logging
from pathlib import Path
from datetime import datetime
import json

# 配置日志
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(sys.stdout),
        logging.FileHandler(
            f'logs/full_import_verification_{datetime.now().strftime("%Y%m%d_%H%M%S")}.log',
            encoding='utf-8'
        )
    ]
)
logger = logging.getLogger(__name__)


class FullImportVerification:
    """完整的导入验证流程"""
    
    def __init__(self):
        self.project_root = Path(__file__).parent.parent
        self.database_dir = Path(__file__).parent
        self.backend_dir = self.project_root / "backend"
        
        # PostgreSQL连接配置
        self.pg_config = {
            'host': '127.0.0.1',
            'port': '5432',
            'user': 'postgres',
            'database': 'matmatch',
            'password': 'xqxatcdj'
        }
        
        # 查找psql路径
        self.psql_path = self._find_psql()
        
        self.results = {
            'sql_generation': None,
            'sql_import': None,
            'python_import': None,
            'symmetry_verification': None,
            'start_time': datetime.now(),
            'end_time': None
        }
    
    def _find_psql(self):
        """查找psql可执行文件"""
        # Windows常见安装路径
        possible_paths = [
            r"D:\Program Files\PostgreSQL\18\bin\psql.exe",
            r"C:\Program Files\PostgreSQL\18\bin\psql.exe",
            r"C:\Program Files\PostgreSQL\17\bin\psql.exe",
            r"C:\Program Files\PostgreSQL\16\bin\psql.exe",
            r"C:\Program Files (x86)\PostgreSQL\18\bin\psql.exe",
        ]
        
        for path in possible_paths:
            if os.path.exists(path):
                logger.info(f"✅ 找到psql: {path}")
                return path
        
        # 尝试从PATH中查找
        try:
            result = subprocess.run(
                ['where', 'psql'],
                capture_output=True,
                text=True,
                shell=True
            )
            if result.returncode == 0:
                path = result.stdout.strip().split('\n')[0]
                logger.info(f"✅ 从PATH找到psql: {path}")
                return path
        except Exception:
            pass
        
        logger.warning("⚠️ 未找到psql，SQL导入可能失败")
        return "psql"
    
    async def step1_generate_sql(self):
        """步骤1: 生成SQL导入脚本"""
        logger.info("=" * 80)
        logger.info("📝 步骤1: 生成SQL导入脚本")
        logger.info("=" * 80)
        
        try:
            # 运行SQL生成脚本
            env = os.environ.copy()
            env['PYTHONIOENCODING'] = 'utf-8'
            
            result = subprocess.run(
                [sys.executable, "generate_sql_import_script.py"],
                cwd=self.database_dir,
                capture_output=True,
                text=True,
                encoding='utf-8',
                errors='replace',
                env=env
            )
            
            if result.returncode == 0:
                logger.info("✅ SQL导入脚本生成成功")
                logger.info(result.stdout)
                self.results['sql_generation'] = {
                    'status': 'success',
                    'output': result.stdout
                }
                return True
            else:
                logger.error(f"❌ SQL生成失败: {result.stderr}")
                self.results['sql_generation'] = {
                    'status': 'failed',
                    'error': result.stderr
                }
                return False
        except Exception as e:
            logger.error(f"❌ SQL生成异常: {e}")
            self.results['sql_generation'] = {
                'status': 'error',
                'error': str(e)
            }
            return False
    
    def _find_latest_sql_file(self):
        """查找最新的SQL导入文件"""
        sql_files = list(self.database_dir.glob("postgresql_import_*.sql"))
        if not sql_files:
            return None
        return max(sql_files, key=lambda p: p.stat().st_mtime)
    
    async def step2_sql_import(self):
        """步骤2: 执行SQL导入（方式一）"""
        logger.info("=" * 80)
        logger.info("🗄️ 步骤2: 执行SQL导入（方式一）")
        logger.info("=" * 80)
        
        # 查找最新的SQL文件
        sql_file = self._find_latest_sql_file()
        if not sql_file:
            logger.error("❌ 未找到SQL导入文件")
            self.results['sql_import'] = {
                'status': 'failed',
                'error': 'SQL file not found'
            }
            return False
        
        logger.info(f"📄 使用SQL文件: {sql_file.name}")
        
        try:
            # 设置环境变量
            env = os.environ.copy()
            env['PGPASSWORD'] = self.pg_config['password']
            
            # 执行psql命令
            cmd = [
                self.psql_path,
                '-h', self.pg_config['host'],
                '-p', self.pg_config['port'],
                '-U', self.pg_config['user'],
                '-d', self.pg_config['database'],
                '-f', str(sql_file)
            ]
            
            logger.info(f"🚀 执行命令: {' '.join(cmd)}")
            
            result = subprocess.run(
                cmd,
                env=env,
                capture_output=True,
                text=True,
                encoding='utf-8',
                cwd=self.database_dir
            )
            
            # 检查结果（SQL导入可能有警告，但退出码为0就算成功）
            if result.returncode == 0:
                logger.info("✅ SQL导入完成")
                
                # 验证导入结果
                counts = await self._get_record_counts()
                logger.info(f"📊 导入统计:")
                logger.info(f"  - extraction_rules: {counts['extraction_rules']} 条")
                logger.info(f"  - synonyms: {counts['synonyms']} 条")
                logger.info(f"  - knowledge_categories: {counts['knowledge_categories']} 条")
                
                self.results['sql_import'] = {
                    'status': 'success',
                    'counts': counts
                }
                return True
            else:
                logger.error(f"❌ SQL导入失败: {result.stderr}")
                self.results['sql_import'] = {
                    'status': 'failed',
                    'error': result.stderr
                }
                return False
        except Exception as e:
            logger.error(f"❌ SQL导入异常: {e}")
            self.results['sql_import'] = {
                'status': 'error',
                'error': str(e)
            }
            return False
    
    async def _get_record_counts(self):
        """获取数据库记录数（使用psql直接查询）"""
        counts = {}
        
        try:
            env = os.environ.copy()
            env['PGPASSWORD'] = self.pg_config['password']
            
            for table in ['extraction_rules', 'synonyms', 'knowledge_categories']:
                cmd = [
                    self.psql_path,
                    '-h', self.pg_config['host'],
                    '-p', self.pg_config['port'],
                    '-U', self.pg_config['user'],
                    '-d', self.pg_config['database'],
                    '-t',  # 只输出数据，不要表头
                    '-c', f"SELECT COUNT(*) FROM {table}"
                ]
                
                result = subprocess.run(
                    cmd,
                    env=env,
                    capture_output=True,
                    text=True
                )
                
                if result.returncode == 0:
                    counts[table] = int(result.stdout.strip())
                else:
                    counts[table] = -1
        except Exception:
            pass
        
        return counts
    
    async def step3_clear_database(self):
        """步骤3: 清空数据库准备Python导入（使用psql）"""
        logger.info("=" * 80)
        logger.info("🧹 步骤3: 清空数据库（准备Python导入）")
        logger.info("=" * 80)
        
        try:
            env = os.environ.copy()
            env['PGPASSWORD'] = self.pg_config['password']
            
            sql_commands = """
            DELETE FROM knowledge_categories;
            DELETE FROM synonyms;
            DELETE FROM extraction_rules;
            """
            
            cmd = [
                self.psql_path,
                '-h', self.pg_config['host'],
                '-p', self.pg_config['port'],
                '-U', self.pg_config['user'],
                '-d', self.pg_config['database'],
                '-c', sql_commands
            ]
            
            result = subprocess.run(
                cmd,
                env=env,
                capture_output=True,
                text=True
            )
            
            if result.returncode == 0:
                logger.info("✅ 数据库已清空")
                return True
            else:
                logger.error(f"❌ 清空数据库失败: {result.stderr}")
                return False
        except Exception as e:
            logger.error(f"❌ 清空数据库异常: {e}")
            return False
    
    async def step4_python_import(self):
        """步骤4: 执行Python异步导入（方式二）"""
        logger.info("=" * 80)
        logger.info("🐍 步骤4: 执行Python异步导入（方式二）")
        logger.info("=" * 80)
        
        try:
            # 运行Python导入脚本（避免编码问题）
            env = os.environ.copy()
            env['PYTHONIOENCODING'] = 'utf-8'
            
            result = subprocess.run(
                [sys.executable, "../backend/scripts/import_knowledge_base.py"],
                cwd=self.database_dir,
                capture_output=True,
                text=True,
                encoding='utf-8',
                errors='replace',  # 替换无法编码的字符
                env=env
            )
            
            if result.returncode == 0:
                logger.info("✅ Python异步导入完成")
                logger.info(result.stdout)
                
                # 验证导入结果
                counts = await self._get_record_counts()
                logger.info(f"📊 导入统计:")
                logger.info(f"  - extraction_rules: {counts['extraction_rules']} 条")
                logger.info(f"  - synonyms: {counts['synonyms']} 条")
                logger.info(f"  - knowledge_categories: {counts['knowledge_categories']} 条")
                
                self.results['python_import'] = {
                    'status': 'success',
                    'counts': counts,
                    'output': result.stdout
                }
                return True
            else:
                logger.error(f"❌ Python导入失败: {result.stderr}")
                self.results['python_import'] = {
                    'status': 'failed',
                    'error': result.stderr
                }
                return False
        except Exception as e:
            logger.error(f"❌ Python导入异常: {e}")
            self.results['python_import'] = {
                'status': 'error',
                'error': str(e)
            }
            return False
    
    async def step5_verify_symmetry(self):
        """步骤5: 运行对称性验证"""
        logger.info("=" * 80)
        logger.info("🔍 步骤5: 验证SQL导入和Python导入的对称性")
        logger.info("=" * 80)
        
        try:
            # 运行对称性验证脚本
            env = os.environ.copy()
            env['PYTHONIOENCODING'] = 'utf-8'
            
            result = subprocess.run(
                [sys.executable, "../backend/scripts/verify_symmetry.py"],
                cwd=self.database_dir,
                capture_output=True,
                text=True,
                encoding='utf-8',
                errors='replace',
                env=env
            )
            
            # 检查验证结果
            success = "🎉 完美！SQL导入和Python导入完全对称！" in result.stdout
            
            if success:
                logger.info("✅ 对称性验证通过")
                logger.info(result.stdout)
                self.results['symmetry_verification'] = {
                    'status': 'passed',
                    'output': result.stdout
                }
                return True
            else:
                logger.warning("⚠️ 对称性验证未完全通过")
                logger.warning(result.stdout)
                if result.stderr:
                    logger.error(result.stderr)
                self.results['symmetry_verification'] = {
                    'status': 'failed',
                    'output': result.stdout,
                    'error': result.stderr
                }
                return False
        except Exception as e:
            logger.error(f"❌ 对称性验证异常: {e}")
            self.results['symmetry_verification'] = {
                'status': 'error',
                'error': str(e)
            }
            return False
    
    def generate_report(self):
        """生成测试报告"""
        self.results['end_time'] = datetime.now()
        duration = (self.results['end_time'] - self.results['start_time']).total_seconds()
        
        logger.info("=" * 80)
        logger.info("📋 完整测试报告")
        logger.info("=" * 80)
        logger.info(f"开始时间: {self.results['start_time'].strftime('%Y-%m-%d %H:%M:%S')}")
        logger.info(f"结束时间: {self.results['end_time'].strftime('%Y-%m-%d %H:%M:%S')}")
        logger.info(f"总耗时: {duration:.2f} 秒")
        logger.info("")
        
        # 各步骤结果
        steps = [
            ('SQL脚本生成', 'sql_generation'),
            ('SQL导入（方式一）', 'sql_import'),
            ('Python导入（方式二）', 'python_import'),
            ('对称性验证', 'symmetry_verification')
        ]
        
        all_passed = True
        for step_name, step_key in steps:
            result = self.results.get(step_key)
            if result:
                status = result.get('status', 'unknown')
                if status in ['success', 'passed']:
                    logger.info(f"✅ {step_name}: 成功")
                    if 'counts' in result:
                        counts = result['counts']
                        logger.info(f"   - extraction_rules: {counts['extraction_rules']}")
                        logger.info(f"   - synonyms: {counts['synonyms']}")
                        logger.info(f"   - knowledge_categories: {counts['knowledge_categories']}")
                else:
                    logger.error(f"❌ {step_name}: 失败")
                    if 'error' in result:
                        logger.error(f"   错误: {result['error'][:200]}")
                    all_passed = False
            else:
                logger.warning(f"⚠️ {step_name}: 未执行")
                all_passed = False
        
        logger.info("")
        logger.info("=" * 80)
        if all_passed:
            logger.info("🎉 所有测试通过！知识库导入和验证完成！")
            logger.info("✅ 验证了'对称处理'原则的正确实现")
        else:
            logger.error("💥 部分测试失败，请检查上述错误信息")
        logger.info("=" * 80)
        
        # 保存JSON格式的详细报告
        report_file = self.database_dir / f"logs/test_report_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        report_file.parent.mkdir(exist_ok=True)
        
        with open(report_file, 'w', encoding='utf-8') as f:
            # 转换datetime为字符串
            results_copy = self.results.copy()
            results_copy['start_time'] = results_copy['start_time'].isoformat()
            results_copy['end_time'] = results_copy['end_time'].isoformat()
            results_copy['duration_seconds'] = duration
            results_copy['all_passed'] = all_passed
            
            json.dump(results_copy, f, indent=2, ensure_ascii=False)
        
        logger.info(f"📄 详细报告已保存: {report_file}")
        
        return all_passed
    
    async def run(self):
        """运行完整的测试流程"""
        logger.info("🚀 开始完整的知识库导入和验证流程")
        logger.info("=" * 80)
        
        try:
            # 确保logs目录存在
            (self.database_dir / "logs").mkdir(exist_ok=True)
            
            # 步骤1: 生成SQL脚本
            if not await self.step1_generate_sql():
                logger.error("SQL生成失败，终止流程")
                return False
            
            # 步骤2: SQL导入
            if not await self.step2_sql_import():
                logger.error("SQL导入失败，终止流程")
                return False
            
            # 步骤3: 清空数据库
            if not await self.step3_clear_database():
                logger.error("清空数据库失败，终止流程")
                return False
            
            # 步骤4: Python导入
            if not await self.step4_python_import():
                logger.error("Python导入失败，终止流程")
                return False
            
            # 步骤5: 对称性验证
            if not await self.step5_verify_symmetry():
                logger.warning("对称性验证未通过，但继续生成报告")
            
            # 生成最终报告
            return self.generate_report()
            
        except Exception as e:
            logger.error(f"❌ 流程执行异常: {e}", exc_info=True)
            return False


async def main():
    """主函数"""
    verifier = FullImportVerification()
    success = await verifier.run()
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    # 确保在正确的目录运行
    os.chdir(Path(__file__).parent)
    
    # 运行异步主函数
    asyncio.run(main())

