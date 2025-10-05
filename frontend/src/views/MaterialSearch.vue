<template>
  <div class="material-search-container">
    <div class="page-header">
      <h1>物料批量查重</h1>
      <p>上传Excel文件，自动识别并查找相似物料</p>
    </div>

    <el-card class="upload-card">
      <template #header>
        <div class="card-header">
          <span>文件上传</span>
          <el-button v-if="hasResults" text @click="clearResults">
            <el-icon><RefreshLeft /></el-icon>
            重新上传
          </el-button>
        </div>
      </template>

      <div v-if="!hasResults" class="upload-section">
        <el-upload
          ref="uploadRef"
          class="upload-demo"
          drag
          :auto-upload="false"
          :accept="'.xlsx,.xls'"
          :limit="1"
          :on-change="handleFileChange"
          :on-exceed="handleExceed"
        >
          <el-icon class="el-icon--upload"><UploadFilled /></el-icon>
          <div class="el-upload__text">
            将Excel文件拖到此处，或<em>点击上传</em>
          </div>
          <template #tip>
            <div class="el-upload__tip">
              只能上传 xlsx/xls 文件，且不超过 10MB
            </div>
          </template>
        </el-upload>

        <div v-if="selectedFile" class="upload-config">
          <el-form :model="config" label-width="140px">
            <el-form-item label="物料名称列名:">
              <el-input
                v-model="config.materialName"
                placeholder="例如: 物料名称 或 A (留空自动检测)"
              />
            </el-form-item>
            <el-form-item label="规格型号列名:">
              <el-input
                v-model="config.specification"
                placeholder="例如: 规格型号 或 B (留空自动检测)"
              />
            </el-form-item>
            <el-form-item label="单位列名:">
              <el-input
                v-model="config.unitName"
                placeholder="例如: 单位 或 C (留空自动检测)"
              />
            </el-form-item>
            <el-form-item>
              <el-button
                type="primary"
                :loading="isProcessing"
                :disabled="!selectedFile"
                @click="handleUpload"
              >
                <el-icon><Search /></el-icon>
                开始查重
              </el-button>
            </el-form-item>
          </el-form>
        </div>

        <el-progress
          v-if="uploadProgress > 0"
          :percentage="uploadProgress"
          :status="uploadProgress === 100 ? 'success' : undefined"
        />
      </div>

      <div v-else class="results-section">
        <el-alert
          title="查重完成"
          type="success"
          :closable="false"
          show-icon
        >
          <template #default>
            共处理 {{ totalProcessed }} 条记录，
            成功率 {{ successRate }}%，
            耗时 {{ processingTime }}秒
          </template>
        </el-alert>

        <div class="results-list">
          <el-collapse v-model="activeNames">
            <el-collapse-item
              v-for="(result, index) in batchResults?.results"
              :key="index"
              :name="index"
            >
              <template #title>
                <div class="result-title">
                  <el-tag>行 {{ result.row_number }}</el-tag>
                  <span class="material-info">
                    {{ result.input_data.material_name }} {{ result.input_data.specification }}
                  </span>
                  <el-tag v-if="result.matches.length > 0" type="success">
                    找到 {{ result.matches.length }} 个匹配
                  </el-tag>
                  <el-tag v-else type="info">无匹配</el-tag>
                </div>
              </template>

              <div v-if="result.parsed_query" class="parsed-query">
                <h4>解析结果:</h4>
                <el-descriptions :column="2" border>
                  <el-descriptions-item label="标准化名称">
                    {{ result.parsed_query.normalized_name }}
                  </el-descriptions-item>
                  <el-descriptions-item label="检测分类">
                    {{ result.parsed_query.detected_category || '未检测到' }}
                  </el-descriptions-item>
                  <el-descriptions-item label="提取属性" :span="2">
                    <el-tag
                      v-for="(value, key) in result.parsed_query.extracted_attributes"
                      :key="key"
                      class="attr-tag"
                    >
                      {{ key }}: {{ value }}
                    </el-tag>
                  </el-descriptions-item>
                </el-descriptions>
              </div>

              <div v-if="result.matches.length > 0" class="matches-list">
                <h4>匹配物料:</h4>
                <el-table :data="result.matches" stripe>
                  <el-table-column prop="erp_code" label="ERP编码" width="120" />
                  <el-table-column prop="material_name" label="物料名称" />
                  <el-table-column prop="specification" label="规格型号" />
                  <el-table-column prop="unit_name" label="单位" width="80" />
                  <el-table-column prop="similarity_score" label="相似度" width="100">
                    <template #default="{ row }">
                      <el-progress
                        :percentage="Math.round(row.similarity_score * 100)"
                        :color="getScoreColor(row.similarity_score)"
                      />
                    </template>
                  </el-table-column>
                </el-table>
              </div>
              <el-empty v-else description="未找到匹配的物料" />
            </el-collapse-item>
          </el-collapse>
        </div>
      </div>
    </el-card>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { ElMessage } from 'element-plus'
import type { UploadFile, UploadInstance } from 'element-plus'
import { useMaterialStore } from '@/stores'

const materialStore = useMaterialStore()

const uploadRef = ref<UploadInstance>()
const selectedFile = ref<File | null>(null)
const activeNames = ref<number[]>([])

const config = ref({
  materialName: '',
  specification: '',
  unitName: ''
})

const isProcessing = computed(() => materialStore.isProcessing)
const uploadProgress = computed(() => materialStore.uploadProgress)
const hasResults = computed(() => materialStore.hasResults)
const batchResults = computed(() => materialStore.batchResults)
const totalProcessed = computed(() => materialStore.totalProcessed)
const successRate = computed(() => materialStore.successRate)

const processingTime = computed(() => {
  if (batchResults.value) {
    return (batchResults.value.processing_time / 1000).toFixed(2)
  }
  return 0
})

const handleFileChange = (file: UploadFile) => {
  if (file.raw) {
    // 验证文件大小
    const maxSize = 10 * 1024 * 1024 // 10MB
    if (file.raw.size > maxSize) {
      ElMessage.error('文件大小不能超过 10MB')
      return
    }
    selectedFile.value = file.raw
  }
}

const handleExceed = () => {
  ElMessage.warning('只能上传一个文件')
}

const handleUpload = async () => {
  if (!selectedFile.value) {
    ElMessage.warning('请先选择文件')
    return
  }

  try {
    await materialStore.uploadAndSearch(selectedFile.value, {
      material_name: config.value.materialName || undefined,
      specification: config.value.specification || undefined,
      unit_name: config.value.unitName || undefined
    })

    ElMessage.success('查重完成')
    // 默认展开前3个结果
    activeNames.value = [0, 1, 2]
  } catch (error: any) {
    console.error('查重失败:', error)
  }
}

const clearResults = () => {
  materialStore.clearResults()
  selectedFile.value = null
  config.value = {
    materialName: '',
    specification: '',
    unitName: ''
  }
  uploadRef.value?.clearFiles()
}

const getScoreColor = (score: number) => {
  if (score >= 0.9) return '#67c23a'
  if (score >= 0.7) return '#e6a23c'
  return '#f56c6c'
}
</script>

<style scoped lang="scss">
.material-search-container {
  padding: 20px;
  max-width: 1400px;
  margin: 0 auto;
}

.page-header {
  margin-bottom: 20px;

  h1 {
    font-size: 24px;
    font-weight: 600;
    color: #303133;
    margin-bottom: 8px;
  }

  p {
    color: #909399;
  }
}

.upload-card {
  .card-header {
    display: flex;
    align-items: center;
    justify-content: space-between;
  }
}

.upload-section {
  .upload-demo {
    margin-bottom: 20px;
  }

  .upload-config {
    margin-top: 30px;
    padding: 20px;
    background: #f5f7fa;
    border-radius: 8px;
  }
}

.results-section {
  .el-alert {
    margin-bottom: 20px;
  }

  .results-list {
    margin-top: 20px;
  }

  .result-title {
    display: flex;
    align-items: center;
    gap: 12px;
    flex: 1;

    .material-info {
      flex: 1;
      font-weight: 500;
    }
  }

  .parsed-query {
    margin-bottom: 20px;
    padding: 16px;
    background: #f5f7fa;
    border-radius: 8px;

    h4 {
      margin-bottom: 12px;
      color: #606266;
    }

    .attr-tag {
      margin-right: 8px;
      margin-bottom: 8px;
    }
  }

  .matches-list {
    h4 {
      margin-bottom: 12px;
      color: #606266;
    }
  }
}
</style>
