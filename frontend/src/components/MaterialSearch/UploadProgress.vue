<template>
  <div class="upload-progress-container">
    <el-card shadow="always">
      <div class="progress-content">
        <!-- 进度标题 -->
        <div class="progress-header">
          <h3>{{ statusText }}</h3>
          <el-tag :type="statusType" size="large">
            {{ progress }}%
          </el-tag>
        </div>

        <!-- 进度条 -->
        <el-progress
          :percentage="progress"
          :status="progressStatus"
          :stroke-width="20"
          :text-inside="false"
        >
          <template #default="{ percentage }">
            <span class="progress-text">{{ percentage }}%</span>
          </template>
        </el-progress>

        <!-- 详细信息 -->
        <div class="progress-details">
          <div class="detail-row">
            <span class="label">
              <el-icon><Clock /></el-icon>
              已用时间:
            </span>
            <span class="value">{{ formattedElapsedTime }}</span>
          </div>
          
          <div v-if="progress < 100" class="detail-row">
            <span class="label">
              <el-icon><Timer /></el-icon>
              预计剩余:
            </span>
            <span class="value">{{ formattedRemainingTime }}</span>
          </div>

          <div v-if="uploadSpeed > 0" class="detail-row">
            <span class="label">
              <el-icon><Upload /></el-icon>
              上传速度:
            </span>
            <span class="value">{{ formattedSpeed }}</span>
          </div>

          <div v-if="processedItems !== null && totalItems !== null" class="detail-row">
            <span class="label">
              <el-icon><Document /></el-icon>
              处理进度:
            </span>
            <span class="value">{{ processedItems }} / {{ totalItems }} 条</span>
          </div>
        </div>

        <!-- 当前状态描述 -->
        <div v-if="currentStep" class="current-step" :class="{ completed: progress === 100 }">
          <el-icon v-if="progress < 100" class="is-loading"><Loading /></el-icon>
          <el-icon v-else color="#67c23a"><CircleCheck /></el-icon>
          <span>{{ currentStep }}</span>
        </div>

        <!-- 操作按钮 -->
        <div class="progress-actions">
          <el-button
            v-if="progress < 100 && !isPaused"
            type="warning"
            @click="handlePause"
            :disabled="!allowCancel"
          >
            <el-icon><VideoPause /></el-icon>
            暂停
          </el-button>
          
          <el-button
            v-if="isPaused"
            type="primary"
            @click="handleResume"
          >
            <el-icon><VideoPlay /></el-icon>
            继续
          </el-button>

          <el-button
            v-if="progress < 100"
            type="danger"
            @click="handleCancel"
            :disabled="!allowCancel"
          >
            <el-icon><Close /></el-icon>
            取消上传
          </el-button>

          <el-button
            v-if="progress === 100"
            type="success"
            @click="handleComplete"
          >
            <el-icon><Check /></el-icon>
            完成
          </el-button>
        </div>
      </div>
    </el-card>
  </div>
</template>

<script setup lang="ts">
/**
 * @component UploadProgress
 * @description 上传进度组件 - 显示实时进度、速度、时间估算
 * 
 * 关联测试点:
 * - [T.3.1] 进度显示准确
 * - [T.3.2] 时间估算合理
 * - [T.3.3] 取消功能正常
 * 
 * @props progress - 当前进度 (0-100)
 * @props uploadSpeed - 上传速度 (bytes/s)
 * @props processedItems - 已处理条数
 * @props totalItems - 总条数
 * @props currentStep - 当前步骤描述
 * @props allowCancel - 是否允许取消
 * 
 * @emits (pause) - 暂停上传
 * @emits (resume) - 继续上传
 * @emits (cancel) - 取消上传
 * @emits (complete) - 完成上传
 */

import { ref, computed, watch, onMounted, onUnmounted } from 'vue'
import { ElMessageBox } from 'element-plus'

interface Props {
  progress: number
  uploadSpeed?: number
  processedItems?: number | null
  totalItems?: number | null
  currentStep?: string
  allowCancel?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  progress: 0,
  uploadSpeed: 0,
  processedItems: null,
  totalItems: null,
  currentStep: '',
  allowCancel: true
})

interface Emits {
  (e: 'pause'): void
  (e: 'resume'): void
  (e: 'cancel'): void
  (e: 'complete'): void
}

const emit = defineEmits<Emits>()

// 状态
const isPaused = ref(false)
const startTime = ref<number>(Date.now())
const elapsedSeconds = ref(0)
let timerInterval: number | null = null

// 计算属性

const statusText = computed(() => {
  if (props.progress === 100) return '上传完成'
  if (isPaused.value) return '已暂停'
  if (props.progress === 0) return '准备上传...'
  return '正在上传'
})

const statusType = computed(() => {
  if (props.progress === 100) return 'success'
  if (isPaused.value) return 'warning'
  return 'primary'
})

const progressStatus = computed(() => {
  if (props.progress === 100) return 'success'
  return undefined
})

const formattedElapsedTime = computed(() => {
  return formatTime(elapsedSeconds.value)
})

const formattedRemainingTime = computed(() => {
  if (props.progress === 0 || props.progress === 100) return '--'
  
  // 基于当前进度和已用时间估算剩余时间
  const avgSpeed = props.progress / elapsedSeconds.value // 每秒进度
  if (avgSpeed <= 0) return '--'
  
  const remainingProgress = 100 - props.progress
  const remainingSeconds = Math.ceil(remainingProgress / avgSpeed)
  
  return formatTime(remainingSeconds)
})

const formattedSpeed = computed(() => {
  if (props.uploadSpeed === 0) return '--'
  return formatBytes(props.uploadSpeed) + '/s'
})

/**
 * 格式化时间（秒 -> HH:MM:SS）
 */
const formatTime = (seconds: number): string => {
  if (seconds < 0) return '00:00'
  
  const hours = Math.floor(seconds / 3600)
  const minutes = Math.floor((seconds % 3600) / 60)
  const secs = seconds % 60
  
  if (hours > 0) {
    return `${String(hours).padStart(2, '0')}:${String(minutes).padStart(2, '0')}:${String(secs).padStart(2, '0')}`
  }
  
  return `${String(minutes).padStart(2, '0')}:${String(secs).padStart(2, '0')}`
}

/**
 * 格式化字节大小
 */
const formatBytes = (bytes: number): string => {
  if (bytes === 0) return '0 B'
  const k = 1024
  const sizes = ['B', 'KB', 'MB', 'GB']
  const i = Math.floor(Math.log(bytes) / Math.log(k))
  return Math.round(bytes / Math.pow(k, i) * 100) / 100 + ' ' + sizes[i]
}

/**
 * 暂停上传
 */
const handlePause = () => {
  isPaused.value = true
  emit('pause')
}

/**
 * 继续上传
 */
const handleResume = () => {
  isPaused.value = false
  emit('resume')
}

/**
 * 取消上传
 */
const handleCancel = async () => {
  try {
    await ElMessageBox.confirm(
      '确定要取消上传吗？已上传的数据将会丢失。',
      '取消确认',
      {
        confirmButtonText: '确定取消',
        cancelButtonText: '继续上传',
        type: 'warning'
      }
    )
    
    emit('cancel')
  } catch {
    // 用户取消了取消操作
  }
}

/**
 * 完成上传
 */
const handleComplete = () => {
  emit('complete')
}

/**
 * 启动计时器
 */
const startTimer = () => {
  if (timerInterval) return
  
  startTime.value = Date.now()
  timerInterval = window.setInterval(() => {
    if (!isPaused.value && props.progress < 100) {
      elapsedSeconds.value = Math.floor((Date.now() - startTime.value) / 1000)
    }
  }, 1000)
}

/**
 * 停止计时器
 */
const stopTimer = () => {
  if (timerInterval) {
    clearInterval(timerInterval)
    timerInterval = null
  }
}

// 监听进度变化
watch(
  () => props.progress,
  (newProgress) => {
    if (newProgress > 0 && newProgress < 100) {
      startTimer()
    } else if (newProgress === 100) {
      stopTimer()
    }
  },
  { immediate: true }
)

// 生命周期
onMounted(() => {
  if (props.progress > 0 && props.progress < 100) {
    startTimer()
  }
})

onUnmounted(() => {
  stopTimer()
})
</script>

<style scoped lang="scss">
.upload-progress-container {
  width: 100%;

  .progress-content {
    padding: 10px 0;

    .progress-header {
      display: flex;
      align-items: center;
      justify-content: space-between;
      margin-bottom: 20px;

      h3 {
        margin: 0;
        font-size: 18px;
        font-weight: 600;
        color: #303133;
      }
    }

    .el-progress {
      margin-bottom: 20px;

      :deep(.el-progress__text) {
        font-size: 16px;
        font-weight: 600;
      }
    }

    .progress-details {
      margin-bottom: 20px;
      padding: 16px;
      background: #f5f7fa;
      border-radius: 8px;

      .detail-row {
        display: flex;
        justify-content: space-between;
        align-items: center;
        padding: 8px 0;

        &:not(:last-child) {
          border-bottom: 1px solid #e4e7ed;
        }

        .label {
          display: flex;
          align-items: center;
          gap: 8px;
          color: #606266;
          font-size: 14px;

          .el-icon {
            color: #909399;
          }
        }

        .value {
          font-weight: 600;
          color: #303133;
          font-size: 14px;
        }
      }
    }

    .current-step {
      display: flex;
      align-items: center;
      gap: 10px;
      padding: 12px;
      margin-bottom: 20px;
      background: #ecf5ff;
      border: 1px solid #d9ecff;
      border-radius: 4px;
      color: #409eff;
      font-size: 14px;
      transition: all 0.3s;

      .el-icon {
        font-size: 18px;
      }

      &.completed {
        background: #f0f9ff;
        border-color: #c6e2ff;
        color: #67c23a;

        .el-icon {
          animation: none !important;
        }
      }
    }

    .progress-actions {
      display: flex;
      justify-content: flex-end;
      gap: 12px;
    }
  }
}
</style>

