<template>
  <div class="admin-container">
    <!-- 页面头部 -->
    <div class="admin-header">
      <h2>管理后台</h2>
      <div class="admin-actions">
        <el-button 
          :icon="Refresh" 
          @click="handleRefreshCache"
          :loading="adminStore.isSubmitting"
        >
          刷新缓存
        </el-button>
        <el-button 
          type="danger" 
          @click="handleLogout"
        >
          退出登录
        </el-button>
      </div>
    </div>

    <!-- Tab导航 -->
    <el-tabs v-model="activeTab" class="admin-tabs">
      <!-- 规则管理 -->
      <el-tab-pane label="规则管理" name="rules">
        <RuleManager v-show="activeTab === 'rules'" />
      </el-tab-pane>

      <!-- 同义词管理 -->
      <el-tab-pane label="同义词管理" name="synonyms">
        <SynonymManager v-show="activeTab === 'synonyms'" />
      </el-tab-pane>

      <!-- 分类管理 -->
      <el-tab-pane label="分类管理" name="categories">
        <CategoryManager v-show="activeTab === 'categories'" />
      </el-tab-pane>

      <!-- ETL监控 -->
      <el-tab-pane label="ETL监控" name="etl">
        <ETLMonitor v-show="activeTab === 'etl'" />
      </el-tab-pane>
    </el-tabs>
  </div>
</template>

<script setup lang="ts">
/**
 * @component Admin
 * @description 管理后台主页面
 * 
 * 功能：
 * - 提供Tab导航，切换不同管理模块
 * - 刷新知识库缓存
 * 
 * 关联测试点 (Associated Test Points):
 * - [T.1.1] - 规则列表加载和分页
 * - [T.1.5] - 同义词CRUD完整流程
 * - [T.1.6] - 分类管理CRUD完整流程
 * - [T.1.7] - ETL监控数据展示
 */

import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { Refresh } from '@element-plus/icons-vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { useAdminStore } from '@/stores/admin'
import { useAuthStore } from '@/stores/auth'
import RuleManager from '@/components/Admin/RuleManager.vue'
import SynonymManager from '@/components/Admin/SynonymManager.vue'
import CategoryManager from '@/components/Admin/CategoryManager.vue'
import ETLMonitor from '@/components/Admin/ETLMonitor.vue'

// Store
const adminStore = useAdminStore()
const authStore = useAuthStore()
const router = useRouter()

// 当前激活的Tab
const activeTab = ref('rules')

// 刷新缓存
const handleRefreshCache = async () => {
  try {
    await adminStore.refreshCache()
    ElMessage.success('缓存刷新成功，规则和词典已更新')
  } catch (error) {
    // 错误已在store中处理
  }
}

// 登出
const handleLogout = async () => {
  try {
    await ElMessageBox.confirm(
      '确定要退出登录吗？',
      '提示',
      {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }
    )
    
    authStore.logout()
    ElMessage.success('已退出登录')
    router.push('/admin/login')
    console.log('[登出] 已清除登录状态')
  } catch {
    // 用户取消
  }
}
</script>

<style scoped lang="scss">
.admin-container {
  padding: 20px;
  background-color: #f5f7fa;
  min-height: calc(100vh - 60px);
}

.admin-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
  padding: 20px;
  background: white;
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);

  h2 {
    margin: 0;
    font-size: 24px;
    font-weight: 600;
    color: #303133;
  }

  .admin-actions {
    display: flex;
    gap: 12px;
  }
}

.admin-tabs {
  background: white;
  padding: 20px;
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);

  :deep(.el-tabs__header) {
    margin-bottom: 20px;
  }

  :deep(.el-tabs__item) {
    font-size: 16px;
    padding: 0 30px;
    height: 50px;
    line-height: 50px;
  }

  :deep(.el-tabs__content) {
    padding: 0;
  }
}
</style>

