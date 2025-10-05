import { ref, computed } from 'vue'
import type { UploadFile } from 'element-plus'
import { ElMessage } from 'element-plus'

export interface FileUploadOptions {
  maxSize?: number // MB
  accept?: string[]
  onSuccess?: (file: File) => void
  onError?: (error: Error) => void
}

export function useFileUpload(options: FileUploadOptions = {}) {
  const {
    maxSize = 10,
    accept = ['.xlsx', '.xls'],
    onSuccess,
    onError
  } = options

  const selectedFile = ref<File | null>(null)
  const fileInfo = ref<{
    name: string
    size: number
    type: string
  } | null>(null)
  const uploadProgress = ref(0)
  const isUploading = ref(false)
  const error = ref<string>('')

  // 文件大小格式化
  const formatFileSize = (bytes: number): string => {
    if (bytes === 0) return '0 B'
    const k = 1024
    const sizes = ['B', 'KB', 'MB', 'GB']
    const i = Math.floor(Math.log(bytes) / Math.log(k))
    return Math.round(bytes / Math.pow(k, i) * 100) / 100 + ' ' + sizes[i]
  }

  // 验证文件类型
  const validateFileType = (file: File): boolean => {
    const extension = '.' + file.name.split('.').pop()?.toLowerCase()
    if (!accept.includes(extension)) {
      error.value = `不支持的文件类型，请上传 ${accept.join(', ')} 格式的文件`
      return false
    }
    return true
  }

  // 验证文件大小
  const validateFileSize = (file: File): boolean => {
    const maxBytes = maxSize * 1024 * 1024
    if (file.size > maxBytes) {
      error.value = `文件大小不能超过 ${maxSize}MB`
      return false
    }
    return true
  }

  // 处理文件选择
  const handleFileChange = (uploadFile: UploadFile) => {
    error.value = ''
    
    if (!uploadFile.raw) {
      error.value = '无效的文件'
      return
    }

    const file = uploadFile.raw

    // 验证文件
    if (!validateFileType(file) || !validateFileSize(file)) {
      selectedFile.value = null
      fileInfo.value = null
      if (onError) {
        onError(new Error(error.value))
      }
      return
    }

    // 保存文件信息
    selectedFile.value = file
    fileInfo.value = {
      name: file.name,
      size: file.size,
      type: file.type
    }

    if (onSuccess) {
      onSuccess(file)
    }
  }

  // 处理文件超出限制
  const handleExceed = () => {
    ElMessage.warning('只能上传一个文件')
  }

  // 清除文件
  const clearFile = () => {
    selectedFile.value = null
    fileInfo.value = null
    uploadProgress.value = 0
    isUploading.value = false
    error.value = ''
  }

  // 模拟上传进度
  const simulateProgress = (callback?: () => void) => {
    isUploading.value = true
    uploadProgress.value = 0

    const interval = setInterval(() => {
      uploadProgress.value += 10
      if (uploadProgress.value >= 100) {
        clearInterval(interval)
        isUploading.value = false
        if (callback) {
          callback()
        }
      }
    }, 200)
  }

  // 计算属性
  const hasFile = computed(() => selectedFile.value !== null)
  const formattedFileSize = computed(() => 
    fileInfo.value ? formatFileSize(fileInfo.value.size) : ''
  )

  return {
    // State
    selectedFile,
    fileInfo,
    uploadProgress,
    isUploading,
    error,

    // Computed
    hasFile,
    formattedFileSize,

    // Methods
    handleFileChange,
    handleExceed,
    clearFile,
    simulateProgress,
    formatFileSize
  }
}
