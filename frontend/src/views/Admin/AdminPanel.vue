<template>
  <div class="admin-panel-container">
    <!-- 顶部导航栏 -->
    <div class="admin-header">
      <div class="header-left">
        <h1>管理后台</h1>
        <el-tag :type="healthStatusType" size="large">
          {{ healthStatusText }}
        </el-tag>
      </div>
      <div class="header-right">
        <el-button type="danger" @click="handleLogout">
          <el-icon><SwitchButton /></el-icon>
          退出登录
        </el-button>
      </div>
    </div>

    <el-tabs v-model="activeTab" class="admin-tabs">
      <!-- 系统监控 -->
      <el-tab-pane label="系统监控" name="monitor">
        <div class="monitor-section">
          <el-row :gutter="20">
            <!-- 健康状态卡片 -->
            <el-col :xs="24" :sm="12" :md="8">
              <el-card class="status-card" shadow="hover">
                <template #header>
                  <div class="card-header">
                    <el-icon :size="24" :color="healthData?.status === 'healthy' ? '#67c23a' : '#e6a23c'">
                      <CircleCheck v-if="healthData?.status === 'healthy'" />
                      <Warning v-else />
                    </el-icon>
                    <span>系统状态</span>
                  </div>
                </template>
                <div class="card-content">
                  <div class="status-value" :class="healthData?.status">
                    {{ healthStatusText }}
                  </div>
                  <div class="status-detail">
                    <p>数据库: {{ healthData?.database || '未知' }}</p>
                    <p>知识库: {{ healthData?.knowledge_base || '未知' }}</p>
                  </div>
                  <el-button type="primary" size="small" @click="refreshHealth" :loading="loadingHealth">
                    刷新状态
                  </el-button>
                </div>
              </el-card>
            </el-col>

            <!-- 就绪状态卡片 -->
            <el-col :xs="24" :sm="12" :md="8">
              <el-card class="status-card" shadow="hover">
                <template #header>
                  <div class="card-header">
                    <el-icon :size="24" :color="readinessData?.ready ? '#67c23a' : '#f56c6c'">
                      <Select v-if="readinessData?.ready" />
                      <Close v-else />
                    </el-icon>
                    <span>就绪状态</span>
                  </div>
                </template>
                <div class="card-content">
                  <div class="status-value" :class="readinessData?.ready ? 'ready' : 'not-ready'">
                    {{ readinessData?.ready ? '已就绪' : '未就绪' }}
                  </div>
                  <div class="status-detail">
                    <p>数据库: {{ readinessData?.checks?.database || '未知' }}</p>
                    <p>处理器: {{ readinessData?.checks?.material_processor || '未知' }}</p>
                    <p>知识库: {{ readinessData?.checks?.knowledge_base || '未知' }}</p>
                  </div>
                </div>
              </el-card>
            </el-col>

            <!-- 系统信息卡片 -->
            <el-col :xs="24" :sm="12" :md="8">
              <el-card class="status-card" shadow="hover">
                <template #header>
                  <div class="card-header">
                    <el-icon :size="24" color="#409eff"><InfoFilled /></el-icon>
                    <span>系统信息</span>
                  </div>
                </template>
                <div class="card-content">
                  <div class="status-detail">
                    <p>API版本: {{ healthData?.version || '未知' }}</p>
                    <p>最后检查: {{ formattedTimestamp }}</p>
                    <p>自动刷新: {{ autoRefresh ? '开启' : '关闭' }}</p>
                  </div>
                  <el-switch
                    v-model="autoRefresh"
                    active-text="自动刷新"
                    @change="toggleAutoRefresh"
                  />
                </div>
              </el-card>
            </el-col>
          </el-row>

          <!-- 详细状态表格 -->
          <el-card class="details-card" shadow="hover">
            <template #header>
              <h3>详细状态</h3>
            </template>
            <el-table :data="detailsTableData" style="width: 100%">
              <el-table-column prop="component" label="组件" width="200" />
              <el-table-column prop="status" label="状态" width="150">
                <template #default="{ row }">
                  <el-tag :type="getStatusType(row.status)">
                    {{ row.status }}
                  </el-tag>
                </template>
              </el-table-column>
              <el-table-column prop="description" label="说明" />
            </el-table>
          </el-card>
        </div>
      </el-tab-pane>

      <!-- 规则管理 -->
      <el-tab-pane label="提取规则" name="rules">
        <el-empty description="提取规则管理功能开发中" />
      </el-tab-pane>

      <!-- 同义词管理 -->
      <el-tab-pane label="同义词词典" name="synonyms">
        <el-empty description="同义词管理功能开发中" />
      </el-tab-pane>

      <!-- 物料分类管理 -->
      <el-tab-pane label="物料分类" name="categories">
        <el-empty description="物料分类管理功能开发中" />
      </el-tab-pane>

      <!-- ETL监控 -->
      <el-tab-pane label="ETL监控" name="etl">
        <el-empty description="ETL监控功能开发中" />
      </el-tab-pane>
    </el-tabs>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import { systemApi, type SystemHealth, type SystemReadiness } from '@/api'
import { useAuthStore } from '@/stores/auth'

const router = useRouter()
const authStore = useAuthStore()

// 当前tab
const activeTab = ref('monitor')

// 健康状态数据
const healthData = ref<SystemHealth | null>(null)
const readinessData = ref<SystemReadiness | null>(null)
const loadingHealth = ref(false)

// 自动刷新
const autoRefresh = ref(true)
let refreshTimer: number | null = null

// 计算属性

const healthStatusText = computed(() => {
  if (!healthData.value) return '加载中...'
  const statusMap = {
    healthy: '正常',
    degraded: '降级',
    unhealthy: '异常'
  }
  return statusMap[healthData.value.status] || '未知'
})

const healthStatusType = computed(() => {
  if (!healthData.value) return 'info'
  const typeMap = {
    healthy: 'success',
    degraded: 'warning',
    unhealthy: 'danger'
  }
  return typeMap[healthData.value.status] || 'info'
})

const formattedTimestamp = computed(() => {
  if (!healthData.value?.timestamp) return '-'
  return new Date(healthData.value.timestamp).toLocaleString('zh-CN')
})

const detailsTableData = computed(() => {
  if (!readinessData.value) return []
  
  return [
    {
      component: '数据库连接',
      status: readinessData.value.checks.database,
      description: 'PostgreSQL数据库连接状态'
    },
    {
      component: '物料处理器',
      status: readinessData.value.checks.material_processor,
      description: 'UniversalMaterialProcessor初始化状态'
    },
    {
      component: '知识库',
      status: readinessData.value.checks.knowledge_base,
      description: '同义词、规则、分类知识库加载状态'
    }
  ]
})

// 方法

/**
 * 获取状态类型（用于表格标签颜色）
 */
const getStatusType = (status: string): string => {
  if (status === 'ok') return 'success'
  if (status === 'not_initialized' || status === 'not_loaded') return 'warning'
  if (status === 'error') return 'danger'
  return 'info'
}

/**
 * 刷新健康状态
 */
const refreshHealth = async () => {
  loadingHealth.value = true
  try {
    const [healthRes, readinessRes] = await Promise.all([
      systemApi.getHealth(),
      systemApi.getReadiness()
    ])
    
    healthData.value = healthRes.data
    readinessData.value = readinessRes.data
    
    if (healthData.value.status !== 'healthy') {
      ElMessage.warning(`系统状态: ${healthStatusText.value}`)
    }
  } catch (error) {
    ElMessage.error('获取系统状态失败')
    console.error('Health check error:', error)
  } finally {
    loadingHealth.value = false
  }
}

/**
 * 切换自动刷新
 */
const toggleAutoRefresh = () => {
  if (autoRefresh.value) {
    startAutoRefresh()
  } else {
    stopAutoRefresh()
  }
}

/**
 * 开始自动刷新
 */
const startAutoRefresh = () => {
  if (refreshTimer) return
  
  refreshTimer = window.setInterval(() => {
    refreshHealth()
  }, 30000) // 每30秒刷新一次
}

/**
 * 停止自动刷新
 */
const stopAutoRefresh = () => {
  if (refreshTimer) {
    clearInterval(refreshTimer)
    refreshTimer = null
  }
}

/**
 * 退出登录
 */
const handleLogout = async () => {
  try {
    await ElMessageBox.confirm(
      '确定要退出管理后台吗？',
      '退出确认',
      {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }
    )
    
    authStore.logout()
    ElMessage.success('已退出登录')
    router.push('/admin/login')
  } catch {
    // 取消退出
  }
}

// 生命周期

onMounted(() => {
  // 初始加载
  refreshHealth()
  
  // 开始自动刷新
  if (autoRefresh.value) {
    startAutoRefresh()
  }
})

onUnmounted(() => {
  // 清理定时器
  stopAutoRefresh()
})
</script>

<style scoped lang="scss">
.admin-panel-container {
  min-height: 100vh;
  background: #f0f2f5;
}

.admin-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 20px 30px;
  background: #fff;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
  margin-bottom: 20px;

  .header-left {
    display: flex;
    align-items: center;
    gap: 16px;

    h1 {
      margin: 0;
      font-size: 24px;
      font-weight: 600;
      color: #303133;
    }
  }
}

.admin-tabs {
  padding: 0 30px 30px;

  :deep(.el-tabs__header) {
    background: #fff;
    padding: 0 20px;
    margin-bottom: 20px;
  }
}

.monitor-section {
  .el-row {
    margin-bottom: 20px;
  }
}

.status-card {
  margin-bottom: 20px;

  .card-header {
    display: flex;
    align-items: center;
    gap: 10px;
    font-size: 16px;
    font-weight: 600;
  }

  .card-content {
    .status-value {
      font-size: 32px;
      font-weight: 700;
      margin-bottom: 16px;

      &.healthy, &.ready {
        color: #67c23a;
      }

      &.degraded {
        color: #e6a23c;
      }

      &.unhealthy, &.not-ready {
        color: #f56c6c;
      }
    }

    .status-detail {
      margin-bottom: 16px;

      p {
        margin: 8px 0;
        color: #606266;
        font-size: 14px;
      }
    }
  }
}

.details-card {
  h3 {
    margin: 0;
    font-size: 16px;
    font-weight: 600;
  }
}
</style>
