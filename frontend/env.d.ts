/// <reference types="vite/client" />

// 声明 .vue 文件模块类型
declare module '*.vue' {
  import type { DefineComponent } from 'vue'
  const component: DefineComponent<{}, {}, any>
  export default component
}

interface ImportMetaEnv {
  readonly VITE_API_BASE_URL: string
  readonly VITE_APP_TITLE: string
  readonly VITE_USE_MOCK: string
  readonly VITE_SHOW_DEBUG: string
}

interface ImportMeta {
  readonly env: ImportMetaEnv
}
