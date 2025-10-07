<template>
  <div class="component-test-container">
    <div class="page-header">
      <h1>组件测试页面</h1>
      <p>Task 4.2.1 - 文件上传组件测试</p>
    </div>

    <el-steps :active="currentStep" finish-status="success" style="margin-bottom: 30px">
      <el-step title="上传文件" />
      <el-step title="配置列名" />
      <el-step title="处理进度" />
      <el-step title="查看结果" />
    </el-steps>

    <!-- Step 1: 文件上传 -->
    <div v-show="currentStep === 0">
      <FileUpload
        ref="fileUploadRef"
        :max-size-m-b="10"
        :preview-rows="5"
        @file-selected="handleFileSelected"
        @file-removed="handleFileRemoved"
        @error="handleUploadError"
      />
      
      <div style="margin-top: 20px; text-align: right">
        <el-button
          type="primary"
          :disabled="!hasFile"
          @click="goToStep(1)"
        >
          下一步
          <el-icon><ArrowRight /></el-icon>
        </el-button>
      </div>
    </div>

    <!-- Step 2: 列名配置 -->
    <div v-show="currentStep === 1">
      <ColumnConfig
        ref="columnConfigRef"
        :available-columns="availableColumns"
        :sample-data="sampleData"
        @config-changed="handleConfigChanged"
        @config-valid="handleConfigValid"
      />

      <div style="margin-top: 20px; display: flex; justify-content: space-between">
        <el-button @click="goToStep(0)">
          <el-icon><ArrowLeft /></el-icon>
          上一步
        </el-button>
        <el-button
          type="primary"
          :disabled="!isConfigValid"
          @click="startUpload"
        >
          开始查重
          <el-icon><Search /></el-icon>
        </el-button>
      </div>
    </div>

    <!-- Step 3: 上传进度 -->
    <div v-show="currentStep === 2">
      <UploadProgress
        :progress="uploadProgress"
        :upload-speed="uploadSpeed"
        :processed-items="processedItems"
        :total-items="totalItems"
        :current-step="currentStepText"
        :allow-cancel="true"
        @pause="handlePause"
        @resume="handleResume"
        @cancel="handleCancel"
        @complete="handleComplete"
      />
    </div>

    <!-- Step 4: 测试结果 -->
    <div v-show="currentStep === 3">
      <el-result
        icon="success"
        title="测试完成"
        sub-title="所有组件功能正常"
      >
        <template #extra>
          <el-button type="primary" @click="resetTest">
            重新测试
          </el-button>
          <el-button @click="$router.push('/search')">
            前往物料查重页面
          </el-button>
        </template>
      </el-result>

      <el-card style="margin-top: 20px">
        <template #header>
          <h3>测试数据</h3>
        </template>
        <el-descriptions :column="2" border>
          <el-descriptions-item label="文件名">
            {{ selectedFile?.name || '-' }}
          </el-descriptions-item>
          <el-descriptions-item label="文件大小">
            {{ formattedFileSize }}
          </el-descriptions-item>
          <el-descriptions-item label="物料名称列">
            {{ columnConfig.materialName || '-' }}
          </el-descriptions-item>
          <el-descriptions-item label="规格型号列">
            {{ columnConfig.specification || '-' }}
          </el-descriptions-item>
          <el-descriptions-item label="单位列">
            {{ columnConfig.unitName || '-' }}
          </el-descriptions-item>
          <el-descriptions-item label="数据行数">
            {{ sampleData.length }} 行
          </el-descriptions-item>
        </el-descriptions>
      </el-card>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { ElMessage } from 'element-plus'
import FileUpload from '@/components/MaterialSearch/FileUpload.vue'
import ColumnConfig from '@/components/MaterialSearch/ColumnConfig.vue'
import UploadProgress from '@/components/MaterialSearch/UploadProgress.vue'
import type { ColumnMapping } from '@/components/MaterialSearch/ColumnConfig.vue'

// 组件引用
const fileUploadRef = ref()
const columnConfigRef = ref()

// 步骤控制
const currentStep = ref(0)

// 文件相关
const selectedFile = ref<File | null>(null)
const sampleData = ref<any[]>([])
const availableColumns = ref<string[]>([])
const hasFile = ref(false)

// 配置相关
const columnConfig = ref<ColumnMapping>({
  materialName: '',
  specification: '',
  unitName: ''
})
const isConfigValid = ref(false)

// 上传进度相关
const uploadProgress = ref(0)
const uploadSpeed = ref(0)
const processedItems = ref(0)
const totalItems = ref(0)
const currentStepText = ref('')
let progressTimer: number | null = null

// 计算属性
const formattedFileSize = computed(() => {
  if (!selectedFile.value) return '-'
  const bytes = selectedFile.value.size
  if (bytes === 0) return '0 B'
  const k = 1024
  const sizes = ['B', 'KB', 'MB', 'GB']
  const i = Math.floor(Math.log(bytes) / Math.log(k))
  return Math.round(bytes / Math.pow(k, i) * 100) / 100 + ' ' + sizes[i]
})

/**
 * 文件选择成功
 */
const handleFileSelected = (file: File, data: any[]) => {
  selectedFile.value = file
  sampleData.value = data
  hasFile.value = true

  // 提取列名
  if (data.length > 0) {
    availableColumns.value = Object.keys(data[0])
  }

  ElMessage.success('文件解析成功')
}

/**
 * 文件移除
 */
const handleFileRemoved = () => {
  selectedFile.value = null
  sampleData.value = []
  availableColumns.value = []
  hasFile.value = false
  currentStep.value = 0
}

/**
 * 上传错误
 */
const handleUploadError = (error: string) => {
  ElMessage.error(error)
}

/**
 * 配置变更
 */
const handleConfigChanged = (config: ColumnMapping) => {
  columnConfig.value = config
}

/**
 * 配置验证
 */
const handleConfigValid = (valid: boolean) => {
  isConfigValid.value = valid
}

/**
 * 跳转步骤
 */
const goToStep = (step: number) => {
  currentStep.value = step
}

/**
 * 开始上传（模拟）
 */
const startUpload = () => {
  currentStep.value = 2
  uploadProgress.value = 0
  processedItems.value = 0
  totalItems.value = sampleData.value.length

  // 模拟上传进度
  simulateProgress()
}

/**
 * 模拟进度
 */
const simulateProgress = () => {
  const steps = [
    { progress: 20, text: '正在上传文件...', speed: 1024 * 500 },
    { progress: 40, text: '正在解析Excel数据...', speed: 1024 * 800 },
    { progress: 60, text: '正在标准化物料描述...', speed: 1024 * 600 },
    { progress: 80, text: '正在查询相似物料...', speed: 1024 * 400 },
    { progress: 100, text: '处理完成！点击"完成"按钮继续', speed: 0 }
  ]

  let stepIndex = 0

  progressTimer = window.setInterval(() => {
    if (stepIndex < steps.length) {
      const step = steps[stepIndex]
      uploadProgress.value = step.progress
      currentStepText.value = step.text
      uploadSpeed.value = step.speed
      processedItems.value = Math.floor((step.progress / 100) * totalItems.value)
      
      stepIndex++
      
      // 到达100%时停止定时器
      if (step.progress === 100) {
        if (progressTimer) {
          clearInterval(progressTimer)
          progressTimer = null
        }
      }
    }
  }, 1000)
}

/**
 * 暂停
 */
const handlePause = () => {
  if (progressTimer) {
    clearInterval(progressTimer)
    progressTimer = null
  }
  ElMessage.info('已暂停')
}

/**
 * 继续
 */
const handleResume = () => {
  ElMessage.info('继续上传')
  simulateProgress()
}

/**
 * 取消
 */
const handleCancel = () => {
  if (progressTimer) {
    clearInterval(progressTimer)
    progressTimer = null
  }
  uploadProgress.value = 0
  currentStep.value = 0
  ElMessage.warning('已取消上传')
}

/**
 * 完成
 */
const handleComplete = () => {
  currentStep.value = 3
  ElMessage.success('测试完成！')
}

/**
 * 重置测试
 */
const resetTest = () => {
  selectedFile.value = null
  sampleData.value = []
  availableColumns.value = []
  hasFile.value = false
  columnConfig.value = {
    materialName: '',
    specification: '',
    unitName: ''
  }
  isConfigValid.value = false
  uploadProgress.value = 0
  currentStep.value = 0
  
  // 清空组件
  fileUploadRef.value?.clearFile()
}
</script>

<style scoped lang="scss">
.component-test-container {
  padding: 20px;
  max-width: 1200px;
  margin: 0 auto;
}

.page-header {
  margin-bottom: 30px;

  h1 {
    font-size: 28px;
    font-weight: 600;
    color: #303133;
    margin-bottom: 8px;
  }

  p {
    color: #909399;
    font-size: 14px;
  }
}
</style>

