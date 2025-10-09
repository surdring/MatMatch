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
      <!-- [T.1.2] 规则创建和表单验证 -->
      <el-form-item label="规则名称" prop="rule_name">
        <el-input
          v-model="formData.rule_name"
          placeholder="请输入规则名称"
          clearable
        />
      </el-form-item>

      <el-form-item label="物料类别" prop="material_category">
        <el-select
          v-model="formData.material_category"
          placeholder="请选择物料类别"
          style="width: 100%"
        >
          <el-option label="通用" value="general" />
          <el-option label="轴承" value="bearing" />
          <el-option label="螺栓螺钉" value="bolt" />
          <el-option label="阀门" value="valve" />
          <el-option label="管道管件" value="pipe" />
          <el-option label="电气元件" value="electrical" />
          <el-option label="泵类" value="pump" />
          <el-option label="电机" value="motor" />
          <el-option label="传感器" value="sensor" />
          <el-option label="电缆线缆" value="cable" />
          <el-option label="过滤器" value="filter" />
        </el-select>
      </el-form-item>

      <el-form-item label="属性名" prop="attribute_name">
        <el-input
          v-model="formData.attribute_name"
          placeholder="例如: size, material, model"
          clearable
        />
      </el-form-item>

      <el-form-item label="正则表达式" prop="regex_pattern">
        <el-input
          v-model="formData.regex_pattern"
          type="textarea"
          :rows="3"
          placeholder="请输入正则表达式"
        />
        <div class="form-tip">
          提示：使用括号()捕获需要提取的值
        </div>
      </el-form-item>

      <el-form-item label="优先级" prop="priority">
        <el-input-number
          v-model="formData.priority"
          :min="0"
          :max="1000"
          :step="10"
          style="width: 100%"
        />
        <div class="form-tip">
          数字越小优先级越高，建议范围 0-1000
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
          :rows="2"
          placeholder="规则说明（可选）"
        />
      </el-form-item>

      <el-form-item label="示例输入" prop="example_input">
        <el-input
          v-model="formData.example_input"
          type="textarea"
          :rows="2"
          placeholder="示例输入文本（可选）"
        />
      </el-form-item>

      <el-form-item label="示例输出" prop="example_output">
        <el-input
          v-model="formData.example_output"
          type="textarea"
          :rows="2"
          placeholder="预期输出结果（可选）"
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
 * @component RuleForm
 * @description 规则编辑表单组件
 * 
 * 功能：
 * - 规则创建表单
 * - 规则编辑表单
 * - 表单验证
 * 
 * 关联测试点 (Associated Test Points):
 * - [T.1.2] - 规则创建和表单验证
 * - [T.1.3] - 规则编辑和更新
 * - [T.2.3] - 表单验证失败的提示
 */

import { ref, computed, watch } from 'vue'
import type { FormInstance, FormRules } from 'element-plus'
import { ElMessage } from 'element-plus'
import { useAdminStore } from '@/stores/admin'
import type { ExtractionRuleInterface } from '@/types/admin'

// Props
interface Props {
  visible: boolean
  ruleData: ExtractionRuleInterface | null
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
  return props.mode === 'create' ? '新建规则' : '编辑规则'
})

// 表单数据
const formData = ref<Partial<ExtractionRuleInterface>>({
  rule_name: '',
  material_category: 'general',
  attribute_name: '',
  regex_pattern: '',
  priority: 100,
  is_active: true,
  description: '',
  example_input: '',
  example_output: ''
})

// [T.2.3] 表单验证规则
const rules: FormRules = {
  rule_name: [
    { required: true, message: '请输入规则名称', trigger: 'blur' },
    { min: 2, max: 100, message: '规则名称长度在 2 到 100 个字符', trigger: 'blur' }
  ],
  material_category: [
    { required: true, message: '请选择物料类别', trigger: 'change' }
  ],
  attribute_name: [
    { required: true, message: '请输入属性名', trigger: 'blur' },
    { min: 2, max: 50, message: '属性名长度在 2 到 50 个字符', trigger: 'blur' }
  ],
  regex_pattern: [
    { required: true, message: '请输入正则表达式', trigger: 'blur' },
    { 
      validator: (rule, value, callback) => {
        try {
          new RegExp(value)
          callback()
        } catch (e) {
          callback(new Error('正则表达式格式不正确'))
        }
      }, 
      trigger: 'blur' 
    }
  ],
  priority: [
    { required: true, message: '请输入优先级', trigger: 'blur' },
    { type: 'number', min: 0, max: 1000, message: '优先级必须在 0 到 1000 之间', trigger: 'blur' }
  ]
}

// 重置表单
const resetForm = () => {
  formData.value = {
    rule_name: '',
    material_category: 'general',
    attribute_name: '',
    regex_pattern: '',
    priority: 100,
    is_active: true,
    description: '',
    example_input: '',
    example_output: ''
  }
  formRef.value?.clearValidate()
}

// 监听ruleData变化，初始化表单
watch(() => props.ruleData, (newData) => {
  if (newData && props.mode === 'edit') {
    // [T.1.3] 编辑模式：预填充现有数据
    formData.value = {
      ...newData
    }
  } else {
    // 创建模式：重置为默认值
    resetForm()
  }
}, { immediate: true })

// 提交表单
const handleSubmit = async () => {
  if (!formRef.value) return
  
  try {
    // 验证表单
    await formRef.value.validate()
    
    // 提交数据
    if (props.mode === 'create') {
      // [T.1.2] 创建规则
      await adminStore.createExtractionRule(formData.value)
    } else {
      // [T.1.3] 更新规则
      if (!props.ruleData?.id) {
        ElMessage.error('规则ID不存在')
        return
      }
      await adminStore.updateExtractionRule(props.ruleData.id, formData.value)
    }
    
    // 成功后关闭弹窗并通知父组件
    emit('success')
    
  } catch (error: any) {
    if (error?.message) {
      // 表单验证失败
      console.error('表单验证失败:', error)
    }
    // API错误已在store中处理
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

:deep(.el-textarea__inner) {
  font-family: 'Courier New', Courier, monospace;
}
</style>

