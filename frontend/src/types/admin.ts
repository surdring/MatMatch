/**
 * @file admin.ts
 * @description 管理后台相关的TypeScript类型定义
 * 
 * 基于后端Schema定义:
 * - backend/api/schemas/admin_schemas.py
 */

// ==================== 提取规则 ====================

export interface ExtractionRuleInterface {
  id?: number
  rule_name: string
  material_category: string
  attribute_name: string
  regex_pattern: string
  priority?: number
  is_active?: boolean
  description?: string
  example_input?: string
  example_output?: string
  version?: number
  created_by?: string
  created_at?: string
  updated_at?: string
}

// ==================== 同义词 ====================

export interface SynonymEntryInterface {
  id?: number
  original_term: string
  standard_term: string
  category?: string
  synonym_type?: 'general' | 'brand' | 'specification' | 'material' | 'unit'
  is_active?: boolean
  confidence?: number
  description?: string
  created_by?: string
  created_at?: string
  updated_at?: string
}

// ==================== 物料分类 ====================

export interface MaterialCategoryInterface {
  id: number
  category_name: string
  keywords: string[]
  detection_confidence?: number
  category_type?: string
  priority?: number
  data_source?: string
  is_active?: boolean
  created_by?: string
  created_at?: string
  updated_at?: string
}

// ==================== ETL监控 ====================

export interface ETLJobLogInterface {
  id: number
  job_type: 'full_sync' | 'incremental_sync'
  status: 'running' | 'completed' | 'failed'
  total_records?: number
  processed_records?: number
  failed_records?: number
  success_rate?: number
  duration_seconds?: number
  error_message?: string
  started_at: string
  completed_at?: string
}

export interface ETLStatisticsInterface {
  total_jobs: number
  today_jobs: number
  total_processed_records: number
  total_failed_records: number
  average_success_rate: number
  last_sync_time?: string
  last_sync_status?: string
}

// ==================== 分页参数 ====================

export interface PaginationParams {
  page?: number
  page_size?: number
  search?: string
  category?: string
  synonym_type?: string
  job_type?: string
  status?: string
  is_active?: boolean
  sort_by?: string
  sort_order?: 'asc' | 'desc'
}

export interface PaginatedResponse<T> {
  items: T[]
  total: number
  page: number
  page_size: number
  total_pages: number
}

// ==================== 批量导入 ====================

export interface BatchImportResult {
  success_count: number
  failed_count: number
  error_details?: Array<{
    row: number
    error: string
  }>
}

// ==================== 表单数据 ====================

export interface RuleFormData extends Omit<ExtractionRuleInterface, 'id' | 'created_at' | 'updated_at'> {}

export interface SynonymFormData extends Omit<SynonymEntryInterface, 'id' | 'created_at' | 'updated_at'> {}

export interface CategoryFormData extends Partial<MaterialCategoryInterface> {}

