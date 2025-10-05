"""
物料查询服务

提供以下功能：
1. 根据ERP编码查询单个物料
2. 查询物料及其关联的分类和单位信息
3. 物料搜索（支持关键词、分类、状态筛选）
4. 获取分类列表（支持分页和层级查询）
5. 统计分类下的物料数量
"""

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, or_, and_, desc
from sqlalchemy.orm import selectinload
from typing import Optional, List, Tuple
import logging

from backend.models.materials import (
    MaterialsMaster,
    MaterialCategory,
    MeasurementUnit
)
from backend.api.exceptions import MaterialNotFoundError

logger = logging.getLogger(__name__)


class MaterialQueryService:
    """物料查询服务"""
    
    def __init__(self, db: AsyncSession):
        self.db = db
    
    async def get_material_by_code(
        self, 
        erp_code: str
    ) -> MaterialsMaster:
        """
        根据ERP编码查询物料
        
        Args:
            erp_code: ERP物料编码
            
        Returns:
            MaterialsMaster: 物料对象
            
        Raises:
            MaterialNotFoundError: 物料不存在
        """
        stmt = select(MaterialsMaster).where(
            MaterialsMaster.erp_code == erp_code
        )
        result = await self.db.execute(stmt)
        material = result.scalar_one_or_none()
        
        if not material:
            raise MaterialNotFoundError(f"物料编码 '{erp_code}' 不存在")
        
        return material
    
    async def get_material_with_relations(
        self, 
        erp_code: str
    ) -> Tuple[MaterialsMaster, Optional[MaterialCategory], Optional[MeasurementUnit]]:
        """
        查询物料及其关联的分类和单位信息
        
        Args:
            erp_code: ERP物料编码
            
        Returns:
            Tuple[MaterialsMaster, MaterialCategory, MeasurementUnit]: 
                物料、分类、单位信息
                
        Raises:
            MaterialNotFoundError: 物料不存在
        """
        # 查询物料
        material = await self.get_material_by_code(erp_code)
        
        # 查询关联的分类信息
        category = None
        if material.oracle_category_id:
            stmt = select(MaterialCategory).where(
                MaterialCategory.oracle_category_id == material.oracle_category_id
            )
            result = await self.db.execute(stmt)
            category = result.scalar_one_or_none()
        
        # 查询关联的单位信息
        unit = None
        if material.oracle_unit_id:
            stmt = select(MeasurementUnit).where(
                MeasurementUnit.oracle_unit_id == material.oracle_unit_id
            )
            result = await self.db.execute(stmt)
            unit = result.scalar_one_or_none()
        
        return material, category, unit
    
    async def search_materials(
        self,
        keyword: str,
        category_id: Optional[str] = None,
        enable_state: Optional[int] = None,
        page: int = 1,
        page_size: int = 20
    ) -> Tuple[List[MaterialsMaster], int]:
        """
        物料搜索
        
        搜索范围：
        - material_name
        - specification
        - model
        - short_name
        - mnemonic_code
        
        Args:
            keyword: 搜索关键词
            category_id: 分类ID筛选（可选）
            enable_state: 启用状态筛选（可选）
            page: 页码（从1开始）
            page_size: 每页数量
            
        Returns:
            Tuple[List[MaterialsMaster], int]: 搜索结果列表和总数
        """
        # 构建基础查询
        stmt = select(MaterialsMaster)
        
        # 关键词搜索条件（使用ILIKE模糊匹配）
        keyword_pattern = f"%{keyword}%"
        search_conditions = or_(
            MaterialsMaster.material_name.ilike(keyword_pattern),
            MaterialsMaster.specification.ilike(keyword_pattern),
            MaterialsMaster.model.ilike(keyword_pattern),
            MaterialsMaster.short_name.ilike(keyword_pattern),
            MaterialsMaster.mnemonic_code.ilike(keyword_pattern)
        )
        stmt = stmt.where(search_conditions)
        
        # 分类筛选
        if category_id:
            stmt = stmt.where(MaterialsMaster.oracle_category_id == category_id)
        
        # 状态筛选
        if enable_state is not None:
            stmt = stmt.where(MaterialsMaster.enable_state == enable_state)
        
        # 计算总数
        count_stmt = select(func.count()).select_from(stmt.subquery())
        result = await self.db.execute(count_stmt)
        total = result.scalar() or 0
        
        # 分页和排序
        offset = (page - 1) * page_size
        stmt = stmt.order_by(desc(MaterialsMaster.updated_at))
        stmt = stmt.offset(offset).limit(page_size)
        
        # 执行查询
        result = await self.db.execute(stmt)
        materials = result.scalars().all()
        
        return list(materials), total
    
    async def get_categories(
        self,
        parent_id: Optional[str] = None,
        page: int = 1,
        page_size: int = 20
    ) -> Tuple[List[MaterialCategory], int]:
        """
        获取分类列表
        
        Args:
            parent_id: 父分类ID（可选，不传则返回顶级分类）
            page: 页码（从1开始）
            page_size: 每页数量
            
        Returns:
            Tuple[List[MaterialCategory], int]: 分类列表和总数
        """
        # 构建查询
        stmt = select(MaterialCategory)
        
        # 父分类筛选
        if parent_id:
            stmt = stmt.where(MaterialCategory.parent_category_id == parent_id)
        else:
            # 顶级分类（parent_category_id为空）
            stmt = stmt.where(MaterialCategory.parent_category_id.is_(None))
        
        # 只查询已启用的分类
        stmt = stmt.where(MaterialCategory.enable_state == 2)
        
        # 计算总数
        count_stmt = select(func.count()).select_from(stmt.subquery())
        result = await self.db.execute(count_stmt)
        total = result.scalar() or 0
        
        # 分页和排序
        offset = (page - 1) * page_size
        stmt = stmt.order_by(MaterialCategory.category_code)
        stmt = stmt.offset(offset).limit(page_size)
        
        # 执行查询
        result = await self.db.execute(stmt)
        categories = result.scalars().all()
        
        return list(categories), total
    
    async def count_materials_by_category(
        self,
        category_id: str
    ) -> int:
        """
        统计分类下的物料数量
        
        Args:
            category_id: 分类ID
            
        Returns:
            int: 物料数量
        """
        stmt = select(func.count()).select_from(MaterialsMaster).where(
            and_(
                MaterialsMaster.oracle_category_id == category_id,
                MaterialsMaster.enable_state == 2  # 只统计已启用的
            )
        )
        result = await self.db.execute(stmt)
        count = result.scalar() or 0
        return count
    
    async def get_categories_with_counts(
        self,
        parent_id: Optional[str] = None,
        page: int = 1,
        page_size: int = 20
    ) -> Tuple[List[Tuple[MaterialCategory, int]], int]:
        """
        获取分类列表及其物料数量
        
        Args:
            parent_id: 父分类ID（可选）
            page: 页码
            page_size: 每页数量
            
        Returns:
            Tuple[List[Tuple[MaterialCategory, int]], int]: 
                (分类, 物料数量)列表和总数
        """
        # 获取分类列表
        categories, total = await self.get_categories(parent_id, page, page_size)
        
        # 统计每个分类的物料数量
        categories_with_counts = []
        for category in categories:
            count = await self.count_materials_by_category(category.oracle_category_id)
            categories_with_counts.append((category, count))
        
        return categories_with_counts, total

