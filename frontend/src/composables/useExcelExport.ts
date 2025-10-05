import * as XLSX from 'xlsx'
import type { BatchSearchResult, MaterialResult } from '@/api/material'

export interface ExportOptions {
  filename?: string
  includeDetails?: boolean
  maxMatches?: number
}

export function useExcelExport() {
  /**
   * 导出批量查重结果到 Excel
   */
  const exportResults = (
    results: BatchSearchResult[],
    options: ExportOptions = {}
  ) => {
    const {
      filename = `物料查重结果_${new Date().toISOString().slice(0, 10)}.xlsx`,
      includeDetails = true,
      maxMatches = 3
    } = options

    try {
      // 创建工作簿
      const workbook = XLSX.utils.book_new()

      // Sheet 1: 查重结果汇总
      const summaryData = createSummarySheet(results, maxMatches)
      const summarySheet = XLSX.utils.aoa_to_sheet(summaryData)
      XLSX.utils.book_append_sheet(workbook, summarySheet, '查重结果汇总')

      // Sheet 2: 详细匹配列表（可选）
      if (includeDetails) {
        const detailsData = createDetailsSheet(results)
        const detailsSheet = XLSX.utils.aoa_to_sheet(detailsData)
        XLSX.utils.book_append_sheet(workbook, detailsSheet, '详细匹配列表')
      }

      // Sheet 3: 统计分析
      const statsData = createStatsSheet(results)
      const statsSheet = XLSX.utils.aoa_to_sheet(statsData)
      XLSX.utils.book_append_sheet(workbook, statsSheet, '统计分析')

      // 写入文件
      XLSX.writeFile(workbook, filename)

      return true
    } catch (error) {
      console.error('导出失败:', error)
      return false
    }
  }

  /**
   * 创建汇总表数据
   */
  const createSummarySheet = (
    results: BatchSearchResult[],
    maxMatches: number
  ): any[][] => {
    const headers = [
      '行号',
      '输入-物料名称',
      '输入-规格型号',
      '输入-单位',
      '标准化名称',
      '检测分类',
      '匹配数量'
    ]

    // 添加匹配物料列
    for (let i = 1; i <= maxMatches; i++) {
      headers.push(
        `匹配${i}-ERP编码`,
        `匹配${i}-物料名称`,
        `匹配${i}-规格型号`,
        `匹配${i}-相似度`
      )
    }

    const rows = results.map(result => {
      const row: any[] = [
        result.row_number,
        result.input_data.material_name,
        result.input_data.specification,
        result.input_data.unit_name,
        result.parsed_query?.normalized_name || '',
        result.parsed_query?.detected_category || '',
        result.matches.length
      ]

      // 添加匹配物料数据
      for (let i = 0; i < maxMatches; i++) {
        const match = result.matches[i]
        if (match) {
          row.push(
            match.erp_code,
            match.material_name,
            match.specification,
            `${(match.similarity_score * 100).toFixed(1)}%`
          )
        } else {
          row.push('', '', '', '')
        }
      }

      return row
    })

    return [headers, ...rows]
  }

  /**
   * 创建详细列表数据
   */
  const createDetailsSheet = (results: BatchSearchResult[]): any[][] => {
    const headers = [
      '输入行号',
      '输入-物料名称',
      '输入-规格型号',
      '匹配排名',
      'ERP编码',
      '物料名称',
      '规格型号',
      '单位',
      '分类',
      '相似度',
      '标准化名称'
    ]

    const rows: any[][] = []

    results.forEach(result => {
      result.matches.forEach((match, index) => {
        rows.push([
          result.row_number,
          result.input_data.material_name,
          result.input_data.specification,
          index + 1,
          match.erp_code,
          match.material_name,
          match.specification,
          match.unit_name,
          match.category_name || '',
          `${(match.similarity_score * 100).toFixed(1)}%`,
          match.normalized_name || ''
        ])
      })
    })

    return [headers, ...rows]
  }

  /**
   * 创建统计分析数据
   */
  const createStatsSheet = (results: BatchSearchResult[]): any[][] => {
    const totalRecords = results.length
    const withMatches = results.filter(r => r.matches.length > 0).length
    const withoutMatches = totalRecords - withMatches
    const avgMatches =
      results.reduce((sum, r) => sum + r.matches.length, 0) / totalRecords

    const avgSimilarity =
      results
        .filter(r => r.matches.length > 0)
        .reduce((sum, r) => sum + (r.matches[0]?.similarity_score || 0), 0) /
      (withMatches || 1)

    // 分类统计
    const categoryStats = new Map<string, number>()
    results.forEach(result => {
      const category = result.parsed_query?.detected_category || '未分类'
      categoryStats.set(category, (categoryStats.get(category) || 0) + 1)
    })

    const data: any[][] = [
      ['统计指标', '数值'],
      ['总记录数', totalRecords],
      ['有匹配记录数', withMatches],
      ['无匹配记录数', withoutMatches],
      ['匹配率', `${((withMatches / totalRecords) * 100).toFixed(1)}%`],
      ['平均匹配数量', avgMatches.toFixed(1)],
      ['平均相似度', `${(avgSimilarity * 100).toFixed(1)}%`],
      [],
      ['分类统计', '数量']
    ]

    categoryStats.forEach((count, category) => {
      data.push([category, count])
    })

    return data
  }

  /**
   * 导出单个结果
   */
  const exportSingleResult = (result: BatchSearchResult, filename?: string) => {
    return exportResults([result], {
      filename: filename || `物料查重_行${result.row_number}.xlsx`,
      includeDetails: true
    })
  }

  return {
    exportResults,
    exportSingleResult
  }
}
