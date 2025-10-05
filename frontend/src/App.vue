<template>
  <router-view />
</template>

<script setup lang="ts">
import { onMounted } from 'vue'
import { useRouter } from 'vue-router'

const router = useRouter()

onMounted(() => {
  // 设置页面标题
  document.title = import.meta.env.VITE_APP_TITLE
})
</script>

<style scoped>
/* App 全局样式 */
</style>
