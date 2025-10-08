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
          <el-row :gutter="24" class="stats-row" justify="space-between">
            <!-- 统计项1: 物料数据 -->
            <el-col :span="4" class="stat-col">
              <el-tooltip effect="dark" placement="top">
                <template #content>
                  <div style="max-width: 280px; line-height: 1.6;">
                    <div style="font-weight: bold; margin-bottom: 6px;">ERP系统中的物料总数</div>
                    <div style="font-size: 13px; margin-bottom: 6px;">
                      包含已启用和已停用的物料
                    </div>
                    <div style="font-size: 12px; color: #e6a23c; border-top: 1px solid rgba(255,255,255,0.2); padding-top: 6px;">
                      💡 <strong>为什么包含停用物料？</strong><br>
                      停用物料仍可能在历史订单、库存记录中出现，<br>
                      查重时需要检测是否与停用物料重复，避免<br>
                      "换个名字重建已停用物料"的数据冗余问题。
                    </div>
                  </div>
                </template>
                <div class="stat-item">
                  <div class="stat-value">{{ formatNumber(stats.totalMaterials) }}</div>
                  <div class="stat-label">物料数据</div>
                </div>
              </el-tooltip>
            </el-col>

            <!-- 统计项2: 物料分类 -->
            <el-col :span="4" class="stat-col">
              <el-tooltip 
                effect="dark" 
                content="系统支持的物料分类数量，用于自动识别物料类别" 
                placement="top"
              >
                <div class="stat-item">
                  <div class="stat-value">{{ formatNumber(stats.totalCategories) }}</div>
                  <div class="stat-label">物料分类</div>
                </div>
              </el-tooltip>
            </el-col>

            <!-- 统计项3: 清洗规则 -->
            <el-col :span="4" class="stat-col">
              <el-tooltip 
                effect="dark" 
                placement="top"
                popper-class="cleaning-rules-tooltip"
              >
                <template #content>
                  <div style="max-width: 350px; line-height: 1.6;">
                    <div style="font-weight: bold; margin-bottom: 8px;">文本标准化清洗规则（13条）：</div>
                    <div style="font-size: 13px;">
                      • 希腊字母标准化（φ/Φ → phi/PHI）<br>
                      • 全角符号转半角（（）：→ ():）<br>
                      • 数学符号标准化（≥≤℃ → &gt;=/&lt;=C）<br>
                      • 去除所有空格（提升匹配精度）<br>
                      • 乘号类统一（*×· → _）<br>
                      • 数字间x/X处理（200x100 → 200_100）<br>
                      • 斜杠类统一（/／\ → _）<br>
                      • 逗号类统一（,，、 → _）<br>
                      • 换行符处理（\n → _）<br>
                      • 连字符智能处理（保留数字范围）<br>
                      • 统一转小写（M8X20 → m8_20）<br>
                      • 小数点.0优化（3.0 → 3）<br>
                      • 清理连续下划线及首尾下划线
                    </div>
                  </div>
                </template>
                <div class="stat-item">
                  <div class="stat-value">13</div>
                  <div class="stat-label">清洗规则</div>
                </div>
              </el-tooltip>
            </el-col>

            <!-- 统计项4: 同义词库 -->
            <el-col :span="4" class="stat-col">
              <el-tooltip 
                effect="dark" 
                content="同义词词典规模，用于物料描述的标准化处理" 
                placement="top"
              >
                <div class="stat-item">
                  <div class="stat-value">{{ formatNumber(stats.totalSynonyms) }}</div>
                  <div class="stat-label">同义词库</div>
                </div>
              </el-tooltip>
            </el-col>

            <!-- 统计项5: 提取规则 -->
            <el-col :span="4" class="stat-col">
              <el-tooltip 
                effect="dark" 
                content="属性提取规则数量，用于从物料描述中自动提取关键属性" 
                placement="top"
              >
                <div class="stat-item">
                  <div class="stat-value">{{ stats.totalRules }}</div>
                  <div class="stat-label">提取规则</div>
                </div>
              </el-tooltip>
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
  padding: 40px 30px;
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.1);
}

.stats-row {
  display: flex;
  align-items: center;
}

.stat-col {
  display: flex;
  justify-content: center;
}

.stat-item {
  text-align: center;
  padding: 20px 10px;
  cursor: pointer;
  transition: all 0.3s ease;
  border-radius: 8px;
  width: 100%;
  
  &:hover {
    background: rgba(64, 158, 255, 0.05);
    transform: translateY(-2px);
  }
  
  .stat-value {
    font-size: 38px;
    font-weight: 700;
    color: #409eff;
    margin-bottom: 8px;
    line-height: 1.2;
  }
  
  .stat-label {
    font-size: 15px;
    color: #606266;
    font-weight: 500;
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
