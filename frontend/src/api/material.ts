import { request } from './request'
import type { ApiResponse } from './request'

// 类型定义
export interface MaterialResult {
  erp_code: string
  material_name: string
  specification: string
  unit_name: string
  category_name?: string
  similarity_score: number
  normalized_name?: string
  attributes?: Record<string, any>
}

export interface BatchSearchResult {
  row_number: number
  input_data: {
    material_name?: string
    specification?: string
    unit_name?: string
    name?: string  // 后端返回的字段
    spec?: string  // 后端返回的字段
    unit?: string  // 后端返回的字段
    original_row?: any
  }
  similar_materials: MaterialResult[]  // 后端实际返回的字段名
  matches?: MaterialResult[]  // 兼容旧版本
  parsed_query?: {
    normalized_name: string
    detected_category: string
    extracted_attributes: Record<string, any>
  }
}

export interface BatchSearchResponse {
  success: boolean
  total_processed: number
  results: BatchSearchResult[]
  detected_columns?: {
    material_name: string
    specification: string
    unit_name: string
  }
  skipped_rows?: number[]
  processing_time: number
}

export interface MaterialDetail {
  erp_code: string
  material_name: string
  specification: string
  full_description: string
  unit_name: string
  category_name?: string
  normalized_name: string
  attributes: Record<string, any>
  detected_category?: string
  created_at: string
  updated_at: string
}

export interface CategoryInfo {
  category_name: string
  material_count: number
}

// API 方法
export const materialApi = {
  /**
   * 批量查重
   */
  batchSearch(
    file: File,
    columns: {
      material_name?: string
      specification?: string
      unit_name?: string
      category_name?: string
    },
    onProgress?: (progress: number) => void
  ): Promise<ApiResponse<BatchSearchResponse>> {
    const formData = new FormData()
    formData.append('file', file)
    
    // 修复：使用后端实际期望的参数名
    if (columns.material_name) formData.append('name_column', columns.material_name)
    if (columns.specification) formData.append('spec_column', columns.specification)
    if (columns.unit_name) formData.append('unit_column', columns.unit_name)
    if (columns.category_name) formData.append('category_column', columns.category_name)

    return request.upload('/api/v1/materials/batch-search', formData, onProgress)
  },

  /**
   * 查询单个物料
   */
  getMaterial(erpCode: string): Promise<ApiResponse<MaterialDetail>> {
    return request.get(`/api/v1/materials/${erpCode}`)
  },

  /**
   * 查询物料详情
   */
  getMaterialDetails(erpCode: string): Promise<ApiResponse<MaterialDetail>> {
    return request.get(`/api/v1/materials/${erpCode}/details`)
  },

  /**
   * 查询相似物料
   */
  getSimilarMaterials(
    erpCode: string,
    limit: number = 10
  ): Promise<ApiResponse<{ materials: MaterialResult[] }>> {
    return request.get(`/api/v1/materials/${erpCode}/similar`, {
      params: { limit }
    })
  },

  /**
   * 搜索物料
   */
  searchMaterials(params: {
    query?: string
    category?: string
    page?: number
    page_size?: number
  }): Promise<ApiResponse<{
    materials: MaterialResult[]
    total: number
    page: number
    page_size: number
  }>> {
    return request.get('/api/v1/materials/search', { params })
  },

  /**
   * 获取分类列表
   */
  getCategories(): Promise<ApiResponse<{ categories: CategoryInfo[] }>> {
    return request.get('/api/v1/categories')
  },

  /**
   * 健康检查
   */
  healthCheck(): Promise<ApiResponse<{
    status: string
    database: string
    timestamp: string
  }>> {
    return request.get('/api/v1/health')
  }
}
