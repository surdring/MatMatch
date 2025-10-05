<template>
  <div class="home-container">
    <el-container>
      <el-header height="80px">
        <div class="header-content">
          <div class="logo">
            <el-icon :size="32" color="#409eff"><Grid /></el-icon>
            <span class="logo-text">MatMatch</span>
          </div>
          <el-menu mode="horizontal" :default-active="activeMenu" @select="handleMenuSelect">
            <el-menu-item index="home">首页</el-menu-item>
            <el-menu-item index="search">物料查重</el-menu-item>
            <el-menu-item index="admin">管理后台</el-menu-item>
          </el-menu>
        </div>
      </el-header>

      <el-main>
        <div class="hero-section">
          <h1 class="hero-title">智能物料查重系统</h1>
          <p class="hero-subtitle">基于AI的物料描述标准化与智能匹配</p>
          
          <div class="hero-actions">
            <el-button type="primary" size="large" @click="goToSearch">
              <el-icon><Upload /></el-icon>
              开始查重
            </el-button>
            <el-button size="large" @click="checkHealth">
              <el-icon><Checked /></el-icon>
              系统状态
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
                <h3>智能标准化</h3>
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

        <div class="stats-section">
          <el-row :gutter="20">
            <el-col :xs="12" :sm="6">
              <div class="stat-item">
                <div class="stat-value">168K+</div>
                <div class="stat-label">物料数据</div>
              </div>
            </el-col>
            <el-col :xs="12" :sm="6">
              <div class="stat-item">
                <div class="stat-value">2,523</div>
                <div class="stat-label">物料分类</div>
              </div>
            </el-col>
            <el-col :xs="12" :sm="6">
              <div class="stat-item">
                <div class="stat-value">91.2%</div>
                <div class="stat-label">匹配精度</div>
              </div>
            </el-col>
            <el-col :xs="12" :sm="6">
              <div class="stat-item">
                <div class="stat-value">&lt;500ms</div>
                <div class="stat-label">查询响应</div>
              </div>
            </el-col>
          </el-row>
        </div>
      </el-main>

      <el-footer height="60px">
        <div class="footer-content">
          <p>&copy; 2025 MatMatch - 智能物料查重系统</p>
        </div>
      </el-footer>
    </el-container>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { materialApi } from '@/api'

const router = useRouter()
const activeMenu = ref('home')

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

const checkHealth = async () => {
  try {
    const response = await materialApi.healthCheck()
    ElMessage.success(`系统运行正常 - 数据库: ${response.data.database}`)
  } catch (error) {
    ElMessage.error('系统健康检查失败')
  }
}
</script>

<style scoped lang="scss">
.home-container {
  width: 100%;
  height: 100%;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
}

.el-container {
  height: 100%;
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

.el-main {
  max-width: 1200px;
  margin: 0 auto;
  padding: 60px 20px;
}

.hero-section {
  text-align: center;
  margin-bottom: 80px;
}

.hero-title {
  font-size: 48px;
  font-weight: 700;
  color: #fff;
  margin-bottom: 16px;
  text-shadow: 0 2px 4px rgba(0, 0, 0, 0.2);
}

.hero-subtitle {
  font-size: 20px;
  color: rgba(255, 255, 255, 0.9);
  margin-bottom: 40px;
}

.hero-actions {
  display: flex;
  gap: 16px;
  justify-content: center;
}

.features-section {
  margin-bottom: 60px;
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
