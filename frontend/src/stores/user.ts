import { defineStore } from 'pinia'
import { ref } from 'vue'

export interface UserInfo {
  id: string
  username: string
  email?: string
  role?: string
}

export const useUserStore = defineStore('user', () => {
  // State
  const userInfo = ref<UserInfo | null>(null)
  const token = ref<string>('')
  const isLoggedIn = ref(false)

  // Actions
  const setUserInfo = (info: UserInfo) => {
    userInfo.value = info
    isLoggedIn.value = true
  }

  const setToken = (newToken: string) => {
    token.value = newToken
    localStorage.setItem('access_token', newToken)
  }

  const logout = () => {
    userInfo.value = null
    token.value = ''
    isLoggedIn.value = false
    localStorage.removeItem('access_token')
  }

  const loadUserFromStorage = () => {
    const storedToken = localStorage.getItem('access_token')
    if (storedToken) {
      token.value = storedToken
      // TODO: 从后端验证 token 并加载用户信息
      console.log('从存储加载用户信息（待实现）')
    }
  }

  return {
    // State
    userInfo,
    token,
    isLoggedIn,

    // Actions
    setUserInfo,
    setToken,
    logout,
    loadUserFromStorage
  }
})
