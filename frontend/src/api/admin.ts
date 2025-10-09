/**
 * @file admin.ts
 * @description 管理后台API客户端封装
 * 
 * 对应后端API:
 * - backend/api/routers/admin.py (15个端点)
 * 
 * API认证说明:
 * - 所有管理API需要Token认证（Bearer Token）
 * - 开发环境使用测试Token（配置在.env.development）
 * - 生产环境需要实现完整的认证系统（技术债）
 */

import request from './request'
import type {
  ExtractionRuleInterface,
  SynonymEntryInterface,
  MaterialCategoryInterface,
  ETLJobLogInterface,
  ETLStatisticsInterface,
  PaginationParams,
  PaginatedResponse,
  BatchImportResult
} from '@/types/admin'

// ==================== 提取规则管理 ====================

/**
 * 获取提取规则列表（分页）
 * GET /api/v1/admin/extraction-rules
 */
export const getExtractionRules = (params?: PaginationParams) => {
  return request.get<PaginatedResponse<ExtractionRuleInterface>>('/api/v1/admin/extraction-rules', { params })
}

/**
 * 获取单个提取规则
 * GET /api/v1/admin/extraction-rules/{id}
 */
export const getExtractionRule = (id: number) => {
  return request.get<ExtractionRuleInterface>(`/api/v1/admin/extraction-rules/${id}`)
}

/**
 * 创建提取规则
 * POST /api/v1/admin/extraction-rules
 */
export const createExtractionRule = (data: Partial<ExtractionRuleInterface>) => {
  return request.post<ExtractionRuleInterface>('/api/v1/admin/extraction-rules', data)
}

/**
 * 更新提取规则
 * PUT /api/v1/admin/extraction-rules/{id}
 */
export const updateExtractionRule = (id: number, data: Partial<ExtractionRuleInterface>) => {
  return request.put<ExtractionRuleInterface>(`/api/v1/admin/extraction-rules/${id}`, data)
}

/**
 * 删除提取规则
 * DELETE /api/v1/admin/extraction-rules/{id}
 */
export const deleteExtractionRule = (id: number) => {
  return request.delete(`/api/v1/admin/extraction-rules/${id}`)
}

/**
 * 批量导入提取规则
 * POST /api/v1/admin/extraction-rules/batch-import
 */
export const batchImportExtractionRules = (formData: FormData) => {
  return request.post<BatchImportResult>('/api/v1/admin/extraction-rules/batch-import', formData, {
    headers: {
      'Content-Type': 'multipart/form-data'
    }
  })
}

// ==================== 同义词管理 ====================

/**
 * 获取同义词列表（分页）
 * GET /api/v1/admin/synonyms
 */
export const getSynonyms = (params?: PaginationParams) => {
  return request.get<PaginatedResponse<SynonymEntryInterface>>('/api/v1/admin/synonyms', { params })
}

/**
 * 获取单个同义词
 * GET /api/v1/admin/synonyms/{id}
 */
export const getSynonym = (id: number) => {
  return request.get<SynonymEntryInterface>(`/api/v1/admin/synonyms/${id}`)
}

/**
 * 创建同义词
 * POST /api/v1/admin/synonyms
 */
export const createSynonym = (data: Partial<SynonymEntryInterface>) => {
  return request.post<SynonymEntryInterface>('/api/v1/admin/synonyms', data)
}

/**
 * 更新同义词
 * PUT /api/v1/admin/synonyms/{id}
 */
export const updateSynonym = (id: number, data: Partial<SynonymEntryInterface>) => {
  return request.put<SynonymEntryInterface>(`/api/v1/admin/synonyms/${id}`, data)
}

/**
 * 删除同义词
 * DELETE /api/v1/admin/synonyms/{id}
 */
export const deleteSynonym = (id: number) => {
  return request.delete(`/api/v1/admin/synonyms/${id}`)
}

/**
 * 批量导入同义词
 * POST /api/v1/admin/synonyms/batch-import
 */
export const batchImportSynonyms = (formData: FormData) => {
  return request.post<BatchImportResult>('/api/v1/admin/synonyms/batch-import', formData, {
    headers: {
      'Content-Type': 'multipart/form-data'
    }
  })
}

// ==================== 物料分类管理 ====================

/**
 * 获取物料分类列表（分页）
 * GET /api/v1/admin/categories
 */
export const getMaterialCategories = (params?: PaginationParams) => {
  return request.get<PaginatedResponse<MaterialCategoryInterface>>('/api/v1/admin/categories', { params })
}

/**
 * 获取单个物料分类
 * GET /api/v1/admin/categories/{id}
 */
export const getMaterialCategory = (id: number) => {
  return request.get<MaterialCategoryInterface>(`/api/v1/admin/categories/${id}`)
}

/**
 * 更新物料分类
 * PUT /api/v1/admin/categories/{id}
 */
export const updateMaterialCategory = (id: number, data: Partial<MaterialCategoryInterface>) => {
  return request.put<MaterialCategoryInterface>(`/api/v1/admin/categories/${id}`, data)
}

// ==================== ETL监控 ====================

/**
 * 获取ETL任务日志（分页）
 * GET /api/v1/admin/etl/jobs
 */
export const getETLJobs = (params?: PaginationParams) => {
  return request.get<PaginatedResponse<ETLJobLogInterface>>('/api/v1/admin/etl/jobs', { params })
}

/**
 * 获取ETL统计信息
 * GET /api/v1/admin/etl/statistics
 */
export const getETLStatistics = () => {
  return request.get<ETLStatisticsInterface>('/api/v1/admin/etl/statistics')
}

// ==================== 缓存管理 ====================

/**
 * 刷新知识库缓存
 * POST /api/v1/admin/cache/refresh
 */
export const refreshCache = () => {
  return request.post('/api/v1/admin/cache/refresh')
}

