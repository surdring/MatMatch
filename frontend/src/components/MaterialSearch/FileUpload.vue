<template>
  <div class="file-upload-container">
    <!-- 拖拽上传区域 -->
    <div v-if="!hasFile" class="upload-area">
      <el-upload
        ref="uploadRef"
        class="upload-dragger"
        drag
        :auto-upload="false"
        :accept="acceptTypes"
        :limit="1"
        :on-change="handleFileSelect"
        :on-exceed="handleExceed"
        :show-file-list="false"
      >
        <div class="upload-content">
          <el-icon class="upload-icon" :size="60" color="#409eff">
            <UploadFilled />
          </el-icon>
          <div class="upload-text">
            <p class="main-text">将Excel文件拖到此处</p>
            <p class="sub-text">或 <em>点击上传</em></p>
          </div>
          <div class="upload-tips">
            <el-tag type="info" size="small">支持 .xlsx, .xls 格式</el-tag>
            <el-tag type="warning" size="small">文件大小 ≤ {{ maxSizeMB }}MB</el-tag>
          </div>
        </div>
      </el-upload>
    </div>

    <!-- 文件信息展示 -->
    <div v-else class="file-info-card">
      <el-card shadow="hover">
        <div class="file-header">
          <div class="file-icon">
            <el-icon :size="40" color="#67c23a">
              <Document />
            </el-icon>
          </div>
          <div class="file-details">
            <h3 class="file-name">{{ fileInfo?.name }}</h3>
            <p class="file-meta">
              <el-tag size="small">{{ formattedFileSize }}</el-tag>
              <el-tag size="small" type="success">{{ fileInfo?.type || 'Excel' }}</el-tag>
            </p>
          </div>
          <div class="file-actions">
            <el-button type="danger" text @click="handleRemoveFile">
              <el-icon><Delete /></el-icon>
              移除文件
            </el-button>
          </div>
        </div>

        <!-- 文件预览区域 -->
        <el-divider />
        <div v-if="previewData.length > 0" class="file-preview">
          <div class="preview-header">
            <h4>文件预览（前 {{ previewData.length }} 行）</h4>
            <el-button text type="primary" @click="refreshPreview">
              <el-icon><Refresh /></el-icon>
              刷新预览
            </el-button>
          </div>
          <el-table
            :data="previewData"
            border
            stripe
            size="small"
            max-height="300"
            style="width: 100%"
          >
            <el-table-column
              v-for="(col, index) in previewColumns"
              :key="index"
              :prop="col.key"
              :label="col.label"
              min-width="120"
              show-overflow-tooltip
            />
          </el-table>
        </div>
        <div v-else class="loading-preview">
          <el-icon class="is-loading" :size="30">
            <Loading />
          </el-icon>
          <p>正在解析文件...</p>
        </div>
      </el-card>
    </div>

    <!-- 错误提示 -->
    <el-alert
      v-if="error"
      type="error"
      :title="error"
      :closable="true"
      show-icon
      @close="error = ''"
      style="margin-top: 16px"
    />
  </div>
</template>

<script setup lang="ts">
/**
 * @component FileUpload
 * @description 文件上传组件 - 支持拖拽上传、文件预览、自动解析Excel
 * 
 * 关联测试点:
 * - [T.1.1] 拖拽上传功能
 * - [T.1.2] 文件类型验证
 * - [T.1.3] 文件大小验证
 * - [T.1.4] 文件预览显示
 * 
 * @emits (file-selected) - 文件选择成功
 * @emits (file-removed) - 文件移除
 * @emits (error) - 文件验证失败
 */

import { ref, computed } from 'vue'
import type { UploadFile, UploadInstance } from 'element-plus'
import { ElMessage } from 'element-plus'
import * as XLSX from 'xlsx'

interface Props {
  maxSizeMB?: number
  acceptTypes?: string
  previewRows?: number
}

const props = withDefaults(defineProps<Props>(), {
  maxSizeMB: 10,
  acceptTypes: '.xlsx,.xls',
  previewRows: 5
})

interface Emits {
  (e: 'file-selected', file: File, previewData: any[]): void
  (e: 'file-removed'): void
  (e: 'error', error: string): void
}

const emit = defineEmits<Emits>()

// 状态
const uploadRef = ref<UploadInstance>()
const selectedFile = ref<File | null>(null)
const fileInfo = ref<{
  name: string
  size: number
  type: string
} | null>(null)
const previewData = ref<any[]>([])
const previewColumns = ref<{ key: string; label: string }[]>([])
const error = ref('')

// 计算属性
const hasFile = computed(() => selectedFile.value !== null)

const formattedFileSize = computed(() => {
  if (!fileInfo.value) return ''
  const bytes = fileInfo.value.size
  if (bytes === 0) return '0 B'
  const k = 1024
  const sizes = ['B', 'KB', 'MB', 'GB']
  const i = Math.floor(Math.log(bytes) / Math.log(k))
  return Math.round(bytes / Math.pow(k, i) * 100) / 100 + ' ' + sizes[i]
})

/**
 * 验证文件类型
 */
const validateFileType = (file: File): boolean => {
  const extension = '.' + file.name.split('.').pop()?.toLowerCase()
  const accepted = props.acceptTypes.split(',').map(t => t.trim())
  
  if (!accepted.includes(extension)) {
    error.value = `不支持的文件类型，请上传 ${props.acceptTypes} 格式的文件`
    return false
  }
  return true
}

/**
 * 验证文件大小
 */
const validateFileSize = (file: File): boolean => {
  const maxBytes = props.maxSizeMB * 1024 * 1024
  if (file.size > maxBytes) {
    error.value = `文件大小不能超过 ${props.maxSizeMB}MB`
    return false
  }
  return true
}

/**
 * 解析Excel文件并生成预览
 */
const parseExcelFile = async (file: File): Promise<void> => {
  try {
    const arrayBuffer = await file.arrayBuffer()
    const workbook = XLSX.read(arrayBuffer, { type: 'array' })
    
    // 读取第一个sheet
    const firstSheetName = workbook.SheetNames[0]
    const worksheet = workbook.Sheets[firstSheetName]
    
    // 转换为JSON
    const jsonData = XLSX.utils.sheet_to_json(worksheet, { header: 1 }) as any[][]
    
    if (jsonData.length === 0) {
      error.value = '文件为空，请检查文件内容'
      return
    }

    // 提取表头
    const headers = jsonData[0] as string[]
    
    // 生成列定义
    previewColumns.value = headers.map((header, index) => ({
      key: `col_${index}`,
      label: header || `列${index + 1}`
    }))

    // 生成预览数据（前N行）
    const dataRows = jsonData.slice(1, props.previewRows + 1)
    previewData.value = dataRows.map(row => {
      const obj: any = {}
      headers.forEach((_, index) => {
        obj[`col_${index}`] = row[index] || ''
      })
      return obj
    })

    // 触发文件选择事件，传递完整数据
    const allData = jsonData.slice(1).map(row => {
      const obj: any = {}
      headers.forEach((header, index) => {
        obj[header || `col_${index}`] = row[index] || ''
      })
      return obj
    })
    
    emit('file-selected', file, allData)
    
  } catch (err) {
    console.error('解析Excel文件失败:', err)
    error.value = '文件解析失败，请确保文件格式正确'
    emit('error', error.value)
  }
}

/**
 * 处理文件选择
 */
const handleFileSelect = async (uploadFile: UploadFile) => {
  error.value = ''
  previewData.value = []
  previewColumns.value = []
  
  if (!uploadFile.raw) {
    error.value = '无效的文件'
    emit('error', error.value)
    return
  }

  const file = uploadFile.raw

  // 验证文件
  if (!validateFileType(file) || !validateFileSize(file)) {
    emit('error', error.value)
    return
  }

  // 保存文件信息
  selectedFile.value = file
  fileInfo.value = {
    name: file.name,
    size: file.size,
    type: file.type || 'application/vnd.ms-excel'
  }

  // 解析文件并生成预览
  await parseExcelFile(file)
  
  ElMessage.success('文件上传成功')
}

/**
 * 处理文件超出限制
 */
const handleExceed = () => {
  ElMessage.warning('只能上传一个文件，请先移除当前文件')
}

/**
 * 移除文件
 */
const handleRemoveFile = () => {
  selectedFile.value = null
  fileInfo.value = null
  previewData.value = []
  previewColumns.value = []
  error.value = ''
  
  // 清空upload组件
  uploadRef.value?.clearFiles()
  
  emit('file-removed')
  ElMessage.info('文件已移除')
}

/**
 * 刷新预览
 */
const refreshPreview = async () => {
  if (selectedFile.value) {
    await parseExcelFile(selectedFile.value)
  }
}

// 暴露方法给父组件
defineExpose({
  selectedFile,
  fileInfo,
  previewData,
  clearFile: handleRemoveFile
})
</script>

<style scoped lang="scss">
.file-upload-container {
  width: 100%;
}

.upload-area {
  .upload-dragger {
    width: 100%;

    :deep(.el-upload-dragger) {
      width: 100%;
      height: 280px;
      display: flex;
      align-items: center;
      justify-content: center;
      border: 2px dashed #d9d9d9;
      border-radius: 8px;
      background: #fafafa;
      transition: all 0.3s;

      &:hover {
        border-color: #409eff;
        background: #f5f7fa;
      }
    }
  }

  .upload-content {
    text-align: center;
    padding: 20px;

    .upload-icon {
      margin-bottom: 16px;
    }

    .upload-text {
      margin-bottom: 20px;

      .main-text {
        font-size: 16px;
        color: #606266;
        margin-bottom: 8px;
      }

      .sub-text {
        font-size: 14px;
        color: #909399;

        em {
          color: #409eff;
          font-style: normal;
          text-decoration: underline;
          cursor: pointer;
        }
      }
    }

    .upload-tips {
      display: flex;
      justify-content: center;
      gap: 8px;
    }
  }
}

.file-info-card {
  .file-header {
    display: flex;
    align-items: center;
    gap: 16px;

    .file-icon {
      flex-shrink: 0;
    }

    .file-details {
      flex: 1;
      min-width: 0;

      .file-name {
        margin: 0 0 8px 0;
        font-size: 16px;
        font-weight: 600;
        color: #303133;
        overflow: hidden;
        text-overflow: ellipsis;
        white-space: nowrap;
      }

      .file-meta {
        margin: 0;
        display: flex;
        gap: 8px;
      }
    }

    .file-actions {
      flex-shrink: 0;
    }
  }

  .file-preview {
    .preview-header {
      display: flex;
      align-items: center;
      justify-content: space-between;
      margin-bottom: 16px;

      h4 {
        margin: 0;
        font-size: 14px;
        font-weight: 600;
        color: #606266;
      }
    }
  }

  .loading-preview {
    text-align: center;
    padding: 40px 20px;
    color: #909399;

    .el-icon {
      margin-bottom: 12px;
    }

    p {
      margin: 0;
      font-size: 14px;
    }
  }
}
</style>

