<template>
  <div class="material-search-container">
    <div class="page-header">
      <h1>物料批量查重</h1>
      <p>上传Excel文件或快速查询单条物料</p>
    </div>

    <!-- Tab切换 - 对应 [T.1.1] 标签页切换功能 -->
    <el-tabs v-model="activeTab" type="card" class="search-tabs">
      <!-- Tab 1: 批量查重 -->
      <el-tab-pane label="批量查重" name="batch">
        <el-steps :active="currentStep" finish-status="success" style="margin-bottom: 30px">
          <el-step title="上传文件" description="选择Excel文件" />
          <el-step title="配置列名" description="映射数据列" />
          <el-step title="处理查重" description="相似度匹配" />
          <el-step title="查看结果" description="查看报告" />
        </el-steps>

    <!-- Step 1: 文件上传 -->
    <div v-show="currentStep === 0">
      <FileUpload
        ref="fileUploadRef"
        :max-size-m-b="10"
        :preview-rows="5"
        @file-selected="handleFileSelected"
        @file-removed="handleFileRemoved"
        @error="handleUploadError"
      />
      
      <div style="margin-top: 20px; text-align: right">
        <el-button
          type="primary"
          size="large"
          :disabled="!hasFile"
          @click="goToStep(1)"
        >
          下一步：配置列名
          <el-icon><ArrowRight /></el-icon>
        </el-button>
      </div>
    </div>

    <!-- Step 2: 列名配置 -->
    <div v-show="currentStep === 1">
      <!-- 优化2: 自动检测中的提示 -->
      <div v-if="isAutoDetecting" style="text-align: center; padding: 100px 0">
        <el-icon class="is-loading" :size="50" color="#409eff">
          <Loading />
        </el-icon>
        <div style="margin-top: 20px; font-size: 18px; color: #303133">
          正在自动检测列名配置中...
        </div>
        <div style="margin-top: 10px; color: #909399">
          请稍候，系统正在自动分析Excel列结构
        </div>
      </div>

      <!-- 列名配置组件 -->
      <div v-show="!isAutoDetecting">
        <ColumnConfig
          ref="columnConfigRef"
          :available-columns="availableColumns"
          :sample-data="sampleData"
          @config-changed="handleConfigChanged"
          @config-valid="handleConfigValid"
        />

        <div style="margin-top: 20px; display: flex; justify-content: space-between">
          <el-button size="large" @click="goToStep(0)">
            <el-icon><ArrowLeft /></el-icon>
            上一步
          </el-button>
          <el-button
            type="primary"
            size="large"
            :disabled="!isConfigValid"
            @click="startSearch"
          >
            开始查重
            <el-icon><Search /></el-icon>
          </el-button>
        </div>
      </div>
    </div>

    <!-- Step 3: 处理进度 -->
    <div v-show="currentStep === 2">
      <UploadProgress
        :progress="uploadProgress"
        :upload-speed="uploadSpeed"
        :processed-items="processedItems"
        :total-items="totalItems"
        :current-step="currentStepText"
        :allow-cancel="true"
        @pause="handlePause"
        @resume="handleResume"
        @cancel="handleCancel"
        @complete="handleComplete"
      />
    </div>

    <!-- Step 4: 查看结果 -->
    <div v-show="currentStep === 3">
      <el-card shadow="hover">
        <template #header>
          <div style="display: flex; justify-content: space-between; align-items: center">
            <h3>查重结果</h3>
            <div>
              <el-button type="primary" @click="handleExport">
                <el-icon><Download /></el-icon>
                导出结果
              </el-button>
              <el-button @click="resetSearch">
                <el-icon><RefreshLeft /></el-icon>
                重新查重
              </el-button>
            </div>
          </div>
        </template>

        <!-- 统计信息 -->
        <el-alert
          title="处理完成"
          type="success"
          :closable="false"
          show-icon
          style="margin-bottom: 20px"
        >
          <template #default>
            共处理 {{ totalProcessed }} 条记录，
            成功 {{ successCount }} 条，
            找到匹配 {{ hasMatchCount }} 条，
            无匹配 {{ noMatchCount }} 条，
            耗时 {{ processingTime }}秒
          </template>
        </el-alert>

        <!-- 结果表格 -->
        <div class="results-table">
          <el-table
            :data="paginatedResults"
            border
            stripe
            style="width: 100%"
            @row-dblclick="handleRowDoubleClick"
            :row-style="{ cursor: 'pointer' }"
          >
            <el-table-column type="index" label="序号" width="60" align="center" />
            <el-table-column label="物料名称" min-width="180" show-overflow-tooltip>
              <template #default="{ row }">
                {{ getInputData(row.input_data).name }}
              </template>
            </el-table-column>
            <el-table-column label="规格型号" min-width="150" show-overflow-tooltip>
              <template #default="{ row }">
                {{ getInputData(row.input_data).spec }}
              </template>
            </el-table-column>
            <el-table-column label="单位" width="80" align="center">
              <template #default="{ row }">
                {{ getInputData(row.input_data).unit }}
              </template>
            </el-table-column>
            <el-table-column label="分类" width="120" align="center">
              <template #default="{ row }">
                {{ getInputData(row.input_data).category }}
              </template>
            </el-table-column>
            <el-table-column label="推荐分类" width="140" align="center">
              <template #default="{ row }">
                <el-tag v-if="row.parsed_query?.detected_category" type="success" size="small">
                  {{ row.parsed_query.detected_category }}
                </el-tag>
                <span v-else style="color: #909399">-</span>
              </template>
            </el-table-column>
            <el-table-column label="匹配数量" width="100" align="center">
              <template #default="{ row }">
                <el-tag :type="row.similar_materials?.length > 0 ? 'success' : 'info'" size="small">
                  {{ row.similar_materials?.length || 0 }} 个
                </el-tag>
              </template>
            </el-table-column>
            <el-table-column label="最高相似度" width="120" align="center">
              <template #default="{ row }">
                <template v-if="row.similar_materials?.[0]">
                  <el-text 
                    :type="getSimilarityTextType(row.similar_materials[0].similarity_score)"
                    style="font-weight: 600"
                  >
                    {{ (row.similar_materials[0].similarity_score * 100).toFixed(1) }}%
                  </el-text>
                </template>
                <span v-else style="color: #909399">-</span>
              </template>
            </el-table-column>
            <el-table-column label="查重结论" width="100" align="center">
              <template #default="{ row }">
                <el-tag 
                  :type="getDuplicateConclusion(row).type" 
                  size="small"
                  effect="dark"
                >
                  {{ getDuplicateConclusion(row).text }}
                </el-tag>
              </template>
            </el-table-column>
            <el-table-column label="操作" width="120" align="center" fixed="right">
              <template #default="{ row }">
                <el-button 
                  type="primary" 
                  size="small" 
                  text
                  @click="handleViewDetail(row)"
                >
                  查看详情
                </el-button>
              </template>
            </el-table-column>
          </el-table>
          
          <!-- 优化4: 分页控件 -->
          <div style="margin-top: 20px; display: flex; justify-content: space-between; align-items: center">
            <el-text type="info" size="small">
              💡 提示：双击表格行可快速查看详细匹配信息
            </el-text>
            <el-pagination
              :current-page="currentPage"
              :page-size="pageSize"
              :page-sizes="[10, 20, 50, 100, 200]"
              :total="totalProcessed"
              layout="total, sizes, prev, pager, next, jumper"
              background
              @current-change="(val) => currentPage = val"
              @size-change="(val) => pageSize = val"
            />
          </div>
        </div>
      </el-card>
    </div>

    <!-- 详情弹窗 -->
    <el-dialog
      v-model="detailDialogVisible"
      title="物料查重详情"
      width="1000px"
      :close-on-click-modal="false"
    >
      <div v-if="selectedRow" class="detail-dialog">
        <!-- 输入物料信息 -->
        <el-card shadow="never" class="input-card">
          <template #header>
            <h3>📝 待查重物料信息</h3>
          </template>
          <el-descriptions :column="2" border>
            <el-descriptions-item label="物料名称">
              <el-text type="primary" style="font-weight: 500">
                {{ getInputData(selectedRow.input_data).name }}
              </el-text>
            </el-descriptions-item>
            <el-descriptions-item label="规格型号">
              {{ getInputData(selectedRow.input_data).spec }}
            </el-descriptions-item>
            <el-descriptions-item label="单位">
              {{ getInputData(selectedRow.input_data).unit }}
            </el-descriptions-item>
            <el-descriptions-item label="分类">
              {{ getInputData(selectedRow.input_data).category }}
            </el-descriptions-item>
            <el-descriptions-item label="推荐分类">
              <el-tag v-if="selectedRow.parsed_query?.detected_category" type="success">
                {{ selectedRow.parsed_query.detected_category }}
              </el-tag>
              <span v-else style="color: #909399">未识别到分类</span>
            </el-descriptions-item>
            <el-descriptions-item label="分类置信度">
              <el-text 
                v-if="selectedRow.parsed_query?.confidence !== undefined" 
                type="success"
                style="font-weight: 600"
              >
                {{ (selectedRow.parsed_query.confidence * 100).toFixed(1) }}%
              </el-text>
              <span v-else style="color: #909399">-</span>
            </el-descriptions-item>
            <el-descriptions-item label="查重结论" :span="2">
              <el-tag 
                :type="getDuplicateConclusion(selectedRow).type" 
                size="large"
                effect="dark"
              >
                {{ getDuplicateConclusion(selectedRow).text }}
              </el-tag>
              <el-text type="info" size="small" style="margin-left: 10px">
                {{ getDuplicateConclusion(selectedRow).description }}
              </el-text>
            </el-descriptions-item>
          </el-descriptions>
        </el-card>

        <!-- 匹配物料列表 -->
        <el-card shadow="never" class="matches-card" style="margin-top: 20px">
          <template #header>
            <h3>🔍 ERP相似物料（前5条）</h3>
          </template>
          <el-table 
            v-if="selectedRow.similar_materials?.length > 0"
            :data="selectedRow.similar_materials.slice(0, 5)" 
            border
            stripe
            max-height="400"
          >
            <el-table-column type="index" label="排名" width="60" align="center" />
            <el-table-column prop="erp_code" label="ERP编码" width="140">
              <template #default="{ row }">
                <el-text type="primary" style="font-weight: 500">{{ row.erp_code }}</el-text>
              </template>
            </el-table-column>
            <el-table-column prop="material_name" label="物料名称" min-width="200" show-overflow-tooltip />
            <el-table-column prop="specification" label="规格型号" min-width="150" show-overflow-tooltip />
            <el-table-column label="单位" width="80" align="center">
              <template #default="{ row }">
                {{ row.unit_name || '-' }}
              </template>
            </el-table-column>
            <el-table-column label="原分类" width="120" align="center" show-overflow-tooltip>
              <template #default="{ row }">
                {{ row.category_name || '-' }}
              </template>
            </el-table-column>
            <el-table-column label="状态" width="90" align="center">
              <template #default="{ row }">
                <el-tag 
                  :type="row.enable_state === 2 ? 'success' : row.enable_state === 3 ? 'danger' : 'info'"
                  size="small"
                >
                  {{ row.enable_state === 2 ? '已启用' : row.enable_state === 3 ? '已停用' : row.enable_state === 1 ? '未启用' : '未知' }}
                </el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="similarity_score" label="相似度" width="120" align="center">
              <template #default="{ row }">
                <el-text 
                  :type="getSimilarityTextType(row.similarity_score)"
                  style="font-weight: 600; font-size: 14px"
                >
                  {{ (row.similarity_score * 100).toFixed(1) }}%
                </el-text>
              </template>
            </el-table-column>
          </el-table>
          <el-empty v-else description="未找到相似物料" />
        </el-card>
      </div>

      <template #footer>
        <el-button @click="detailDialogVisible = false">关闭</el-button>
        <el-button type="primary" @click="handleExportSingleResult">
          <el-icon><Download /></el-icon>
          导出此物料查重结果
        </el-button>
      </template>
    </el-dialog>
      </el-tab-pane>

      <!-- Tab 2: 快速查询 - 对应 [T.1.2] 完整快速查询流程 -->
      <el-tab-pane label="快速查询 ⚡" name="quick">
        <QuickQueryForm 
          :is-loading="isProcessing"
          @query="handleQuickQuery"
        />
      </el-tab-pane>
    </el-tabs>

    <!-- 结果展示区域（两种模式共用） - 对应 [T.1.5] 结果展示一致性 -->
    <div v-if="hasResults" style="margin-top: 30px">
      <el-card shadow="hover">
        <template #header>
          <div style="display: flex; justify-content: space-between; align-items: center">
            <h3>查重结果</h3>
            <div>
              <el-button type="primary" @click="handleExport">
                <el-icon><Download /></el-icon>
                导出结果
              </el-button>
              <el-button @click="resetSearch">
                <el-icon><RefreshLeft /></el-icon>
                重新查重
              </el-button>
            </div>
          </div>
        </template>

        <!-- 统计信息 -->
        <el-alert
          title="处理完成"
          type="success"
          :closable="false"
          show-icon
          style="margin-bottom: 20px"
        >
          <template #default>
            共处理 {{ totalProcessed }} 条记录，
            成功 {{ successCount }} 条，
            找到匹配 {{ hasMatchCount }} 条，
            无匹配 {{ noMatchCount }} 条
          </template>
        </el-alert>

        <!-- 结果表格 -->
        <div class="results-table">
          <el-table
            :data="paginatedResults"
            border
            stripe
            style="width: 100%"
            @row-dblclick="handleRowDoubleClick"
            :row-style="{ cursor: 'pointer' }"
          >
            <el-table-column type="index" label="序号" width="60" align="center" />
            <el-table-column label="物料名称" min-width="180" show-overflow-tooltip>
              <template #default="{ row }">
                {{ getInputData(row.input_data).name }}
              </template>
            </el-table-column>
            <el-table-column label="规格型号" min-width="150" show-overflow-tooltip>
              <template #default="{ row }">
                {{ getInputData(row.input_data).spec }}
              </template>
            </el-table-column>
            <el-table-column label="单位" width="80" align="center">
              <template #default="{ row }">
                {{ getInputData(row.input_data).unit }}
              </template>
            </el-table-column>
            <el-table-column label="推荐分类" width="120" align="center">
              <template #default="{ row }">
                <el-tag v-if="row.parsed_query?.detected_category" type="success" size="small">
                  {{ row.parsed_query.detected_category }}
                </el-tag>
                <span v-else style="color: #909399; font-size: 12px">未识别</span>
              </template>
            </el-table-column>
            <el-table-column label="置信度" width="100" align="center">
              <template #default="{ row }">
                <el-text 
                  v-if="row.parsed_query?.confidence !== undefined" 
                  type="success"
                  style="font-weight: 600"
                >
                  {{ (row.parsed_query.confidence * 100).toFixed(1) }}%
                </el-text>
                <span v-else style="color: #909399">-</span>
              </template>
            </el-table-column>
            <el-table-column label="查重结论" width="120" align="center">
              <template #default="{ row }">
                <el-tag :type="getDuplicateConclusion(row).type" size="small">
                  {{ getDuplicateConclusion(row).text }}
                </el-tag>
              </template>
            </el-table-column>
            <el-table-column label="匹配数" width="90" align="center">
              <template #default="{ row }">
                {{ row.similar_materials?.length || 0 }}
              </template>
            </el-table-column>
            <el-table-column label="最高相似度" width="120" align="center">
              <template #default="{ row }">
                <el-text 
                  v-if="row.similar_materials && row.similar_materials.length > 0"
                  type="primary"
                  style="font-weight: 600"
                >
                  {{ (row.similar_materials[0].similarity_score * 100).toFixed(1) }}%
                </el-text>
                <span v-else style="color: #909399">-</span>
              </template>
            </el-table-column>
          </el-table>

          <!-- 分页 -->
          <div style="margin-top: 20px; display: flex; justify-content: flex-end">
            <el-pagination
              :current-page="currentPage"
              :page-size="pageSize"
              :page-sizes="[10, 20, 50, 100]"
              :total="allResults.length"
              layout="total, sizes, prev, pager, next, jumper"
              @size-change="handleSizeChange"
              @current-change="handleCurrentChange"
            />
          </div>
        </div>
      </el-card>
    </div>

    <!-- 详情弹窗（两种模式共用） -->
    <el-dialog
      v-model="detailDialogVisible"
      title="物料详情"
      width="900px"
      :close-on-click-modal="false"
    >
      <el-card shadow="never" v-if="selectedRow">
        <template #header>
          <h3>📋 输入物料信息</h3>
        </template>
        <el-descriptions :column="2" border>
          <el-descriptions-item label="物料名称">
            {{ getInputData(selectedRow.input_data).name }}
          </el-descriptions-item>
          <el-descriptions-item label="规格型号">
            {{ getInputData(selectedRow.input_data).spec }}
          </el-descriptions-item>
          <el-descriptions-item label="单位">
            {{ getInputData(selectedRow.input_data).unit }}
          </el-descriptions-item>
          <el-descriptions-item label="分类">
            {{ getInputData(selectedRow.input_data).category }}
          </el-descriptions-item>
          <el-descriptions-item label="推荐分类">
            <el-tag v-if="selectedRow.parsed_query?.detected_category" type="success">
              {{ selectedRow.parsed_query.detected_category }}
            </el-tag>
            <span v-else style="color: #909399">未识别到分类</span>
          </el-descriptions-item>
          <el-descriptions-item label="分类置信度">
            <el-text 
              v-if="selectedRow.parsed_query?.confidence !== undefined" 
              type="success"
              style="font-weight: 600"
            >
              {{ (selectedRow.parsed_query.confidence * 100).toFixed(1) }}%
            </el-text>
            <span v-else style="color: #909399">-</span>
          </el-descriptions-item>
          <el-descriptions-item label="查重结论" :span="2">
            <el-tag 
              :type="getDuplicateConclusion(selectedRow).type" 
              size="large"
              effect="dark"
            >
              {{ getDuplicateConclusion(selectedRow).text }}
            </el-tag>
            <el-text type="info" size="small" style="margin-left: 10px">
              {{ getDuplicateConclusion(selectedRow).description }}
            </el-text>
          </el-descriptions-item>
        </el-descriptions>
      </el-card>

      <!-- 匹配物料列表 -->
      <el-card shadow="never" class="matches-card" style="margin-top: 20px" v-if="selectedRow">
        <template #header>
          <h3>🔍 ERP相似物料（前5条）</h3>
        </template>
        <el-table 
          v-if="selectedRow.similar_materials?.length > 0"
          :data="selectedRow.similar_materials.slice(0, 5)" 
          border
          stripe
          style="width: 100%"
        >
          <el-table-column type="index" label="排名" width="60" align="center" />
          <el-table-column label="物料编码" width="150" show-overflow-tooltip>
            <template #default="{ row }">
              {{ row.erp_code }}
            </template>
          </el-table-column>
          <el-table-column label="物料名称" min-width="180" show-overflow-tooltip>
            <template #default="{ row }">
              {{ row.material_name }}
            </template>
          </el-table-column>
          <el-table-column label="规格" min-width="150" show-overflow-tooltip>
            <template #default="{ row }">
              {{ row.specification || '-' }}
            </template>
          </el-table-column>
          <el-table-column label="型号" min-width="120" show-overflow-tooltip>
            <template #default="{ row }">
              {{ row.model || '-' }}
            </template>
          </el-table-column>
          <el-table-column label="单位" width="80" align="center">
            <template #default="{ row }">
              {{ row.unit_name || '-' }}
            </template>
          </el-table-column>
          <el-table-column label="原分类" width="120" align="center" show-overflow-tooltip>
            <template #default="{ row }">
              {{ row.category_name || '-' }}
            </template>
          </el-table-column>
          <el-table-column label="状态" width="90" align="center">
            <template #default="{ row }">
              <el-tag 
                :type="row.enable_state === 2 ? 'success' : row.enable_state === 3 ? 'danger' : 'info'"
                size="small"
              >
                {{ row.enable_state === 2 ? '已启用' : row.enable_state === 3 ? '已停用' : row.enable_state === 1 ? '未启用' : '未知' }}
              </el-tag>
            </template>
          </el-table-column>
          <el-table-column label="相似度" width="100" align="center">
            <template #default="{ row }">
              <el-text type="primary" style="font-weight: 600; font-size: 14px">
                {{ (row.similarity_score * 100).toFixed(1) }}%
              </el-text>
            </template>
          </el-table-column>
        </el-table>
        <el-empty 
          v-else 
          description="未找到相似物料"
          :image-size="80"
        />
      </el-card>

      <template #footer>
        <el-button @click="detailDialogVisible = false">关闭</el-button>
        <el-button type="primary" @click="handleExportSingleResult">
          <el-icon><Download /></el-icon>
          导出此物料查重结果
        </el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
/**
 * @component 物料查重主页面
 * @description 提供批量查重和快速查询两种模式，复用核心查重逻辑和结果展示组件
 * 
 * 关联测试点 (Associated Test Points):
 * - [T.1.1] - 标签页切换功能
 * - [T.1.2] - 完整快速查询流程
 * - [T.1.5] - 结果展示一致性
 */

import { ref, computed, nextTick } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { ArrowRight, ArrowLeft, Search, Download, RefreshLeft, Loading } from '@element-plus/icons-vue'
import FileUpload from '@/components/MaterialSearch/FileUpload.vue'
import ColumnConfig from '@/components/MaterialSearch/ColumnConfig.vue'
import UploadProgress from '@/components/MaterialSearch/UploadProgress.vue'
import QuickQueryForm from '@/components/MaterialSearch/QuickQueryForm.vue'
import type { ColumnMapping } from '@/components/MaterialSearch/ColumnConfig.vue'
import { useMaterialStore } from '@/stores'
import * as XLSX from 'xlsx'

const materialStore = useMaterialStore()

// ==================== Tab控制 ====================
// 对应 [T.1.1] - 标签页切换功能
// 为什么使用 ref 而不是其他状态管理：Tab切换是页面级别的UI状态，使用本地ref即可
const activeTab = ref<'batch' | 'quick'>('batch')

// 组件引用
const fileUploadRef = ref()
const columnConfigRef = ref()

// 步骤控制
const currentStep = ref(0)

// 文件相关
const selectedFile = ref<File | null>(null)
const sampleData = ref<any[]>([])
const availableColumns = ref<string[]>([])
const hasFile = ref(false)

// 配置相关
const columnConfig = ref<ColumnMapping>({
  materialName: '',
  specification: '',
  unitName: ''
})
const isConfigValid = ref(false)
const isAutoDetecting = ref(false)  // 优化2: 自动检测标志

// 处理相关
const uploadProgress = ref(0)
const uploadSpeed = ref(0)
const processedItems = ref(0)
const totalItems = ref(0)
const currentStepText = ref('')

// 结果相关
const batchResults = ref<any>(null)
const activeNames = ref<number[]>([])

// 详情弹窗相关
const detailDialogVisible = ref(false)
const selectedRow = ref<any>(null)

// 优化4: 分页相关
const currentPage = ref(1)
const pageSize = ref(20)  // 默认每页20条

// ==================== 计算属性 ====================
// 统一从 materialStore 获取数据（单一数据源）
const hasResults = computed(() => materialStore.hasResults)
const isProcessing = computed(() => materialStore.isProcessing)
const currentResults = computed(() => materialStore.batchResults?.results || [])
const allResults = computed(() => materialStore.batchResults?.results || [])

// 优化4: 分页后的结果
const paginatedResults = computed(() => {
  const start = (currentPage.value - 1) * pageSize.value
  const end = start + pageSize.value
  return allResults.value.slice(start, end)
})

const totalProcessed = computed(() => currentResults.value.length)

const successCount = computed(() => 
  currentResults.value.filter(r => r.similar_materials && r.similar_materials.length > 0).length
)

const hasMatchCount = computed(() => successCount.value)

const noMatchCount = computed(() => totalProcessed.value - successCount.value)

const processingTime = computed(() => {
  const time = materialStore.batchResults?.processing_time
  return time ? (time / 1000).toFixed(2) : '0.00'
})

// ==================== 分页处理方法 ====================

/**
 * 处理每页数量变化
 */
const handleSizeChange = (val: number) => {
  pageSize.value = val
  currentPage.value = 1  // 重置到第一页
}

/**
 * 处理当前页码变化
 */
const handleCurrentChange = (val: number) => {
  currentPage.value = val
}

// ==================== 辅助函数 ====================

/**
 * 获取物料输入数据（统一字段访问）
 */
const getInputData = (inputData: any) => {
  return {
    name: inputData.name || inputData.material_name || '',
    spec: inputData.spec || inputData.specification || '',
    unit: inputData.unit || inputData.unit_name || '',
    category: inputData.category || inputData.category_name || ''
  }
}

/**
 * 获取查重结论
 * 三级判定标准（优先级从高到低）：
 * 1. 清洗后名称 + 规格型号 + 单位 完全匹配 → 重复
 * 2. 清洗后名称 + 规格型号完全匹配，但单位不匹配 → 疑是重复
 * 3. 相似度 >= 90% → 疑是重复
 */
const getDuplicateConclusion = (row: any): { type: 'success' | 'danger' | 'warning', text: string, description: string } => {
  if (!row.similar_materials || row.similar_materials.length === 0) {
    return {
      type: 'success' as const,
      text: '不重复',
      description: '未找到相似物料，可以创建新物料'
    }
  }
  
  // 获取最高相似度
  const highestScore = row.similar_materials[0].similarity_score
  const topMatch = row.similar_materials[0]
  
  // 获取输入数据（使用对称处理后的数据进行对比）
  // ✅ 对称原则：使用 full_description（13条规则+同义词替换后的完整描述）
  const inputFullDesc = (row.parsed_query?.full_description || '').trim().toLowerCase()
  const inputUnit = (row.parsed_query?.cleaned_unit || '').trim().toLowerCase()
  
  // 遍历相似物料，检查完全匹配
  for (const material of row.similar_materials) {
    // ✅ ERP的 full_description 已经过13条规则+同义词替换，与输入完全对称
    const erpFullDesc = (material.full_description || '').trim().toLowerCase()
    const erpUnit = (material.unit_name || '').trim().toLowerCase()
    
    // 判定标准1：完整描述 + 单位 完全匹配 → 重复
    // ✅ 对称处理：full_description都经过13条规则+同义词替换，实现语义等价匹配
    if (inputFullDesc && erpFullDesc && 
        inputFullDesc === erpFullDesc && 
        inputUnit === erpUnit) {
      return {
        type: 'danger' as const,
        text: '重复',
        description: `完全匹配：名称、规格、单位完全相同（编码：${material.erp_code}）`
      }
    }
    
    // 判定标准2：完整描述匹配，但单位不匹配 → 疑是重复
    if (inputFullDesc && erpFullDesc && 
        inputFullDesc === erpFullDesc && 
        inputUnit !== erpUnit) {
      return {
        type: 'warning' as const,
        text: '疑是重复',
        description: `部分匹配：名称和规格相同，但单位不同（编码：${material.erp_code}，ERP单位：${erpUnit || '无'}，输入单位：${inputUnit || '无'}）`
      }
    }
  }
  
  // 判定标准3：相似度 >= 90% → 疑是重复
  if (highestScore >= 0.9) {
    return {
      type: 'warning' as const,
      text: '疑是重复',
      description: `高度相似：相似度${(highestScore * 100).toFixed(1)}%（编码：${topMatch.erp_code}）`
    }
  }
  
  // 不满足任何重复标准
  return {
    type: 'success' as const,
    text: '不重复',
    description: `最高相似度${(highestScore * 100).toFixed(1)}%，未达到重复标准`
  }
}

/**
 * 获取相似度文本类型（用于el-text的type属性）
 */
const getSimilarityTextType = (score: number) => {
  if (score >= 0.9) return 'danger'   // 红色 - 高度相似
  if (score >= 0.7) return 'warning'  // 橙色 - 中度相似
  return 'success'                     // 绿色 - 低度相似
}

// ==================== 事件处理方法 ====================

/**
 * 处理快速查询
 * 对应 [T.1.2] - 完整快速查询流程
 * 对应 [T.1.4] - 列名映射正确性
 * 
 * @param file - QuickQueryForm生成的临时Excel文件
 * @param columnMapping - 列名映射配置
 */
const handleQuickQuery = async (file: File, columnMapping: any) => {
  try {
    // 为什么直接调用uploadAndSearch：快速查询复用批量查重的全部逻辑，无需重复实现
    // 为什么不需要重置步骤：快速查询不使用步骤导航，直接显示结果
    
    // 转换列名映射格式为Store期望的格式
    // 关键修复：传递Excel中的列名（即中文列名），而不是字段映射
    const storeColumnMapping = {
      material_name: columnMapping.materialName,  // "物料名称"
      specification: columnMapping.specification, // "规格型号"
      unit_name: columnMapping.unitName           // "单位"
    }
    
    await materialStore.uploadAndSearch(file, storeColumnMapping)
    
    if (materialStore.batchResults && materialStore.batchResults.results.length > 0) {
      ElMessage.success('查询完成！')
    } else {
      ElMessage.warning('未找到结果')
    }
  } catch (error: any) {
    ElMessage.error(error.message || '查询失败')
  }
}

/**
 * 文件选择成功
 */
const handleFileSelected = (file: File, data: any[]) => {
  selectedFile.value = file
  sampleData.value = data
  hasFile.value = true

  // 提取列名
  if (data.length > 0) {
    availableColumns.value = Object.keys(data[0])
  }

  // 优化1: 只保留一个提示消息（移除此处的ElMessage）
}

/**
 * 文件移除
 */
const handleFileRemoved = () => {
  selectedFile.value = null
  sampleData.value = []
  availableColumns.value = []
  hasFile.value = false
  currentStep.value = 0
  batchResults.value = null
  
  ElMessage.info({
    message: '📁 文件已移除，您可以重新上传',
    duration: 2000
  })
}

/**
 * 上传错误
 */
const handleUploadError = (error: string) => {
  ElMessage.error({
    message: `❌ 文件上传失败：${error}`,
    duration: 5000,
    showClose: true
  })
}

/**
 * 配置变更
 */
const handleConfigChanged = (config: ColumnMapping) => {
  columnConfig.value = config
}

/**
 * 配置验证
 */
const handleConfigValid = (valid: boolean) => {
  isConfigValid.value = valid
}

/**
 * 跳转步骤
 * 优化2: 进入第2步时自动触发检测
 */
const goToStep = async (step: number) => {
  currentStep.value = step
  
  // 优化2: 进入列名配置页面时，先显示自动检测中
  if (step === 1) {
    isAutoDetecting.value = true
    
    // 模拟自动检测过程（1.5秒）
    await new Promise(resolve => setTimeout(resolve, 1500))
    
    isAutoDetecting.value = false
    
    // 等待DOM更新后，调用ColumnConfig组件的autoDetect方法
    await nextTick()
    if (columnConfigRef.value) {
      // 触发自动检测
      columnConfigRef.value.autoDetect()
    }
  }
}

/**
 * 开始查重
 */
const startSearch = async () => {
  if (!selectedFile.value) {
    ElMessage.warning({
      message: '⚠️ 请先选择要查重的Excel文件',
      duration: 3000
    })
    return
  }

  currentStep.value = 2
  uploadProgress.value = 0
  processedItems.value = 0
  totalItems.value = sampleData.value.length

  try {
    // 模拟进度更新
    const progressSteps = [
      { progress: 20, text: '📤 正在上传文件到服务器...', delay: 300 },
      { progress: 40, text: '📊 正在解析Excel数据...', delay: 500 },
      { progress: 60, text: '正在标准化物料描述...', delay: 800 },
      { progress: 80, text: '🔍 正在ERP数据库中查询相似物料...', delay: 1000 }
    ]

    for (const step of progressSteps) {
      await new Promise(resolve => setTimeout(resolve, step.delay))
      uploadProgress.value = step.progress
      currentStepText.value = step.text
      processedItems.value = Math.floor((step.progress / 100) * totalItems.value)
    }

    // 调用 materialStore
    const response = await materialStore.uploadAndSearch(
      selectedFile.value,
      {
        material_name: columnConfig.value.materialName,
        specification: columnConfig.value.specification,
        unit_name: columnConfig.value.unitName
      }
    )

    uploadProgress.value = 100
    currentStepText.value = '✅ 处理完成！正在准备结果...'
    batchResults.value = response

    // 等待一下让用户看到100%的进度
    await new Promise(resolve => setTimeout(resolve, 500))
    
    ElMessage.success({
      message: `🎉 查重完成！成功处理 ${response.total_processed} 条物料数据`,
      duration: 3000
    })
    
    // 自动跳转到结果页面
    handleComplete()
  } catch (error: any) {
    console.error('查重失败:', error)
    ElMessage.error({
      message: `❌ 查重失败：${error.message || '服务器处理出错，请检查网络连接或稍后重试'}`,
      duration: 5000,
      showClose: true
    })
    currentStep.value = 1  // 出错回到第二步（配置列名）
  }
}

/**
 * 暂停
 */
const handlePause = () => {
  ElMessage.info({
    message: 'ℹ️ 暂停功能开发中，敬请期待',
    duration: 2000
  })
}

/**
 * 继续
 */
const handleResume = () => {
  ElMessage.info({
    message: 'ℹ️ 继续功能开发中，敬请期待',
    duration: 2000
  })
}

/**
 * 取消
 */
const handleCancel = () => {
  uploadProgress.value = 0
  currentStep.value = 1
  ElMessage.warning({
    message: '⚠️ 已取消查重操作，您可以重新配置后再试',
    duration: 3000
  })
}

/**
 * 完成
 */
const handleComplete = () => {
  currentStep.value = 3
  
  // 自动展开所有结果
  if (currentResults.value.length > 0) {
    activeNames.value = currentResults.value.map((_: any, index: number) => index)
  }
}

/**
 * 导出结果
 * 优化5: 不重复的物料只导出推荐分类，不导出ERP推荐物料信息
 */
const handleExport = () => {
  if (currentResults.value.length === 0) {
    ElMessage.warning({
      message: '⚠️ 暂无数据可导出，请先完成查重',
      duration: 3000
    })
    return
  }

  try {
    const exportData = currentResults.value.map((item: any) => {
      const input = getInputData(item.input_data)
      const topMatch = item.similar_materials?.[0]
      const conclusion = getDuplicateConclusion(item)
      const isDuplicate = conclusion.text === '重复'
      
      // 优化5: 根据查重结论，决定是否导出ERP推荐信息
      const baseData = {
        '行号': item.row_number,
        '输入-物料名称': input.name,
        '输入-规格型号': input.spec,
        '输入-单位': input.unit,
        '输入-分类': input.category,
        '推荐分类': item.parsed_query?.detected_category || '',
        '分类置信度': item.parsed_query?.confidence !== undefined ? `${(item.parsed_query.confidence * 100).toFixed(1)}%` : '-',
        '查重结论': conclusion.text
      }
      
      // 只有重复的物料才导出ERP推荐信息
      if (isDuplicate) {
        return {
          ...baseData,
          '匹配数量': item.similar_materials?.length || 0,
          '最高相似度': topMatch ? `${(topMatch.similarity_score * 100).toFixed(1)}%` : '-',
          '推荐-ERP编码': topMatch?.erp_code || '',
          '推荐-物料名称': topMatch?.material_name || '',
          '推荐-规格型号': topMatch?.specification || '',
          '推荐-单位': topMatch?.unit_name || ''
        }
      } else {
        // 不重复的物料，ERP推荐列留空
        return {
          ...baseData,
          '匹配数量': '-',
          '最高相似度': '-',
          '推荐-ERP编码': '',
          '推荐-物料名称': '',
          '推荐-规格型号': '',
          '推荐-单位': ''
        }
      }
    })

    // 创建工作簿
    const ws = XLSX.utils.json_to_sheet(exportData)
    const wb = XLSX.utils.book_new()
    XLSX.utils.book_append_sheet(wb, ws, '查重结果')

    // 生成默认文件名
    const timestamp = new Date().toISOString().slice(0, 19).replace(/:/g, '-')
    const defaultFileName = `物料查重结果_${timestamp}.xlsx`

    // 使用File System Access API（如果支持）让用户选择保存位置
    if ('showSaveFilePicker' in window) {
      // 现代浏览器支持文件选择器
      ;(window as any).showSaveFilePicker({
        suggestedName: defaultFileName,
        types: [{
          description: 'Excel文件',
          accept: { 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet': ['.xlsx'] }
        }]
      }).then(async (fileHandle: any) => {
        const writable = await fileHandle.createWritable()
        const buffer = XLSX.write(wb, { type: 'buffer', bookType: 'xlsx' })
        await writable.write(buffer)
        await writable.close()
        
        ElMessage.success({
          message: `✅ 导出成功！文件已保存`,
          duration: 3000
        })
      }).catch((err: any) => {
        if (err.name !== 'AbortError') {
          console.error('Save file error:', err)
          ElMessage.warning({
            message: '⚠️ 取消保存或保存失败，请重试',
            duration: 3000
          })
        }
      })
    } else {
      // 降级方案：直接下载到浏览器默认下载目录
      XLSX.writeFile(wb, defaultFileName)
      
      ElMessage.success({
        message: `✅ 导出成功！文件已保存到下载文件夹：${defaultFileName}`,
        duration: 4000,
        showClose: true
      })
    }
  } catch (error: any) {
    console.error('Export error:', error)
    ElMessage.error({
      message: `❌ 导出失败：${error.message || '文件生成出错，请重试'}`,
      duration: 5000,
      showClose: true
    })
  }
}

/**
 * 重新查重
 */
const resetSearch = async () => {
  try {
    await ElMessageBox.confirm(
      '当前查重结果将被清空，确定要重新开始吗？',
      '⚠️ 重新查重确认',
      {
        confirmButtonText: '确定重新开始',
        cancelButtonText: '继续查看结果',
        type: 'warning',
        distinguishCancelAndClose: true
      }
    )
    
    selectedFile.value = null
    sampleData.value = []
    availableColumns.value = []
    hasFile.value = false
    currentStep.value = 0
    batchResults.value = null
    uploadProgress.value = 0
    activeNames.value = []
    
    // 优化4: 重置分页
    currentPage.value = 1
    pageSize.value = 20
    
    fileUploadRef.value?.clearFile()
    materialStore.clearResults()
    
    ElMessage.success({
      message: '✅ 已重置，请重新上传Excel文件开始查重',
      duration: 3000
    })
  } catch (action) {
    if (action === 'cancel') {
      ElMessage.info({
        message: 'ℹ️ 已取消，继续查看当前结果',
        duration: 2000
      })
    }
  }
}


/**
 * 双击表格行 - 显示详情
 */
const handleRowDoubleClick = (row: any) => {
  selectedRow.value = row
  detailDialogVisible.value = true
}

/**
 * 点击查看详情按钮
 */
const handleViewDetail = (row: any) => {
  selectedRow.value = row
  detailDialogVisible.value = true
}

/**
 * 导出单条物料查重结果
 * 优化5: 不重复的物料只导出推荐分类
 */
const handleExportSingleResult = () => {
  if (!selectedRow.value) return
  
  try {
    const input = getInputData(selectedRow.value.input_data)
    const conclusion = getDuplicateConclusion(selectedRow.value)
    const isDuplicate = conclusion.text === '重复'
    
    let exportData = []
    
    // 优化5: 根据查重结论决定导出内容
    if (isDuplicate) {
      // 重复物料：导出前5条ERP相似物料
      exportData = selectedRow.value.similar_materials?.slice(0, 5).map((item: any, index: number) => ({
        '排名': index + 1,
        '物料名称': input.name,
        '规格型号': input.spec,
        '单位': input.unit,
        '分类': input.category,
        '推荐分类': selectedRow.value.parsed_query?.detected_category || '',
        '分类置信度': selectedRow.value.parsed_query?.confidence !== undefined ? `${(selectedRow.value.parsed_query.confidence * 100).toFixed(1)}%` : '-',
        '查重结论': conclusion.text,
        'ERP编码': item.erp_code,
        'ERP物料名称': item.material_name,
        'ERP规格型号': item.specification,
        'ERP单位': item.unit_name,
        '相似度': `${(item.similarity_score * 100).toFixed(1)}%`
      })) || []
    } else {
      // 不重复物料：只导出基本信息和推荐分类
      exportData = [{
        '物料名称': input.name,
        '规格型号': input.spec,
        '单位': input.unit,
        '分类': input.category,
        '推荐分类': selectedRow.value.parsed_query?.detected_category || '',
        '分类置信度': selectedRow.value.parsed_query?.confidence !== undefined ? `${(selectedRow.value.parsed_query.confidence * 100).toFixed(1)}%` : '-',
        '查重结论': conclusion.text,
        '备注': '未找到相似物料，建议创建新物料'
      }]
    }
    
    const ws = XLSX.utils.json_to_sheet(exportData)
    const wb = XLSX.utils.book_new()
    XLSX.utils.book_append_sheet(wb, ws, '查重详情')
    
    const timestamp = new Date().toISOString().slice(0, 19).replace(/:/g, '-')
    const defaultFileName = `物料查重详情_${input.name}_${timestamp}.xlsx`
    
    // 使用File System Access API（如果支持）
    if ('showSaveFilePicker' in window) {
      ;(window as any).showSaveFilePicker({
        suggestedName: defaultFileName,
        types: [{
          description: 'Excel文件',
          accept: { 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet': ['.xlsx'] }
        }]
      }).then(async (fileHandle: any) => {
        const writable = await fileHandle.createWritable()
        const buffer = XLSX.write(wb, { type: 'buffer', bookType: 'xlsx' })
        await writable.write(buffer)
        await writable.close()
        
        ElMessage.success({
          message: `✅ 导出成功！文件已保存`,
          duration: 3000
        })
      }).catch((err: any) => {
        if (err.name !== 'AbortError') {
          console.error('Save file error:', err)
          ElMessage.warning({
            message: '⚠️ 取消保存或保存失败，请重试',
            duration: 3000
          })
        }
      })
    } else {
      // 降级方案
      XLSX.writeFile(wb, defaultFileName)
      
      ElMessage.success({
        message: `✅ 导出成功！文件已保存到下载文件夹：${defaultFileName}`,
        duration: 4000,
        showClose: true
      })
    }
  } catch (error: any) {
    console.error('Export error:', error)
    ElMessage.error({
      message: `❌ 导出失败：${error.message || '文件生成出错，请重试'}`,
      duration: 5000,
      showClose: true
    })
  }
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
  text-align: center;

  h1 {
    font-size: 28px;
    font-weight: 600;
    color: #303133;
    margin-bottom: 8px;
  }

  p {
    color: #909399;
    font-size: 14px;
  }
}

// Tab 样式
.search-tabs {
  margin-bottom: 20px;

  :deep(.el-tabs__item) {
    font-size: 16px;
    font-weight: 500;
  }
}

.results-table {
  margin-top: 20px;

  .table-footer {
    margin-top: 15px;
    text-align: center;
    padding: 10px;
    background: #f5f7fa;
    border-radius: 4px;
  }
}

.detail-dialog {
  .input-card,
  .matches-card {
    h3 {
      margin: 0;
      font-size: 16px;
      font-weight: 600;
      color: #303133;
    }
  }
}
</style>

