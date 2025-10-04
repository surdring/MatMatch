"""
ETL数据管道主类

实现Oracle到PostgreSQL的完整ETL流程:
- Extract: 从Oracle提取数据（多表JOIN）
- Transform: 对称处理算法
- Load: 批量写入PostgreSQL
"""

import logging
import uuid
from datetime import datetime, timedelta
from typing import Dict, Any, List, Optional, Callable, AsyncGenerator

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update
from sqlalchemy.exc import IntegrityError, DatabaseError

from backend.adapters.oracle_adapter import OracleConnectionAdapter
from backend.models.materials import MaterialsMaster
from .material_processor import SimpleMaterialProcessor
from .etl_config import ETLConfig
from .exceptions import ETLError, ExtractError, TransformError, LoadError

logger = logging.getLogger(__name__)


class ETLPipeline:
    """
    ETL数据管道主类
    
    职责:
    - Extract: 使用Oracle连接适配器执行业务查询（含多表JOIN）
    - Transform: 对称处理、数据验证、清洗、转换
    - Load: 批量写入PostgreSQL、事务管理、错误恢复
    - 监控: ETL任务日志、性能指标、进度追踪
    """
    
    def __init__(
        self,
        oracle_adapter: OracleConnectionAdapter,
        pg_session: AsyncSession,
        material_processor: SimpleMaterialProcessor,
        config: Optional[ETLConfig] = None
    ):
        """
        初始化ETL管道
        
        Args:
            oracle_adapter: Oracle连接适配器（Task 1.2）
            pg_session: PostgreSQL异步会话
            material_processor: 物料处理器（对称处理算法）
            config: ETL配置（可选）
        """
        self.oracle_adapter = oracle_adapter
        self.pg_session = pg_session
        self.processor = material_processor
        self.config = config or ETLConfig()
        
        # 统计信息
        self.processed_count = 0
        self.failed_count = 0
        self.start_time: Optional[datetime] = None
        self.current_job_id: Optional[str] = None
        
        logger.info("ETLPipeline initialized")
    
    # ==================== 公共方法 ====================
    
    async def run_full_sync(
        self,
        batch_size: Optional[int] = None,
        progress_callback: Optional[Callable[[int, int], None]] = None
    ) -> Dict[str, Any]:
        """
        执行全量同步
        
        Args:
            batch_size: 每批处理数量（默认使用config配置）
            progress_callback: 进度回调函数 callback(processed, total)
            
        Returns:
            {
                "job_id": "uuid",
                "status": "success|failed",
                "total_records": 数量,
                "processed_records": 数量,
                "failed_records": 数量,
                "duration_seconds": 秒数,
                "records_per_minute": 速率
            }
            
        Raises:
            ETLError: ETL处理失败
        """
        batch_size = batch_size or self.config.batch_size
        
        try:
            logger.info("="*80)
            logger.info("Starting FULL SYNC")
            logger.info("="*80)
            
            # 1. 创建ETL任务日志
            job_id = str(uuid.uuid4())
            self.current_job_id = job_id
            self.start_time = datetime.now()
            self.processed_count = 0
            self.failed_count = 0
            
            logger.info(f"Job ID: {job_id}")
            logger.info(f"Batch size: {batch_size}")
            
            # 2. 确保知识库已加载
            if not self.processor._knowledge_base_loaded:
                logger.info("Loading knowledge base...")
                await self.processor.load_knowledge_base()
            
            # 3. 连接Oracle
            logger.info("Connecting to Oracle...")
            await self.oracle_adapter.connect()
            
            # 4. 批量提取、处理、加载
            total_processed = 0
            offset = 0
            
            while True:
                # Extract
                logger.info(f"Extracting batch at offset {offset}...")
                batch = await self._extract_materials_batch(batch_size, offset)
                
                if not batch:
                    logger.info("No more data to extract")
                    break
                
                batch_size_actual = len(batch)
                logger.info(f"Extracted {batch_size_actual} records")
                
                # Transform
                logger.info("Transforming batch...")
                materials = await self._process_batch(batch)
                
                # Load
                logger.info("Loading batch to PostgreSQL...")
                loaded_count = await self._load_batch(materials)
                
                total_processed += loaded_count
                self.processed_count = total_processed
                
                # 进度回调
                if progress_callback:
                    progress_callback(total_processed, total_processed)
                
                # 日志输出
                if total_processed % self.config.log_interval == 0:
                    elapsed = (datetime.now() - self.start_time).total_seconds()
                    rate = total_processed / (elapsed / 60) if elapsed > 0 else 0
                    logger.info(f"Progress: {total_processed} records, {rate:.2f} records/min")
                
                # 如果返回的记录数少于batch_size，说明已经到达末尾
                if batch_size_actual < batch_size:
                    break
                
                offset += batch_size
            
            # 5. 断开Oracle连接
            await self.oracle_adapter.disconnect()
            
            # 6. 计算统计信息
            end_time = datetime.now()
            duration = (end_time - self.start_time).total_seconds()
            records_per_minute = (total_processed / (duration / 60)) if duration > 0 else 0
            
            result = {
                "job_id": job_id,
                "status": "success",
                "total_records": total_processed,
                "processed_records": total_processed,
                "failed_records": self.failed_count,
                "duration_seconds": duration,
                "records_per_minute": records_per_minute
            }
            
            logger.info("="*80)
            logger.info("FULL SYNC COMPLETED")
            logger.info(f"Total records: {total_processed}")
            logger.info(f"Failed records: {self.failed_count}")
            logger.info(f"Duration: {duration:.2f} seconds")
            logger.info(f"Rate: {records_per_minute:.2f} records/min")
            logger.info("="*80)
            
            return result
            
        except Exception as e:
            error_msg = f"Full sync failed: {str(e)}"
            logger.error(error_msg)
            
            # 确保断开连接
            try:
                await self.oracle_adapter.disconnect()
            except:
                pass
            
            raise ETLError(error_msg) from e
    
    async def run_incremental_sync(
        self,
        since_time: str,
        batch_size: Optional[int] = None,
        progress_callback: Optional[Callable[[int, int], None]] = None
    ) -> Dict[str, Any]:
        """
        执行增量同步
        
        Args:
            since_time: 起始时间（格式：'YYYY-MM-DD HH:MI:SS'）
            batch_size: 每批处理数量
            progress_callback: 进度回调
            
        Returns:
            同run_full_sync()
            
        Raises:
            ETLError: ETL处理失败
        """
        batch_size = batch_size or self.config.batch_size
        
        try:
            logger.info("="*80)
            logger.info("Starting INCREMENTAL SYNC")
            logger.info(f"Since: {since_time}")
            logger.info("="*80)
            
            # 1. 创建ETL任务日志
            job_id = str(uuid.uuid4())
            self.current_job_id = job_id
            self.start_time = datetime.now()
            self.processed_count = 0
            self.failed_count = 0
            
            # 2. 确保知识库已加载
            if not self.processor._knowledge_base_loaded:
                await self.processor.load_knowledge_base()
            
            # 3. 连接Oracle
            await self.oracle_adapter.connect()
            
            # 4. 批量提取、处理、加载（增量）
            total_processed = 0
            
            async for batch in self._extract_materials_incremental(since_time, batch_size):
                if not batch:
                    continue
                
                batch_size_actual = len(batch)
                logger.info(f"Extracted {batch_size_actual} incremental records")
                
                # Transform
                materials = await self._process_batch(batch)
                
                # Load (UPSERT mode)
                loaded_count = await self._load_batch(materials, upsert=True)
                
                total_processed += loaded_count
                self.processed_count = total_processed
                
                # 进度回调
                if progress_callback:
                    progress_callback(total_processed, total_processed)
            
            # 5. 断开Oracle连接
            await self.oracle_adapter.disconnect()
            
            # 6. 计算统计信息
            end_time = datetime.now()
            duration = (end_time - self.start_time).total_seconds()
            records_per_minute = (total_processed / (duration / 60)) if duration > 0 else 0
            
            result = {
                "job_id": job_id,
                "status": "success",
                "total_records": total_processed,
                "processed_records": total_processed,
                "failed_records": self.failed_count,
                "duration_seconds": duration,
                "records_per_minute": records_per_minute
            }
            
            logger.info("="*80)
            logger.info("INCREMENTAL SYNC COMPLETED")
            logger.info(f"Total records: {total_processed}")
            logger.info(f"Duration: {duration:.2f} seconds")
            logger.info("="*80)
            
            return result
            
        except Exception as e:
            error_msg = f"Incremental sync failed: {str(e)}"
            logger.error(error_msg)
            
            try:
                await self.oracle_adapter.disconnect()
            except:
                pass
            
            raise ETLError(error_msg) from e
    
    # ==================== Extract 阶段 ====================
    
    async def _extract_materials_batch(
        self,
        batch_size: int,
        offset: int
    ) -> List[Dict[str, Any]]:
        """
        从Oracle批量提取物料数据（含多表JOIN）⭐核心方法
        
        Args:
            batch_size: 每批数量
            offset: 偏移量
            
        Returns:
            批量数据 List[Dict]
            
        SQL查询包含多表JOIN获取category_name和unit_name
        """
        try:
            # 构建多表JOIN SQL查询（Oracle ROWNUM分页语法）
            query = f"""
            SELECT * FROM (
                SELECT a.*, ROWNUM rn FROM (
                    SELECT 
                        m.code as erp_code,
                        m.name as material_name,
                        m.materialspec as specification,
                        m.materialtype as model,
                        m.pk_marbasclass as oracle_category_id,
                        c.name as category_name,
                        c.code as category_code,
                        m.pk_measdoc as oracle_unit_id,
                        u.name as unit_name,
                        u.ename as unit_english_name,
                        m.enablestate as enable_state,
                        m.ename as english_name,
                        m.ematerialspec as english_spec,
                        m.materialshortname as short_name,
                        m.materialmnecode as mnemonic_code,
                        m.memo as memo,
                        m.creationtime as oracle_created_time,
                        m.modifiedtime as oracle_modified_time,
                        m.pk_org as oracle_org_id
                    FROM DHNC65.bd_material m
                    LEFT JOIN DHNC65.bd_marbasclass c ON m.pk_marbasclass = c.pk_marbasclass
                    LEFT JOIN DHNC65.bd_measdoc u ON m.pk_measdoc = u.pk_measdoc
                    ORDER BY m.code
                ) a
                WHERE ROWNUM <= {offset + batch_size}
            )
            WHERE rn > {offset}
            """
            
            params = {}
            
            # 使用Task 1.2的execute_query方法
            batch = await self.oracle_adapter.execute_query(query, params, use_cache=False)
            
            return batch
            
        except Exception as e:
            error_msg = f"Failed to extract materials batch: {str(e)}"
            logger.error(error_msg)
            raise ExtractError(error_msg) from e
    
    async def _extract_materials_incremental(
        self,
        since_time: str,
        batch_size: int
    ) -> AsyncGenerator[List[Dict[str, Any]], None]:
        """
        从Oracle增量提取物料数据（基于modified_time）
        
        Args:
            since_time: 起始时间
            batch_size: 每批数量
            
        Yields:
            批量数据
        """
        try:
            # 构建增量查询SQL（添加schema前缀保持一致）
            query = """
            SELECT 
                m.code as erp_code,
                m.name as material_name,
                m.materialspec as specification,
                m.materialtype as model,
                m.pk_marbasclass as oracle_category_id,
                c.name as category_name,
                c.code as category_code,
                m.pk_measdoc as oracle_unit_id,
                u.name as unit_name,
                u.ename as unit_english_name,
                m.enablestate as enable_state,
                m.ename as english_name,
                m.ematerialspec as english_spec,
                m.materialshortname as short_name,
                m.materialmnecode as mnemonic_code,
                m.memo as memo,
                m.creationtime as oracle_created_time,
                m.modifiedtime as oracle_modified_time,
                m.pk_org as oracle_org_id
            FROM DHNC65.bd_material m
            LEFT JOIN DHNC65.bd_marbasclass c ON m.pk_marbasclass = c.pk_marbasclass
            LEFT JOIN DHNC65.bd_measdoc u ON m.pk_measdoc = u.pk_measdoc
            WHERE m.modifiedtime > TO_TIMESTAMP(:since_time, 'YYYY-MM-DD HH24:MI:SS')
            ORDER BY m.modifiedtime
            """
            
            params = {'since_time': since_time}
            
            # 使用Task 1.2的流式查询
            async for batch in self.oracle_adapter.execute_query_generator(
                query,
                params,
                batch_size=batch_size
            ):
                yield batch
                
        except Exception as e:
            error_msg = f"Failed to extract incremental materials: {str(e)}"
            logger.error(error_msg)
            raise ExtractError(error_msg) from e
    
    # ==================== Transform 阶段 ====================
    
    async def _process_batch(
        self,
        batch: List[Dict[str, Any]]
    ) -> List[MaterialsMaster]:
        """
        批量处理数据（对称处理）⭐核心方法
        
        Args:
            batch: 原始数据批次
            
        Returns:
            处理后的ORM对象列表
            
        异常处理:
            - 单条记录失败不影响整批
            - 记录失败原因到日志
            - failed_count += 1
        """
        materials = []
        
        for item in batch:
            try:
                # 调用SimpleMaterialProcessor进行对称处理
                material = self.processor.process_material(item)
                materials.append(material)
                
            except Exception as e:
                self.failed_count += 1
                erp_code = item.get('erp_code', 'UNKNOWN')
                logger.error(f"Failed to process material {erp_code}: {str(e)}")
                
                if not self.config.skip_failed_records:
                    raise TransformError(f"Processing failed for {erp_code}") from e
        
        return materials
    
    # ==================== Load 阶段 ====================
    
    async def _load_batch(
        self,
        materials: List[MaterialsMaster],
        upsert: bool = False
    ) -> int:
        """
        批量写入PostgreSQL（带事务管理）⭐核心方法
        
        Args:
            materials: ORM对象列表
            upsert: 是否使用UPSERT模式（增量同步）
            
        Returns:
            成功写入的记录数
            
        异常处理:
            - IntegrityError: 记录重复，跳过或更新
            - DatabaseError: 回滚事务，记录错误
        """
        if not materials:
            return 0
        
        try:
            if upsert:
                # UPSERT模式：逐条更新或插入
                count = 0
                for material in materials:
                    try:
                        # 检查是否存在
                        stmt = select(MaterialsMaster).where(
                            MaterialsMaster.erp_code == material.erp_code
                        )
                        result = await self.pg_session.execute(stmt)
                        existing = result.scalar_one_or_none()
                        
                        if existing:
                            # 更新
                            for key, value in material.__dict__.items():
                                if not key.startswith('_') and key != 'id':
                                    setattr(existing, key, value)
                        else:
                            # 插入
                            self.pg_session.add(material)
                        
                        count += 1
                        
                    except Exception as e:
                        logger.error(f"Failed to upsert material {material.erp_code}: {str(e)}")
                        if not self.config.skip_failed_records:
                            raise
                
                await self.pg_session.commit()
                return count
                
            else:
                # 批量插入模式
                self.pg_session.add_all(materials)
                await self.pg_session.commit()
                return len(materials)
                
        except IntegrityError as e:
            await self.pg_session.rollback()
            error_msg = f"Integrity error during load: {str(e)}"
            logger.error(error_msg)
            
            # 如果是UPSERT模式，不应该抛出异常
            if upsert:
                logger.warning("Integrity error in UPSERT mode, this should not happen")
                return 0
            else:
                raise LoadError(error_msg) from e
                
        except DatabaseError as e:
            await self.pg_session.rollback()
            error_msg = f"Database error during load: {str(e)}"
            logger.error(error_msg)
            raise LoadError(error_msg) from e
        
        except Exception as e:
            await self.pg_session.rollback()
            error_msg = f"Unexpected error during load: {str(e)}"
            logger.error(error_msg)
            raise LoadError(error_msg) from e

