import { ref, computed } from 'vue'
import type { BatchSearchResult } from '@/api/material'

export type FilterType = 'all' | 'with-matches' | 'without-matches'
export type SortField = 'row_number' | 'similarity' | 'match_count'
export type SortOrder = 'asc' | 'desc'

export function useResultFilter(results: Ref<BatchSearchResult[]>) {
  const filterType = ref<FilterType>('all')
  const sortField = ref<SortField>('row_number')
  const sortOrder = ref<SortOrder>('asc')
  const searchQuery = ref('')
  const currentPage = ref(1)
  const pageSize = ref(20)

  // 筛选结果
  const filteredResults = computed(() => {
    let filtered = results.value

    // 按类型筛选
    if (filterType.value === 'with-matches') {
      filtered = filtered.filter(r => r.matches.length > 0)
    } else if (filterType.value === 'without-matches') {
      filtered = filtered.filter(r => r.matches.length === 0)
    }

    // 按搜索词筛选
    if (searchQuery.value) {
      const query = searchQuery.value.toLowerCase()
      filtered = filtered.filter(
        r =>
          r.input_data.material_name.toLowerCase().includes(query) ||
          r.input_data.specification.toLowerCase().includes(query) ||
          r.matches.some(m => m.material_name.toLowerCase().includes(query))
      )
    }

    return filtered
  })

  // 排序结果
  const sortedResults = computed(() => {
    const sorted = [...filteredResults.value]

    sorted.sort((a, b) => {
      let compareValue = 0

      switch (sortField.value) {
        case 'row_number':
          compareValue = a.row_number - b.row_number
          break
        case 'similarity':
          compareValue =
            (b.matches[0]?.similarity_score || 0) - (a.matches[0]?.similarity_score || 0)
          break
        case 'match_count':
          compareValue = b.matches.length - a.matches.length
          break
      }

      return sortOrder.value === 'asc' ? compareValue : -compareValue
    })

    return sorted
  })

  // 分页结果
  const paginatedResults = computed(() => {
    const start = (currentPage.value - 1) * pageSize.value
    const end = start + pageSize.value
    return sortedResults.value.slice(start, end)
  })

  // 总页数
  const totalPages = computed(() => {
    return Math.ceil(sortedResults.value.length / pageSize.value)
  })

  // 统计信息
  const stats = computed(() => {
    const total = results.value.length
    const withMatches = results.value.filter(r => r.matches.length > 0).length
    const withoutMatches = total - withMatches
    const filtered = filteredResults.value.length

    return {
      total,
      withMatches,
      withoutMatches,
      filtered,
      matchRate: total > 0 ? ((withMatches / total) * 100).toFixed(1) : '0'
    }
  })

  // 设置筛选类型
  const setFilterType = (type: FilterType) => {
    filterType.value = type
    currentPage.value = 1
  }

  // 设置排序
  const setSort = (field: SortField, order?: SortOrder) => {
    if (sortField.value === field && !order) {
      // 切换排序方向
      sortOrder.value = sortOrder.value === 'asc' ? 'desc' : 'asc'
    } else {
      sortField.value = field
      sortOrder.value = order || 'asc'
    }
    currentPage.value = 1
  }

  // 设置搜索词
  const setSearchQuery = (query: string) => {
    searchQuery.value = query
    currentPage.value = 1
  }

  // 设置页码
  const setPage = (page: number) => {
    if (page >= 1 && page <= totalPages.value) {
      currentPage.value = page
    }
  }

  // 重置筛选
  const resetFilter = () => {
    filterType.value = 'all'
    sortField.value = 'row_number'
    sortOrder.value = 'asc'
    searchQuery.value = ''
    currentPage.value = 1
  }

  return {
    // State
    filterType,
    sortField,
    sortOrder,
    searchQuery,
    currentPage,
    pageSize,

    // Computed
    filteredResults,
    sortedResults,
    paginatedResults,
    totalPages,
    stats,

    // Methods
    setFilterType,
    setSort,
    setSearchQuery,
    setPage,
    resetFilter
  }
}
