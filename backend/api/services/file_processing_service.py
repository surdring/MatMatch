"""
文件处理服务

负责Excel文件解析和批量查重处理
整合UniversalMaterialProcessor和SimilarityCalculator
"""

import logging
import time
from typing import List, Dict, Any, Optional, Tuple
from fastapi import UploadFile
import pandas as pd
import io

from sqlalchemy.ext.asyncio import AsyncSession

from backend.core.processors.material_processor import UniversalMaterialProcessor
from backend.core.calculators.similarity_calculator import SimilarityCalculator
from backend.api.schemas.batch_search_schemas import (
    BatchSearchResponse,
    BatchSearchResultItem,
    InputData,
    SimilarMaterialItem,
    BatchSearchErrorItem,
    SkippedRowItem,
    DetectedColumns,
    RequiredColumnsMissingError,
)
from backend.api.utils.column_detection import detect_required_columns
from backend.api.exceptions import (
    FileTypeError,
    FileTooLargeError,
    ExcelParseError,
)

logger = logging.getLogger(__name__)


# ============================================================================
# 常量配置
# ============================================================================

MAX_FILE_SIZE = 10 * 1024 * 1024  # 10MB
ALLOWED_EXTENSIONS = {".xlsx", ".xls"}
ALLOWED_MIME_TYPES = {
    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",  # .xlsx
    "application/vnd.ms-excel",  # .xls
}


# ============================================================================
# 文件处理服务
# ============================================================================

class FileProcessingService:
    """
    文件处理服务
    
    职责:
    1. 文件验证（类型、大小）
    2. Excel解析
    3. 列名检测
    4. 批量查重处理
    5. 结果聚合
    """
    
    def __init__(self, db_session: AsyncSession):
        """
        初始化文件处理服务
        
        Args:
            db_session: 数据库会话
        """
        self.db = db_session
        self.processor = UniversalMaterialProcessor(db_session)
        self.calculator = SimilarityCalculator(db_session)
        
        logger.info("FileProcessingService initialized")
    
    async def process_batch_file(
        self,
        file: UploadFile,
        name_column: Optional[str] = None,
        spec_column: Optional[str] = None,
        unit_column: Optional[str] = None,
        category_column: Optional[str] = None,
        top_k: int = 10
    ) -> BatchSearchResponse:
        """
        处理批量查重Excel文件
        
        Args:
            file: 上传的Excel文件
            name_column: 名称列（None时自动检测）
            spec_column: 规格列（None时自动检测）
            unit_column: 单位列（None时自动检测）
            category_column: 分类列（None时自动检测，可选）
            top_k: 返回Top-K相似物料
            
        Returns:
            BatchSearchResponse: 批量查重响应
            
        Raises:
            FileTypeError: 文件类型错误
            FileTooLargeError: 文件过大
            ExcelParseError: Excel解析错误
            RequiredColumnsMissingError: 缺少必需列
        """
        start_time = time.time()
        
        try:
            logger.info(f"=" * 80)
            logger.info(f"开始处理批量查重文件: {file.filename}")
            logger.info(f"文件大小: {file.size} bytes")
            logger.info(f"=" * 80)
            
            # 1. 文件验证
            logger.debug("步骤1: 验证文件...")
            self._validate_file(file)
            logger.info("✅ 文件验证通过")
            
            # 2. 读取Excel
            logger.debug("步骤2: 读取Excel...")
            df = await self._read_excel(file)
            logger.info(f"✅ Excel读取成功，共 {len(df)} 行")
            
            # 3. 列名检测
            logger.debug("步骤3: 检测列名...")
            available_columns = df.columns.tolist()
            logger.debug(f"可用列: {available_columns}")
            
            detected_columns_dict = detect_required_columns(
                available_columns,
                name_column,
                spec_column,
                unit_column,
                category_column  # 添加分类列检测
            )
            
            detected_columns = DetectedColumns(
                name=detected_columns_dict["name"],
                spec=detected_columns_dict["spec"],
                unit=detected_columns_dict["unit"]
            )
            
            # 分类列是可选的
            category_col = detected_columns_dict.get("category")
            
            logger.info(
                f"✅ 列名检测完成: name={detected_columns.name}, spec={detected_columns.spec}, "
                f"unit={detected_columns.unit}, category={category_col}"
            )
            
            # 4. 批量处理
            logger.info(f"步骤4: 开始批量处理 {len(df)} 条数据...")
            results, errors, skipped_rows = await self._process_rows(
                df,
                detected_columns,
                top_k,
                category_col  # 传递分类列名
            )
            logger.info(f"✅ 批量处理完成: 成功{len(results)}条, 错误{len(errors)}条, 跳过{len(skipped_rows)}条")
            
        except Exception as e:
            logger.error(f"❌ 批量查重处理失败: {str(e)}", exc_info=True)
            raise
        
        # 5. 计算统计信息
        processing_time = time.time() - start_time
        success_count = len(results)
        failed_count = len(errors)
        skipped_count = len(skipped_rows)
        total_processed = success_count + failed_count
        
        logger.info(
            f"Batch processing completed: {total_processed} processed, "
            f"{success_count} succeeded, {failed_count} failed, {skipped_count} skipped "
            f"in {processing_time:.2f}s"
        )
        
        # 6. 构建响应
        return BatchSearchResponse(
            total_processed=total_processed,
            success_count=success_count,
            failed_count=failed_count,
            skipped_count=skipped_count,
            processing_time_seconds=round(processing_time, 2),
            detected_columns=detected_columns,
            available_columns=available_columns,
            results=results,
            errors=errors,
            skipped_rows=skipped_rows
        )
    
    def _validate_file(self, file: UploadFile) -> None:
        """
        验证文件
        
        Args:
            file: 上传的文件
            
        Raises:
            FileTypeError: 文件类型错误
            FileTooLargeError: 文件过大
        """
        # 1. 验证文件扩展名
        if not file.filename:
            raise FileTypeError("文件名为空")
        
        file_ext = file.filename[file.filename.rfind('.'):].lower() if '.' in file.filename else ''
        if file_ext not in ALLOWED_EXTENSIONS:
            raise FileTypeError(
                f"不支持的文件类型: {file_ext}，仅支持: {', '.join(ALLOWED_EXTENSIONS)}"
            )
        
        # 2. 验证MIME类型
        if file.content_type and file.content_type not in ALLOWED_MIME_TYPES:
            logger.warning(f"MIME type mismatch: {file.content_type}")
        
        # 3. 验证文件大小（如果可用）
        # 注意: UploadFile不直接提供size，需要读取内容后检查
        logger.info(f"File validation passed: {file.filename}")
    
    async def _read_excel(self, file: UploadFile) -> pd.DataFrame:
        """
        读取Excel文件
        
        Args:
            file: 上传的Excel文件
            
        Returns:
            pd.DataFrame: Excel数据
            
        Raises:
            FileTooLargeError: 文件过大
            ExcelParseError: Excel解析错误
        """
        try:
            # 读取文件内容
            content = await file.read()
            
            # 验证文件大小
            if len(content) > MAX_FILE_SIZE:
                raise FileTooLargeError(
                    f"文件大小超过限制: {len(content) / 1024 / 1024:.2f}MB > {MAX_FILE_SIZE / 1024 / 1024}MB"
                )
            
            # 解析Excel
            buffer = io.BytesIO(content)
            
            # 尝试读取xlsx
            try:
                df = pd.read_excel(buffer, engine='openpyxl')
            except Exception:
                # 尝试xls
                buffer.seek(0)
                df = pd.read_excel(buffer, engine='xlrd')
            
            # 验证数据
            if df.empty:
                raise ExcelParseError("Excel文件为空")
            
            logger.info(f"Excel parsed: {len(df)} rows, {len(df.columns)} columns")
            
            return df
            
        except FileTooLargeError:
            raise
        except ExcelParseError:
            raise
        except Exception as e:
            logger.error(f"Failed to read Excel: {str(e)}")
            raise ExcelParseError(f"Excel解析失败: {str(e)}")
    
    async def _process_rows(
        self,
        df: pd.DataFrame,
        detected_columns: DetectedColumns,
        top_k: int,
        category_column: Optional[str] = None
    ) -> Tuple[List[BatchSearchResultItem], List[BatchSearchErrorItem], List[SkippedRowItem]]:
        """
        处理Excel行数据
        
        Args:
            df: Excel数据
            detected_columns: 检测到的列名
            top_k: 返回Top-K相似物料
            category_column: 分类列名（可选）
            
        Returns:
            (results, errors, skipped_rows)
        """
        results: List[BatchSearchResultItem] = []
        errors: List[BatchSearchErrorItem] = []
        skipped_rows: List[SkippedRowItem] = []
        
        total_rows = len(df)
        logger.info(f"开始逐行处理，总计 {total_rows} 行")
        
        for idx, row in df.iterrows():
            row_number = int(idx) + 2  # Excel行号从2开始（1是表头）
            
            # 每10行记录一次进度
            if row_number % 10 == 0:
                logger.info(f"处理进度: {row_number-1}/{total_rows} ({(row_number-1)/total_rows*100:.1f}%)")
            
            try:
                # 提取3个必需字段
                name = self._get_cell_value(row, detected_columns.name)
                spec = self._get_cell_value(row, detected_columns.spec)
                unit = self._get_cell_value(row, detected_columns.unit)
                
                # 提取可选的分类字段
                category = None
                if category_column:
                    category = self._get_cell_value(row, category_column)
                
                # 验证必需字段
                if not name or not spec:
                    skipped_rows.append(SkippedRowItem(
                        row_number=row_number,
                        reason="EMPTY_REQUIRED_FIELD",
                        message=f"物料名称或规格型号为空，已跳过"
                    ))
                    continue
                
                # 组合描述
                combined_description = f"{name} {spec}".strip()
                
                # 处理查询（传入原始name、spec和unit用于清洗）
                parsed_query = await self.processor.process_material_description(
                    description=combined_description,
                    raw_name=name,
                    raw_spec=spec,
                    raw_unit=unit
                )
                
                # 查找相似物料
                similar_materials_raw = await self.calculator.find_similar_materials(
                    parsed_query,
                    limit=top_k,
                    min_similarity=0.1
                )
                
                # 转换为SimilarMaterialItem（兼容对象和字典）
                similar_materials = []
                for mat in similar_materials_raw:
                    # 兼容对象和字典两种格式（支持测试Mock）
                    if isinstance(mat, dict):
                        mat_dict = mat
                    else:
                        mat_dict = {
                            'erp_code': mat.erp_code,
                            'material_name': mat.material_name,
                            'specification': mat.specification,
                            'model': mat.model,
                            'similarity_score': mat.similarity_score,
                            'similarity_breakdown': mat.similarity_breakdown,
                            'normalized_name': mat.normalized_name,
                            'attributes': mat.attributes,
                            'detected_category': mat.detected_category,
                            'category_confidence': mat.category_confidence
                        }
                    
                    similar_materials.append(SimilarMaterialItem(
                        erp_code=mat_dict.get('erp_code', ''),
                        material_name=mat_dict.get('material_name', ''),
                        specification=mat_dict.get('specification'),
                        model=mat_dict.get('model'),
                        category_name=mat_dict.get('category_name'),
                        unit_name=mat_dict.get('unit_name'),
                        similarity_score=mat_dict.get('similarity_score', 0.0),
                        similarity_breakdown=mat_dict.get('similarity_breakdown', {}),
                        normalized_name=mat_dict.get('normalized_name', ''),
                        attributes=mat_dict.get('attributes', {}),
                        detected_category=mat_dict.get('detected_category', ''),
                        category_confidence=mat_dict.get('category_confidence', 0.0)
                    ))
                
                # 构建输入数据
                input_data = InputData(
                    name=name,
                    spec=spec,
                    unit=unit,
                    category=category,  # 添加分类字段
                    original_row=row.to_dict()
                )
                
                # 构建结果项
                result_item = BatchSearchResultItem(
                    row_number=row_number,
                    input_data=input_data,
                    combined_description=combined_description,
                    parsed_query=parsed_query,
                    similar_materials=similar_materials
                )
                
                results.append(result_item)
                
            except Exception as e:
                logger.error(f"❌ 处理第 {row_number} 行失败: {str(e)}", exc_info=True)
                logger.debug(f"错误详情: 类型={type(e).__name__}, 行内容={row.to_dict()}")
                errors.append(BatchSearchErrorItem(
                    row_number=row_number,
                    input_description=f"{name} {spec}" if 'name' in locals() else "未知",
                    error_type=type(e).__name__,
                    error_message=str(e)
                ))
        
        return results, errors, skipped_rows
    
    def _get_cell_value(self, row: pd.Series, column_name: str) -> str:
        """
        获取单元格值并转换为字符串
        
        Args:
            row: DataFrame行
            column_name: 列名
            
        Returns:
            单元格值（字符串）
        """
        if column_name not in row:
            return ""
        
        value = row[column_name]
        
        # 处理NaN和None
        if pd.isna(value):
            return ""
        
        # 转换为字符串并去除首尾空格
        return str(value).strip()

