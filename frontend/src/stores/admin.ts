/**
 * @store adminStore
 * @description 管理后台状态管理Store
 * 
 * 职责：
 * - 管理提取规则、同义词、分类数据的状态
 * - 提供CRUD操作的Actions
 * - 管理ETL监控数据
 * - 管理加载状态和错误信息
 * 
 * 关联测试点 (Associated Test Points):
 * - [T.1.1] - 规则列表加载和分页
 * - [T.1.5] - 同义词CRUD完整流程
 * - [T.1.6] - 分类管理CRUD完整流程
 * - [T.1.7] - ETL监控数据展示
 */

import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import type { 
  ExtractionRuleInterface, 
  SynonymEntryInterface, 
  MaterialCategoryInterface,
  ETLJobLogInterface,
  ETLStatisticsInterface,
  PaginationParams,
  BatchImportResult
} from '@/types/admin'
import * as adminApi from '@/api/admin'
import { ElMessage } from 'element-plus'

export const useAdminStore = defineStore('admin', () => {
  // ==================== State ====================
  
  // 提取规则管理
  const extractionRules = ref<ExtractionRuleInterface[]>([])
  const extractionRulesTotal = ref(0)
  const currentRule = ref<ExtractionRuleInterface | null>(null)
  
  // 同义词管理
  const synonyms = ref<SynonymEntryInterface[]>([])
  const synonymsTotal = ref(0)
  const currentSynonym = ref<SynonymEntryInterface | null>(null)
  
  // 物料分类管理
  const materialCategories = ref<MaterialCategoryInterface[]>([])
  const categoriesTotal = ref(0)
  const currentCategory = ref<MaterialCategoryInterface | null>(null)
  
  // ETL监控
  const etlJobs = ref<ETLJobLogInterface[]>([])
  const etlJobsTotal = ref(0)
  const etlStatistics = ref<ETLStatisticsInterface | null>(null)
  
  // 加载状态
  const isLoading = ref(false)
  const isSubmitting = ref(false)
  const isImporting = ref(false)
  
  // 错误信息
  const errorMessage = ref('')
  
  // 批量导入结果
  const importResult = ref<BatchImportResult | null>(null)
  
  // ==================== Getters ====================
  
  const hasExtractionRules = computed(() => extractionRules.value.length > 0)
  const hasSynonyms = computed(() => synonyms.value.length > 0)
  const hasCategories = computed(() => materialCategories.value.length > 0)
  const hasETLJobs = computed(() => etlJobs.value.length > 0)
  
  // ==================== Actions ====================
  
  // ---------- 提取规则管理 ----------
  
  /**
   * [I.2.1] 加载提取规则列表
   * 对应测试点: [T.1.1] 规则列表加载和分页
   * 
   * @param params 分页和筛选参数
   */
  const loadExtractionRules = async (params: PaginationParams = {}) => {
    isLoading.value = true
    errorMessage.value = ''
    
    try {
      // [I.2.1.1] 使用后端分页，避免前端加载全部数据
      // 原因：规则数量可能增长到几百条，前端全量加载会影响性能
      const response = await adminApi.getExtractionRules(params)
      
      extractionRules.value = response.data.items
      extractionRulesTotal.value = response.data.total
      
    } catch (error: any) {
      errorMessage.value = error.response?.data?.detail || '加载规则列表失败'
      ElMessage.error(errorMessage.value)
      throw error
    } finally {
      isLoading.value = false
    }
  }
  
  /**
   * [I.2.2] 创建提取规则
   * 对应测试点: [T.1.2] 规则创建和表单验证
   * 
   * @param rule 规则数据
   */
  const createExtractionRule = async (rule: Partial<ExtractionRuleInterface>) => {
    isSubmitting.value = true
    errorMessage.value = ''
    
    try {
      const response = await adminApi.createExtractionRule(rule)
      
      // 添加到列表顶部
      extractionRules.value.unshift(response.data)
      extractionRulesTotal.value += 1
      
      ElMessage.success('规则创建成功')
      return response.data
      
    } catch (error: any) {
      errorMessage.value = error.response?.data?.detail || '创建规则失败'
      ElMessage.error(errorMessage.value)
      throw error
    } finally {
      isSubmitting.value = false
    }
  }
  
  /**
   * [I.2.3] 更新提取规则
   * 对应测试点: [T.1.3] 规则编辑和更新
   * 
   * @param id 规则ID
   * @param rule 更新的规则数据
   */
  const updateExtractionRule = async (id: number, rule: Partial<ExtractionRuleInterface>) => {
    isSubmitting.value = true
    errorMessage.value = ''
    
    try {
      const response = await adminApi.updateExtractionRule(id, rule)
      
      // 更新列表中的规则
      const index = extractionRules.value.findIndex(r => r.id === id)
      if (index !== -1) {
        extractionRules.value[index] = response.data
      }
      
      ElMessage.success('规则更新成功')
      return response.data
      
    } catch (error: any) {
      errorMessage.value = error.response?.data?.detail || '更新规则失败'
      ElMessage.error(errorMessage.value)
      throw error
    } finally {
      isSubmitting.value = false
    }
  }
  
  /**
   * [I.2.4] 删除提取规则
   * 对应测试点: [T.1.4] 规则删除和二次确认
   * 
   * @param id 规则ID
   */
  const deleteExtractionRule = async (id: number) => {
    isSubmitting.value = true
    errorMessage.value = ''
    
    try {
      await adminApi.deleteExtractionRule(id)
      
      // 从列表中移除
      extractionRules.value = extractionRules.value.filter(r => r.id !== id)
      extractionRulesTotal.value -= 1
      
      ElMessage.success('规则删除成功')
      
    } catch (error: any) {
      errorMessage.value = error.response?.data?.detail || '删除规则失败'
      ElMessage.error(errorMessage.value)
      throw error
    } finally {
      isSubmitting.value = false
    }
  }
  
  /**
   * [I.2.5] 批量导入提取规则
   * 
   * @param file Excel文件
   */
  const batchImportExtractionRules = async (file: File) => {
    isImporting.value = true
    errorMessage.value = ''
    
    try {
      const formData = new FormData()
      formData.append('file', file)
      
      const response = await adminApi.batchImportExtractionRules(formData)
      
      importResult.value = response.data
      
      ElMessage.success(`成功导入 ${response.data.success_count} 条规则`)
      
      // 刷新列表
      await loadExtractionRules()
      
      return response.data
      
    } catch (error: any) {
      errorMessage.value = error.response?.data?.detail || '批量导入失败'
      ElMessage.error(errorMessage.value)
      throw error
    } finally {
      isImporting.value = false
    }
  }
  
  // ---------- 同义词管理 ----------
  
  /**
   * [I.3.1] 加载同义词列表
   * 对应测试点: [T.1.5] 同义词CRUD完整流程
   * 
   * @param params 分页和筛选参数
   */
  const loadSynonyms = async (params: PaginationParams = {}) => {
    isLoading.value = true
    errorMessage.value = ''
    
    try {
      const response = await adminApi.getSynonyms(params)
      
      synonyms.value = response.data.items
      synonymsTotal.value = response.data.total
      
    } catch (error: any) {
      errorMessage.value = error.response?.data?.detail || '加载同义词列表失败'
      ElMessage.error(errorMessage.value)
      throw error
    } finally {
      isLoading.value = false
    }
  }
  
  /**
   * [I.3.2] 创建同义词
   * 
   * @param synonym 同义词数据
   */
  const createSynonym = async (synonym: Partial<SynonymEntryInterface>) => {
    isSubmitting.value = true
    errorMessage.value = ''
    
    try {
      const response = await adminApi.createSynonym(synonym)
      
      synonyms.value.unshift(response.data)
      synonymsTotal.value += 1
      
      ElMessage.success('同义词创建成功')
      return response.data
      
    } catch (error: any) {
      errorMessage.value = error.response?.data?.detail || '创建同义词失败'
      ElMessage.error(errorMessage.value)
      throw error
    } finally {
      isSubmitting.value = false
    }
  }
  
  /**
   * [I.3.3] 更新同义词
   * 
   * @param id 同义词ID
   * @param synonym 更新的同义词数据
   */
  const updateSynonym = async (id: number, synonym: Partial<SynonymEntryInterface>) => {
    isSubmitting.value = true
    errorMessage.value = ''
    
    try {
      const response = await adminApi.updateSynonym(id, synonym)
      
      const index = synonyms.value.findIndex(s => s.id === id)
      if (index !== -1) {
        synonyms.value[index] = response.data
      }
      
      ElMessage.success('同义词更新成功')
      return response.data
      
    } catch (error: any) {
      errorMessage.value = error.response?.data?.detail || '更新同义词失败'
      ElMessage.error(errorMessage.value)
      throw error
    } finally {
      isSubmitting.value = false
    }
  }
  
  /**
   * [I.3.4] 删除同义词
   * 
   * @param id 同义词ID
   */
  const deleteSynonym = async (id: number) => {
    isSubmitting.value = true
    errorMessage.value = ''
    
    try {
      await adminApi.deleteSynonym(id)
      
      synonyms.value = synonyms.value.filter(s => s.id !== id)
      synonymsTotal.value -= 1
      
      ElMessage.success('同义词删除成功')
      
    } catch (error: any) {
      errorMessage.value = error.response?.data?.detail || '删除同义词失败'
      ElMessage.error(errorMessage.value)
      throw error
    } finally {
      isSubmitting.value = false
    }
  }
  
  /**
   * [I.3.5] 批量导入同义词
   * 
   * @param file Excel文件
   */
  const batchImportSynonyms = async (file: File) => {
    isImporting.value = true
    errorMessage.value = ''
    
    try {
      const formData = new FormData()
      formData.append('file', file)
      
      const response = await adminApi.batchImportSynonyms(formData)
      
      importResult.value = response.data
      
      ElMessage.success(`成功导入 ${response.data.success_count} 条同义词`)
      
      await loadSynonyms()
      
      return response.data
      
    } catch (error: any) {
      errorMessage.value = error.response?.data?.detail || '批量导入失败'
      ElMessage.error(errorMessage.value)
      throw error
    } finally {
      isImporting.value = false
    }
  }
  
  // ---------- 物料分类管理 ----------
  
  /**
   * [I.4.1] 加载物料分类列表
   * 对应测试点: [T.1.6] 分类管理CRUD完整流程
   * 
   * @param params 分页和筛选参数
   */
  const loadMaterialCategories = async (params: PaginationParams = {}) => {
    isLoading.value = true
    errorMessage.value = ''
    
    try {
      const response = await adminApi.getMaterialCategories(params)
      
      materialCategories.value = response.data.items
      categoriesTotal.value = response.data.total
      
    } catch (error: any) {
      errorMessage.value = error.response?.data?.detail || '加载分类列表失败'
      ElMessage.error(errorMessage.value)
      throw error
    } finally {
      isLoading.value = false
    }
  }
  
  /**
   * [I.4.2] 更新物料分类
   * 
   * @param id 分类ID
   * @param category 更新的分类数据
   */
  const updateMaterialCategory = async (id: number, category: Partial<MaterialCategoryInterface>) => {
    isSubmitting.value = true
    errorMessage.value = ''
    
    try {
      const response = await adminApi.updateMaterialCategory(id, category)
      
      const index = materialCategories.value.findIndex(c => c.id === id)
      if (index !== -1) {
        materialCategories.value[index] = response.data
      }
      
      ElMessage.success('分类更新成功')
      return response.data
      
    } catch (error: any) {
      errorMessage.value = error.response?.data?.detail || '更新分类失败'
      ElMessage.error(errorMessage.value)
      throw error
    } finally {
      isSubmitting.value = false
    }
  }
  
  // ---------- ETL监控 ----------
  
  /**
   * [I.5.1] 加载ETL任务日志
   * 对应测试点: [T.1.7] ETL监控数据展示
   * 
   * @param params 分页和筛选参数
   */
  const loadETLJobs = async (params: PaginationParams = {}) => {
    isLoading.value = true
    errorMessage.value = ''
    
    try {
      const response = await adminApi.getETLJobs(params)
      
      etlJobs.value = response.data.items
      etlJobsTotal.value = response.data.total
      
    } catch (error: any) {
      errorMessage.value = error.response?.data?.detail || '加载ETL日志失败'
      ElMessage.error(errorMessage.value)
      throw error
    } finally {
      isLoading.value = false
    }
  }
  
  /**
   * [I.5.2] 加载ETL统计信息
   * 
   */
  const loadETLStatistics = async () => {
    isLoading.value = true
    errorMessage.value = ''
    
    try {
      const response = await adminApi.getETLStatistics()
      
      etlStatistics.value = response.data
      
    } catch (error: any) {
      errorMessage.value = error.response?.data?.detail || '加载ETL统计失败'
      ElMessage.error(errorMessage.value)
      throw error
    } finally {
      isLoading.value = false
    }
  }
  
  // ---------- 缓存管理 ----------
  
  /**
   * [I.6.1] 刷新知识库缓存
   * 
   */
  const refreshCache = async () => {
    isSubmitting.value = true
    errorMessage.value = ''
    
    try {
      await adminApi.refreshCache()
      
      ElMessage.success('缓存刷新成功')
      
    } catch (error: any) {
      errorMessage.value = error.response?.data?.detail || '缓存刷新失败'
      ElMessage.error(errorMessage.value)
      throw error
    } finally {
      isSubmitting.value = false
    }
  }
  
  // ---------- 清理方法 ----------
  
  const clearExtractionRules = () => {
    extractionRules.value = []
    extractionRulesTotal.value = 0
    currentRule.value = null
  }
  
  const clearSynonyms = () => {
    synonyms.value = []
    synonymsTotal.value = 0
    currentSynonym.value = null
  }
  
  const clearCategories = () => {
    materialCategories.value = []
    categoriesTotal.value = 0
    currentCategory.value = null
  }
  
  const clearETLJobs = () => {
    etlJobs.value = []
    etlJobsTotal.value = 0
    etlStatistics.value = null
  }
  
  const clearAll = () => {
    clearExtractionRules()
    clearSynonyms()
    clearCategories()
    clearETLJobs()
    errorMessage.value = ''
    importResult.value = null
  }
  
  // ==================== Return ====================
  
  return {
    // State
    extractionRules,
    extractionRulesTotal,
    currentRule,
    synonyms,
    synonymsTotal,
    currentSynonym,
    materialCategories,
    categoriesTotal,
    currentCategory,
    etlJobs,
    etlJobsTotal,
    etlStatistics,
    isLoading,
    isSubmitting,
    isImporting,
    errorMessage,
    importResult,
    
    // Getters
    hasExtractionRules,
    hasSynonyms,
    hasCategories,
    hasETLJobs,
    
    // Actions - 提取规则
    loadExtractionRules,
    createExtractionRule,
    updateExtractionRule,
    deleteExtractionRule,
    batchImportExtractionRules,
    
    // Actions - 同义词
    loadSynonyms,
    createSynonym,
    updateSynonym,
    deleteSynonym,
    batchImportExtractionRules,
    
    // Actions - 分类
    loadMaterialCategories,
    updateMaterialCategory,
    
    // Actions - ETL
    loadETLJobs,
    loadETLStatistics,
    
    // Actions - 缓存
    refreshCache,
    
    // Actions - 清理
    clearExtractionRules,
    clearSynonyms,
    clearCategories,
    clearETLJobs,
    clearAll
  }
})
