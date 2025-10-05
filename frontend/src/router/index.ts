import { createRouter, createWebHistory } from 'vue-router'
import type { RouteRecordRaw } from 'vue-router'

const routes: RouteRecordRaw[] = [
  {
    path: '/',
    name: 'home',
    component: () => import('@/views/Home.vue'),
    meta: {
      title: '首页'
    }
  },
  {
    path: '/search',
    name: 'material-search',
    component: () => import('@/views/MaterialSearch.vue'),
    meta: {
      title: '物料查重'
    }
  },
  {
    path: '/admin',
    name: 'admin',
    component: () => import('@/views/Admin/AdminPanel.vue'),
    meta: {
      title: '管理后台',
      requiresAuth: true
    }
  },
  {
    path: '/:pathMatch(.*)*',
    name: 'not-found',
    component: () => import('@/views/NotFound.vue'),
    meta: {
      title: '页面未找到'
    }
  }
]

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes
})

// 路由守卫
router.beforeEach((to, _from, next) => {
  // 设置页面标题
  if (to.meta.title) {
    document.title = `${to.meta.title} - ${import.meta.env.VITE_APP_TITLE}`
  }

  // 权限验证（暂时跳过，后续实现）
  if (to.meta.requiresAuth) {
    // TODO: 实现权限验证逻辑
    console.warn('需要权限验证，但当前未实现')
  }

  next()
})

export default router
