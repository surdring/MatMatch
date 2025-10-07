/**
 * 系统管理相关API
 * 
 * 提供系统健康检查、监控等管理功能
 */

import axios from 'axios'

/**
 * 系统健康状态
 */
export interface SystemHealth {
  status: 'healthy' | 'degraded' | 'unhealthy'
  timestamp: string
  version: string
  database: string
  knowledge_base: string
}

/**
 * 系统就绪状态
 */
export interface SystemReadiness {
  ready: boolean
  checks: {
    database: string
    material_processor: string
    knowledge_base: string
  }
  timestamp: string
}

// 创建专用的axios实例，不使用通用的响应拦截器
const systemHttp = axios.create({
  baseURL: '', // 使用相对路径，让Vite proxy处理
  timeout: 10000
})

export const systemApi = {
  /**
   * 获取系统健康状态
   */
  async getHealth(): Promise<{ data: SystemHealth }> {
    const response = await systemHttp.get<SystemHealth>('/api/v1/health')
    return { data: response.data }
  },

  /**
   * 获取系统就绪状态
   */
  async getReadiness(): Promise<{ data: SystemReadiness }> {
    const response = await systemHttp.get<SystemReadiness>('/api/v1/health/readiness')
    return { data: response.data }
  },

  /**
   * 存活检查（简单的ping）
   */
  async getLiveness(): Promise<{ data: { alive: boolean; timestamp: string } }> {
    const response = await systemHttp.get<{ alive: boolean; timestamp: string }>('/api/v1/health/liveness')
    return { data: response.data }
  }
}

