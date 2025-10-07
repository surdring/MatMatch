/**
 * 认证状态管理
 * 
 * 管理管理员登录状态和权限验证
 */

import { defineStore } from 'pinia'
import { ref, computed } from 'vue'

export const useAuthStore = defineStore('auth', () => {
  // State
  const isAuthenticated = ref<boolean>(false)
  const adminPassword = ref<string>('') // 临时存储，实际应该从后端获取

  // 从localStorage恢复登录状态
  const storedAuth = localStorage.getItem('admin_authenticated')
  if (storedAuth === 'true') {
    isAuthenticated.value = true
  }

  // Getters
  const isAdmin = computed(() => isAuthenticated.value)

  // Actions
  
  /**
   * 管理员登录
   * 
   * @param password - 管理员密码
   * @returns 是否登录成功
   */
  const login = (password: string): boolean => {
    // TODO: 后续应该调用后端API验证
    // 目前使用简单的硬编码密码
    const ADMIN_PASSWORD = 'admin123' // 临时密码，生产环境应该从环境变量或后端获取
    
    if (password === ADMIN_PASSWORD) {
      isAuthenticated.value = true
      localStorage.setItem('admin_authenticated', 'true')
      return true
    }
    
    return false
  }

  /**
   * 管理员登出
   */
  const logout = () => {
    isAuthenticated.value = false
    localStorage.removeItem('admin_authenticated')
  }

  /**
   * 检查是否已登录
   */
  const checkAuth = (): boolean => {
    return isAuthenticated.value
  }

  return {
    // State
    isAuthenticated,
    
    // Getters
    isAdmin,
    
    // Actions
    login,
    logout,
    checkAuth
  }
})

