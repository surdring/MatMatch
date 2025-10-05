"""
Excel测试文件生成工具

用于创建测试用的Excel文件，包含各种测试场景
"""

import pandas as pd
from pathlib import Path
from typing import List, Dict, Any
import io


class ExcelFixtureGenerator:
    """Excel测试文件生成器"""
    
    @staticmethod
    def create_standard_test_file() -> io.BytesIO:
        """
        创建标准测试Excel文件
        
        包含所有必需列：物料名称、规格型号、单位
        10行正常数据
        
        Returns:
            BytesIO对象，可直接用于UploadFile
        """
        data = {
            "序号": list(range(1, 11)),
            "物料名称": [
                "六角螺栓",
                "内六角螺钉",
                "球阀",
                "截止阀",
                "轴承",
                "深沟球轴承",
                "电缆",
                "电力电缆",
                "管件",
                "弯头"
            ],
            "规格型号": [
                "M8*20",
                "M10*25",
                "DN50",
                "DN25",
                "6205",
                "6308",
                "4*6",
                "3*4",
                "DN100",
                "DN50 90度"
            ],
            "单位": ["个"] * 10,
            "备注": ["测试数据"] * 10
        }
        
        df = pd.DataFrame(data)
        buffer = io.BytesIO()
        df.to_excel(buffer, index=False, engine='openpyxl')
        buffer.seek(0)
        return buffer
    
    @staticmethod
    def create_file_with_empty_values() -> io.BytesIO:
        """
        创建包含空值的测试文件
        
        包含：
        - 2行正常数据
        - 2行空名称
        - 2行空规格
        - 1行全空
        
        Returns:
            BytesIO对象
        """
        data = {
            "物料名称": ["六角螺栓", "球阀", "", "", "轴承", "电缆", ""],
            "规格型号": ["M8*20", "DN50", "M10*25", "", "", "", ""],
            "单位": ["个", "个", "个", "个", "个", "个", ""]
        }
        
        df = pd.DataFrame(data)
        buffer = io.BytesIO()
        df.to_excel(buffer, index=False, engine='openpyxl')
        buffer.seek(0)
        return buffer
    
    @staticmethod
    def create_file_with_different_column_names(
        name_col: str = "材料名称",
        spec_col: str = "规格",
        unit_col: str = "计量单位"
    ) -> io.BytesIO:
        """
        创建使用不同列名的测试文件
        
        Args:
            name_col: 名称列的列名
            spec_col: 规格列的列名
            unit_col: 单位列的列名
        
        Returns:
            BytesIO对象
        """
        data = {
            name_col: ["六角螺栓", "球阀", "轴承"],
            spec_col: ["M8*20", "DN50", "6205"],
            unit_col: ["个", "个", "套"]
        }
        
        df = pd.DataFrame(data)
        buffer = io.BytesIO()
        df.to_excel(buffer, index=False, engine='openpyxl')
        buffer.seek(0)
        return buffer
    
    @staticmethod
    def create_file_missing_columns(missing: List[str]) -> io.BytesIO:
        """
        创建缺失必需列的测试文件
        
        Args:
            missing: 缺失的列名列表，可选值：["name", "spec", "unit"]
        
        Returns:
            BytesIO对象
        """
        data = {}
        
        if "name" not in missing:
            data["物料名称"] = ["六角螺栓", "球阀"]
        
        if "spec" not in missing:
            data["规格型号"] = ["M8*20", "DN50"]
        
        if "unit" not in missing:
            data["单位"] = ["个", "个"]
        
        # 添加一些其他列
        data["序号"] = [1, 2]
        data["备注"] = ["测试", "测试"]
        
        df = pd.DataFrame(data)
        buffer = io.BytesIO()
        df.to_excel(buffer, index=False, engine='openpyxl')
        buffer.seek(0)
        return buffer
    
    @staticmethod
    def create_large_test_file(row_count: int = 100) -> io.BytesIO:
        """
        创建大批量测试文件
        
        Args:
            row_count: 行数
        
        Returns:
            BytesIO对象
        """
        data = {
            "物料名称": [f"测试物料{i}" for i in range(1, row_count + 1)],
            "规格型号": [f"M{i}*20" for i in range(1, row_count + 1)],
            "单位": ["个"] * row_count
        }
        
        df = pd.DataFrame(data)
        buffer = io.BytesIO()
        df.to_excel(buffer, index=False, engine='openpyxl')
        buffer.seek(0)
        return buffer
    
    @staticmethod
    def create_file_with_special_characters() -> io.BytesIO:
        """
        创建包含特殊字符的测试文件
        
        Returns:
            BytesIO对象
        """
        data = {
            "物料名称": [
                "六角螺栓（304不锈钢）",
                "球阀/截止阀",
                "轴承-深沟球",
                "电缆@电力",
                "管件#弯头"
            ],
            "规格型号": [
                "M8*20（GB/T5782）",
                "DN50 PN1.6",
                "6205-2RS",
                "4*6mm²",
                "DN100×90°"
            ],
            "单位": ["个", "个", "套", "米", "个"]
        }
        
        df = pd.DataFrame(data)
        buffer = io.BytesIO()
        df.to_excel(buffer, index=False, engine='openpyxl')
        buffer.seek(0)
        return buffer
    
    @staticmethod
    def create_file_with_english_columns() -> io.BytesIO:
        """
        创建英文列名的测试文件
        
        Returns:
            BytesIO对象
        """
        data = {
            "Material Name": ["Hex Bolt", "Ball Valve", "Bearing"],
            "Specification": ["M8*20", "DN50", "6205"],
            "Unit": ["PC", "PC", "SET"]
        }
        
        df = pd.DataFrame(data)
        buffer = io.BytesIO()
        df.to_excel(buffer, index=False, engine='openpyxl')
        buffer.seek(0)
        return buffer
    
    @staticmethod
    def create_corrupted_file() -> io.BytesIO:
        """
        创建损坏的文件（非Excel格式）
        
        Returns:
            BytesIO对象
        """
        buffer = io.BytesIO()
        buffer.write(b"This is not an Excel file, just plain text")
        buffer.seek(0)
        return buffer


# 预定义的Mock数据
MOCK_PARSED_QUERY = {
    "standardized_name": "六角螺栓 M8x20 304不锈钢",
    "attributes": {
        "thread_diameter": "8",
        "length": "20",
        "material": "304"
    },
    "detected_category": "fastener",
    "confidence": 0.95,
    "full_description": "六角螺栓 M8x20 304不锈钢",
    "processing_steps": [
        "类别检测: fastener (0.95)",
        "标准化: 六角螺栓 M8*20 -> 六角螺栓 M8x20",
        "同义词替换: 应用2个同义词",
        "属性提取: thread_diameter=8, length=20"
    ]
}

MOCK_SIMILAR_MATERIALS = [
    {
        "erp_code": "MAT001234",
        "material_name": "六角螺栓",
        "specification": "M8*20",
        "model": None,
        "category_name": "标准件/螺栓螺钉",
        "unit_name": "个",
        "similarity_score": 0.98,
        "similarity_breakdown": {
            "name_score": 0.95,
            "description_score": 0.98,
            "attribute_score": 1.0,
            "category_score": 1.0
        },
        "normalized_name": "六角螺栓 M8x20 304不锈钢",
        "attributes": {"thread_diameter": "8", "length": "20", "material": "304"},
        "detected_category": "fastener",
        "category_confidence": 0.95
    },
    {
        "erp_code": "MAT001235",
        "material_name": "六角头螺栓",
        "specification": "M8*25",
        "model": None,
        "category_name": "标准件/螺栓螺钉",
        "unit_name": "个",
        "similarity_score": 0.85,
        "similarity_breakdown": {
            "name_score": 0.90,
            "description_score": 0.85,
            "attribute_score": 0.80,
            "category_score": 1.0
        },
        "normalized_name": "六角头螺栓 M8x25",
        "attributes": {"thread_diameter": "8", "length": "25"},
        "detected_category": "fastener",
        "category_confidence": 0.92
    }
]

