<template>
  <div class="rule-manager">
    <!-- 操作栏 -->
    <div class="action-bar">
      <div class="search-box">
        <el-input
          v-model="searchKeyword"
          placeholder="搜索规则名称或物料类别"
          :prefix-icon="Search"
          clearable
          @clear="handleSearch"
          @keyup.enter="handleSearch"
          style="width: 300px"
        />
        <el-button type="primary" :icon="Search" @click="handleSearch">
          搜索
        </el-button>
      </div>
      
      <div class="action-buttons">
        <el-button type="primary" :icon="Plus" @click="handleCreate">
          新建规则
        </el-button>
        <el-button :icon="Upload" @click="handleBatchImport">
          批量导入
        </el-button>
        <el-button :icon="Refresh" @click="handleRefresh">
          刷新
        </el-button>
      </div>
    </div>

    <!-- 规则列表表格 -->
    <!-- [T.1.1] 规则列表加载和分页 -->
    <el-table
      v-loading="adminStore.isLoading"
      :data="adminStore.extractionRules"
      stripe
      border
      style="width: 100%"
      :empty-text="emptyText"
    >
      <el-table-column prop="id" label="ID" width="80" align="center" />
      
      <el-table-column prop="rule_name" label="规则名称" min-width="180" show-overflow-tooltip />
      
      <el-table-column prop="material_category" label="物料类别" width="120" align="center">
        <template #default="{ row }">
          <el-tag>{{ getCategoryLabel(row.material_category) }}</el-tag>
        </template>
      </el-table-column>
      
      <el-table-column prop="attribute_name" label="属性名" width="120" align="center" />
      
      <el-table-column prop="regex_pattern" label="正则表达式" min-width="200" show-overflow-tooltip />
      
      <el-table-column prop="priority" label="优先级" width="100" align="center" sortable />
      
      <el-table-column prop="is_active" label="状态" width="100" align="center">
        <template #default="{ row }">
          <el-switch
            v-model="row.is_active"
            @change="handleToggleActive(row)"
            :disabled="adminStore.isSubmitting"
          />
        </template>
      </el-table-column>
      
      <el-table-column prop="created_at" label="创建时间" width="180" align="center">
        <template #default="{ row }">
          {{ formatDateTime(row.created_at) }}
        </template>
      </el-table-column>
      
      <el-table-column label="操作" width="180" align="center" fixed="right">
        <template #default="{ row }">
          <el-button link type="primary" size="small" @click="handleEdit(row)">
            编辑
          </el-button>
          <!-- [T.1.4] 规则删除和二次确认 -->
          <el-popconfirm
            title="确定要删除这条规则吗？"
            confirm-button-text="确定"
            cancel-button-text="取消"
            @confirm="handleDelete(row)"
          >
            <template #reference>
              <el-button link type="danger" size="small">
                删除
              </el-button>
            </template>
          </el-popconfirm>
        </template>
      </el-table-column>
    </el-table>

    <!-- 分页 -->
    <div class="pagination-container">
      <el-pagination
        v-model:current-page="currentPage"
        v-model:page-size="pageSize"
        :page-sizes="[10, 20, 50, 100]"
        :total="adminStore.extractionRulesTotal"
        layout="total, sizes, prev, pager, next, jumper"
        @size-change="handleSizeChange"
        @current-change="handlePageChange"
      />
    </div>

    <!-- 规则编辑表单弹窗 -->
    <!-- [T.1.2] 规则创建和表单验证 -->
    <!-- [T.1.3] 规则编辑和更新 -->
    <RuleForm
      v-model:visible="formVisible"
      :rule-data="currentRule"
      :mode="formMode"
      @success="handleFormSuccess"
    />

    <!-- 批量导入弹窗 -->
    <el-dialog
      v-model="importDialogVisible"
      title="批量导入规则"
      width="500px"
      :close-on-click-modal="false"
    >
      <el-upload
        ref="uploadRef"
        :auto-upload="false"
        :limit="1"
        :on-change="handleFileChange"
        :on-exceed="handleFileExceed"
        accept=".xlsx,.xls"
        drag
      >
        <el-icon class="el-icon--upload"><upload-filled /></el-icon>
        <div class="el-upload__text">
          将Excel文件拖到此处，或<em>点击上传</em>
        </div>
        <template #tip>
          <div class="el-upload__tip">
            只能上传 .xlsx/.xls 文件，且不超过 10MB
          </div>
        </template>
      </el-upload>
      
      <template #footer>
        <el-button @click="importDialogVisible = false">取消</el-button>
        <el-button
          type="primary"
          :loading="adminStore.isImporting"
          :disabled="!selectedFile"
          @click="handleConfirmImport"
        >
          确定导入
        </el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
/**
 * @component RuleManager
 * @description 规则管理组件 - 提取规则的CRUD管理
 * 
 * 功能：
 * - 规则列表展示（分页、搜索、排序）
 * - 规则创建、编辑、删除
 * - 规则启用/禁用
 * - 批量导入规则
 * 
 * 关联测试点 (Associated Test Points):
 * - [T.1.1] - 规则列表加载和分页
 * - [T.1.2] - 规则创建和表单验证
 * - [T.1.3] - 规则编辑和更新
 * - [T.1.4] - 规则删除和二次确认
 * - [T.2.1] - 空数据状态展示
 * - [T.2.5] - 批量导入文件格式错误
 */

import { ref, computed, onMounted } from 'vue'
import { Search, Plus, Upload, Refresh } from '@element-plus/icons-vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import type { UploadFile } from 'element-plus'
import { useAdminStore } from '@/stores/admin'
import type { ExtractionRuleInterface } from '@/types/admin'
import RuleForm from './RuleForm.vue'

// Store
const adminStore = useAdminStore()

// 搜索关键词
const searchKeyword = ref('')

// 分页参数
const currentPage = ref(1)
const pageSize = ref(20)

// 表单弹窗
const formVisible = ref(false)
const formMode = ref<'create' | 'edit'>('create')
const currentRule = ref<ExtractionRuleInterface | null>(null)

// 批量导入
const importDialogVisible = ref(false)
const uploadRef = ref()
const selectedFile = ref<File | null>(null)

// [T.2.1] 空数据状态展示
const emptyText = computed(() => {
  return adminStore.isLoading ? '加载中...' : '暂无数据'
})

// 物料类别标签映射
const categoryLabels: Record<string, string> = {
  'general': '通用',
  'bearing': '轴承',
  'bolt': '螺栓',
  'valve': '阀门',
  'pipe': '管件',
  'electrical': '电气',
  'pump': '泵类',
  'motor': '电机',
  'sensor': '传感器',
  'cable': '电缆',
  'filter': '过滤器'
}

const getCategoryLabel = (category: string) => {
  return categoryLabels[category] || category
}

// 格式化日期时间
const formatDateTime = (dateStr?: string) => {
  if (!dateStr) return '-'
  const date = new Date(dateStr)
  return date.toLocaleString('zh-CN', {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit'
  })
}

// [I.2.1] 加载规则列表
const loadRules = async () => {
  try {
    await adminStore.loadExtractionRules({
      page: currentPage.value,
      page_size: pageSize.value,
      search: searchKeyword.value || undefined
    })
  } catch (error) {
    // 错误已在store中处理
  }
}

// 搜索
const handleSearch = () => {
  currentPage.value = 1
  loadRules()
}

// 刷新
const handleRefresh = () => {
  searchKeyword.value = ''
  currentPage.value = 1
  loadRules()
}

// 分页改变
const handlePageChange = (page: number) => {
  currentPage.value = page
  loadRules()
}

const handleSizeChange = (size: number) => {
  pageSize.value = size
  currentPage.value = 1
  loadRules()
}

// [T.1.2] 创建规则
const handleCreate = () => {
  formMode.value = 'create'
  currentRule.value = null
  formVisible.value = true
}

// [T.1.3] 编辑规则
const handleEdit = (rule: ExtractionRuleInterface) => {
  formMode.value = 'edit'
  currentRule.value = { ...rule }
  formVisible.value = true
}

// [T.1.4] 删除规则（二次确认已通过el-popconfirm实现）
const handleDelete = async (rule: ExtractionRuleInterface) => {
  if (!rule.id) return
  
  try {
    await adminStore.deleteExtractionRule(rule.id)
    // 如果当前页没有数据了，返回上一页
    if (adminStore.extractionRules.length === 0 && currentPage.value > 1) {
      currentPage.value -= 1
    }
    await loadRules()
  } catch (error) {
    // 错误已在store中处理
  }
}

// 切换启用/禁用状态
const handleToggleActive = async (rule: ExtractionRuleInterface) => {
  if (!rule.id) return
  
  try {
    await adminStore.updateExtractionRule(rule.id, {
      is_active: rule.is_active
    })
  } catch (error) {
    // 恢复原状态
    rule.is_active = !rule.is_active
  }
}

// 表单提交成功
const handleFormSuccess = () => {
  formVisible.value = false
  loadRules()
}

// 批量导入
const handleBatchImport = () => {
  importDialogVisible.value = true
  selectedFile.value = null
}

// [T.2.5] 批量导入文件格式错误处理
const handleFileChange = (file: UploadFile) => {
  // 验证文件类型
  const isExcel = file.name.endsWith('.xlsx') || file.name.endsWith('.xls')
  if (!isExcel) {
    ElMessage.error('只能上传 .xlsx 或 .xls 格式的文件')
    return
  }
  
  // 验证文件大小
  const isLt10M = file.size! / 1024 / 1024 < 10
  if (!isLt10M) {
    ElMessage.error('文件大小不能超过 10MB')
    return
  }
  
  selectedFile.value = file.raw || null
}

const handleFileExceed = () => {
  ElMessage.warning('只能上传一个文件')
}

const handleConfirmImport = async () => {
  if (!selectedFile.value) {
    ElMessage.error('请先选择文件')
    return
  }
  
  try {
    await adminStore.batchImportExtractionRules(selectedFile.value)
    importDialogVisible.value = false
    selectedFile.value = null
    // 刷新列表
    await loadRules()
  } catch (error) {
    // 错误已在store中处理
  }
}

// 组件挂载时加载数据
onMounted(() => {
  loadRules()
})
</script>

<style scoped lang="scss">
.rule-manager {
  .action-bar {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 20px;

    .search-box {
      display: flex;
      gap: 12px;
    }

    .action-buttons {
      display: flex;
      gap: 12px;
    }
  }

  .pagination-container {
    margin-top: 20px;
    display: flex;
    justify-content: flex-end;
  }

  :deep(.el-table) {
    font-size: 14px;

    .el-table__empty-text {
      color: #909399;
    }
  }

  :deep(.el-upload-dragger) {
    padding: 40px;
  }
}
</style>

