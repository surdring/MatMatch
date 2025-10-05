<template>
  <div class="admin-panel-container">
    <div class="page-header">
      <h1>管理后台</h1>
      <p>规则管理、同义词管理、ETL监控（功能开发中）</p>
    </div>

    <el-card>
      <el-tabs v-model="activeTab">
        <el-tab-pane label="提取规则" name="rules">
          <el-empty description="提取规则管理功能开发中" />
        </el-tab-pane>

        <el-tab-pane label="同义词词典" name="synonyms">
          <el-empty description="同义词管理功能开发中" />
        </el-tab-pane>

        <el-tab-pane label="物料分类" name="categories">
          <el-empty description="物料分类管理功能开发中" />
        </el-tab-pane>

        <el-tab-pane label="ETL监控" name="etl">
          <el-empty description="ETL监控功能开发中" />
        </el-tab-pane>
      </el-tabs>
    </el-card>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'

const activeTab = ref('rules')
</script>

<style scoped lang="scss">
.admin-panel-container {
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
</style>
