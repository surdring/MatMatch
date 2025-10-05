"""
物料查重路由

提供物料查重相关API接口
包括单条查询、批量查重、相似物料查询、分类列表等
"""

import logging
import time
from typing import Optional
from math import ceil

from fastapi import APIRouter, Depends, File, UploadFile, Form, Query, status
from fastapi.responses import JSONResponse
from sqlalchemy.ext.asyncio import AsyncSession

from backend.database.session import get_db
from backend.core.processors.material_processor import UniversalMaterialProcessor
from backend.core.calculators.similarity_calculator import SimilarityCalculator
from backend.core.schemas.material_schemas import ParsedQuery
from backend.api.dependencies import (
    get_material_processor,
    get_similarity_calculator
)
from backend.api.services.file_processing_service import FileProcessingService
from backend.api.services.material_query_service import MaterialQueryService
from backend.api.schemas.batch_search_schemas import (
    BatchSearchResponse,
    RequiredColumnsMissingError,
)
from backend.api.schemas.material_schemas import (
    MaterialDetailResponse,
    MaterialFullDetailResponse,
    SimilarMaterialsResponse,
    CategoriesListResponse,
    MaterialSearchResponse,
    MaterialBasicInfo,
    SimilarMaterialItem,
    CategoryInfo,
    UnitInfo,
    OracleMetadata,
    CategoryItem,
    PaginationInfo,
    MaterialSearchItem,
    SearchStats,
    SimilarityBreakdown,
)
from backend.api.exceptions import (
    FileTypeError,
    FileTooLargeError,
    ExcelParseError,
    MatMatchAPIException,
    MaterialNotFoundError,
    ValidationError,
)

logger = logging.getLogger(__name__)

router = APIRouter(
    prefix="/api/v1/materials",
    tags=["物料查重"]
)


@router.post(
    "/batch-search",
    response_model=BatchSearchResponse,
    status_code=status.HTTP_200_OK,
    summary="批量查重API",
    description="""
    上传Excel文件进行批量物料查重
    
    **必需字段**：Excel文件必须包含以下3列
    - 名称（物料名称/材料名称/名称）
    - 规格型号（规格型号/规格/型号）
    - 单位（单位/计量单位）
    
    **列名指定方式**：
    1. **自动检测**（推荐）：不指定列名参数，系统自动识别
    2. **手动指定**：明确指定列名（支持精确匹配、不区分大小写、模糊匹配）
    3. **混合模式**：部分指定，部分自动检测
    
    **示例**：
    ```bash
    # 自动检测所有列
    curl -X POST -F "file=@materials.xlsx" http://localhost:8000/api/v1/materials/batch-search
    
    # 手动指定所有列
    curl -X POST -F "file=@materials.xlsx" -F "name_column=物料名称" -F "spec_column=规格型号" -F "unit_column=单位" http://localhost:8000/api/v1/materials/batch-search
    
    # 混合模式
    curl -X POST -F "file=@materials.xlsx" -F "name_column=物料名称" http://localhost:8000/api/v1/materials/batch-search
    ```
    
    **性能**：
    - 100行数据预计耗时：10-15秒
    - 单行处理：约100-150ms
    
    **返回结果**：
    - 每行输入的Top-K相似物料
    - 包含相似度得分、属性解析、类别检测等信息
    """
)
async def batch_search_materials(
    file: UploadFile = File(..., description="Excel文件（.xlsx/.xls，≤10MB）"),
    name_column: Optional[str] = Form(None, description="物料名称列（None时自动检测）"),
    spec_column: Optional[str] = Form(None, description="规格型号列（None时自动检测）"),
    unit_column: Optional[str] = Form(None, description="单位列（None时自动检测）"),
    top_k: int = Form(10, ge=1, le=50, description="返回Top-K相似物料"),
    db: AsyncSession = Depends(get_db)
) -> BatchSearchResponse:
    """
    批量查重API
    
    Args:
        file: Excel文件
        name_column: 名称列（可选）
        spec_column: 规格列（可选）
        unit_column: 单位列（可选）
        top_k: Top-K结果数
        db: 数据库会话
        
    Returns:
        BatchSearchResponse: 批量查重结果
        
    Raises:
        HTTPException: 各种错误情况
    """
    logger.info(
        f"Batch search request received: file={file.filename}, "
        f"name_column={name_column}, spec_column={spec_column}, unit_column={unit_column}, top_k={top_k}"
    )
    
    try:
        # 创建文件处理服务
        service = FileProcessingService(db)
        
        # 处理批量文件
        response = await service.process_batch_file(
            file=file,
            name_column=name_column,
            spec_column=spec_column,
            unit_column=unit_column,
            top_k=top_k
        )
        
        logger.info(
            f"Batch search completed: {response.total_processed} processed, "
            f"{response.success_count} succeeded, {response.failed_count} failed, "
            f"{response.skipped_count} skipped in {response.processing_time_seconds}s"
        )
        
        return response
        
    except RequiredColumnsMissingError as e:
        # 缺少必需列错误
        logger.warning(f"Required columns missing: {e.missing_columns}")
        return JSONResponse(
            status_code=status.HTTP_400_BAD_REQUEST,
            content={"error": e.to_dict()}
        )
    
    except FileTypeError as e:
        logger.warning(f"File type error: {e.message}")
        return JSONResponse(
            status_code=status.HTTP_400_BAD_REQUEST,
            content={
                "error": {
                    "code": e.error_code,
                    "message": e.message,
                    "help": "请上传.xlsx或.xls格式的Excel文件"
                }
            }
        )
    
    except FileTooLargeError as e:
        logger.warning(f"File too large: {e.message}")
        return JSONResponse(
            status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
            content={
                "error": {
                    "code": e.error_code,
                    "message": e.message,
                    "help": "文件大小不能超过10MB"
                }
            }
        )
    
    except ExcelParseError as e:
        logger.error(f"Excel parse error: {e.message}")
        return JSONResponse(
            status_code=status.HTTP_400_BAD_REQUEST,
            content={
                "error": {
                    "code": e.error_code,
                    "message": e.message,
                    "help": "请确保上传的是有效的Excel文件"
                }
            }
        )
    
    except MatMatchAPIException as e:
        logger.error(f"API exception: {e.message}")
        return JSONResponse(
            status_code=status.HTTP_400_BAD_REQUEST,
            content={
                "error": {
                    "code": e.error_code,
                    "message": e.message
                }
            }
        )
    
    except Exception as e:
        logger.error(f"Unexpected error in batch search: {str(e)}", exc_info=True)
        return JSONResponse(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            content={
                "error": {
                    "code": "INTERNAL_SERVER_ERROR",
                    "message": "服务器内部错误",
                    "details": str(e) if logger.level == logging.DEBUG else None
                }
            }
        )


# ========== 新增API端点 ==========

@router.get(
    "/{erp_code}",
    response_model=MaterialDetailResponse,
    status_code=status.HTTP_200_OK,
    summary="查询单个物料",
    description="根据ERP编码查询单个物料的详细信息"
)
async def get_material_by_code(
    erp_code: str,
    db: AsyncSession = Depends(get_db)
):
    """
    根据ERP编码查询单个物料
    
    Args:
        erp_code: ERP物料编码
        db: 数据库会话
        
    Returns:
        MaterialDetailResponse: 物料详情
        
    Raises:
        MaterialNotFoundError: 物料不存在
    """
    logger.info(f"Get material by code: {erp_code}")
    
    try:
        service = MaterialQueryService(db)
        material = await service.get_material_by_code(erp_code)
        
        return MaterialDetailResponse.model_validate(material)
    
    except MaterialNotFoundError as e:
        logger.warning(f"Material not found: {erp_code}")
        return JSONResponse(
            status_code=status.HTTP_404_NOT_FOUND,
            content={
                "error": {
                    "code": "MATERIAL_NOT_FOUND",
                    "message": e.message
                }
            }
        )


@router.get(
    "/{erp_code}/details",
    response_model=MaterialFullDetailResponse,
    status_code=status.HTTP_200_OK,
    summary="查询物料完整详情",
    description="查询物料的完整详情，包括分类信息、单位信息、Oracle原始字段等"
)
async def get_material_details(
    erp_code: str,
    db: AsyncSession = Depends(get_db)
):
    """
    获取物料完整详情
    
    Args:
        erp_code: ERP物料编码
        db: 数据库会话
        
    Returns:
        MaterialFullDetailResponse: 物料完整详情
    """
    logger.info(f"Get material details: {erp_code}")
    
    try:
        service = MaterialQueryService(db)
        material, category, unit = await service.get_material_with_relations(erp_code)
        
        # 构建响应
        response_data = MaterialDetailResponse.model_validate(material).model_dump()
        
        # 添加分类信息
        if category:
            response_data["category_info"] = CategoryInfo(
                oracle_category_id=category.oracle_category_id,
                category_code=category.category_code,
                category_name=category.category_name,
                parent_category_id=category.parent_category_id
            )
        else:
            response_data["category_info"] = None
        
        # 添加单位信息
        if unit:
            response_data["unit_info"] = UnitInfo(
                oracle_unit_id=unit.oracle_unit_id,
                unit_code=unit.unit_code,
                unit_name=unit.unit_name,
                english_name=unit.english_name,
                scale_factor=unit.scale_factor
            )
        else:
            response_data["unit_info"] = None
        
        # 添加Oracle元数据
        response_data["oracle_metadata"] = OracleMetadata(
            oracle_material_id=material.oracle_material_id,
            oracle_org_id=material.oracle_org_id,
            oracle_created_time=material.oracle_created_time,
            oracle_modified_time=material.oracle_modified_time
        )
        
        return MaterialFullDetailResponse(**response_data)
    
    except MaterialNotFoundError as e:
        logger.warning(f"Material not found: {erp_code}")
        return JSONResponse(
            status_code=status.HTTP_404_NOT_FOUND,
            content={
                "error": {
                    "code": "MATERIAL_NOT_FOUND",
                    "message": e.message
                }
            }
        )


@router.get(
    "/{erp_code}/similar",
    response_model=SimilarMaterialsResponse,
    status_code=status.HTTP_200_OK,
    summary="查找相似物料",
    description="查找与指定物料相似的其他物料"
)
async def get_similar_materials(
    erp_code: str,
    limit: int = Query(default=10, ge=1, le=50, description="返回相似物料数量"),
    db: AsyncSession = Depends(get_db),
    processor: UniversalMaterialProcessor = Depends(get_material_processor),
    calculator: SimilarityCalculator = Depends(get_similarity_calculator)
):
    """
    查找相似物料
    
    Args:
        erp_code: ERP物料编码
        limit: 返回数量限制
        db: 数据库会话
        processor: 物料处理器
        calculator: 相似度计算器
        
    Returns:
        SimilarMaterialsResponse: 相似物料列表
    """
    logger.info(f"Get similar materials for: {erp_code}, limit={limit}")
    
    try:
        # 查询源物料
        service = MaterialQueryService(db)
        material = await service.get_material_by_code(erp_code)
        
        # 构建查询对象
        parsed_query = ParsedQuery(
            standardized_name=material.normalized_name,
            full_description=material.full_description or material.normalized_name,
            attributes=material.attributes,
            detected_category=material.detected_category,
            confidence=material.category_confidence,
            processing_steps=[]
        )
        
        # 查找相似物料
        similar_results = await calculator.find_similar_materials(
            parsed_query=parsed_query,
            limit=limit + 1  # +1是为了排除自身
        )
        
        # 过滤掉自身
        filtered_results = [
            result for result in similar_results 
            if result.erp_code != erp_code
        ][:limit]
        
        # 构建响应
        source_material = MaterialBasicInfo(
            erp_code=material.erp_code,
            material_name=material.material_name,
            specification=material.specification,
            model=material.model,
            category_name=material.category_name,
            unit_name=material.unit_name,
            enable_state=material.enable_state
        )
        
        similar_items = [
            SimilarMaterialItem(
                erp_code=result.erp_code,
                material_name=result.material_name,
                specification=result.specification,
                category_name=result.category_name,
                similarity_score=result.similarity_score,
                similarity_breakdown=SimilarityBreakdown(
                    name_similarity=result.similarity_breakdown.get("name", 0.0),
                    description_similarity=result.similarity_breakdown.get("description", 0.0),
                    attributes_similarity=result.similarity_breakdown.get("attributes", 0.0),
                    category_match=result.similarity_breakdown.get("category", 0.0)
                )
            )
            for result in filtered_results
        ]
        
        return SimilarMaterialsResponse(
            source_material=source_material,
            similar_materials=similar_items,
            total_found=len(similar_items)
        )
    
    except MaterialNotFoundError as e:
        logger.warning(f"Material not found: {erp_code}")
        return JSONResponse(
            status_code=status.HTTP_404_NOT_FOUND,
            content={
                "error": {
                    "code": "MATERIAL_NOT_FOUND",
                    "message": e.message
                }
            }
        )


@router.get(
    "/search",
    response_model=MaterialSearchResponse,
    status_code=status.HTTP_200_OK,
    summary="物料搜索",
    description="根据关键词搜索物料，支持分类和状态筛选"
)
async def search_materials(
    keyword: str = Query(..., min_length=1, description="搜索关键词"),
    category_id: Optional[str] = Query(None, description="分类ID筛选"),
    enable_state: Optional[int] = Query(None, description="启用状态筛选"),
    page: int = Query(default=1, ge=1, description="页码"),
    page_size: int = Query(default=20, ge=1, le=100, description="每页数量"),
    db: AsyncSession = Depends(get_db)
):
    """
    物料搜索
    
    Args:
        keyword: 搜索关键词
        category_id: 分类筛选
        enable_state: 状态筛选
        page: 页码
        page_size: 每页数量
        db: 数据库会话
        
    Returns:
        MaterialSearchResponse: 搜索结果
    """
    logger.info(
        f"Search materials: keyword={keyword}, category_id={category_id}, "
        f"enable_state={enable_state}, page={page}, page_size={page_size}"
    )
    
    start_time = time.time()
    
    try:
        service = MaterialQueryService(db)
        materials, total = await service.search_materials(
            keyword=keyword,
            category_id=category_id,
            enable_state=enable_state,
            page=page,
            page_size=page_size
        )
        
        search_time_ms = int((time.time() - start_time) * 1000)
        
        # 构建响应
        search_items = [
            MaterialSearchItem(
                erp_code=m.erp_code,
                material_name=m.material_name,
                specification=m.specification,
                model=m.model,
                category_name=m.category_name,
                unit_name=m.unit_name,
                enable_state=m.enable_state
            )
            for m in materials
        ]
        
        pagination = PaginationInfo(
            page=page,
            page_size=page_size,
            total_items=total,
            total_pages=ceil(total / page_size) if page_size > 0 else 0
        )
        
        search_stats = SearchStats(
            search_time_ms=search_time_ms,
            keyword=keyword,
            total_results=total
        )
        
        return MaterialSearchResponse(
            materials=search_items,
            pagination=pagination,
            search_stats=search_stats
        )
    
    except ValidationError as e:
        logger.warning(f"Validation error: {e.message}")
        return JSONResponse(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            content={
                "error": {
                    "code": "VALIDATION_ERROR",
                    "message": e.message
                }
            }
        )


@router.get(
    "/categories",
    response_model=CategoriesListResponse,
    status_code=status.HTTP_200_OK,
    summary="获取分类列表",
    description="获取物料分类列表，支持分页和层级查询",
    tags=["分类管理"]
)
async def get_categories(
    parent_id: Optional[str] = Query(None, description="父分类ID，不传则返回顶级分类"),
    page: int = Query(default=1, ge=1, description="页码"),
    page_size: int = Query(default=20, ge=1, le=100, description="每页数量"),
    db: AsyncSession = Depends(get_db)
):
    """
    获取分类列表
    
    Args:
        parent_id: 父分类ID
        page: 页码
        page_size: 每页数量
        db: 数据库会话
        
    Returns:
        CategoriesListResponse: 分类列表
    """
    logger.info(f"Get categories: parent_id={parent_id}, page={page}, page_size={page_size}")
    
    try:
        service = MaterialQueryService(db)
        categories_with_counts, total = await service.get_categories_with_counts(
            parent_id=parent_id,
            page=page,
            page_size=page_size
        )
        
        # 构建响应
        category_items = [
            CategoryItem(
                oracle_category_id=category.oracle_category_id,
                category_code=category.category_code,
                category_name=category.category_name,
                parent_category_id=category.parent_category_id,
                category_level=category.category_level,
                material_count=count,
                detection_keywords=category.detection_keywords or [],
                enable_state=category.enable_state
            )
            for category, count in categories_with_counts
        ]
        
        pagination = PaginationInfo(
            page=page,
            page_size=page_size,
            total_items=total,
            total_pages=ceil(total / page_size) if page_size > 0 else 0
        )
        
        return CategoriesListResponse(
            categories=category_items,
            pagination=pagination
        )
    
    except Exception as e:
        logger.error(f"Error getting categories: {str(e)}", exc_info=True)
        return JSONResponse(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            content={
                "error": {
                    "code": "INTERNAL_SERVER_ERROR",
                    "message": "获取分类列表失败"
                }
            }
        )

