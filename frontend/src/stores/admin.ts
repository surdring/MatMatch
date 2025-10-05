import { defineStore } from 'pinia'
import { ref } from 'vue'

export const useAdminStore = defineStore('admin', () => {
  // State
  const extractionRules = ref<any[]>([])
  const synonyms = ref<any[]>([])
  const materialCategories = ref<any[]>([])
  const etlJobs = ref<any[]>([])
  const currentETLJob = ref<any>(null)
  const testResults = ref<any[]>([])
  const isLoading = ref(false)

  // Actions
  const loadExtractionRules = async () => {
    // TODO: 实现加载提取规则
    isLoading.value = true
    try {
      // const response = await adminApi.getExtractionRules()
      // extractionRules.value = response.data
      console.log('加载提取规则（待实现）')
    } finally {
      isLoading.value = false
    }
  }

  const loadSynonyms = async () => {
    // TODO: 实现加载同义词
    isLoading.value = true
    try {
      // const response = await adminApi.getSynonyms()
      // synonyms.value = response.data
      console.log('加载同义词（待实现）')
    } finally {
      isLoading.value = false
    }
  }

  const loadMaterialCategories = async () => {
    // TODO: 实现加载物料分类
    isLoading.value = true
    try {
      // const response = await adminApi.getMaterialCategories()
      // materialCategories.value = response.data
      console.log('加载物料分类（待实现）')
    } finally {
      isLoading.value = false
    }
  }

  return {
    // State
    extractionRules,
    synonyms,
    materialCategories,
    etlJobs,
    currentETLJob,
    testResults,
    isLoading,

    // Actions
    loadExtractionRules,
    loadSynonyms,
    loadMaterialCategories
  }
})
