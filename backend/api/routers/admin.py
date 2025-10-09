"""
管理后台API路由

本模块定义管理后台所有的HTTP端点，包括：
- 提取规则管理 API
- 同义词管理 API
- 物料分类管理 API
- ETL任务监控 API
- 缓存刷新 API

关联测试点 (Associated Test Points):
- [T.1.1-T.1.20] - 核心功能路由
- [T.2.1-T.2.18] - 边界情况处理

符合Design.md第2.5.2节 - API端点定义
"""

from typing import List, Optional
from fastapi import APIRouter, Depends, Query, Path, Body, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
import structlog

from backend.database.session import get_db
from backend.api.services.admin_service import AdminService
from backend.api.dependencies import get_material_processor
from backend.api.dependencies_auth import require_admin_auth, AuditLogger
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
    DatabaseException,
    CacheRefreshException
)

logger = structlog.get_logger()

# 创建路由器（默认要求管理员认证）
router = APIRouter(
    prefix="/api/v1/admin",
    tags=["Admin Management - 🔐 需要认证"],
    dependencies=[Depends(require_admin_auth)],  # 🔐 全局认证依赖
    responses={
        401: {"description": "未认证或Token无效"},
        403: {"description": "权限不足"},
        404: {"description": "资源未找到"},
        409: {"description": "资源已存在"},
        422: {"description": "验证失败"},
        429: {"description": "请求过于频繁"},
        500: {"description": "服务器内部错误"}
    }
)


# ============================================================================
# 依赖注入：获取AdminService实例
# ============================================================================

async def get_admin_service(db: AsyncSession = Depends(get_db)) -> AdminService:
    """
    依赖注入：创建AdminService实例
    
    参数:
    - db: AsyncSession - 数据库会话（通过依赖注入）
    
    返回:
    - AdminService - 管理服务实例
    """
    return AdminService(db)


# ============================================================================
# 提取规则管理API (Extraction Rules API)
# ============================================================================

@router.post(
    "/extraction-rules",
    response_model=ExtractionRuleResponse,
    status_code=status.HTTP_201_CREATED,
    summary="创建提取规则",
    description="创建新的属性提取规则（需要管理员权限）"
)
async def create_extraction_rule(
    rule_data: ExtractionRuleCreate,
    admin: dict = Depends(require_admin_auth),
    service: AdminService = Depends(get_admin_service)
):
    """
    创建提取规则
    
    🔐 **需要管理员认证**：此端点需要有效的管理员API Token
    
    认证方式:
    - Authorization: Bearer <admin_token>
    - 或 X-API-Key: <admin_token>
    
    关联测试点: [T.1.1] - 创建提取规则Happy Path
    
    请求体:
    - rule_data: ExtractionRuleCreate - 规则创建数据
    
    返回:
    - ExtractionRuleResponse - 创建成功的规则
    
    HTTP状态码:
    - 201: 创建成功
    - 401: 未认证或Token无效
    - 403: 权限不足
    - 409: 规则名称已存在
    - 422: 正则表达式无效
    - 500: 服务器内部错误
    """
    try:
        result = await service.create_extraction_rule(rule_data)
        
        # 记录审计日志
        await AuditLogger.log_admin_action(
            admin_user=admin,
            action="create",
            resource_type="extraction_rule",
            resource_id=result.id,
            details={"rule_name": rule_data.rule_name}
        )
        
        return result
    except (AdminResourceExistsException, AdminValidationException) as e:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT if isinstance(e, AdminResourceExistsException) 
            else status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail={"error_code": e.error_code, "message": e.message}
        )
    except DatabaseException as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail={"error_code": e.error_code, "message": e.message}
        )


@router.get(
    "/extraction-rules/{rule_id}",
    response_model=ExtractionRuleResponse,
    summary="获取单个提取规则",
    description="根据ID获取提取规则详情"
)
async def get_extraction_rule(
    rule_id: int,
    service: AdminService = Depends(get_admin_service)
):
    """
    获取单个提取规则
    
    关联测试点: [T.1.2] - 获取单个规则
    
    路径参数:
    - rule_id: int - 规则ID
    
    返回:
    - ExtractionRuleResponse - 规则详情
    
    HTTP状态码:
    - 200: 获取成功
    - 404: 规则不存在
    """
    try:
        return await service.get_extraction_rule(rule_id)
    except AdminResourceNotFoundException as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"error_code": e.error_code, "message": e.message}
        )


@router.get(
    "/extraction-rules",
    response_model=PaginatedResponse[ExtractionRuleResponse],
    summary="分页查询提取规则",
    description="获取提取规则列表，支持分页和过滤"
)
async def list_extraction_rules(
    page: int = Query(1, ge=1, description="页码（从1开始）"),
    page_size: int = Query(50, ge=1, le=100, description="每页数量（1-100）"),
    material_category: Optional[str] = Query(None, description="按类别过滤"),
    is_active: Optional[bool] = Query(None, description="按状态过滤"),
    service: AdminService = Depends(get_admin_service)
):
    """
    分页查询提取规则
    
    关联测试点: [T.1.3] - 分页查询规则
    
    查询参数:
    - page: int - 页码（默认1）
    - page_size: int - 每页数量（默认50，最大100）
    - material_category: Optional[str] - 按类别过滤
    - is_active: Optional[bool] - 按状态过滤
    
    返回:
    - PaginatedResponse[ExtractionRuleResponse] - 分页结果
    """
    pagination = PaginationParams(page=page, page_size=page_size)
    return await service.list_extraction_rules(
        pagination=pagination,
        material_category=material_category,
        is_active=is_active
    )


@router.put(
    "/extraction-rules/{rule_id}",
    response_model=ExtractionRuleResponse,
    summary="更新提取规则",
    description="更新指定ID的提取规则"
)
async def update_extraction_rule(
    rule_id: int,
    rule_data: ExtractionRuleUpdate,
    service: AdminService = Depends(get_admin_service)
):
    """
    更新提取规则
    
    关联测试点: [T.1.4] - 更新规则
    
    路径参数:
    - rule_id: int - 规则ID
    
    请求体:
    - rule_data: ExtractionRuleUpdate - 更新数据
    
    返回:
    - ExtractionRuleResponse - 更新后的规则
    """
    try:
        return await service.update_extraction_rule(rule_id, rule_data)
    except AdminResourceNotFoundException as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"error_code": e.error_code, "message": e.message}
        )
    except AdminValidationException as e:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail={"error_code": e.error_code, "message": e.message}
        )


@router.delete(
    "/extraction-rules/{rule_id}",
    summary="删除提取规则",
    description="删除指定ID的提取规则"
)
async def delete_extraction_rule(
    rule_id: int,
    service: AdminService = Depends(get_admin_service)
):
    """
    删除提取规则
    
    关联测试点: [T.1.5] - 删除规则
    
    路径参数:
    - rule_id: int - 规则ID
    
    返回:
    - Dict[str, str] - 删除成功消息
    """
    try:
        return await service.delete_extraction_rule(rule_id)
    except AdminResourceNotFoundException as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"error_code": e.error_code, "message": e.message}
        )


@router.post(
    "/extraction-rules/batch-import",
    response_model=BatchImportResult,
    summary="批量导入提取规则",
    description="批量导入提取规则（JSON数组）"
)
async def batch_import_extraction_rules(
    rules_data: List[ExtractionRuleCreate],
    service: AdminService = Depends(get_admin_service)
):
    """
    批量导入提取规则
    
    关联测试点: [T.1.6] - 批量导入规则
    
    请求体:
    - rules_data: List[ExtractionRuleCreate] - 规则列表
    
    返回:
    - BatchImportResult - 导入结果统计
    """
    return await service.batch_import_extraction_rules(rules_data)


# ============================================================================
# 同义词管理API (Synonyms API)
# ============================================================================

@router.post(
    "/synonyms",
    response_model=SynonymResponse,
    status_code=status.HTTP_201_CREATED,
    summary="创建同义词",
    description="创建新的同义词映射"
)
async def create_synonym(
    synonym_data: SynonymCreate,
    service: AdminService = Depends(get_admin_service)
):
    """
    创建同义词
    
    关联测试点: [T.1.9] - 创建同义词Happy Path
    """
    try:
        return await service.create_synonym(synonym_data)
    except AdminResourceExistsException as e:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail={"error_code": e.error_code, "message": e.message}
        )
    except DatabaseException as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail={"error_code": e.error_code, "message": e.message}
        )


@router.get(
    "/synonyms/{synonym_id}",
    response_model=SynonymResponse,
    summary="获取单个同义词",
    description="根据ID获取同义词详情"
)
async def get_synonym(
    synonym_id: int,
    service: AdminService = Depends(get_admin_service)
):
    """
    获取单个同义词
    
    关联测试点: [T.1.10] - 获取单个同义词
    """
    try:
        return await service.get_synonym(synonym_id)
    except AdminResourceNotFoundException as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"error_code": e.error_code, "message": e.message}
        )


@router.get(
    "/synonyms",
    response_model=PaginatedResponse[SynonymResponse],
    summary="分页查询同义词",
    description="获取同义词列表，支持分页和过滤"
)
async def list_synonyms(
    page: int = Query(1, ge=1, description="页码（从1开始）"),
    page_size: int = Query(50, ge=1, le=100, description="每页数量（1-100）"),
    category: Optional[str] = Query(None, description="按类别过滤"),
    standard_term: Optional[str] = Query(None, description="按标准词过滤"),
    is_active: Optional[bool] = Query(None, description="按状态过滤"),
    service: AdminService = Depends(get_admin_service)
):
    """
    分页查询同义词
    
    关联测试点: [T.1.11] - 分页查询同义词
    """
    pagination = PaginationParams(page=page, page_size=page_size)
    return await service.list_synonyms(
        pagination=pagination,
        category=category,
        standard_term=standard_term,
        is_active=is_active
    )


@router.put(
    "/synonyms/{synonym_id}",
    response_model=SynonymResponse,
    summary="更新同义词",
    description="更新指定ID的同义词"
)
async def update_synonym(
    synonym_id: int,
    synonym_data: SynonymUpdate,
    service: AdminService = Depends(get_admin_service)
):
    """
    更新同义词
    
    关联测试点: [T.1.12] - 更新同义词
    """
    try:
        return await service.update_synonym(synonym_id, synonym_data)
    except AdminResourceNotFoundException as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"error_code": e.error_code, "message": e.message}
        )


@router.delete(
    "/synonyms/{synonym_id}",
    summary="删除同义词",
    description="删除指定ID的同义词"
)
async def delete_synonym(
    synonym_id: int,
    service: AdminService = Depends(get_admin_service)
):
    """
    删除同义词
    
    关联测试点: [T.1.13] - 删除同义词
    """
    try:
        return await service.delete_synonym(synonym_id)
    except AdminResourceNotFoundException as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"error_code": e.error_code, "message": e.message}
        )


@router.post(
    "/synonyms/batch-import",
    response_model=BatchImportResult,
    summary="批量导入同义词",
    description="批量导入同义词（JSON数组）"
)
async def batch_import_synonyms(
    synonyms_data: List[SynonymCreate],
    service: AdminService = Depends(get_admin_service)
):
    """
    批量导入同义词
    
    关联测试点: [T.1.14] - 批量导入同义词
    """
    return await service.batch_import_synonyms(synonyms_data)


# ============================================================================
# 物料分类管理API (Material Categories API)
# ============================================================================

@router.post(
    "/categories",
    response_model=MaterialCategoryResponse,
    status_code=status.HTTP_201_CREATED,
    summary="创建物料分类",
    description="创建新的物料分类"
)
async def create_material_category(
    category_data: MaterialCategoryCreate,
    service: AdminService = Depends(get_admin_service)
):
    """
    创建物料分类
    
    关联测试点: [T.1.17] - 创建物料分类
    """
    try:
        return await service.create_material_category(category_data)
    except AdminResourceExistsException as e:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail={"error_code": e.error_code, "message": e.message}
        )
    except DatabaseException as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail={"error_code": e.error_code, "message": e.message}
        )


@router.get(
    "/categories",
    response_model=PaginatedResponse[MaterialCategoryResponse],
    summary="分页查询物料分类",
    description="获取物料分类列表"
)
async def list_material_categories(
    page: int = Query(1, ge=1, description="页码（从1开始）"),
    page_size: int = Query(50, ge=1, le=100, description="每页数量（1-100）"),
    is_active: Optional[bool] = Query(None, description="按状态过滤"),
    service: AdminService = Depends(get_admin_service)
):
    """
    分页查询物料分类
    
    关联测试点: [T.1.18] - 查询物料分类
    """
    pagination = PaginationParams(page=page, page_size=page_size)
    return await service.list_material_categories(
        pagination=pagination,
        is_active=is_active
    )


@router.get(
    "/categories/{category_id}",
    response_model=MaterialCategoryResponse,
    summary="获取单个分类详情",
    description="根据ID获取物料分类的详细信息"
)
async def get_material_category(
    category_id: int = Path(..., description="分类ID"),
    service: AdminService = Depends(get_admin_service)
):
    """
    获取单个分类详情
    
    关联测试点: [T.1.18] - 查询单个分类详情
    """
    try:
        return await service.get_material_category(category_id)
    except AdminResourceNotFoundException as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"error_code": e.error_code, "message": e.message}
        )


@router.put(
    "/categories/{category_id}",
    response_model=MaterialCategoryResponse,
    summary="更新物料分类",
    description="更新物料分类的关键词和状态"
)
async def update_material_category(
    category_id: int = Path(..., description="分类ID"),
    category_data: MaterialCategoryUpdate = Body(...),
    service: AdminService = Depends(get_admin_service)
):
    """
    更新物料分类
    
    关联测试点: [T.1.16] - 更新物料分类
    """
    try:
        return await service.update_material_category(category_id, category_data)
    except AdminResourceNotFoundException as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"error_code": e.error_code, "message": e.message}
        )


# ============================================================================
# ETL任务监控API (ETL Job Monitoring API)
# ============================================================================

@router.get(
    "/etl/jobs",
    response_model=PaginatedResponse[ETLJobLogResponse],
    summary="获取ETL任务日志",
    description="获取最近的ETL任务执行日志"
)
async def get_recent_etl_jobs(
    page: int = Query(1, ge=1, description="页码（从1开始）"),
    page_size: int = Query(50, ge=1, le=100, description="每页数量（1-100）"),
    days: int = Query(7, ge=1, le=90, description="查询最近N天的数据（1-90天）"),
    service: AdminService = Depends(get_admin_service)
):
    """
    获取最近的ETL任务日志
    
    关联测试点: [T.1.19] - ETL任务监控
    """
    pagination = PaginationParams(page=page, page_size=page_size)
    return await service.get_recent_etl_jobs(pagination=pagination, days=days)


@router.get(
    "/etl/statistics",
    response_model=ETLJobStatistics,
    summary="获取ETL统计信息",
    description="获取ETL任务的统计数据（成功率、平均耗时等）"
)
async def get_etl_statistics(
    days: int = Query(30, ge=1, le=365, description="统计最近N天的数据（1-365天）"),
    service: AdminService = Depends(get_admin_service)
):
    """
    获取ETL任务统计信息
    
    关联测试点: [T.1.20] - ETL统计数据
    """
    return await service.get_etl_statistics(days=days)


# ============================================================================
# 缓存管理API (Cache Management API)
# ============================================================================

@router.post(
    "/cache/refresh",
    summary="刷新知识库缓存",
    description="清空并重新加载UniversalMaterialProcessor的知识库缓存"
)
async def refresh_knowledge_cache(
    service: AdminService = Depends(get_admin_service),
    processor = Depends(get_material_processor)
):
    """
    刷新知识库缓存
    
    关联测试点: [T.2.17] - 缓存刷新功能
    
    返回:
    - Dict[str, Any] - 刷新结果和新的缓存统计
    
    注意:
    此端点通过依赖注入获取UniversalMaterialProcessor实例，
    确保刷新的是当前运行中的处理器缓存。
    """
    try:
        return await service.refresh_knowledge_cache(processor=processor)
    except CacheRefreshException as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail={"error_code": e.error_code, "message": e.message}
        )

