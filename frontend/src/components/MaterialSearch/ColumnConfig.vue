<template>
  <div class="column-config-container">
    <el-card shadow="hover">
      <template #header>
        <div class="card-header">
          <span>列名配置</span>
          <el-button text type="primary" @click="autoDetect">
            <el-icon><MagicStick /></el-icon>
            自动检测
          </el-button>
        </div>
      </template>

      <el-form :model="config" label-width="140px" :rules="rules" ref="formRef">
        <!-- 物料名称列 -->
        <el-form-item label="物料名称列:" prop="materialName" required>
          <el-select
            v-model="config.materialName"
            placeholder="请选择或输入列名"
            filterable
            allow-create
            style="width: 100%"
          >
            <el-option
              v-for="col in availableColumns"
              :key="col"
              :label="col"
              :value="col"
            >
              <span>{{ col }}</span>
              <el-tag
                v-if="detectionHints.materialName === col"
                type="success"
                size="small"
                style="margin-left: 8px"
              >
                推荐
              </el-tag>
            </el-option>
          </el-select>
          <div class="field-hint">
            <el-icon><InfoFilled /></el-icon>
            必填项 - 物料的主要名称，如"304不锈钢板"
          </div>
        </el-form-item>

        <!-- 规格型号列 -->
        <el-form-item label="规格型号列:" prop="specification">
          <el-select
            v-model="config.specification"
            placeholder="请选择或输入列名（可选）"
            filterable
            allow-create
            clearable
            style="width: 100%"
          >
            <el-option
              v-for="col in availableColumns"
              :key="col"
              :label="col"
              :value="col"
            >
              <span>{{ col }}</span>
              <el-tag
                v-if="detectionHints.specification === col"
                type="success"
                size="small"
                style="margin-left: 8px"
              >
                推荐
              </el-tag>
            </el-option>
          </el-select>
          <div class="field-hint">
            <el-icon><InfoFilled /></el-icon>
            可选 - 物料的规格型号，如"1200×600×3mm"
          </div>
        </el-form-item>

        <!-- 单位列 -->
        <el-form-item label="单位列:" prop="unitName">
          <el-select
            v-model="config.unitName"
            placeholder="请选择或输入列名（可选）"
            filterable
            allow-create
            clearable
            style="width: 100%"
          >
            <el-option
              v-for="col in availableColumns"
              :key="col"
              :label="col"
              :value="col"
            >
              <span>{{ col }}</span>
              <el-tag
                v-if="detectionHints.unitName === col"
                type="success"
                size="small"
                style="margin-left: 8px"
              >
                推荐
              </el-tag>
            </el-option>
          </el-select>
          <div class="field-hint">
            <el-icon><InfoFilled /></el-icon>
            可选 - 计量单位，如"个"、"kg"、"米"
          </div>
        </el-form-item>

        <!-- 分类列 -->
        <el-form-item label="分类列:" prop="categoryName">
          <el-select
            v-model="config.categoryName"
            placeholder="请选择或输入列名（可选）"
            filterable
            allow-create
            clearable
            style="width: 100%"
          >
            <el-option
              v-for="col in availableColumns"
              :key="col"
              :label="col"
              :value="col"
            >
              <span>{{ col }}</span>
              <el-tag
                v-if="detectionHints.categoryName === col"
                type="success"
                size="small"
                style="margin-left: 8px"
              >
                推荐
              </el-tag>
            </el-option>
          </el-select>
          <div class="field-hint">
            <el-icon><InfoFilled /></el-icon>
            可选 - 物料分类，如"金属材料"、"电子元件"
          </div>
        </el-form-item>

        <!-- 预览配置结果 -->
        <el-divider />
        <div v-if="showPreview" class="config-preview">
          <h4>配置预览</h4>
          <el-table :data="previewData" border size="small" max-height="200">
            <el-table-column label="原始列名" prop="original" min-width="120" />
            <el-table-column label="映射到" prop="mapped" min-width="120">
              <template #default="{ row }">
                <el-tag :type="row.type" size="small">{{ row.mapped }}</el-tag>
              </template>
            </el-table-column>
            <el-table-column label="示例数据" prop="sample" min-width="150" show-overflow-tooltip />
          </el-table>
        </div>
      </el-form>
    </el-card>
  </div>
</template>

<script setup lang="ts">
/**
 * @component ColumnConfig
 * @description 列名配置组件 - 自动列名检测和手动配置
 * 
 * 关联测试点:
 * - [T.2.1] 列名检测准确率
 * - [T.2.2] 列名配置交互
 * - [T.2.3] 配置验证
 * 
 * @props availableColumns - 可用的列名列表
 * @props sampleData - 示例数据（用于预览）
 * @emits (config-changed) - 配置变更
 */

import { ref, computed, watch } from 'vue'
import type { FormInstance, FormRules } from 'element-plus'
import { ElMessage } from 'element-plus'

export interface ColumnMapping {
  materialName: string
  specification?: string
  unitName?: string
  categoryName?: string
}

interface Props {
  availableColumns: string[]
  sampleData?: any[]
  initialConfig?: Partial<ColumnMapping>
}

const props = withDefaults(defineProps<Props>(), {
  sampleData: () => [],
  initialConfig: () => ({})
})

interface Emits {
  (e: 'config-changed', config: ColumnMapping): void
  (e: 'config-valid', valid: boolean): void
}

const emit = defineEmits<Emits>()

// 状态
const formRef = ref<FormInstance>()
const config = ref<ColumnMapping>({
  materialName: props.initialConfig.materialName || '',
  specification: props.initialConfig.specification || '',
  unitName: props.initialConfig.unitName || '',
  categoryName: props.initialConfig.categoryName || ''
})

const detectionHints = ref<Partial<ColumnMapping>>({})
const showPreview = ref(false)

// 表单验证规则
const rules: FormRules = {
  materialName: [
    { required: true, message: '请选择或输入物料名称列', trigger: 'change' }
  ]
}

// 列名检测规则（关键词匹配）
const DETECTION_RULES = {
  materialName: [
    '物料名称', '名称', '品名', 'material_name', 'name', 
    '物资名称', '商品名称', 'material', '物料'
  ],
  specification: [
    '规格型号', '规格', '型号', 'specification', 'spec',
    '型号规格', 'model', '规格/型号'
  ],
  unitName: [
    '单位', '计量单位', 'unit', 'unit_name', 
    '基本单位', '主单位', '计量'
  ],
  categoryName: [
    '分类', '物料分类', '类别', '类型', 'category', 
    'category_name', '品类', '大类', '物料类别'
  ]
}

// 计算属性
const previewData = computed(() => {
  if (!showPreview.value || props.sampleData.length === 0) return []

  const result: any[] = []
  
  // 物料名称
  if (config.value.materialName) {
    result.push({
      original: config.value.materialName,
      mapped: '物料名称',
      type: 'success',
      sample: props.sampleData[0]?.[config.value.materialName] || '-'
    })
  }

  // 规格型号
  if (config.value.specification) {
    result.push({
      original: config.value.specification,
      mapped: '规格型号',
      type: 'warning',
      sample: props.sampleData[0]?.[config.value.specification] || '-'
    })
  }

  // 单位
  if (config.value.unitName) {
    result.push({
      original: config.value.unitName,
      mapped: '单位',
      type: 'info',
      sample: props.sampleData[0]?.[config.value.unitName] || '-'
    })
  }

  // 分类
  if (config.value.categoryName) {
    result.push({
      original: config.value.categoryName,
      mapped: '分类',
      type: 'primary',
      sample: props.sampleData[0]?.[config.value.categoryName] || '-'
    })
  }

  return result
})

/**
 * 自动检测列名
 * 基于关键词匹配算法
 */
const autoDetect = () => {
  if (props.availableColumns.length === 0) {
    ElMessage.warning('没有可用的列名')
    return
  }

  // 清空之前的检测结果
  detectionHints.value = {}

  // 检测每个字段
  for (const [field, keywords] of Object.entries(DETECTION_RULES)) {
    let bestMatch: string | null = null
    let bestScore = 0

    for (const column of props.availableColumns) {
      const columnLower = column.toLowerCase()
      
      // 计算匹配分数
      let score = 0
      for (const keyword of keywords) {
        const keywordLower = keyword.toLowerCase()
        
        // 完全匹配
        if (columnLower === keywordLower) {
          score = 100
          break
        }
        
        // 包含匹配
        if (columnLower.includes(keywordLower)) {
          score = Math.max(score, 80)
        }
        
        // 部分匹配
        if (keywordLower.includes(columnLower) && columnLower.length > 1) {
          score = Math.max(score, 60)
        }
      }

      if (score > bestScore) {
        bestScore = score
        bestMatch = column
      }
    }

    // 设置检测提示
    if (bestMatch && bestScore >= 60) {
      detectionHints.value[field as keyof ColumnMapping] = bestMatch
    }
  }

  // 自动应用检测结果
  if (detectionHints.value.materialName) {
    config.value.materialName = detectionHints.value.materialName
  }
  if (detectionHints.value.specification) {
    config.value.specification = detectionHints.value.specification
  }
  if (detectionHints.value.unitName) {
    config.value.unitName = detectionHints.value.unitName
  }
  if (detectionHints.value.categoryName) {
    config.value.categoryName = detectionHints.value.categoryName
  }

  showPreview.value = true

  ElMessage.success({
    message: '自动检测完成！已为您推荐列名',
    duration: 2000
  })
}

/**
 * 验证配置
 */
const validateConfig = async (): Promise<boolean> => {
  if (!formRef.value) return false
  
  try {
    await formRef.value.validate()
    return true
  } catch {
    return false
  }
}

/**
 * 获取配置
 */
const getConfig = (): ColumnMapping => {
  return { ...config.value }
}

// 监听配置变化
watch(
  config,
  async (newConfig) => {
    emit('config-changed', { ...newConfig })
    
    // 验证并触发有效性事件
    const valid = await validateConfig()
    emit('config-valid', valid)
    
    // 显示预览
    if (newConfig.materialName) {
      showPreview.value = true
    }
  },
  { deep: true }
)

// 初始化时自动检测
if (props.availableColumns.length > 0 && !props.initialConfig?.materialName) {
  setTimeout(() => {
    autoDetect()
  }, 500)
}

// 暴露方法给父组件
defineExpose({
  validateConfig,
  getConfig,
  autoDetect
})
</script>

<style scoped lang="scss">
.column-config-container {
  width: 100%;

  .card-header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    font-weight: 600;
  }

  .el-form {
    .field-hint {
      margin-top: 4px;
      font-size: 12px;
      color: #909399;
      display: flex;
      align-items: center;
      gap: 4px;

      .el-icon {
        font-size: 14px;
      }
    }
  }

  .config-preview {
    h4 {
      margin: 0 0 12px 0;
      font-size: 14px;
      font-weight: 600;
      color: #606266;
    }
  }
}
</style>

