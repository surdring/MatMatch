"""
文件处理服务

负责Excel文件解析和批量查重处理
整合UniversalMaterialProcessor和SimilarityCalculator
"""

import logging
import time
import asyncio
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

# 性能优化：并发批处理配置
BATCH_SIZE = 10  # 每批处理10条（平衡性能和内存）
MAX_CONCURRENT_BATCHES = 3  # 最多3批并发（30条）


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
        
        # 减少初始化日志
    
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
            # 减少处理日志
            logger.info(f"[批量查重] 开始: {file.filename} ({file.size} bytes)")
            
            # 1. 文件验证
            self._validate_file(file)
            
            # 2. 读取Excel
            df = await self._read_excel(file)
            
            # 3. 列名检测
            # 减少列检测日志
            available_columns = df.columns.tolist()
            
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
            
            # 减少列名检测日志
            
            # 4. 批量处理
            # 减少批量处理开始日志
            results, errors, skipped_rows = await self._process_rows(
                df,
                detected_columns,
                top_k,
                category_col  # 传递分类列名
            )
            # 只输出最终汇总
            logger.info(f"[批量查重] 完成: 成功{len(results)}, 错误{len(errors)}, 跳过{len(skipped_rows)}")
            
        except Exception as e:
            logger.error(f"[ERROR] 批量查重处理失败: {str(e)}", exc_info=True)
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
            logger.warning(
                f"MIME类型警告: {file.content_type} 不在允许列表中，但扩展名有效，继续处理"
            )
        
        # 3. 验证文件大小（如果可用）
        # 注意: UploadFile不直接提供size，需要读取内容后检查
    
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
            
            # 减少解析日志
            
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
        处理Excel行数据（异步并发批处理优化）
        
        性能优化：
        - 使用asyncio.gather并发处理多行
        - 批处理大小：10条/批
        - 最大并发：3批（30条）
        - 预期性能：30条 ≤ 5秒
        
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
        # 减少批处理开始日志
        
        # 将数据分成多个批次
        rows_list = list(df.iterrows())
        batches = [rows_list[i:i + BATCH_SIZE] for i in range(0, len(rows_list), BATCH_SIZE)]
        total_batches = len(batches)
        
        # 使用信号量控制最大并发批数
        semaphore = asyncio.Semaphore(MAX_CONCURRENT_BATCHES)
        
        async def process_batch_with_semaphore(batch_idx: int, batch: List):
            """处理单个批次（带信号量控制）"""
            async with semaphore:
                return await self._process_single_batch(
                    batch, batch_idx, total_batches, 
                    detected_columns, top_k, category_column
                )
        
        # 并发处理所有批次
        batch_results = await asyncio.gather(
            *[process_batch_with_semaphore(i, batch) for i, batch in enumerate(batches)],
            return_exceptions=True
        )
        
        # 聚合所有批次的结果
        for batch_result in batch_results:
            if isinstance(batch_result, Exception):
                logger.error(f"批次处理失败: {str(batch_result)}")
                continue
            
            batch_success, batch_errors, batch_skipped = batch_result
            results.extend(batch_success)
            errors.extend(batch_errors)
            skipped_rows.extend(batch_skipped)
        
        # 减少批处理完成日志
        
        return results, errors, skipped_rows
    
    async def _process_single_batch(
        self,
        batch: List,
        batch_idx: int,
        total_batches: int,
        detected_columns: DetectedColumns,
        top_k: int,
        category_column: Optional[str] = None
    ) -> Tuple[List[BatchSearchResultItem], List[BatchSearchErrorItem], List[SkippedRowItem]]:
        """
        处理单个批次的数据
        
        Args:
            batch: 批次数据（包含(idx, row)元组）
            batch_idx: 批次索引
            total_batches: 总批次数
            detected_columns: 检测到的列名
            top_k: 返回Top-K相似物料
            category_column: 分类列名（可选）
            
        Returns:
            (results, errors, skipped_rows)
        """
        results = []
        errors = []
        skipped_rows = []
        
        # 减少批次开始日志
        
        # Step 1: 批量解析和验证所有行
        valid_rows = []
        for idx, row in batch:
            row_number = int(idx) + 2
            
            # 提取字段
            name = self._get_cell_value(row, detected_columns.name)
            spec = self._get_cell_value(row, detected_columns.spec)
            unit = self._get_cell_value(row, detected_columns.unit)
            
            # 验证必需字段
            if not name or not spec:
                skipped_rows.append(SkippedRowItem(
                    row_number=row_number,
                    reason="EMPTY_REQUIRED_FIELD",
                    message=f"物料名称或规格型号为空，已跳过"
                ))
                continue
            
            valid_rows.append({
                'row_number': row_number,
                'name': name,
                'spec': spec,
                'unit': unit,
                'row_data': row
            })
        
        if not valid_rows:
            # 减少跳过日志
            return results, errors, skipped_rows
        
        # Step 2: 批量物料处理（UniversalMaterialProcessor）
        try:
            parsed_queries = []
            for vr in valid_rows:
                combined_description = f"{vr['name']} {vr['spec']}".strip()
                parsed_query = await self.processor.process_material_description(
                    description=combined_description,
                    raw_name=vr['name'],
                    raw_spec=vr['spec'],
                    raw_unit=vr['unit']
                )
                parsed_queries.append(parsed_query)
            
            # Step 3: 批量相似度查询（单次SQL）⚡
            similar_materials_dict = await self.calculator.find_similar_materials_batch(
                parsed_queries,
                limit=top_k,
                min_similarity=0.1
            )
            
            # Step 4: 组装结果
            for i, vr in enumerate(valid_rows):
                similar_materials_raw = similar_materials_dict.get(i, [])
                
                # 转换为SimilarMaterialItem
                similar_materials = [
                    SimilarMaterialItem(
                        erp_code=mat.erp_code,
                        material_name=mat.material_name,
                        specification=mat.specification or '',
                        unit_name=mat.unit_name or '',
                        category_name=mat.category_name or '',
                        enable_state=mat.enable_state,
                        similarity_score=mat.similarity_score,
                        full_description=mat.full_description,
                        normalized_name=mat.normalized_name,
                        detected_category=mat.detected_category,
                        category_confidence=mat.category_confidence
                    )
                    for mat in similar_materials_raw
                ]
                
                # 判定查重状态
                is_duplicate, duplicate_reason = self._check_duplicate(
                    parsed_queries[i],
                    similar_materials
                )
                
                results.append(BatchSearchResultItem(
                    row_number=vr['row_number'],
                    input_data=InputData(
                        name=vr['name'],
                        spec=vr['spec'],
                        unit=vr['unit']
                    ),
                    combined_description=f"{vr['name']} {vr['spec']}",
                    parsed_query=parsed_queries[i],
                    similar_materials=similar_materials
                ))
        
        except Exception as e:
            # 批量处理失败，记录所有行为错误（保留关键错误日志）
            logger.error(f"批量处理异常: {str(e)}", exc_info=True)
            for vr in valid_rows:
                errors.append(BatchSearchErrorItem(
                    row_number=vr['row_number'],
                    input_description=f"{vr['name']} {vr['spec']}",
                    error_type="BATCH_PROCESSING_ERROR",
                    error_message=f"批量处理失败: {str(e)}"
                ))
        
        # 减少批次完成日志
        
        return results, errors, skipped_rows
    
    def _check_duplicate(
        self,
        parsed_query,
        similar_materials: List[SimilarMaterialItem]
    ) -> Tuple[bool, str]:
        """
        判定是否重复
        
        判定标准：
        1. 完整描述 + 单位完全匹配 → 重复
        2. 完整描述匹配，单位不同 → 疑是重复
        3. 相似度≥90% → 疑是重复
        4. 其他 → 不重复
        
        Args:
            parsed_query: 解析后的查询
            similar_materials: 相似物料列表
            
        Returns:
            (is_duplicate, duplicate_reason)
        """
        if not similar_materials or len(similar_materials) == 0:
            return False, "未找到相似物料"
        
        # 使用full_description进行对比（13条规则+同义词）
        input_full_desc = (parsed_query.full_description or '').strip().lower()
        input_unit = (parsed_query.cleaned_unit or '').strip().lower()
        
        for material in similar_materials:
            erp_full_desc = (material.full_description or '').strip().lower()
            erp_unit = (material.unit_name or '').strip().lower()
            
            # 判定标准1: 完整描述 + 单位完全匹配 → 重复
            if input_full_desc and erp_full_desc and \
               input_full_desc == erp_full_desc and \
               input_unit == erp_unit:
                return True, f"完全匹配：名称、规格、单位完全相同（编码：{material.erp_code}）"
            
            # 判定标准2: 完整描述匹配，单位不同 → 疑是重复
            if input_full_desc and erp_full_desc and \
               input_full_desc == erp_full_desc and \
               input_unit != erp_unit:
                return True, f"疑是重复：名称、规格相同，单位不同（编码：{material.erp_code}，单位：{material.unit_name}）"
        
        # 判定标准3: 相似度≥90% → 疑是重复
        highest_score = similar_materials[0].similarity_score
        if highest_score >= 0.9:
            return True, f"疑是重复：相似度{highest_score*100:.1f}%（编码：{similar_materials[0].erp_code}）"
        
        # 判定标准4: 其他 → 不重复
        return False, f"不重复：最高相似度{highest_score*100:.1f}%"
    
    async def _process_single_row(
        self,
        row_number: int,
        row: pd.Series,
        detected_columns: DetectedColumns,
        top_k: int,
        category_column: Optional[str] = None
    ) -> Optional[Tuple[str, Any]]:
        """
        处理单行数据（废弃方法，现使用批量处理）
        """
        return None
    
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

