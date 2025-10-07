<template>
  <div class="quick-query-form">
    <el-card shadow="hover">
      <template #header>
        <div class="card-header">
          <span>快速查询</span>
          <el-text type="info" size="small">输入单条物料信息进行查重</el-text>
        </div>
      </template>

      <el-form
        ref="formRef"
        :model="form"
        :rules="rules"
        label-width="100px"
        label-position="right"
      >
        <el-form-item label="物料名称" prop="materialName">
          <el-input
            v-model="form.materialName"
            placeholder="请输入物料名称"
            clearable
            maxlength="200"
            show-word-limit
          />
        </el-form-item>

        <el-form-item label="规格型号" prop="specification">
          <el-input
            v-model="form.specification"
            placeholder="请输入规格型号"
            clearable
            maxlength="200"
            show-word-limit
          />
        </el-form-item>

        <el-form-item label="单位" prop="unit">
          <el-input
            v-model="form.unit"
            placeholder="请输入单位（如：个、套、米）"
            clearable
            maxlength="50"
            show-word-limit
          />
        </el-form-item>

        <el-form-item label="分类">
          <el-input
            v-model="form.category"
            placeholder="可选：输入物料分类"
            clearable
            maxlength="100"
            show-word-limit
          />
          <template #extra>
            <el-text type="info" size="small">分类字段为可选项</el-text>
          </template>
        </el-form-item>

        <el-form-item>
          <el-button
            type="primary"
            :loading="isLoading"
            @click="handleSubmit"
          >
            <el-icon><Search /></el-icon>
            <span>开始查重</span>
          </el-button>
          <el-button @click="handleReset">重置</el-button>
        </el-form-item>
      </el-form>
    </el-card>
  </div>
</template>

<script setup lang="ts">
/**
 * @component 快速查询表单组件
 * @description 提供单条物料快速查询功能，通过表单输入生成临时Excel文件并复用批量查重逻辑
 * 
 * 关联测试点 (Associated Test Points):
 * - [T.1.2] - 完整快速查询流程
 * - [T.1.3] - 临时Excel文件生成
 * - [T.1.4] - 列名映射正确性
 * - [T.2.1-T.2.3] - 必需字段验证
 * - [T.2.4] - 可选字段为空
 * 
 * @emits (query) - 查询事件，载荷包含生成的File对象和列名映射
 */

import { reactive, ref } from 'vue'
import { ElMessage } from 'element-plus'
import { Search } from '@element-plus/icons-vue'
import * as XLSX from 'xlsx'

// ==================== Props & Emits ====================
const emit = defineEmits<{
  query: [file: File, columnMapping: any]
}>()

const props = defineProps<{
  isLoading?: boolean
}>()

// ==================== Reactive State ====================
const formRef = ref()
const form = reactive({
  materialName: '',
  specification: '',
  unit: '',
  category: ''
})

// ==================== Validation Rules ====================
// 对应 [T.2.1-T.2.3] - 必需字段验证
const rules = {
  materialName: [
    { required: true, message: '请输入物料名称', trigger: 'blur' }
  ],
  specification: [
    { required: true, message: '请输入规格型号', trigger: 'blur' }
  ],
  unit: [
    { required: true, message: '请输入单位', trigger: 'blur' }
  ]
}

// ==================== Methods ====================

/**
 * 处理表单提交
 * 
 * 对应 [T.1.2] - 完整快速查询流程
 * 对应 [T.1.3] - 临时Excel文件生成
 * 对应 [T.1.4] - 列名映射正确性
 */
const handleSubmit = async () => {
  try {
    // 表单验证
    await formRef.value.validate()

    // 构造临时Excel数据
    // 为什么使用这个结构：必须与后端API期望的Excel列名完全一致
    const tempData = [{
      '物料名称': form.materialName,
      '规格型号': form.specification,
      '单位': form.unit,
      '分类': form.category || '' // 可选字段，对应 [T.2.4]
    }]

    // 生成Excel文件
    // 为什么使用 json_to_sheet：这是 xlsx 库的标准方法，自动处理列名和数据格式
    const ws = XLSX.utils.json_to_sheet(tempData)
    const wb = XLSX.utils.book_new()
    XLSX.utils.book_append_sheet(wb, ws, 'Sheet1')

    // 转换为二进制数据
    // 为什么使用 type: 'array'：生成 ArrayBuffer，可直接用于创建 Blob
    const wbout = XLSX.write(wb, { type: 'array', bookType: 'xlsx' })

    // 创建Blob对象
    const blob = new Blob([wbout], {
      type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
    })

    // 创建File对象
    const file = new File([blob], 'quick-query.xlsx', {
      type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
    })

    // 构造列名映射
    // 为什么这个映射结构：必须与 ColumnConfig.vue 的映射格式完全一致
    // 为什么分类使用条件性包含：后端API根据有无分类字段决定是否使用分类过滤
    const columnMapping = {
      materialName: '物料名称',
      specification: '规格型号',
      unitName: '单位',
      ...(form.category && { categoryName: '分类' })
    }

    // 触发查询事件
    emit('query', file, columnMapping)

    ElMessage.success('正在查询...')
  } catch (error) {
    // 表单验证失败时，Element Plus会自动显示错误信息
    console.error('表单验证失败:', error)
  }
}

/**
 * 重置表单
 */
const handleReset = () => {
  formRef.value.resetFields()
  ElMessage.info('表单已重置')
}
</script>

<style scoped lang="scss">
.quick-query-form {
  max-width: 600px;
  margin: 0 auto;

  .card-header {
    display: flex;
    justify-content: space-between;
    align-items: center;

    span:first-child {
      font-size: 16px;
      font-weight: 500;
    }
  }

  :deep(.el-form) {
    .el-form-item {
      margin-bottom: 24px;

      &:last-child {
        margin-bottom: 0;
        margin-top: 32px;
      }
    }

    .el-button {
      min-width: 120px;

      + .el-button {
        margin-left: 16px;
      }
    }
  }
}
</style>

