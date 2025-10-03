"""
文件清单工具
显示database目录中所有文件的状态和用途
"""

import os
import json
from datetime import datetime
from pathlib import Path

def get_file_info():
    """获取文件信息"""
    current_dir = Path('.')
    files_info = []
    
    # 定义文件类别和描述
    file_descriptions = {
        # 核心执行脚本
        'analyze_real_data.py': ('🔍 核心脚本', '分析Oracle真实数据', '必须首次执行'),
        'generate_standardized_rules.py': ('📊 核心脚本', '生成标准化规则和词典', '核心生成工具'),
        'generate_sql_import_script.py': ('🗄️ 核心脚本', '生成PostgreSQL导入脚本', '推荐导入方式'),
        'import_to_postgresql.py': ('🚀 核心脚本', 'Python方式导入PostgreSQL', 'Python环境导入'),
        'test_generated_rules.py': ('🧪 核心脚本', '测试规则效果', '验证生成质量'),
        
        # 配置和连接文件
        'oracle_config.py': ('⚙️ 配置文件', 'Oracle数据库配置', '连接参数、SQL查询'),
        'oracledb_connector.py': ('⚙️ 配置文件', 'Oracle数据库连接器', '连接、查询方法'),
        'test_oracle_connection.py': ('⚙️ 配置文件', 'Oracle连接测试', '连接验证'),
        
        # 辅助工具
        'check_oracle_tables.py': ('🔍 辅助工具', '检查Oracle表结构', '调试连接问题'),
        'check_material_fields.py': ('🔍 辅助工具', '检查物料表字段', '验证表结构'),
        'quick_import.bat': ('🔍 辅助工具', 'Windows快速导入', 'Windows一键导入'),
        
        # 旧版本/备用脚本
        'generate_rules_and_dictionary.py': ('🔄 旧版脚本', '旧版规则生成器', '已被替代'),
        'intelligent_rule_generator.py': ('📚 参考脚本', '智能规则生成器核心', '高级定制参考'),
        'init_postgresql_rules.py': ('🔄 旧版脚本', '旧版PostgreSQL初始化', '已被替代'),
        'one_click_setup.py': ('🔄 旧版脚本', '一键设置脚本', '已被替代'),
        
        # 文档和指南
        'README.md': ('📄 文档', '主要使用指南', '完整操作流程'),
        'postgresql_import_guide.md': ('📄 文档', 'PostgreSQL导入指南', '详细导入步骤'),
        '同义词词典构建操作指南.md': ('📄 文档', '同义词词典指南', '词典构建方法'),
        'requirements.txt': ('📄 配置', 'Python依赖清单', '项目依赖包'),
    }
    
    for file_path in current_dir.iterdir():
        if file_path.is_file() and not file_path.name.startswith('.') and file_path.name != '__pycache__':
            file_name = file_path.name
            file_size = file_path.stat().st_size
            file_mtime = datetime.fromtimestamp(file_path.stat().st_mtime)
            
            # 获取文件描述
            if file_name in file_descriptions:
                category, description, usage = file_descriptions[file_name]
            elif file_name.startswith('oracle_data_analysis_'):
                category, description, usage = ('📊 数据文件', 'Oracle数据分析结果', '分析结果JSON')
            elif file_name.startswith('oracle_data_analysis_report_'):
                category, description, usage = ('📊 数据文件', 'Oracle数据分析报告', '可读分析报告')
            elif file_name.startswith('standardized_extraction_rules_'):
                category, description, usage = ('📊 数据文件', '标准化提取规则', '6条高质量规则')
            elif file_name.startswith('standardized_synonym_dictionary_'):
                category, description, usage = ('📊 数据文件', '标准化同义词典', '3,347个同义词')
            elif file_name.startswith('standardized_category_keywords_'):
                category, description, usage = ('📊 数据文件', '标准化类别关键词', '1,243个类别')
            elif file_name.startswith('standardized_rules_usage_'):
                category, description, usage = ('📄 文档', '标准化规则使用说明', '规则使用文档')
            elif file_name.startswith('postgresql_import_') and file_name.endswith('.sql'):
                category, description, usage = ('🗄️ SQL文件', 'PostgreSQL导入脚本', '4,596条SQL语句')
            elif file_name.startswith('postgresql_import_usage_'):
                category, description, usage = ('📄 文档', 'PostgreSQL导入说明', '导入使用文档')
            else:
                category, description, usage = ('❓ 其他', '未分类文件', '需要检查')
            
            files_info.append({
                'name': file_name,
                'category': category,
                'description': description,
                'usage': usage,
                'size': file_size,
                'size_mb': round(file_size / 1024 / 1024, 2) if file_size > 1024*1024 else round(file_size / 1024, 2),
                'size_unit': 'MB' if file_size > 1024*1024 else 'KB',
                'modified': file_mtime.strftime('%Y-%m-%d %H:%M:%S')
            })
    
    return sorted(files_info, key=lambda x: (x['category'], x['name']))

def print_file_summary():
    """打印文件摘要"""
    files_info = get_file_info()
    
    print("=" * 80)
    print("📁 智能物料查重工具 - Database目录文件清单")
    print("=" * 80)
    print(f"📊 统计时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"📂 总文件数: {len(files_info)}")
    print()
    
    # 按类别分组
    categories = {}
    total_size = 0
    
    for file_info in files_info:
        category = file_info['category']
        if category not in categories:
            categories[category] = []
        categories[category].append(file_info)
        total_size += file_info['size']
    
    print(f"💾 总大小: {round(total_size / 1024 / 1024, 2)} MB")
    print()
    
    # 显示各类别文件
    for category, files in categories.items():
        print(f"{category} ({len(files)}个文件)")
        print("-" * 60)
        
        for file_info in files:
            size_str = f"{file_info['size_mb']}{file_info['size_unit']}"
            print(f"  📄 {file_info['name']:<40} {size_str:>8}")
            print(f"      {file_info['description']} - {file_info['usage']}")
            print(f"      修改时间: {file_info['modified']}")
            print()
    
    # 显示推荐使用流程
    print("🚀 推荐使用流程:")
    print("-" * 60)
    print("1. python analyze_real_data.py              # 分析Oracle数据")
    print("2. python generate_standardized_rules.py    # 生成标准化规则")
    print("3. python generate_sql_import_script.py     # 生成SQL导入脚本")
    print("4. psql -f postgresql_import_*.sql          # 导入到PostgreSQL")
    print("5. python test_generated_rules.py           # 测试规则效果")
    print()
    
    # 显示关键文件状态
    key_files = [
        'oracle_data_analysis_20251002_184248.json',
        'standardized_extraction_rules_20251002_184612.json',
        'standardized_synonym_dictionary_20251002_184612.json',
        'postgresql_import_20251002_185603.sql'
    ]
    
    print("🔑 关键文件状态:")
    print("-" * 60)
    for key_file in key_files:
        exists = any(f['name'] == key_file for f in files_info)
        status = "✅ 存在" if exists else "❌ 缺失"
        print(f"  {status} {key_file}")
    print()

def save_file_inventory():
    """保存文件清单到JSON"""
    files_info = get_file_info()
    
    inventory = {
        'generated_at': datetime.now().isoformat(),
        'total_files': len(files_info),
        'total_size_mb': round(sum(f['size'] for f in files_info) / 1024 / 1024, 2),
        'files': files_info
    }
    
    with open('file_inventory.json', 'w', encoding='utf-8') as f:
        json.dump(inventory, f, ensure_ascii=False, indent=2)
    
    print(f"📋 文件清单已保存到: file_inventory.json")

if __name__ == "__main__":
    print_file_summary()
    save_file_inventory()
