<template>
  <div class="home-container">
    <el-container>
      <el-header height="80px">
        <div class="header-content">
          <div class="logo">
            <el-icon :size="32" color="#409eff"><Grid /></el-icon>
            <span class="logo-text">MatMatch</span>
          </div>
          <div class="nav-buttons">
            <el-button 
              :type="activeMenu === 'home' ? 'primary' : ''"
              text
              @click="handleMenuSelect('home')"
            >
              首页
            </el-button>
            <el-button 
              :type="activeMenu === 'search' ? 'primary' : ''"
              text
              @click="handleMenuSelect('search')"
            >
              物料查重
            </el-button>
            <el-button 
              :type="activeMenu === 'admin' ? 'primary' : ''"
              text
              @click="handleMenuSelect('admin')"
            >
              管理后台
            </el-button>
          </div>
        </div>
      </el-header>

      <el-main>
        <div class="hero-section">
          <h1 class="hero-title">物料查重系统</h1>
          <p class="hero-subtitle">物料描述标准化与相似度匹配</p>
          
          <div class="hero-actions">
            <el-button type="primary" size="large" @click="goToSearch">
              <el-icon><Upload /></el-icon>
              开始查重
            </el-button>
          </div>
        </div>

        <div class="features-section">
          <el-row :gutter="20">
            <el-col :xs="24" :sm="12" :md="8">
              <el-card class="feature-card" shadow="hover">
                <template #header>
                  <el-icon :size="40" color="#409eff"><DataAnalysis /></el-icon>
                </template>
                <h3>自动标准化</h3>
                <p>自动识别物料类别，标准化物料描述，提取关键属性</p>
              </el-card>
            </el-col>

            <el-col :xs="24" :sm="12" :md="8">
              <el-card class="feature-card" shadow="hover">
                <template #header>
                  <el-icon :size="40" color="#67c23a"><Search /></el-icon>
                </template>
                <h3>高精度匹配</h3>
                <p>基于多字段加权相似度算法，准确率超过90%</p>
              </el-card>
            </el-col>

            <el-col :xs="24" :sm="12" :md="8">
              <el-card class="feature-card" shadow="hover">
                <template #header>
                  <el-icon :size="40" color="#e6a23c"><Timer /></el-icon>
                </template>
                <h3>批量处理</h3>
                <p>支持Excel文件批量上传，100条记录30秒内完成</p>
              </el-card>
            </el-col>
          </el-row>
        </div>

        <div class="stats-section" v-loading="statsLoading">
          <el-row :gutter="20">
            <el-col :xs="12" :sm="6">
              <div class="stat-item">
                <div class="stat-value">{{ formatNumber(stats.totalMaterials) }}</div>
                <div class="stat-label">物料数据</div>
              </div>
            </el-col>
            <el-col :xs="12" :sm="6">
              <div class="stat-item">
                <div class="stat-value">{{ formatNumber(stats.totalCategories) }}</div>
                <div class="stat-label">物料分类</div>
              </div>
            </el-col>
            <el-col :xs="12" :sm="6">
              <div class="stat-item">
                <div class="stat-value">{{ formatNumber(stats.totalSynonyms) }}</div>
                <div class="stat-label">同义词库</div>
              </div>
            </el-col>
            <el-col :xs="12" :sm="6">
              <div class="stat-item">
                <div class="stat-value">{{ stats.totalRules }}</div>
                <div class="stat-label">提取规则</div>
              </div>
            </el-col>
          </el-row>
        </div>
      </el-main>

      <el-footer height="60px">
        <div class="footer-content">
          <p>&copy; 2025 MatMatch - 物料查重系统</p>
        </div>
      </el-footer>
    </el-container>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import http from '@/api/request'

const router = useRouter()
const activeMenu = ref('home')

// 统计数据
const statsLoading = ref(false)
const stats = ref({
  totalMaterials: 0,
  totalCategories: 0,
  totalSynonyms: 0,
  totalRules: 0
})

// 格式化数字显示
const formatNumber = (num: number): string => {
  if (num >= 10000) {
    return `${(num / 10000).toFixed(1)}万`
  }
  return num.toLocaleString()
}

// 获取统计数据
const fetchStats = async () => {
  statsLoading.value = true
  try {
    const response = await http.get('/api/v1/materials/stats')
    stats.value = {
      totalMaterials: response.data.total_materials || 0,
      totalCategories: response.data.total_categories || 0,
      totalSynonyms: response.data.total_synonyms || 0,
      totalRules: response.data.total_rules || 0
    }
  } catch (error: any) {
    console.error('获取统计信息失败:', error)
    ElMessage.warning('获取统计信息失败，显示默认数据')
  } finally {
    statsLoading.value = false
  }
}

const handleMenuSelect = (index: string) => {
  activeMenu.value = index
  if (index === 'search') {
    router.push('/search')
  } else if (index === 'admin') {
    router.push('/admin')
  }
}

const goToSearch = () => {
  router.push('/search')
}

// 页面加载时获取统计数据
onMounted(() => {
  fetchStats()
})
</script>

<style scoped lang="scss">
.home-container {
  width: 100%;
  min-height: 100vh;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  overflow-x: hidden;
}

.el-container {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
}

.el-header {
  background: rgba(255, 255, 255, 0.95);
  backdrop-filter: blur(10px);
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
}

.header-content {
  display: flex;
  align-items: center;
  justify-content: space-between;
  height: 100%;
  max-width: 1200px;
  margin: 0 auto;
  padding: 0 20px;
}

.logo {
  display: flex;
  align-items: center;
  gap: 12px;
  font-size: 24px;
  font-weight: 600;
  color: #409eff;
}

.nav-buttons {
  display: flex;
  align-items: center;
  gap: 8px;

  .el-button {
    font-size: 16px;
    font-weight: 500;
  }
}

.el-main {
  flex: 1;
  max-width: 1200px;
  margin: 0 auto;
  padding: 40px 20px;
  width: 100%;
  overflow-y: auto;
}

.hero-section {
  text-align: center;
  margin-bottom: 50px;
}

.hero-title {
  font-size: 42px;
  font-weight: 700;
  color: #fff;
  margin-bottom: 12px;
  text-shadow: 0 2px 4px rgba(0, 0, 0, 0.2);
}

.hero-subtitle {
  font-size: 18px;
  color: rgba(255, 255, 255, 0.9);
  margin-bottom: 30px;
}

.hero-actions {
  display: flex;
  gap: 16px;
  justify-content: center;
}

.features-section {
  margin-bottom: 40px;
}

.feature-card {
  text-align: center;
  margin-bottom: 20px;
  
  :deep(.el-card__header) {
    padding: 30px 20px 10px;
  }
  
  h3 {
    font-size: 20px;
    font-weight: 600;
    margin-bottom: 12px;
    color: #303133;
  }
  
  p {
    color: #606266;
    line-height: 1.6;
  }
}

.stats-section {
  background: rgba(255, 255, 255, 0.95);
  border-radius: 12px;
  padding: 40px 20px;
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.1);
}

.stat-item {
  text-align: center;
  
  .stat-value {
    font-size: 36px;
    font-weight: 700;
    color: #409eff;
    margin-bottom: 8px;
  }
  
  .stat-label {
    font-size: 14px;
    color: #909399;
  }
}

.el-footer {
  background: rgba(255, 255, 255, 0.95);
  backdrop-filter: blur(10px);
  flex-shrink: 0;
}

.footer-content {
  display: flex;
  align-items: center;
  justify-content: center;
  height: 100%;
  color: #909399;
  font-size: 14px;
}
</style>
