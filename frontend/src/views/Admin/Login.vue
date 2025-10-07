<template>
  <div class="login-container">
    <el-card class="login-card" shadow="always">
      <template #header>
        <div class="card-header">
          <el-icon :size="40" color="#409eff"><Lock /></el-icon>
          <h2>管理员登录</h2>
        </div>
      </template>

      <el-form
        ref="loginFormRef"
        :model="loginForm"
        :rules="rules"
        @submit.prevent="handleLogin"
      >
        <el-form-item prop="password">
          <el-input
            v-model="loginForm.password"
            type="password"
            placeholder="请输入管理员密码"
            size="large"
            show-password
            @keyup.enter="handleLogin"
          >
            <template #prefix>
              <el-icon><Lock /></el-icon>
            </template>
          </el-input>
        </el-form-item>

        <el-form-item>
          <el-button
            type="primary"
            size="large"
            :loading="loading"
            @click="handleLogin"
            style="width: 100%"
          >
            {{ loading ? '登录中...' : '登录' }}
          </el-button>
        </el-form-item>
      </el-form>

      <div class="login-tips">
        <el-alert
          title="提示"
          type="info"
          :closable="false"
          show-icon
        >
          <p>默认密码：<code>admin123</code></p>
          <p style="margin-top: 8px; font-size: 12px; color: #909399;">
            生产环境请立即修改密码
          </p>
        </el-alert>
      </div>
    </el-card>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage, type FormInstance, type FormRules } from 'element-plus'
import { useAuthStore } from '@/stores/auth'

const router = useRouter()
const authStore = useAuthStore()

// 表单引用
const loginFormRef = ref<FormInstance>()

// 表单数据
const loginForm = reactive({
  password: ''
})

// 加载状态
const loading = ref(false)

// 表单验证规则
const rules: FormRules = {
  password: [
    { required: true, message: '请输入管理员密码', trigger: 'blur' },
    { min: 6, message: '密码长度不能少于6位', trigger: 'blur' }
  ]
}

/**
 * 处理登录
 */
const handleLogin = async () => {
  if (!loginFormRef.value) return

  await loginFormRef.value.validate(async (valid) => {
    if (!valid) return

    loading.value = true

    try {
      // 模拟网络延迟
      await new Promise(resolve => setTimeout(resolve, 500))

      // 调用登录
      const success = authStore.login(loginForm.password)

      if (success) {
        ElMessage.success('登录成功')
        // 跳转到管理后台
        router.push('/admin')
      } else {
        ElMessage.error('密码错误，请重试')
        loginForm.password = ''
      }
    } catch (error) {
      ElMessage.error('登录失败，请稍后重试')
    } finally {
      loading.value = false
    }
  })
}
</script>

<style scoped lang="scss">
.login-container {
  display: flex;
  align-items: center;
  justify-content: center;
  min-height: 100vh;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  padding: 20px;
}

.login-card {
  width: 100%;
  max-width: 400px;

  .card-header {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 16px;

    h2 {
      margin: 0;
      font-size: 24px;
      font-weight: 600;
      color: #303133;
    }
  }

  :deep(.el-card__body) {
    padding-top: 30px;
  }
}

.login-tips {
  margin-top: 20px;

  code {
    padding: 2px 8px;
    background: #f5f7fa;
    border-radius: 4px;
    font-family: 'Courier New', monospace;
    color: #409eff;
    font-weight: 600;
  }
}
</style>

