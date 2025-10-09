<template>
  <div class="synonym-manager">
    <!-- 操作栏 -->
    <div class="action-bar">
      <div class="search-box">
        <el-input
          v-model="searchKeyword"
          placeholder="搜索原始词汇或标准词汇"
          :prefix-icon="Search"
          clearable
          @clear="handleSearch"
          @keyup.enter="handleSearch"
          style="width: 300px"
        />
        <el-select
          v-model="filterType"
          placeholder="同义词类型"
          clearable
          style="width: 150px"
          @change="handleSearch"
        >
          <el-option label="全部类型" value="" />
          <el-option label="通用" value="general" />
          <el-option label="品牌" value="brand" />
          <el-option label="规格" value="specification" />
          <el-option label="材质" value="material" />
          <el-option label="单位" value="unit" />
        </el-select>
        <el-button type="primary" :icon="Search" @click="handleSearch">
          搜索
        </el-button>
      </div>
      
      <div class="action-buttons">
        <el-button type="primary" :icon="Plus" @click="handleCreate">
          新建同义词
        </el-button>
        <el-button :icon="Upload" @click="handleBatchImport">
          批量导入
        </el-button>
        <el-button :icon="Download" @click="handleBatchExport">
          批量导出
        </el-button>
        <el-button :icon="Refresh" @click="handleRefresh">
          刷新
        </el-button>
      </div>
    </div>

    <!-- 同义词列表表格 -->
    <!-- [T.1.5] 同义词CRUD完整流程 -->
    <el-table
      v-loading="adminStore.isLoading"
      :data="adminStore.synonyms"
      stripe
      border
      style="width: 100%"
      :empty-text="emptyText"
    >
      <el-table-column prop="id" label="ID" width="80" align="center" />
      
      <el-table-column prop="original_term" label="原始词汇" min-width="150" show-overflow-tooltip />
      
      <el-table-column prop="standard_term" label="标准词汇" min-width="150" show-overflow-tooltip />
      
      <el-table-column prop="category" label="类别" width="120" align="center">
        <template #default="{ row }">
          <el-tag>{{ row.category || 'general' }}</el-tag>
        </template>
      </el-table-column>
      
      <el-table-column prop="synonym_type" label="同义词类型" width="120" align="center">
        <template #default="{ row }">
          <el-tag :type="getTypeTagType(row.synonym_type)">
            {{ getTypeLabel(row.synonym_type) }}
          </el-tag>
        </template>
      </el-table-column>
      
      <el-table-column prop="confidence" label="置信度" width="100" align="center">
        <template #default="{ row }">
          {{ (parseFloat(row.confidence) || 1.0).toFixed(2) }}
        </template>
      </el-table-column>
      
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
          <el-popconfirm
            title="确定要删除这条同义词吗？"
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
        :total="adminStore.synonymsTotal"
        layout="total, sizes, prev, pager, next, jumper"
        @size-change="handleSizeChange"
        @current-change="handlePageChange"
      />
    </div>

    <!-- 同义词编辑表单弹窗 -->
    <SynonymForm
      v-model:visible="formVisible"
      :synonym-data="currentSynonym"
      :mode="formMode"
      @success="handleFormSuccess"
    />

    <!-- 批量导入弹窗 -->
    <el-dialog
      v-model="importDialogVisible"
      title="批量导入同义词"
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
            <br>
            Excel文件必须包含列：原始词汇、标准词汇
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
 * @component SynonymManager
 * @description 同义词管理组件 - 同义词的CRUD管理
 * 
 * 功能：
 * - 同义词列表展示（分页、搜索、筛选）
 * - 同义词创建、编辑、删除
 * - 同义词启用/禁用
 * - 批量导入导出同义词
 * 
 * 关联测试点 (Associated Test Points):
 * - [T.1.5] - 同义词CRUD完整流程
 * - [T.2.1] - 空数据状态展示
 * - [T.2.5] - 批量导入文件格式错误
 * - [T.3.1] - 批量导入性能测试
 */

import { ref, computed, onMounted } from 'vue'
import { Search, Plus, Upload, Download, Refresh, UploadFilled } from '@element-plus/icons-vue'
import { ElMessage } from 'element-plus'
import type { UploadFile } from 'element-plus'
import { useAdminStore } from '@/stores/admin'
import type { SynonymEntryInterface } from '@/types/admin'
import SynonymForm from './SynonymForm.vue'
import * as XLSX from 'xlsx'

// Store
const adminStore = useAdminStore()

// 搜索关键词
const searchKeyword = ref('')
const filterType = ref('')

// 分页参数
const currentPage = ref(1)
const pageSize = ref(20)

// 表单弹窗
const formVisible = ref(false)
const formMode = ref<'create' | 'edit'>('create')
const currentSynonym = ref<SynonymEntryInterface | null>(null)

// 批量导入
const importDialogVisible = ref(false)
const uploadRef = ref()
const selectedFile = ref<File | null>(null)

// 空数据状态
const emptyText = computed(() => {
  return adminStore.isLoading ? '加载中...' : '暂无数据'
})

// 同义词类型标签
const getTypeLabel = (type?: string) => {
  const labels: Record<string, string> = {
    'general': '通用',
    'brand': '品牌',
    'specification': '规格',
    'material': '材质',
    'unit': '单位'
  }
  return labels[type || 'general'] || '通用'
}

const getTypeTagType = (type?: string) => {
  const types: Record<string, any> = {
    'general': undefined,
    'brand': 'success',
    'specification': 'warning',
    'material': 'info',
    'unit': 'danger'
  }
  return types[type || 'general'] || undefined
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

// 加载同义词列表
const loadSynonyms = async () => {
  try {
    await adminStore.loadSynonyms({
      page: currentPage.value,
      page_size: pageSize.value,
      search: searchKeyword.value || undefined,
      synonym_type: filterType.value || undefined
    })
  } catch (error) {
    // 错误已在store中处理
  }
}

// 搜索
const handleSearch = () => {
  currentPage.value = 1
  loadSynonyms()
}

// 刷新
const handleRefresh = () => {
  searchKeyword.value = ''
  filterType.value = ''
  currentPage.value = 1
  loadSynonyms()
}

// 分页改变
const handlePageChange = (page: number) => {
  currentPage.value = page
  loadSynonyms()
}

const handleSizeChange = (size: number) => {
  pageSize.value = size
  currentPage.value = 1
  loadSynonyms()
}

// 创建同义词
const handleCreate = () => {
  formMode.value = 'create'
  currentSynonym.value = null
  formVisible.value = true
}

// 编辑同义词
const handleEdit = (synonym: SynonymEntryInterface) => {
  formMode.value = 'edit'
  currentSynonym.value = { ...synonym }
  formVisible.value = true
}

// 删除同义词
const handleDelete = async (synonym: SynonymEntryInterface) => {
  if (!synonym.id) return
  
  try {
    await adminStore.deleteSynonym(synonym.id)
    if (adminStore.synonyms.length === 0 && currentPage.value > 1) {
      currentPage.value -= 1
    }
    await loadSynonyms()
  } catch (error) {
    // 错误已在store中处理
  }
}

// 切换启用/禁用状态
const handleToggleActive = async (synonym: SynonymEntryInterface) => {
  if (!synonym.id) return
  
  try {
    await adminStore.updateSynonym(synonym.id, {
      is_active: synonym.is_active
    })
  } catch (error) {
    // 恢复原状态
    synonym.is_active = !synonym.is_active
  }
}

// 表单提交成功
const handleFormSuccess = () => {
  formVisible.value = false
  loadSynonyms()
}

// 批量导入
const handleBatchImport = () => {
  importDialogVisible.value = true
  selectedFile.value = null
}

const handleFileChange = (file: UploadFile) => {
  const isExcel = file.name.endsWith('.xlsx') || file.name.endsWith('.xls')
  if (!isExcel) {
    ElMessage.error('只能上传 .xlsx 或 .xls 格式的文件')
    return
  }
  
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

// [T.3.1] 批量导入性能测试（目标：100条 ≤ 1秒）
const handleConfirmImport = async () => {
  if (!selectedFile.value) {
    ElMessage.error('请先选择文件')
    return
  }
  
  try {
    await adminStore.batchImportSynonyms(selectedFile.value)
    importDialogVisible.value = false
    selectedFile.value = null
    await loadSynonyms()
  } catch (error) {
    // 错误已在store中处理
  }
}

// 批量导出
const handleBatchExport = async () => {
  try {
    // 导出当前筛选的所有数据（不分页）
    const response = await adminStore.loadSynonyms({
      page: 1,
      page_size: 10000, // 大数量
      search: searchKeyword.value || undefined,
      synonym_type: filterType.value || undefined
    })
    
    if (adminStore.synonyms.length === 0) {
      ElMessage.warning('没有可导出的数据')
      return
    }
    
    // 准备导出数据
    const exportData = adminStore.synonyms.map(item => ({
      'ID': item.id,
      '原始词汇': item.original_term,
      '标准词汇': item.standard_term,
      '类别': item.category || 'general',
      '同义词类型': getTypeLabel(item.synonym_type),
      '置信度': item.confidence || 1.0,
      '状态': item.is_active ? '启用' : '禁用',
      '创建时间': formatDateTime(item.created_at)
    }))
    
    // 创建工作簿
    const ws = XLSX.utils.json_to_sheet(exportData)
    const wb = XLSX.utils.book_new()
    XLSX.utils.book_append_sheet(wb, ws, '同义词')
    
    // 下载文件
    const fileName = `同义词导出_${new Date().toISOString().slice(0, 10)}.xlsx`
    XLSX.writeFile(wb, fileName)
    
    ElMessage.success('导出成功')
    
  } catch (error) {
    ElMessage.error('导出失败')
  }
}

// 组件挂载时加载数据
onMounted(() => {
  loadSynonyms()
})
</script>

<style scoped lang="scss">
.synonym-manager {
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
  }
}
</style>

