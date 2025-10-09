<template>
  <div class="category-manager">
    <!-- 操作栏 -->
    <div class="action-bar">
      <div class="search-box">
        <el-input
          v-model="searchKeyword"
          placeholder="搜索分类名称"
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
        <el-button :icon="Refresh" @click="handleRefresh">
          刷新
        </el-button>
      </div>
    </div>

    <!-- 分类列表表格 -->
    <!-- [T.1.6] 分类管理CRUD完整流程 -->
    <el-table
      v-loading="adminStore.isLoading"
      :data="adminStore.materialCategories"
      stripe
      border
      style="width: 100%"
      :empty-text="emptyText"
    >
      <el-table-column prop="id" label="ID" width="80" align="center" />
      
      <el-table-column prop="category_name" label="分类名称" min-width="150" show-overflow-tooltip />
      
      <el-table-column prop="keywords" label="检测关键词" min-width="300">
        <template #default="{ row }">
          <div class="keywords-list">
            <el-tag
              v-for="(keyword, index) in row.keywords.slice(0, 5)"
              :key="index"
              size="small"
              style="margin-right: 4px; margin-bottom: 4px;"
            >
              {{ keyword }}
            </el-tag>
            <el-tag
              v-if="row.keywords.length > 5"
              size="small"
              type="info"
            >
              +{{ row.keywords.length - 5 }}
            </el-tag>
          </div>
        </template>
      </el-table-column>
      
      <el-table-column prop="detection_confidence" label="检测置信度" width="120" align="center">
        <template #default="{ row }">
          {{ Number(row.detection_confidence || 0.8).toFixed(2) }}
        </template>
      </el-table-column>
      
      <el-table-column prop="priority" label="优先级" width="100" align="center" sortable />
      
      <el-table-column prop="is_active" label="状态" width="100" align="center">
        <template #default="{ row }">
          <el-tag :type="row.is_active ? 'success' : 'danger'">
            {{ row.is_active ? '启用' : '禁用' }}
          </el-tag>
        </template>
      </el-table-column>
      
      <el-table-column prop="created_at" label="创建时间" width="180" align="center">
        <template #default="{ row }">
          {{ formatDateTime(row.created_at) }}
        </template>
      </el-table-column>
      
      <el-table-column label="操作" width="120" align="center" fixed="right">
        <template #default="{ row }">
          <el-button link type="primary" size="small" @click="handleEdit(row)">
            编辑
          </el-button>
          <el-button link size="small" @click="handleView(row)">
            详情
          </el-button>
        </template>
      </el-table-column>
    </el-table>

    <!-- 分页 -->
    <div class="pagination-container">
      <el-pagination
        v-model:current-page="currentPage"
        v-model:page-size="pageSize"
        :page-sizes="[10, 20, 50, 100]"
        :total="adminStore.categoriesTotal"
        layout="total, sizes, prev, pager, next, jumper"
        @size-change="handleSizeChange"
        @current-change="handlePageChange"
      />
    </div>

    <!-- 分类详情/编辑弹窗 -->
    <el-dialog
      v-model="dialogVisible"
      :title="dialogMode === 'edit' ? '编辑分类' : '分类详情'"
      width="700px"
      :close-on-click-modal="false"
    >
      <el-form
        v-if="currentCategory"
        ref="formRef"
        :model="formData"
        :rules="dialogMode === 'edit' ? rules : undefined"
        label-width="120px"
        :disabled="dialogMode === 'view'"
      >
        <el-form-item label="分类名称" prop="category_name">
          <el-input v-model="formData.category_name" disabled />
        </el-form-item>

        <el-form-item label="检测关键词" prop="keywords">
          <el-select
            v-model="formData.keywords"
            multiple
            filterable
            allow-create
            default-first-option
            placeholder="输入关键词后按回车添加"
            style="width: 100%"
          >
          </el-select>
          <div class="form-tip">
            可以输入新关键词后按回车添加，关键词用于自动检测物料分类
          </div>
        </el-form-item>

        <el-form-item label="检测置信度" prop="detection_confidence">
          <el-input-number
            v-model="formData.detection_confidence"
            :min="0"
            :max="1"
            :step="0.1"
            :precision="2"
            style="width: 100%"
          />
        </el-form-item>

        <el-form-item label="优先级" prop="priority">
          <el-input-number
            v-model="formData.priority"
            :min="0"
            :max="1000"
            :step="10"
            style="width: 100%"
          />
        </el-form-item>

        <el-form-item label="数据来源">
          <el-input v-model="formData.data_source" disabled />
        </el-form-item>
      </el-form>

      <template #footer v-if="dialogMode === 'edit'">
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button
          type="primary"
          :loading="adminStore.isSubmitting"
          @click="handleSubmit"
        >
          确定
        </el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
/**
 * @component CategoryManager
 * @description 物料分类管理组件
 * 
 * 功能：
 * - 分类列表展示（分页、搜索）
 * - 分类详情查看
 * - 分类关键词编辑
 * 
 * 关联测试点 (Associated Test Points):
 * - [T.1.6] - 分类管理CRUD完整流程
 * - [T.2.1] - 空数据状态展示
 * - [T.2.6] - 大数据量分页性能
 */

import { ref, computed, onMounted } from 'vue'
import { Search, Refresh } from '@element-plus/icons-vue'
import type { FormInstance, FormRules } from 'element-plus'
import { ElMessage } from 'element-plus'
import { useAdminStore } from '@/stores/admin'
import type { MaterialCategoryInterface } from '@/types/admin'

// Store
const adminStore = useAdminStore()

// 搜索关键词
const searchKeyword = ref('')

// 分页参数
const currentPage = ref(1)
const pageSize = ref(20)

// 弹窗
const dialogVisible = ref(false)
const dialogMode = ref<'view' | 'edit'>('view')
const currentCategory = ref<MaterialCategoryInterface | null>(null)
const formRef = ref<FormInstance>()

// 表单数据
const formData = ref<Partial<MaterialCategoryInterface>>({
  category_name: '',
  keywords: [],
  detection_confidence: 0.8,
  priority: 50,
  data_source: ''
})

// 表单验证规则
const rules: FormRules = {
  keywords: [
    { required: true, type: 'array', min: 1, message: '至少添加一个关键词', trigger: 'change' }
  ],
  detection_confidence: [
    { required: true, type: 'number', min: 0, max: 1, message: '置信度必须在 0 到 1 之间', trigger: 'blur' }
  ],
  priority: [
    { required: true, type: 'number', min: 0, max: 1000, message: '优先级必须在 0 到 1000 之间', trigger: 'blur' }
  ]
}

// 空数据状态
const emptyText = computed(() => {
  return adminStore.isLoading ? '加载中...' : '暂无数据'
})

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

// 加载分类列表
const loadCategories = async () => {
  try {
    await adminStore.loadMaterialCategories({
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
  loadCategories()
}

// 刷新
const handleRefresh = () => {
  searchKeyword.value = ''
  currentPage.value = 1
  loadCategories()
}

// 分页改变
const handlePageChange = (page: number) => {
  currentPage.value = page
  loadCategories()
}

const handleSizeChange = (size: number) => {
  pageSize.value = size
  currentPage.value = 1
  loadCategories()
}

// 查看详情
const handleView = (category: MaterialCategoryInterface) => {
  dialogMode.value = 'view'
  currentCategory.value = { ...category }
  formData.value = {
    category_name: category.category_name,
    keywords: [...(category.keywords || [])],
    detection_confidence: category.detection_confidence,
    priority: category.priority,
    data_source: category.data_source
  }
  dialogVisible.value = true
}

// 编辑分类
const handleEdit = (category: MaterialCategoryInterface) => {
  dialogMode.value = 'edit'
  currentCategory.value = { ...category }
  formData.value = {
    category_name: category.category_name,
    keywords: [...(category.keywords || [])],
    detection_confidence: category.detection_confidence,
    priority: category.priority,
    data_source: category.data_source
  }
  dialogVisible.value = true
}

// 提交编辑
const handleSubmit = async () => {
  if (!formRef.value || !currentCategory.value?.id) return
  
  try {
    await formRef.value.validate()
    
    await adminStore.updateMaterialCategory(currentCategory.value.id, {
      keywords: formData.value.keywords,
      detection_confidence: formData.value.detection_confidence,
      priority: formData.value.priority
    })
    
    dialogVisible.value = false
    await loadCategories()
    
  } catch (error: any) {
    if (error?.message) {
      console.error('表单验证失败:', error)
    }
  }
}

// 组件挂载时加载数据
onMounted(() => {
  loadCategories()
})
</script>

<style scoped lang="scss">
.category-manager {
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

  .keywords-list {
    display: flex;
    flex-wrap: wrap;
    gap: 4px;
  }

  .pagination-container {
    margin-top: 20px;
    display: flex;
    justify-content: flex-end;
  }

  .form-tip {
    font-size: 12px;
    color: #909399;
    margin-top: 4px;
    line-height: 1.4;
  }

  :deep(.el-table) {
    font-size: 14px;
  }
}
</style>

