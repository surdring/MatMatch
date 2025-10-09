"""
管理后台业务逻辑服务

本模块实现管理后台所有的业务逻辑，包括：
- 提取规则的CRUD操作
- 同义词的CRUD操作
- 物料分类的CRUD操作  
- ETL任务监控
- 缓存刷新管理

关联测试点 (Associated Test Points):
- [T.1.1-T.1.20] - 核心功能实现
- [T.2.1-T.2.18] - 边界情况处理
- [T.3.1-T.3.2] - 并发和性能

符合Design.md第2.1.2节 - 动态规则管理服务层设计
"""

from typing import List, Dict, Optional, Any
from datetime import datetime, timedelta
from sqlalchemy import select, update, delete, func, and_, or_, Integer, case
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.exc import IntegrityError, SQLAlchemyError
import structlog

from backend.models.materials import (
    ExtractionRule,
    Synonym,
    KnowledgeCategory,
    ETLJobLog
)
from backend.api.schemas.admin_schemas import (
    # 提取规则Schema
    ExtractionRuleCreate,
    ExtractionRuleUpdate,
    ExtractionRuleResponse,
    # 同义词Schema
    SynonymCreate,
    SynonymUpdate,
    SynonymResponse,
    # 物料分类Schema
    MaterialCategoryCreate,
    MaterialCategoryUpdate,
    MaterialCategoryResponse,
    # ETL监控Schema
    ETLJobLogResponse,
    ETLJobStatistics,
    # 批量导入Schema
    BatchImportResult,
    # 分页Schema
    PaginationParams,
    PaginatedResponse
)
from backend.api.exceptions import (
    AdminResourceNotFoundException,
    AdminResourceExistsException,
    AdminValidationException,
    AdminBatchImportException,
    CacheRefreshException,
    DatabaseException
)

logger = structlog.get_logger()


class AdminService:
    """
    管理后台业务逻辑服务
    
    职责:
    1. 实现所有管理后台的CRUD操作
    2. 数据验证和业务规则检查
    3. 批量导入/导出功能
    4. 缓存刷新触发
    5. ETL任务监控
    
    依赖:
    - SQLAlchemy AsyncSession (数据库操作)
    - UniversalMaterialProcessor (缓存刷新)
    """
    
    def __init__(self, db: AsyncSession):
        """
        初始化AdminService
        
        参数:
        - db: AsyncSession - 数据库会话（通过依赖注入）
        """
        self.db = db
        self.logger = logger.bind(service="AdminService")
    
    # ========================================================================
    # 提取规则管理 (Extraction Rules Management)
    # ========================================================================
    
    async def create_extraction_rule(
        self,
        rule_data: ExtractionRuleCreate
    ) -> ExtractionRuleResponse:
        """
        创建提取规则
        
        关联测试点: [T.1.1] - 创建提取规则Happy Path
        
        参数:
        - rule_data: ExtractionRuleCreate - 规则创建数据
        
        返回:
        - ExtractionRuleResponse - 创建成功的规则
        
        异常:
        - AdminResourceExistsException: 规则名称已存在
        - AdminValidationException: 正则表达式无效
        - DatabaseException: 数据库操作失败
        """
        self.logger.info("create_extraction_rule", rule_name=rule_data.rule_name)
        
        try:
            # 1. 检查规则名称是否已存在
            stmt = select(ExtractionRule).where(
                ExtractionRule.rule_name == rule_data.rule_name
            )
            result = await self.db.execute(stmt)
            existing_rule = result.scalar_one_or_none()
            
            if existing_rule:
                raise AdminResourceExistsException(
                    resource_type="提取规则",
                    resource_id=rule_data.rule_name
                )
            
            # 2. 验证正则表达式（尝试编译）
            import re
            try:
                re.compile(rule_data.regex_pattern)
            except re.error as e:
                raise AdminValidationException(
                    field="regex_pattern",
                    issue=f"正则表达式无效: {str(e)}"
                )
            
            # 3. 创建新规则
            new_rule = ExtractionRule(
                rule_name=rule_data.rule_name,
                material_category=rule_data.material_category,
                attribute_name=rule_data.attribute_name,
                regex_pattern=rule_data.regex_pattern,
                priority=rule_data.priority,
                is_active=rule_data.is_active,
                description=rule_data.description,
                created_at=datetime.now(),
                updated_at=datetime.now()
            )
            
            self.db.add(new_rule)
            await self.db.commit()
            await self.db.refresh(new_rule)
            
            self.logger.info(
                "extraction_rule_created",
                rule_id=new_rule.id,
                rule_name=new_rule.rule_name
            )
            
            return ExtractionRuleResponse.model_validate(new_rule)
        
        except (AdminResourceExistsException, AdminValidationException):
            raise
        except SQLAlchemyError as e:
            await self.db.rollback()
            self.logger.error("database_error_create_rule", error=str(e))
            raise DatabaseException(f"创建规则失败: {str(e)}")
    
    async def get_extraction_rule(self, rule_id: int) -> ExtractionRuleResponse:
        """
        获取单个提取规则
        
        关联测试点: [T.1.2] - 获取单个规则
        
        参数:
        - rule_id: int - 规则ID
        
        返回:
        - ExtractionRuleResponse - 规则详情
        
        异常:
        - AdminResourceNotFoundException: 规则不存在
        """
        stmt = select(ExtractionRule).where(ExtractionRule.id == rule_id)
        result = await self.db.execute(stmt)
        rule = result.scalar_one_or_none()
        
        if not rule:
            raise AdminResourceNotFoundException(
                resource_type="提取规则",
                resource_id=rule_id
            )
        
        return ExtractionRuleResponse.model_validate(rule)
    
    async def list_extraction_rules(
        self,
        pagination: PaginationParams,
        material_category: Optional[str] = None,
        is_active: Optional[bool] = None
    ) -> PaginatedResponse[ExtractionRuleResponse]:
        """
        分页列表查询提取规则
        
        关联测试点: [T.1.3] - 分页查询规则
        
        参数:
        - pagination: PaginationParams - 分页参数
        - material_category: Optional[str] - 按类别过滤
        - is_active: Optional[bool] - 按状态过滤
        
        返回:
        - PaginatedResponse[ExtractionRuleResponse] - 分页结果
        """
        # 构建基础查询
        stmt = select(ExtractionRule)
        count_stmt = select(func.count()).select_from(ExtractionRule)
        
        # 应用过滤条件
        filters = []
        if material_category:
            filters.append(ExtractionRule.material_category == material_category)
        if is_active is not None:
            filters.append(ExtractionRule.is_active == is_active)
        
        if filters:
            stmt = stmt.where(and_(*filters))
            count_stmt = count_stmt.where(and_(*filters))
        
        # 按优先级排序
        stmt = stmt.order_by(ExtractionRule.priority.desc())
        
        # 分页
        offset = (pagination.page - 1) * pagination.page_size
        stmt = stmt.offset(offset).limit(pagination.page_size)
        
        # 执行查询
        result = await self.db.execute(stmt)
        rules = result.scalars().all()
        
        # 获取总数
        count_result = await self.db.execute(count_stmt)
        total = count_result.scalar()
        
        # 转换为Response
        items = [ExtractionRuleResponse.model_validate(rule) for rule in rules]
        
        # 计算总页数
        total_pages = (total + pagination.page_size - 1) // pagination.page_size if total > 0 else 0
        
        return PaginatedResponse(
            items=items,
            total=total,
            page=pagination.page,
            page_size=pagination.page_size,
            total_pages=total_pages
        )
    
    async def update_extraction_rule(
        self,
        rule_id: int,
        rule_data: ExtractionRuleUpdate
    ) -> ExtractionRuleResponse:
        """
        更新提取规则
        
        关联测试点: [T.1.4] - 更新规则
        
        参数:
        - rule_id: int - 规则ID
        - rule_data: ExtractionRuleUpdate - 更新数据
        
        返回:
        - ExtractionRuleResponse - 更新后的规则
        
        异常:
        - AdminResourceNotFoundException: 规则不存在
        - AdminValidationException: 正则表达式无效
        """
        # 1. 查询规则是否存在
        stmt = select(ExtractionRule).where(ExtractionRule.id == rule_id)
        result = await self.db.execute(stmt)
        rule = result.scalar_one_or_none()
        
        if not rule:
            raise AdminResourceNotFoundException(
                resource_type="提取规则",
                resource_id=rule_id
            )
        
        # 2. 验证新的正则表达式（如果提供）
        if rule_data.regex_pattern:
            import re
            try:
                re.compile(rule_data.regex_pattern)
            except re.error as e:
                raise AdminValidationException(
                    field="regex_pattern",
                    issue=f"正则表达式无效: {str(e)}"
                )
        
        # 3. 更新字段
        update_data = rule_data.model_dump(exclude_unset=True)
        for key, value in update_data.items():
            setattr(rule, key, value)
        
        rule.updated_at = datetime.now()
        
        await self.db.commit()
        await self.db.refresh(rule)
        
        self.logger.info("extraction_rule_updated", rule_id=rule_id)
        
        return ExtractionRuleResponse.model_validate(rule)
    
    async def delete_extraction_rule(self, rule_id: int) -> Dict[str, str]:
        """
        删除提取规则
        
        关联测试点: [T.1.5] - 删除规则
        
        参数:
        - rule_id: int - 规则ID
        
        返回:
        - Dict[str, str] - 删除成功消息
        
        异常:
        - AdminResourceNotFoundException: 规则不存在
        """
        stmt = select(ExtractionRule).where(ExtractionRule.id == rule_id)
        result = await self.db.execute(stmt)
        rule = result.scalar_one_or_none()
        
        if not rule:
            raise AdminResourceNotFoundException(
                resource_type="提取规则",
                resource_id=rule_id
            )
        
        await self.db.delete(rule)
        await self.db.commit()
        
        self.logger.info("extraction_rule_deleted", rule_id=rule_id)
        
        return {"message": f"规则 {rule_id} 已成功删除"}
    
    async def batch_import_extraction_rules(
        self,
        rules_data: List[ExtractionRuleCreate]
    ) -> BatchImportResult:
        """
        批量导入提取规则（优化版：真正的批量插入）
        
        关联测试点: [T.1.6] - 批量导入规则
        
        参数:
        - rules_data: List[ExtractionRuleCreate] - 规则列表
        
        返回:
        - BatchImportResult - 导入结果统计
        
        性能优化:
        - 使用 session.add_all() 进行批量插入
        - 在验证阶段预先检查重复和正则表达式
        - 出错时回滚整个批次（保证原子性）
        """
        total = len(rules_data)
        success_count = 0
        failed_count = 0
        errors = []
        
        # 第一步：预验证所有规则
        valid_rules = []
        for idx, rule_data in enumerate(rules_data, start=1):
            try:
                # 1. 检查规则名称是否已存在
                stmt = select(ExtractionRule).where(
                    ExtractionRule.rule_name == rule_data.rule_name
                )
                result = await self.db.execute(stmt)
                existing_rule = result.scalar_one_or_none()
                
                if existing_rule:
                    raise AdminResourceExistsException(
                        resource_type="提取规则",
                        resource_id=rule_data.rule_name
                    )
                
                # 2. 验证正则表达式
                import re
                try:
                    re.compile(rule_data.regex_pattern)
                except re.error as e:
                    raise AdminValidationException(
                        field="regex_pattern",
                        issue=f"正则表达式无效: {str(e)}"
                    )
                
                # 验证通过，加入待插入列表
                valid_rules.append(rule_data)
                
            except Exception as e:
                failed_count += 1
                errors.append({
                    "row": idx,
                    "rule_name": rule_data.rule_name,
                    "error": str(e)
                })
                self.logger.warning(
                    "batch_import_rule_validation_failed",
                    row=idx,
                    rule_name=rule_data.rule_name,
                    error=str(e)
                )
        
        # 第二步：批量插入所有验证通过的规则
        if valid_rules:
            try:
                # 创建ORM对象列表
                new_rules = [
                    ExtractionRule(
                        rule_name=rule_data.rule_name,
                        material_category=rule_data.material_category,
                        attribute_name=rule_data.attribute_name,
                        regex_pattern=rule_data.regex_pattern,
                        priority=rule_data.priority,
                        is_active=rule_data.is_active,
                        description=rule_data.description,
                        created_at=datetime.now(),
                        updated_at=datetime.now()
                    )
                    for rule_data in valid_rules
                ]
                
                # 批量插入（性能优化）
                self.db.add_all(new_rules)
                await self.db.commit()
                
                success_count = len(valid_rules)
                
                self.logger.info(
                    "batch_import_rules_completed",
                    total=total,
                    success=success_count,
                    failed=failed_count,
                    batch_size=len(new_rules)
                )
                
            except SQLAlchemyError as e:
                await self.db.rollback()
                # 如果批量插入失败，所有规则都标记为失败
                failed_count = len(valid_rules)
                success_count = 0
                errors.append({
                    "error": f"批量插入失败: {str(e)}",
                    "affected_count": len(valid_rules)
                })
                self.logger.error("batch_import_database_error", error=str(e))
        
        return BatchImportResult(
            total=total,
            success=success_count,
            failed=failed_count,
            errors=errors
        )
    
    # ========================================================================
    # 同义词管理 (Synonyms Management)
    # ========================================================================
    
    async def create_synonym(
        self,
        synonym_data: SynonymCreate
    ) -> SynonymResponse:
        """
        创建同义词
        
        关联测试点: [T.1.9] - 创建同义词Happy Path
        
        参数:
        - synonym_data: SynonymCreate - 同义词创建数据
        
        返回:
        - SynonymResponse - 创建成功的同义词
        
        异常:
        - AdminResourceExistsException: 同义词对已存在
        """
        self.logger.info(
            "create_synonym",
            standard_term=synonym_data.standard_term,
            original_term=synonym_data.original_term
        )
        
        try:
            # 检查是否已存在相同的同义词对
            stmt = select(Synonym).where(
                and_(
                    Synonym.standard_term == synonym_data.standard_term,
                    Synonym.original_term == synonym_data.original_term
                )
            )
            result = await self.db.execute(stmt)
            existing = result.scalar_one_or_none()
            
            if existing:
                raise AdminResourceExistsException(
                    resource_type="同义词",
                    resource_id=f"{synonym_data.standard_term} → {synonym_data.original_term}"
                )
            
            # 创建新同义词
            new_synonym = Synonym(
                standard_term=synonym_data.standard_term,
                original_term=synonym_data.original_term,
                category=synonym_data.category,
                confidence=synonym_data.confidence,
                is_active=synonym_data.is_active,
                created_at=datetime.now(),
                updated_at=datetime.now()
            )
            
            self.db.add(new_synonym)
            await self.db.commit()
            await self.db.refresh(new_synonym)
            
            self.logger.info("synonym_created", synonym_id=new_synonym.id)
            
            return SynonymResponse.model_validate(new_synonym)
        
        except AdminResourceExistsException:
            raise
        except SQLAlchemyError as e:
            await self.db.rollback()
            self.logger.error("database_error_create_synonym", error=str(e))
            raise DatabaseException(f"创建同义词失败: {str(e)}")
    
    async def get_synonym(self, synonym_id: int) -> SynonymResponse:
        """
        获取单个同义词
        
        关联测试点: [T.1.10] - 获取单个同义词
        """
        stmt = select(Synonym).where(Synonym.id == synonym_id)
        result = await self.db.execute(stmt)
        synonym = result.scalar_one_or_none()
        
        if not synonym:
            raise AdminResourceNotFoundException(
                resource_type="同义词",
                resource_id=synonym_id
            )
        
        return SynonymResponse.model_validate(synonym)
    
    async def list_synonyms(
        self,
        pagination: PaginationParams,
        category: Optional[str] = None,
        standard_term: Optional[str] = None,
        is_active: Optional[bool] = None
    ) -> PaginatedResponse[SynonymResponse]:
        """
        分页列表查询同义词
        
        关联测试点: [T.1.11] - 分页查询同义词
        
        参数:
        - pagination: PaginationParams - 分页参数
        - category: Optional[str] - 按类别过滤
        - standard_term: Optional[str] - 按标准词过滤
        - is_active: Optional[bool] - 按状态过滤
        """
        # 构建基础查询
        stmt = select(Synonym)
        count_stmt = select(func.count()).select_from(Synonym)
        
        # 应用过滤条件
        filters = []
        if category:
            filters.append(Synonym.category == category)
        if standard_term:
            filters.append(Synonym.standard_term == standard_term)
        if is_active is not None:
            filters.append(Synonym.is_active == is_active)
        
        if filters:
            stmt = stmt.where(and_(*filters))
            count_stmt = count_stmt.where(and_(*filters))
        
        # 排序
        stmt = stmt.order_by(Synonym.confidence.desc(), Synonym.created_at.desc())
        
        # 分页
        offset = (pagination.page - 1) * pagination.page_size
        stmt = stmt.offset(offset).limit(pagination.page_size)
        
        # 执行查询
        result = await self.db.execute(stmt)
        synonyms = result.scalars().all()
        
        # 获取总数
        count_result = await self.db.execute(count_stmt)
        total = count_result.scalar()
        
        # 转换为Response
        items = [SynonymResponse.model_validate(syn) for syn in synonyms]
        
        # 计算总页数
        total_pages = (total + pagination.page_size - 1) // pagination.page_size if total > 0 else 0
        
        return PaginatedResponse(
            items=items,
            total=total,
            page=pagination.page,
            page_size=pagination.page_size,
            total_pages=total_pages
        )
    
    async def update_synonym(
        self,
        synonym_id: int,
        synonym_data: SynonymUpdate
    ) -> SynonymResponse:
        """
        更新同义词
        
        关联测试点: [T.1.12] - 更新同义词
        """
        stmt = select(Synonym).where(Synonym.id == synonym_id)
        result = await self.db.execute(stmt)
        synonym = result.scalar_one_or_none()
        
        if not synonym:
            raise AdminResourceNotFoundException(
                resource_type="同义词",
                resource_id=synonym_id
            )
        
        # 更新字段
        update_data = synonym_data.model_dump(exclude_unset=True)
        for key, value in update_data.items():
            setattr(synonym, key, value)
        
        synonym.updated_at = datetime.now()
        
        await self.db.commit()
        await self.db.refresh(synonym)
        
        self.logger.info("synonym_updated", synonym_id=synonym_id)
        
        return SynonymResponse.model_validate(synonym)
    
    async def delete_synonym(self, synonym_id: int) -> Dict[str, str]:
        """
        删除同义词
        
        关联测试点: [T.1.13] - 删除同义词
        """
        stmt = select(Synonym).where(Synonym.id == synonym_id)
        result = await self.db.execute(stmt)
        synonym = result.scalar_one_or_none()
        
        if not synonym:
            raise AdminResourceNotFoundException(
                resource_type="同义词",
                resource_id=synonym_id
            )
        
        await self.db.delete(synonym)
        await self.db.commit()
        
        self.logger.info("synonym_deleted", synonym_id=synonym_id)
        
        return {"message": f"同义词 {synonym_id} 已成功删除"}
    
    async def batch_import_synonyms(
        self,
        synonyms_data: List[SynonymCreate]
    ) -> BatchImportResult:
        """
        批量导入同义词
        
        关联测试点: [T.1.14] - 批量导入同义词
        """
        total = len(synonyms_data)
        success_count = 0
        failed_count = 0
        errors = []
        
        for idx, synonym_data in enumerate(synonyms_data, start=1):
            try:
                await self.create_synonym(synonym_data)
                success_count += 1
            except Exception as e:
                failed_count += 1
                errors.append({
                    "row": idx,
                    "standard_term": synonym_data.standard_term,
                    "original_term": synonym_data.original_term,
                    "error": str(e)
                })
                self.logger.warning(
                    "batch_import_synonym_failed",
                    row=idx,
                    error=str(e)
                )
        
        self.logger.info(
            "batch_import_synonyms_completed",
            total=total,
            success=success_count,
            failed=failed_count
        )
        
        return BatchImportResult(
            total=total,
            success=success_count,
            failed=failed_count,
            errors=errors
        )
    
    # ========================================================================
    # 物料分类管理 (Material Categories Management)
    # ========================================================================
    
    async def create_material_category(
        self,
        category_data: MaterialCategoryCreate
    ) -> MaterialCategoryResponse:
        """
        创建物料分类
        
        关联测试点: [T.1.17] - 创建物料分类
        """
        self.logger.info("create_material_category", category_name=category_data.category_name)
        
        try:
            # 检查是否已存在
            stmt = select(KnowledgeCategory).where(
                KnowledgeCategory.category_name == category_data.category_name
            )
            result = await self.db.execute(stmt)
            existing = result.scalar_one_or_none()
            
            if existing:
                raise AdminResourceExistsException(
                    resource_type="物料分类",
                    resource_id=category_data.category_name
                )
            
            # 创建新分类
            new_category = KnowledgeCategory(
                category_name=category_data.category_name,
                keywords=category_data.keywords,
                is_active=category_data.is_active,
                created_at=datetime.now(),
                updated_at=datetime.now()
            )
            
            self.db.add(new_category)
            await self.db.commit()
            await self.db.refresh(new_category)
            
            self.logger.info("material_category_created", category_id=new_category.id)
            
            return MaterialCategoryResponse.model_validate(new_category)
        
        except AdminResourceExistsException:
            raise
        except SQLAlchemyError as e:
            await self.db.rollback()
            self.logger.error("database_error_create_category", error=str(e))
            raise DatabaseException(f"创建物料分类失败: {str(e)}")
    
    async def get_material_category(
        self,
        category_id: int
    ) -> MaterialCategoryResponse:
        """
        获取单个物料分类详情
        
        关联测试点: [T.1.18] - 查询单个分类详情
        """
        self.logger.info("get_material_category", category_id=category_id)
        
        try:
            stmt = select(KnowledgeCategory).where(KnowledgeCategory.id == category_id)
            result = await self.db.execute(stmt)
            category = result.scalar_one_or_none()
            
            if not category:
                raise AdminResourceNotFoundException(
                    resource_type="物料分类",
                    resource_id=str(category_id)
                )
            
            return MaterialCategoryResponse.model_validate(category)
        
        except AdminResourceNotFoundException:
            raise
        except SQLAlchemyError as e:
            self.logger.error("database_error_get_category", error=str(e))
            raise DatabaseException(f"查询物料分类失败: {str(e)}")
    
    async def update_material_category(
        self,
        category_id: int,
        category_data: MaterialCategoryUpdate
    ) -> MaterialCategoryResponse:
        """
        更新物料分类
        
        关联测试点: [T.1.16] - 更新物料分类
        """
        self.logger.info("update_material_category", category_id=category_id)
        
        try:
            # 查找分类
            stmt = select(KnowledgeCategory).where(KnowledgeCategory.id == category_id)
            result = await self.db.execute(stmt)
            category = result.scalar_one_or_none()
            
            if not category:
                raise AdminResourceNotFoundException(
                    resource_type="物料分类",
                    resource_id=str(category_id)
                )
            
            # 更新字段
            if category_data.keywords is not None:
                category.keywords = category_data.keywords
            if category_data.is_active is not None:
                category.is_active = category_data.is_active
            
            category.updated_at = datetime.now()
            
            await self.db.commit()
            await self.db.refresh(category)
            
            self.logger.info("material_category_updated", category_id=category_id)
            
            return MaterialCategoryResponse.model_validate(category)
        
        except AdminResourceNotFoundException:
            raise
        except SQLAlchemyError as e:
            await self.db.rollback()
            self.logger.error("database_error_update_category", error=str(e))
            raise DatabaseException(f"更新物料分类失败: {str(e)}")
    
    async def list_material_categories(
        self,
        pagination: PaginationParams,
        is_active: Optional[bool] = None
    ) -> PaginatedResponse[MaterialCategoryResponse]:
        """
        分页列表查询物料分类
        
        关联测试点: [T.1.18] - 查询物料分类
        """
        stmt = select(KnowledgeCategory)
        count_stmt = select(func.count()).select_from(KnowledgeCategory)
        
        if is_active is not None:
            stmt = stmt.where(KnowledgeCategory.is_active == is_active)
            count_stmt = count_stmt.where(KnowledgeCategory.is_active == is_active)
        
        # 排序
        stmt = stmt.order_by(KnowledgeCategory.created_at.desc())
        
        # 分页
        offset = (pagination.page - 1) * pagination.page_size
        stmt = stmt.offset(offset).limit(pagination.page_size)
        
        # 执行查询
        result = await self.db.execute(stmt)
        categories = result.scalars().all()
        
        # 获取总数
        count_result = await self.db.execute(count_stmt)
        total = count_result.scalar()
        
        # 转换为Response
        items = [MaterialCategoryResponse.model_validate(cat) for cat in categories]
        
        # 计算总页数
        total_pages = (total + pagination.page_size - 1) // pagination.page_size if total > 0 else 0
        
        return PaginatedResponse(
            items=items,
            total=total,
            page=pagination.page,
            page_size=pagination.page_size,
            total_pages=total_pages
        )
    
    # ========================================================================
    # ETL任务监控 (ETL Job Monitoring)
    # ========================================================================
    
    async def get_recent_etl_jobs(
        self,
        pagination: PaginationParams,
        days: int = 7
    ) -> PaginatedResponse[ETLJobLogResponse]:
        """
        获取最近的ETL任务日志
        
        关联测试点: [T.1.19] - ETL任务监控
        
        参数:
        - pagination: PaginationParams - 分页参数
        - days: int - 查询最近N天的数据（默认7天）
        """
        since = datetime.now() - timedelta(days=days)
        
        stmt = select(ETLJobLog).where(ETLJobLog.started_at >= since)
        count_stmt = select(func.count()).select_from(ETLJobLog).where(
            ETLJobLog.started_at >= since
        )
        
        # 排序（最新的在前）
        stmt = stmt.order_by(ETLJobLog.started_at.desc())
        
        # 分页
        offset = (pagination.page - 1) * pagination.page_size
        stmt = stmt.offset(offset).limit(pagination.page_size)
        
        # 执行查询
        result = await self.db.execute(stmt)
        jobs = result.scalars().all()
        
        # 获取总数
        count_result = await self.db.execute(count_stmt)
        total = count_result.scalar()
        
        # 转换为Response
        items = [ETLJobLogResponse.model_validate(job) for job in jobs]
        
        # 计算总页数
        total_pages = (total + pagination.page_size - 1) // pagination.page_size if total > 0 else 0
        
        return PaginatedResponse(
            items=items,
            total=total,
            page=pagination.page,
            page_size=pagination.page_size,
            total_pages=total_pages
        )
    
    async def get_etl_statistics(self, days: int = 30) -> ETLJobStatistics:
        """
        获取ETL任务统计信息
        
        关联测试点: [T.1.20] - ETL统计数据
        
        参数:
        - days: int - 统计最近N天的数据（默认30天）
        """
        since = datetime.now() - timedelta(days=days)
        
        # 查询任务总数和成功/失败数量
        stmt = select(
            func.count(ETLJobLog.id).label("total_jobs"),
            func.sum(
                case((ETLJobLog.status == "completed", 1), else_=0)
            ).label("success_jobs"),
            func.sum(
                case((ETLJobLog.status == "failed", 1), else_=0)
            ).label("failed_jobs"),
            func.avg(ETLJobLog.duration_seconds).label("avg_duration_seconds")
        ).where(ETLJobLog.started_at >= since)
        
        result = await self.db.execute(stmt)
        row = result.first()
        
        # 如果在时间范围内没有任务，返回全零的统计信息
        if not row or row.total_jobs == 0:
            return ETLJobStatistics()
        
        
        return ETLJobStatistics(
            total_jobs=row.total_jobs or 0,
            success_jobs=row.success_jobs or 0,
            failed_jobs=row.failed_jobs or 0,
            success_rate=(
                round((row.success_jobs or 0) / (row.total_jobs or 1) * 100, 2)
            ),
            avg_duration_seconds=round(row.avg_duration_seconds or 0, 2)
        )
    
    # ========================================================================
    # 缓存管理 (Cache Management)
    # ========================================================================
    
    async def refresh_knowledge_cache(
        self,
        processor: Optional[Any] = None
    ) -> Dict[str, Any]:
        """
        刷新UniversalMaterialProcessor的知识库缓存
        
        关联测试点: [T.2.17] - 缓存刷新功能
        
        参数:
        - processor: Optional[UniversalMaterialProcessor] - 处理器实例（通过依赖注入提供）
        
        返回:
        - Dict[str, Any] - 刷新结果和新的缓存统计
        
        注意:
        此方法通过调用UniversalMaterialProcessor的clear_cache()方法，
        触发缓存清空。下次查询时，处理器会自动从数据库重新加载知识库。
        """
        try:
            # 如果没有提供processor实例，通过reset全局实例来刷新
            if processor is None:
                from backend.api.dependencies import reset_material_processor
                await reset_material_processor()
                
                self.logger.info("knowledge_cache_refreshed_via_reset")
                
                return {
                    "message": "知识库缓存已成功刷新（全局实例已重置）",
                    "note": "下次查询时将自动重新加载知识库"
                }
            else:
                # 使用提供的processor实例
                await processor.clear_cache()
                
                # 获取新的缓存统计（触发重新加载）
                await processor._ensure_cache_fresh()
                cache_stats = processor.get_cache_stats()
                
                self.logger.info("knowledge_cache_refreshed", cache_stats=cache_stats)
                
                return {
                    "message": "知识库缓存已成功刷新",
                    "cache_stats": cache_stats
                }
        
        except Exception as e:
            self.logger.error("cache_refresh_failed", error=str(e))
            raise CacheRefreshException(f"缓存刷新失败: {str(e)}")

