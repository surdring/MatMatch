"""
MatMatch 一键启动脚本
功能：自动导入知识库 → 启动后端API → 启动前端
"""
import asyncio
import subprocess
import sys
import time
import json
from pathlib import Path
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from sqlalchemy import text

# 导入配置
sys.path.insert(0, str(Path(__file__).parent / 'backend'))
from backend.core.config import database_config

class MatMatchLauncher:
    def __init__(self):
        self.root_dir = Path(__file__).parent
        self.backend_process = None
        self.frontend_process = None
        
    async def check_knowledge_base(self):
        """检查知识库是否已导入"""
        print("\n🔍 检查知识库状态...")
        engine = create_async_engine(database_config.database_url)
        async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
        
        try:
            async with async_session() as session:
                result = await session.execute(text('SELECT COUNT(*) FROM extraction_rules'))
                rules_count = result.scalar()
                
                result = await session.execute(text('SELECT COUNT(*) FROM synonyms'))
                synonyms_count = result.scalar()
                
                result = await session.execute(text('SELECT COUNT(*) FROM knowledge_categories'))
                categories_count = result.scalar()
                
                print(f"  - 提取规则: {rules_count} 条")
                print(f"  - 同义词: {synonyms_count} 条")
                print(f"  - 分类: {categories_count} 个")
                
                await engine.dispose()
                
                # 判断是否需要导入
                if rules_count == 0 or synonyms_count == 0 or categories_count == 0:
                    print("❌ 知识库数据不完整，需要导入")
                    return False
                else:
                    print("✅ 知识库数据完整")
                    return True
        except Exception as e:
            print(f"❌ 检查失败: {e}")
            await engine.dispose()
            return False
    
    async def import_knowledge_base(self):
        """导入知识库"""
        print("\n📥 开始导入知识库...")
        
        db_dir = Path("database")
        
        # 查找最新文件
        rules_files = list(db_dir.glob("standardized_extraction_rules_*.json"))
        synonym_files = list(db_dir.glob("standardized_synonym_records_*.json"))
        category_files = list(db_dir.glob("standardized_category_keywords_*.json"))
        
        if not all([rules_files, synonym_files, category_files]):
            print("❌ 找不到知识库文件")
            return False
        
        rules_file = sorted(rules_files)[-1]
        synonym_file = sorted(synonym_files)[-1]
        category_file = sorted(category_files)[-1]
        
        print(f"  - 提取规则: {rules_file.name}")
        print(f"  - 同义词: {synonym_file.name}")
        print(f"  - 分类: {category_file.name}")
        
        engine = create_async_engine(database_config.database_url)
        async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
        
        try:
            async with async_session() as session:
                # 1. 清空现有数据
                print("\n🧹 清空现有知识库...")
                await session.execute(text('TRUNCATE TABLE extraction_rules CASCADE'))
                await session.execute(text('TRUNCATE TABLE synonyms CASCADE'))
                await session.execute(text('TRUNCATE TABLE knowledge_categories CASCADE'))
                await session.commit()
                
                # 2. 导入提取规则
                print("\n📥 导入提取规则...")
                with open(rules_file, 'r', encoding='utf-8') as f:
                    rules = json.load(f)
                
                for rule in rules:
                    await session.execute(
                        text("""
                            INSERT INTO extraction_rules 
                            (rule_name, material_category, attribute_name, regex_pattern, priority, is_active, description, example_input, example_output)
                            VALUES (:rule_name, :material_category, :attribute_name, :regex_pattern, :priority, :is_active, :description, :example_input, :example_output)
                        """),
                        {
                            'rule_name': rule['rule_name'],
                            'material_category': rule['material_category'],
                            'attribute_name': rule['attribute_name'],
                            'regex_pattern': rule['regex_pattern'],
                            'priority': rule.get('priority', 100),
                            'is_active': rule.get('is_active', True),
                            'description': rule.get('description', ''),
                            'example_input': rule.get('example_input', ''),
                            'example_output': rule.get('example_output', '')
                        }
                    )
                await session.commit()
                print(f"  ✅ 导入 {len(rules)} 条")
                
                # 3. 导入同义词（批量）
                print("\n📥 导入同义词...")
                with open(synonym_file, 'r', encoding='utf-8') as f:
                    synonyms = json.load(f)
                
                batch_size = 1000
                for i in range(0, len(synonyms), batch_size):
                    batch = synonyms[i:i+batch_size]
                    for syn in batch:
                        await session.execute(
                            text("""
                                INSERT INTO synonyms 
                                (original_term, standard_term, category, synonym_type, confidence, is_active)
                                VALUES (:original_term, :standard_term, :category, :synonym_type, :confidence, :is_active)
                            """),
                            {
                                'original_term': syn['original_term'],
                                'standard_term': syn['standard_term'],
                                'category': syn.get('category', 'general'),
                                'synonym_type': syn.get('synonym_type', 'general'),
                                'confidence': syn.get('confidence', 1.0),
                                'is_active': True
                            }
                        )
                    await session.commit()
                    if (i + batch_size) % 5000 == 0 or i + batch_size >= len(synonyms):
                        print(f"  进度: {min(i+batch_size, len(synonyms))}/{len(synonyms)}")
                
                print(f"  ✅ 导入 {len(synonyms)} 条")
                
                # 4. 导入分类关键词
                print("\n📥 导入分类关键词...")
                with open(category_file, 'r', encoding='utf-8') as f:
                    categories = json.load(f)
                
                for cat_name, keywords in categories.items():
                    if keywords:
                        await session.execute(
                            text("""
                                INSERT INTO knowledge_categories 
                                (category_name, keywords, is_active)
                                VALUES (:category_name, :keywords, :is_active)
                            """),
                            {
                                'category_name': cat_name,
                                'keywords': keywords,
                                'is_active': True
                            }
                        )
                await session.commit()
                print(f"  ✅ 导入 {len([k for k in categories.values() if k])} 个")
            
            await engine.dispose()
            print("\n✅ 知识库导入完成！")
            return True
            
        except Exception as e:
            print(f"\n❌ 导入失败: {e}")
            await engine.dispose()
            return False
    
    def start_backend(self):
        """启动后端服务"""
        print("\n🚀 启动后端API服务...")
        backend_dir = self.root_dir / "backend"
        python_exe = self.root_dir / "venv" / "Scripts" / "python.exe"
        
        cmd = [
            str(python_exe),
            "-m", "uvicorn",
            "api.main:app",
            "--reload",
            "--host", "0.0.0.0",
            "--port", "8000"
        ]
        
        self.backend_process = subprocess.Popen(
            cmd,
            cwd=str(backend_dir),
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            bufsize=1
        )
        
        # 等待后端启动
        print("  等待后端启动...")
        time.sleep(8)
        
        if self.backend_process.poll() is None:
            print("  ✅ 后端服务启动成功: http://localhost:8000")
            print("  📚 API文档: http://localhost:8000/docs")
            return True
        else:
            print("  ❌ 后端服务启动失败")
            return False
    
    def start_frontend(self):
        """启动前端服务"""
        print("\n🚀 启动前端开发服务...")
        frontend_dir = self.root_dir / "frontend"
        
        # Windows需要使用npm.cmd
        npm_cmd = "npm.cmd" if sys.platform == 'win32' else "npm"
        cmd = [npm_cmd, "run", "dev"]
        
        self.frontend_process = subprocess.Popen(
            cmd,
            cwd=str(frontend_dir),
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            bufsize=1,
            creationflags=subprocess.CREATE_NEW_CONSOLE if sys.platform == 'win32' else 0
        )
        
        # 等待前端启动
        print("  等待前端启动...")
        time.sleep(5)
        
        if self.frontend_process.poll() is None:
            print("  ✅ 前端服务启动成功: http://localhost:3000")
            return True
        else:
            print("  ❌ 前端服务启动失败")
            return False
    
    async def run(self):
        """主流程"""
        print("=" * 80)
        print("MatMatch 智能物料查重系统 - 一键启动")
        print("=" * 80)
        
        # 步骤1: 检查知识库
        kb_ok = await self.check_knowledge_base()
        
        # 步骤2: 如果知识库不完整，导入
        if not kb_ok:
            if not await self.import_knowledge_base():
                print("\n❌ 启动失败：知识库导入失败")
                return False
        
        # 步骤3: 启动后端
        if not self.start_backend():
            print("\n❌ 启动失败：后端服务启动失败")
            return False
        
        # 步骤4: 启动前端
        if not self.start_frontend():
            print("\n❌ 启动失败：前端服务启动失败")
            self.cleanup()
            return False
        
        # 完成
        print("\n" + "=" * 80)
        print("🎉 MatMatch 系统启动完成！")
        print("=" * 80)
        print("\n📊 访问地址：")
        print("  - 前端界面: http://localhost:3000")
        print("  - 后端API: http://localhost:8000")
        print("  - API文档: http://localhost:8000/docs")
        print("\n💡 提示：")
        print("  - 按 Ctrl+C 停止所有服务")
        print("  - 后端日志将显示在当前窗口")
        print("  - 前端日志在新窗口中")
        print("=" * 80)
        
        # 保持运行并显示后端日志
        try:
            print("\n📝 后端日志：\n")
            while True:
                output = self.backend_process.stdout.readline()
                if output:
                    print(output.rstrip())
                elif self.backend_process.poll() is not None:
                    break
                time.sleep(0.1)
        except KeyboardInterrupt:
            print("\n\n⏹️  停止所有服务...")
            self.cleanup()
        
        return True
    
    def cleanup(self):
        """清理进程"""
        if self.backend_process:
            self.backend_process.terminate()
            print("  ✓ 后端服务已停止")
        
        if self.frontend_process:
            self.frontend_process.terminate()
            print("  ✓ 前端服务已停止")

async def main():
    launcher = MatMatchLauncher()
    await launcher.run()

if __name__ == "__main__":
    asyncio.run(main())

