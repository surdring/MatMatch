"""
Oracle数据库配置和查询定义

本文件包含Oracle数据库的连接配置、查询语句定义以及物料数据相关的SQL查询
"""

import os
from typing import Dict, Any


class OracleConfig:
    """Oracle数据库配置类"""
    
    # 数据库连接配置
    DB_CONFIG = {
        'host': '192.168.80.90',
        'port': 1521,
        'service_name': 'ORCL',
        'username': 'matmatch_read',
        'password': os.getenv('ORACLE_READONLY_PASSWORD', 'matmatch_read'),
        'encoding': 'UTF-8',
        'timeout': 30
    }
    
    # 查询超时设置（秒）
    QUERY_TIMEOUT = 300
    
    # 批量查询大小
    BATCH_SIZE = 1000
    
    @classmethod
    def get_connection_string(cls) -> str:
        """获取数据库连接字符串"""
        return f"{cls.DB_CONFIG['username']}/{cls.DB_CONFIG['password']}@{cls.DB_CONFIG['host']}:{cls.DB_CONFIG['port']}/{cls.DB_CONFIG['service_name']}"
    
    @classmethod
    def get_connection_params(cls) -> Dict[str, Any]:
        """获取数据库连接参数"""
        return cls.DB_CONFIG.copy()


class MaterialQueries:
    """物料数据查询语句定义"""
    
    # 基础物料信息查询（基于真实表结构，包括分类信息）
    BASIC_MATERIAL_QUERY = """
    SELECT 
        m.code as erp_code,
        m.name as material_name,
        m.materialspec as specification,
        m.materialtype as model,
        m.ename as english_name,
        m.ematerialspec as english_spec,
        m.materialshortname as short_name,
        m.materialmnecode as mnemonic_code,
        m.memo as remark,
        m.enablestate as enable_state,
        m.creationtime as created_time,
        m.modifiedtime as modified_time,
        
        -- 分类信息
        m.pk_marbasclass as category_id,
        c.code as category_code,
        c.name as category_name,
        c.pk_parent as parent_category_id,
        c.enablestate as category_enable_state,
        
        -- 品牌和单位信息
        m.pk_brand as brand_id,
        m.pk_measdoc as unit_id,
        u.name as unit_name,
        u.ename as unit_english_name,
        
        -- 组织信息
        m.pk_org as org_id
        
    FROM DHNC65.bd_material m
    LEFT JOIN DHNC65.bd_marbasclass c ON m.pk_marbasclass = c.pk_marbasclass
    LEFT JOIN DHNC65.bd_measdoc u ON m.pk_measdoc = u.pk_measdoc
    -- 包含所有物料（不限制启用状态）
    ORDER BY m.code
    """
    
    # 物料分类信息查询
    MATERIAL_CATEGORIES_QUERY = """
    SELECT 
        pk_marbasclass as category_id,
        code as category_code,
        name as category_name,
        pk_parent as parent_category_id,
        enablestate as enable_state,
        creationtime as created_time,
        modifiedtime as modified_time
    FROM DHNC65.bd_marbasclass
    -- 包含所有分类（不限制启用状态）
    ORDER BY code
    """
    
    # 物料计量单位查询
    UNIT_QUERY = """
    SELECT 
        code as unit_code,
        name as unit_name,
        ename as english_name,
        oppdimen as dimension,
        scalefactor as scale_factor,
        bitnumber as decimal_places,
        basecodeflag as is_base_unit
    FROM DHNC65.bd_measdoc
    """
    
    # 分页查询物料数据
    @classmethod
    def get_paginated_material_query(cls, page: int = 1, page_size: int = 1000) -> str:
        """获取分页物料查询语句"""
        offset = (page - 1) * page_size
        return f"""
        SELECT * FROM (
            SELECT a.*, ROWNUM rn FROM (
                {cls.BASIC_MATERIAL_QUERY}
            ) a
            WHERE ROWNUM <= {offset + page_size}
        )
        WHERE rn > {offset}
        """
    
    # 根据物料编码查询特定物料（包括无效状态）
    @classmethod
    def get_material_by_code_query(cls, material_codes: list) -> str:
        """根据物料编码列表查询物料"""
        codes_str = ",".join([f"'{code}'" for code in material_codes])
        return f"""
        SELECT 
            m.code as erp_code,
            m.name as original_description,
            m.materialspec as specification,
            m.materialtype as category,
            m.pk_measdoc as unit_id,
            u.name as unit_name,
            u.ename as unit_english_name,
            m.enablestate as status
        FROM bd_material m
        LEFT JOIN bd_measdoc u ON m.pk_measdoc = u.pk_measdoc
        WHERE m.code IN ({codes_str})
        """


class ExtractionQueries:
    """数据提取专用查询语句"""
    
    # 统计物料总数（所有物料，包括无效状态）
    COUNT_QUERY = """
    SELECT COUNT(*) as total_count
    FROM bd_material 
    """
    
    # 获取物料类型分布（所有物料，包括无效状态）
    TYPE_DISTRIBUTION_QUERY = """
    SELECT 
        materialtype as category,
        COUNT(*) as count
    FROM bd_material 
    GROUP BY materialtype
    ORDER BY count DESC
    """
    
    # 获取物料描述长度统计（所有物料，包括无效状态）
    DESCRIPTION_STATS_QUERY = """
    SELECT 
        MIN(LENGTH(name)) as min_length,
        MAX(LENGTH(name)) as max_length,
        AVG(LENGTH(name)) as avg_length,
        COUNT(*) as total_count
    FROM bd_material 
    """


class ValidationQueries:
    """数据验证查询语句"""
    
    # 验证表是否存在
    TABLE_EXISTS_QUERY = """
    SELECT table_name 
    FROM user_tables 
    WHERE table_name = UPPER(:table_name)
    """
    
    # 验证列是否存在
    COLUMN_EXISTS_QUERY = """
    SELECT column_name 
    FROM user_tab_columns 
    WHERE table_name = UPPER(:table_name)
    AND column_name = UPPER(:column_name)
    """
    
    # 验证连接是否正常
    CONNECTION_TEST_QUERY = "SELECT 1 FROM DUAL"


# 配置验证函数
def validate_config() -> bool:
    """验证配置是否完整"""
    config = OracleConfig.DB_CONFIG
    
    # 检查必要配置项
    required_fields = ['host', 'port', 'service_name', 'username', 'password']
    for field in required_fields:
        if not config.get(field):
            print(f"❌ 缺少必要配置项: {field}")
            return False
    
    # 检查端口范围
    if not (1 <= config['port'] <= 65535):
        print(f"❌ 端口号超出范围: {config['port']}")
        return False
    
    print("✅ 配置验证通过")
    return True


if __name__ == "__main__":
    """配置测试代码"""
    print("=== Oracle数据库配置测试 ===")
    
    # 测试配置验证
    if validate_config():
        print("配置验证: 通过")
        
        # 显示连接信息（隐藏密码）
        config = OracleConfig.DB_CONFIG.copy()
        config['password'] = '***'  # 隐藏密码
        print(f"数据库配置: {config}")
        print(f"连接字符串: {OracleConfig.get_connection_string().replace(config['password'], '***')}")
        
        # 测试查询语句
        print("\n=== 查询语句测试 ===")
        print("基础物料查询:")
        print(MaterialQueries.BASIC_MATERIAL_QUERY[:100] + "...")
        
        print("\n分页查询 (第1页, 1000条):")
        print(MaterialQueries.get_paginated_material_query(1, 1000)[:100] + "...")
        
        print("\n统计查询:")
        print(ExtractionQueries.COUNT_QUERY)
        
        print("\n✅ 配置测试完成")
    else:
        print("❌ 配置验证失败")