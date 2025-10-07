import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { materialApi } from '@/api'
import type { BatchSearchResponse, MaterialResult, CategoryInfo } from '@/api/material'

export const useMaterialStore = defineStore('material', () => {
  // State
  const batchResults = ref<BatchSearchResponse | null>(null)
  const isProcessing = ref(false)
  const uploadProgress = ref(0)
  const errorMessage = ref('')
  const currentFile = ref<File | null>(null)
  const categories = ref<CategoryInfo[]>([])

  // 处理统计
  const processingStats = ref({
    totalRecords: 0,
    processedRecords: 0,
    failedRecords: 0,
    estimatedTimeRemaining: 0
  })

  // Getters
  const hasResults = computed(() => batchResults.value?.results && batchResults.value.results.length > 0)
  const totalProcessed = computed(() => batchResults.value?.total_processed || 0)
  const successRate = computed(() => {
    const stats = processingStats.value
    if (stats.totalRecords === 0) return 0
    return ((stats.processedRecords / stats.totalRecords) * 100).toFixed(1)
  })

  // Actions
  const uploadAndSearch = async (
    file: File,
    columns: {
      material_name?: string
      specification?: string
      unit_name?: string
    }
  ) => {
    try {
      isProcessing.value = true
      errorMessage.value = ''
      currentFile.value = file
      uploadProgress.value = 0

      const response = await materialApi.batchSearch(file, columns, (progress) => {
        uploadProgress.value = progress
      })

      batchResults.value = response.data
      processingStats.value = {
        totalRecords: response.data.total_processed || 0,
        processedRecords: response.data.total_processed || 0,
        failedRecords: response.data.skipped_rows?.length || 0,
        estimatedTimeRemaining: 0
      }

      return response.data
    } catch (error: any) {
      errorMessage.value = error.message || '批量查重失败'
      throw error
    } finally {
      isProcessing.value = false
      uploadProgress.value = 0
    }
  }

  const clearResults = () => {
    batchResults.value = null
    errorMessage.value = ''
    currentFile.value = null
    uploadProgress.value = 0
    processingStats.value = {
      totalRecords: 0,
      processedRecords: 0,
      failedRecords: 0,
      estimatedTimeRemaining: 0
    }
  }

  const loadCategories = async () => {
    try {
      const response = await materialApi.getCategories()
      categories.value = response.data.categories
    } catch (error: any) {
      console.error('加载分类失败:', error)
      throw error
    }
  }

  return {
    // State
    batchResults,
    isProcessing,
    uploadProgress,
    errorMessage,
    currentFile,
    processingStats,
    categories,

    // Getters
    hasResults,
    totalProcessed,
    successRate,

    // Actions
    uploadAndSearch,
    clearResults,
    loadCategories
  }
})
