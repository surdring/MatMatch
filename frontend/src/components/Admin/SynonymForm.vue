<template>
  <el-dialog
    v-model="dialogVisible"
    :title="title"
    width="600px"
    :close-on-click-modal="false"
    @close="handleClose"
  >
    <el-form
      ref="formRef"
      :model="formData"
      :rules="rules"
      label-width="120px"
      label-position="right"
    >
      <el-form-item label="原始词汇" prop="original_term">
        <el-input
          v-model="formData.original_term"
          placeholder="请输入原始词汇"
          clearable
        />
      </el-form-item>

      <el-form-item label="标准词汇" prop="standard_term">
        <el-input
          v-model="formData.standard_term"
          placeholder="请输入标准词汇"
          clearable
        />
      </el-form-item>

      <el-form-item label="类别" prop="category">
        <el-input
          v-model="formData.category"
          placeholder="例如: material, brand, general"
          clearable
        />
      </el-form-item>

      <el-form-item label="同义词类型" prop="synonym_type">
        <el-select
          v-model="formData.synonym_type"
          placeholder="请选择同义词类型"
          style="width: 100%"
        >
          <el-option label="通用" value="general" />
          <el-option label="品牌" value="brand" />
          <el-option label="规格" value="specification" />
          <el-option label="材质" value="material" />
          <el-option label="单位" value="unit" />
        </el-select>
      </el-form-item>

      <el-form-item label="置信度" prop="confidence">
        <el-slider
          v-model="formData.confidence"
          :min="0"
          :max="1"
          :step="0.1"
          :marks="{ 0: '0', 0.5: '0.5', 1: '1' }"
          show-input
          :input-size="'small'"
        />
        <div class="form-tip">
          置信度范围 0-1，数值越大表示同义关系越可靠
        </div>
      </el-form-item>

      <el-form-item label="启用状态" prop="is_active">
        <el-switch
          v-model="formData.is_active"
          active-text="启用"
          inactive-text="禁用"
        />
      </el-form-item>

      <el-form-item label="描述" prop="description">
        <el-input
          v-model="formData.description"
          type="textarea"
          :rows="3"
          placeholder="同义词说明（可选）"
        />
      </el-form-item>
    </el-form>

    <template #footer>
      <el-button @click="handleClose">取消</el-button>
      <el-button
        type="primary"
        :loading="adminStore.isSubmitting"
        @click="handleSubmit"
      >
        确定
      </el-button>
    </template>
  </el-dialog>
</template>

<script setup lang="ts">
/**
 * @component SynonymForm
 * @description 同义词编辑表单组件
 * 
 * 功能：
 * - 同义词创建表单
 * - 同义词编辑表单
 * - 表单验证
 * 
 * 关联测试点 (Associated Test Points):
 * - [T.1.5] - 同义词CRUD完整流程
 * - [T.2.3] - 表单验证失败的提示
 */

import { ref, computed, watch } from 'vue'
import type { FormInstance, FormRules } from 'element-plus'
import { ElMessage } from 'element-plus'
import { useAdminStore } from '@/stores/admin'
import type { SynonymEntryInterface } from '@/types/admin'

// Props
interface Props {
  visible: boolean
  synonymData: SynonymEntryInterface | null
  mode: 'create' | 'edit'
}

const props = defineProps<Props>()

// Emits
const emit = defineEmits<{
  'update:visible': [value: boolean]
  'success': []
}>()

// Store
const adminStore = useAdminStore()

// 表单ref
const formRef = ref<FormInstance>()

// 弹窗显示状态
const dialogVisible = computed({
  get: () => props.visible,
  set: (value) => emit('update:visible', value)
})

// 标题
const title = computed(() => {
  return props.mode === 'create' ? '新建同义词' : '编辑同义词'
})

// 表单数据
const formData = ref<Partial<SynonymEntryInterface>>({
  original_term: '',
  standard_term: '',
  category: 'general',
  synonym_type: 'general',
  confidence: 1.0,
  is_active: true,
  description: ''
})

// 表单验证规则
const rules: FormRules = {
  original_term: [
    { required: true, message: '请输入原始词汇', trigger: 'blur' },
    { min: 1, max: 100, message: '原始词汇长度在 1 到 100 个字符', trigger: 'blur' }
  ],
  standard_term: [
    { required: true, message: '请输入标准词汇', trigger: 'blur' },
    { min: 1, max: 100, message: '标准词汇长度在 1 到 100 个字符', trigger: 'blur' }
  ],
  category: [
    { max: 50, message: '类别长度不能超过 50 个字符', trigger: 'blur' }
  ],
  synonym_type: [
    { required: true, message: '请选择同义词类型', trigger: 'change' }
  ],
  confidence: [
    { required: true, message: '请设置置信度', trigger: 'blur' },
    { type: 'number', min: 0, max: 1, message: '置信度必须在 0 到 1 之间', trigger: 'blur' }
  ]
}

// 重置表单
const resetForm = () => {
  formData.value = {
    original_term: '',
    standard_term: '',
    category: 'general',
    synonym_type: 'general',
    confidence: 1.0,
    is_active: true,
    description: ''
  }
  formRef.value?.clearValidate()
}

// 监听synonymData变化，初始化表单
watch(() => props.synonymData, (newData) => {
  if (newData && props.mode === 'edit') {
    formData.value = {
      ...newData
    }
  } else {
    resetForm()
  }
}, { immediate: true })

// 提交表单
const handleSubmit = async () => {
  if (!formRef.value) return
  
  try {
    await formRef.value.validate()
    
    if (props.mode === 'create') {
      await adminStore.createSynonym(formData.value)
    } else {
      if (!props.synonymData?.id) {
        ElMessage.error('同义词ID不存在')
        return
      }
      await adminStore.updateSynonym(props.synonymData.id, formData.value)
    }
    
    emit('success')
    
  } catch (error: any) {
    if (error?.message) {
      console.error('表单验证失败:', error)
    }
  }
}

// 关闭弹窗
const handleClose = () => {
  resetForm()
  emit('update:visible', false)
}
</script>

<style scoped lang="scss">
.form-tip {
  font-size: 12px;
  color: #909399;
  margin-top: 4px;
  line-height: 1.4;
}

:deep(.el-form-item__label) {
  font-weight: 500;
}
</style>

