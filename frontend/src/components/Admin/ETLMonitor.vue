<template>
  <div class="etl-monitor">
    <!-- ETL统计卡片 -->
    <!-- [T.1.7] ETL监控数据展示 -->
    <el-row :gutter="20" class="stats-cards">
      <el-col :span="6">
        <el-card shadow="hover">
          <div class="stat-card">
            <div class="stat-icon" style="background-color: #409eff;">
              <el-icon :size="32"><Document /></el-icon>
            </div>
            <div class="stat-content">
              <div class="stat-label">今日同步次数</div>
              <div class="stat-value">{{ statistics?.today_jobs || 0 }}</div>
            </div>
          </div>
        </el-card>
      </el-col>

      <el-col :span="6">
        <el-card shadow="hover">
          <div class="stat-card">
            <div class="stat-icon" style="background-color: #67c23a;">
              <el-icon :size="32"><DataAnalysis /></el-icon>
            </div>
            <div class="stat-content">
              <div class="stat-label">总处理记录数</div>
              <div class="stat-value">{{ formatNumber(statistics?.total_processed_records) }}</div>
            </div>
          </div>
        </el-card>
      </el-col>

      <el-col :span="6">
        <el-card shadow="hover">
          <div class="stat-card">
            <div class="stat-icon" style="background-color: #e6a23c;">
              <el-icon :size="32"><TrendCharts /></el-icon>
            </div>
            <div class="stat-content">
              <div class="stat-label">平均成功率</div>
              <div class="stat-value">{{ (statistics?.average_success_rate || 0).toFixed(1) }}%</div>
            </div>
          </div>
        </el-card>
      </el-col>

      <el-col :span="6">
        <el-card shadow="hover">
          <div class="stat-card">
            <div class="stat-icon" style="background-color: #909399;">
              <el-icon :size="32"><Clock /></el-icon>
            </div>
            <div class="stat-content">
              <div class="stat-label">最后同步时间</div>
              <div class="stat-value stat-time">
                {{ formatLastSync(statistics?.last_sync_time) }}
              </div>
            </div>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 操作栏 -->
    <div class="action-bar">
      <div class="title">
        <h3>ETL任务日志</h3>
      </div>
      
      <div class="action-buttons">
        <el-button :icon="Refresh" @click="handleRefresh">
          刷新
        </el-button>
        <el-switch
          v-model="autoRefresh"
          active-text="自动刷新"
          inactive-text="手动刷新"
          @change="handleAutoRefreshChange"
        />
      </div>
    </div>

    <!-- ETL任务日志表格 -->
    <el-table
      v-loading="adminStore.isLoading"
      :data="adminStore.etlJobs"
      stripe
      border
      style="width: 100%"
      :empty-text="emptyText"
    >
      <el-table-column prop="id" label="ID" width="80" align="center" />
      
      <el-table-column prop="job_type" label="任务类型" width="140" align="center">
        <template #default="{ row }">
          <el-tag :type="getJobTypeTag(row.job_type)">
            {{ getJobTypeLabel(row.job_type) }}
          </el-tag>
        </template>
      </el-table-column>
      
      <el-table-column prop="status" label="状态" width="120" align="center">
        <template #default="{ row }">
          <el-tag :type="getStatusTag(row.status)">
            {{ getStatusLabel(row.status) }}
          </el-tag>
        </template>
      </el-table-column>
      
      <el-table-column prop="total_records" label="总记录数" width="120" align="center">
        <template #default="{ row }">
          {{ formatNumber(row.total_records) }}
        </template>
      </el-table-column>
      
      <el-table-column prop="processed_records" label="已处理" width="120" align="center">
        <template #default="{ row }">
          {{ formatNumber(row.processed_records) }}
        </template>
      </el-table-column>
      
      <el-table-column prop="failed_records" label="失败记录" width="120" align="center">
        <template #default="{ row }">
          <span :class="{ 'text-danger': row.failed_records > 0 }">
            {{ formatNumber(row.failed_records) }}
          </span>
        </template>
      </el-table-column>
      
      <el-table-column prop="success_rate" label="成功率" width="100" align="center">
        <template #default="{ row }">
          <el-progress
            :percentage="row.success_rate || 0"
            :color="getProgressColor(row.success_rate)"
            :stroke-width="12"
          />
        </template>
      </el-table-column>
      
      <el-table-column prop="duration_seconds" label="执行时长" width="120" align="center">
        <template #default="{ row }">
          {{ formatDuration(row.duration_seconds) }}
        </template>
      </el-table-column>
      
      <el-table-column prop="started_at" label="开始时间" width="180" align="center">
        <template #default="{ row }">
          {{ formatDateTime(row.started_at) }}
        </template>
      </el-table-column>
      
      <el-table-column label="操作" width="120" align="center" fixed="right">
        <template #default="{ row }">
          <el-button
            link
            type="primary"
            size="small"
            @click="handleViewDetail(row)"
            :disabled="!row.error_message"
          >
            查看详情
          </el-button>
        </template>
      </el-table-column>
    </el-table>

    <!-- 分页 -->
    <div class="pagination-container">
      <el-pagination
        v-model:current-page="currentPage"
        v-model:page-size="pageSize"
        :page-sizes="[10, 20, 50, 100]"
        :total="adminStore.etlJobsTotal"
        layout="total, sizes, prev, pager, next, jumper"
        @size-change="handleSizeChange"
        @current-change="handlePageChange"
      />
    </div>

    <!-- 错误详情弹窗 -->
    <el-dialog
      v-model="detailDialogVisible"
      title="任务错误详情"
      width="700px"
    >
      <div v-if="currentJob" class="job-detail">
        <el-descriptions :column="2" border>
          <el-descriptions-item label="任务ID">
            {{ currentJob.id }}
          </el-descriptions-item>
          <el-descriptions-item label="任务类型">
            {{ getJobTypeLabel(currentJob.job_type) }}
          </el-descriptions-item>
          <el-descriptions-item label="状态">
            <el-tag :type="getStatusTag(currentJob.status)">
              {{ getStatusLabel(currentJob.status) }}
            </el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="成功率">
            {{ (currentJob.success_rate || 0).toFixed(1) }}%
          </el-descriptions-item>
          <el-descriptions-item label="开始时间" :span="2">
            {{ formatDateTime(currentJob.started_at) }}
          </el-descriptions-item>
        </el-descriptions>

        <div class="error-message">
          <h4>错误信息：</h4>
          <el-input
            v-model="currentJob.error_message"
            type="textarea"
            :rows="10"
            readonly
          />
        </div>
      </div>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
/**
 * @component ETLMonitor
 * @description ETL监控组件
 * 
 * 功能：
 * - ETL统计信息展示
 * - ETL任务日志列表
 * - 自动刷新功能
 * - 任务错误详情查看
 * 
 * 关联测试点 (Associated Test Points):
 * - [T.1.7] - ETL监控数据展示
 * - [T.2.1] - 空数据状态展示
 */

import { ref, computed, onMounted, onUnmounted } from 'vue'
import { 
  Refresh, 
  Document, 
  DataAnalysis, 
  TrendCharts, 
  Clock 
} from '@element-plus/icons-vue'
import { useAdminStore } from '@/stores/admin'
import type { ETLJobLogInterface, ETLStatisticsInterface } from '@/types/admin'

// Store
const adminStore = useAdminStore()

// 分页参数
const currentPage = ref(1)
const pageSize = ref(20)

// 自动刷新
const autoRefresh = ref(false)
let refreshTimer: number | null = null

// 统计数据
const statistics = computed(() => adminStore.etlStatistics)

// 详情弹窗
const detailDialogVisible = ref(false)
const currentJob = ref<ETLJobLogInterface | null>(null)

// 空数据状态
const emptyText = computed(() => {
  return adminStore.isLoading ? '加载中...' : '暂无数据'
})

// 任务类型标签
const getJobTypeLabel = (type: string) => {
  const labels: Record<string, string> = {
    'full_sync': '全量同步',
    'incremental_sync': '增量同步'
  }
  return labels[type] || type
}

const getJobTypeTag = (type: string) => {
  return type === 'full_sync' ? 'primary' : 'success'
}

// 状态标签
const getStatusLabel = (status: string) => {
  const labels: Record<string, string> = {
    'running': '运行中',
    'completed': '已完成',
    'failed': '失败'
  }
  return labels[status] || status
}

const getStatusTag = (status: string) => {
  const tags: Record<string, any> = {
    'running': 'warning',
    'completed': 'success',
    'failed': 'danger'
  }
  return tags[status] || 'info'
}

// 进度条颜色
const getProgressColor = (rate?: number) => {
  if (!rate) return '#f56c6c'
  if (rate >= 95) return '#67c23a'
  if (rate >= 80) return '#e6a23c'
  return '#f56c6c'
}

// 格式化数字
const formatNumber = (num?: number) => {
  if (num === undefined || num === null) return '-'
  return num.toLocaleString()
}

// 格式化时长
const formatDuration = (seconds?: number) => {
  if (!seconds) return '-'
  if (seconds < 60) return `${seconds}秒`
  const minutes = Math.floor(seconds / 60)
  const remainSeconds = seconds % 60
  return `${minutes}分${remainSeconds}秒`
}

// 格式化日期时间
const formatDateTime = (dateStr?: string) => {
  if (!dateStr) return '-'
  const date = new Date(dateStr)
  return date.toLocaleString('zh-CN', {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit'
  })
}

// 格式化最后同步时间（相对时间）
const formatLastSync = (dateStr?: string) => {
  if (!dateStr) return '从未同步'
  const date = new Date(dateStr)
  const now = new Date()
  const diff = now.getTime() - date.getTime()
  
  const minutes = Math.floor(diff / 60000)
  const hours = Math.floor(minutes / 60)
  const days = Math.floor(hours / 24)
  
  if (days > 0) return `${days}天前`
  if (hours > 0) return `${hours}小时前`
  if (minutes > 0) return `${minutes}分钟前`
  return '刚刚'
}

// 加载ETL数据
const loadETLData = async () => {
  try {
    // 同时加载统计信息和任务日志
    await Promise.all([
      adminStore.loadETLStatistics(),
      adminStore.loadETLJobs({
        page: currentPage.value,
        page_size: pageSize.value
      })
    ])
  } catch (error) {
    // 错误已在store中处理
  }
}

// 刷新
const handleRefresh = () => {
  loadETLData()
}

// 分页改变
const handlePageChange = (page: number) => {
  currentPage.value = page
  adminStore.loadETLJobs({
    page: currentPage.value,
    page_size: pageSize.value
  })
}

const handleSizeChange = (size: number) => {
  pageSize.value = size
  currentPage.value = 1
  adminStore.loadETLJobs({
    page: currentPage.value,
    page_size: pageSize.value
  })
}

// 自动刷新
const handleAutoRefreshChange = (value: boolean) => {
  if (value) {
    // 启动自动刷新（每30秒刷新一次）
    refreshTimer = window.setInterval(() => {
      loadETLData()
    }, 30000)
  } else {
    // 停止自动刷新
    if (refreshTimer) {
      clearInterval(refreshTimer)
      refreshTimer = null
    }
  }
}

// 查看详情
const handleViewDetail = (job: ETLJobLogInterface) => {
  currentJob.value = { ...job }
  detailDialogVisible.value = true
}

// 组件挂载时加载数据
onMounted(() => {
  loadETLData()
})

// 组件卸载时清理定时器
onUnmounted(() => {
  if (refreshTimer) {
    clearInterval(refreshTimer)
  }
})
</script>

<style scoped lang="scss">
.etl-monitor {
  .stats-cards {
    margin-bottom: 24px;

    .stat-card {
      display: flex;
      align-items: center;
      gap: 16px;

      .stat-icon {
        width: 60px;
        height: 60px;
        border-radius: 8px;
        display: flex;
        align-items: center;
        justify-content: center;
        color: white;
      }

      .stat-content {
        flex: 1;

        .stat-label {
          font-size: 14px;
          color: #909399;
          margin-bottom: 8px;
        }

        .stat-value {
          font-size: 24px;
          font-weight: 600;
          color: #303133;

          &.stat-time {
            font-size: 16px;
            font-weight: 500;
          }
        }
      }
    }
  }

  .action-bar {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 20px;

    .title {
      h3 {
        margin: 0;
        font-size: 18px;
        font-weight: 600;
        color: #303133;
      }
    }

    .action-buttons {
      display: flex;
      gap: 12px;
      align-items: center;
    }
  }

  .text-danger {
    color: #f56c6c;
    font-weight: 600;
  }

  .pagination-container {
    margin-top: 20px;
    display: flex;
    justify-content: flex-end;
  }

  .job-detail {
    .error-message {
      margin-top: 20px;

      h4 {
        margin-bottom: 12px;
        font-size: 14px;
        font-weight: 600;
        color: #303133;
      }

      :deep(.el-textarea__inner) {
        font-family: 'Courier New', Courier, monospace;
        font-size: 13px;
      }
    }
  }

  :deep(.el-table) {
    font-size: 14px;
  }

  :deep(.el-card__body) {
    padding: 20px;
  }
}
</style>

