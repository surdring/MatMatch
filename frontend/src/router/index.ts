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
    path: '/test-components',
    name: 'component-test',
    component: () => import('@/views/ComponentTest.vue'),
    meta: {
      title: '组件测试'
    }
  },
  {
    path: '/admin/login',
    name: 'admin-login',
    component: () => import('@/views/Admin/Login.vue'),
    meta: {
      title: '管理员登录'
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

  // 权限验证
  if (to.meta.requiresAuth) {
    // 动态导入authStore以避免循环依赖
    import('@/stores/auth').then(({ useAuthStore }) => {
      const authStore = useAuthStore()
      
      if (!authStore.checkAuth()) {
        // 未登录，重定向到登录页
        next({
          path: '/admin/login',
          query: { redirect: to.fullPath } // 保存原本要访问的路径
        })
      } else {
        // 已登录，允许访问
        next()
      }
    })
  } else {
    next()
  }
})

export default router
