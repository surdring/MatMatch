import axios from 'axios'
import type { AxiosInstance, AxiosRequestConfig, AxiosResponse, AxiosError } from 'axios'
import { ElMessage } from 'element-plus'

// 响应数据接口
export interface ApiResponse<T = any> {
  success: boolean
  data: T
  message?: string
  error_code?: string
}

// 创建 axios 实例
const service: AxiosInstance = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL,
  timeout: 300000, // 增加到300秒（5分钟），处理大批量数据和并发查重
  headers: {
    'Content-Type': 'application/json'
  }
})

// 请求拦截器
service.interceptors.request.use(
  (config: any) => {
    // 添加请求 ID（用于追踪）
    config.headers['X-Request-ID'] = `req_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`

    // 添加 token（如果存在）
    const token = localStorage.getItem('access_token')
    if (token) {
      config.headers['Authorization'] = `Bearer ${token}`
    }

    // [Task 4.5] 管理后台API Token认证
    // 技术债：开发环境使用测试Token，生产环境需实现完整认证系统
    if (config.url?.startsWith('/api/v1/admin')) {
      // 优先使用环境变量中的测试Token
      const adminToken = import.meta.env.VITE_ADMIN_TOKEN || 'admin_dev_token_change_in_production'
      config.headers['Authorization'] = `Bearer ${adminToken}`
      
      // 可选：添加X-API-Key作为备用认证方式
      config.headers['X-API-Key'] = adminToken
    }

    // 调试信息
    if (import.meta.env.VITE_SHOW_DEBUG === 'true') {
      console.log('[Request]', config.method?.toUpperCase(), config.url, config.data || config.params)
    }

    return config
  },
  (error: AxiosError) => {
    console.error('[Request Error]', error)
    return Promise.reject(error)
  }
)

// 响应拦截器
service.interceptors.response.use(
  (response: AxiosResponse<ApiResponse>) => {
    const res = response.data

    // 调试信息
    if (import.meta.env.VITE_SHOW_DEBUG === 'true') {
      console.log('[Response]', response.config.url, res)
    }

    // 如果后端直接返回数据（没有 success 字段），包装成标准格式
    if (res.success === undefined) {
      // 特殊API：批量查重、统计信息等直接返回数据
      if (res.total_processed !== undefined || res.total_materials !== undefined) {
        return {
          success: true,
          data: res,
          message: 'success'
        } as ApiResponse
      }
      
      // 管理API：分页响应（包含 items、total 等字段）
      if (res.items !== undefined || res.total !== undefined) {
        return {
          success: true,
          data: res,
          message: 'success'
        } as ApiResponse
      }
    }

    // 处理成功响应
    if (res.success !== false) {
      return res
    }

    // 处理业务错误
    const errorMessage = res.message || '请求失败'
    ElMessage.error(errorMessage)
    return Promise.reject(new Error(errorMessage))
  },
  (error: AxiosError<ApiResponse>) => {
    console.error('[Response Error]', error)

    // 处理 HTTP 错误
    if (error.response) {
      const { status, data } = error.response
      let message = data?.message || '服务器错误'

      switch (status) {
        case 400:
          message = data?.message || '请求参数错误'
          break
        case 401:
          message = '未授权，请重新登录'
          // TODO: 跳转到登录页
          break
        case 403:
          message = '拒绝访问'
          break
        case 404:
          message = '请求的资源不存在'
          break
        case 500:
          message = '服务器内部错误'
          break
        case 503:
          message = '服务暂时不可用'
          break
        default:
          message = `请求失败 (${status})`
      }

      ElMessage.error(message)
      return Promise.reject(error)
    }

    // 处理网络错误
    if (error.message.includes('timeout')) {
      ElMessage.error('请求超时，请稍后重试')
    } else if (error.message.includes('Network Error')) {
      ElMessage.error('网络连接失败，请检查网络')
    } else {
      ElMessage.error('请求失败，请稍后重试')
    }

    return Promise.reject(error)
  }
)

// 导出请求方法
export const request = {
  get<T = any>(url: string, config?: AxiosRequestConfig): Promise<ApiResponse<T>> {
    return service.get(url, config)
  },

  post<T = any>(url: string, data?: any, config?: AxiosRequestConfig): Promise<ApiResponse<T>> {
    return service.post(url, data, config)
  },

  put<T = any>(url: string, data?: any, config?: AxiosRequestConfig): Promise<ApiResponse<T>> {
    return service.put(url, data, config)
  },

  delete<T = any>(url: string, config?: AxiosRequestConfig): Promise<ApiResponse<T>> {
    return service.delete(url, config)
  },

  upload<T = any>(url: string, formData: FormData, onProgress?: (progress: number) => void): Promise<ApiResponse<T>> {
    return service.post(url, formData, {
      headers: {
        'Content-Type': 'multipart/form-data'
      },
      onUploadProgress: (progressEvent) => {
        if (onProgress && progressEvent.total) {
          const progress = Math.round((progressEvent.loaded * 100) / progressEvent.total)
          onProgress(progress)
        }
      }
    })
  }
}

export default service
