import * as XLSX from 'xlsx'

/**
 * Excel 工具函数
 */

/**
 * 读取 Excel 文件
 */
export const readExcelFile = (file: File): Promise<XLSX.WorkBook> => {
  return new Promise((resolve, reject) => {
    const reader = new FileReader()

    reader.onload = (e) => {
      try {
        const data = e.target?.result
        const workbook = XLSX.read(data, { type: 'binary' })
        resolve(workbook)
      } catch (error) {
        reject(new Error('Excel 文件解析失败'))
      }
    }

    reader.onerror = () => {
      reject(new Error('文件读取失败'))
    }

    reader.readAsBinaryString(file)
  })
}

/**
 * 获取工作表数据
 */
export const getSheetData = (workbook: XLSX.WorkBook, sheetIndex: number = 0): any[][] => {
  const sheetName = workbook.SheetNames[sheetIndex]
  const worksheet = workbook.Sheets[sheetName]
  return XLSX.utils.sheet_to_json(worksheet, { header: 1 })
}

/**
 * 获取列名（第一行）
 */
export const getColumnNames = (data: any[][]): string[] => {
  if (data.length === 0) return []
  return data[0].map((col: any) => String(col || ''))
}

/**
 * 检测列名
 */
export const detectColumn = (columnNames: string[], patterns: string[]): string | null => {
  for (const pattern of patterns) {
    const lowerPattern = pattern.toLowerCase()
    const foundColumn = columnNames.find((col) =>
      col.toLowerCase().includes(lowerPattern)
    )
    if (foundColumn) return foundColumn
  }
  return null
}

/**
 * 自动检测必需列
 */
export interface DetectedColumns {
  material_name: string | null
  specification: string | null
  unit_name: string | null
}

export const autoDetectColumns = (columnNames: string[]): DetectedColumns => {
  const materialNamePatterns = ['物料名称', '名称', '品名', 'name', 'material']
  const specificationPatterns = ['规格型号', '规格', '型号', 'spec', 'specification', 'model']
  const unitNamePatterns = ['单位', '计量单位', 'unit']

  return {
    material_name: detectColumn(columnNames, materialNamePatterns),
    specification: detectColumn(columnNames, specificationPatterns),
    unit_name: detectColumn(columnNames, unitNamePatterns)
  }
}

/**
 * 将 Excel 列字母转换为索引（A=0, B=1, ...）
 */
export const excelColumnToIndex = (column: string): number => {
  let index = 0
  for (let i = 0; i < column.length; i++) {
    index = index * 26 + column.charCodeAt(i) - 'A'.charCodeAt(0) + 1
  }
  return index - 1
}

/**
 * 将索引转换为 Excel 列字母（0=A, 1=B, ...）
 */
export const indexToExcelColumn = (index: number): string => {
  let column = ''
  let num = index + 1
  while (num > 0) {
    const remainder = (num - 1) % 26
    column = String.fromCharCode('A'.charCodeAt(0) + remainder) + column
    num = Math.floor((num - 1) / 26)
  }
  return column
}

/**
 * 解析列名配置（支持列名、索引、Excel字母）
 */
export const parseColumnConfig = (
  config: string,
  columnNames: string[]
): string | null => {
  if (!config || config.trim() === '') return null

  const trimmed = config.trim()

  // 尝试作为列名
  if (columnNames.includes(trimmed)) {
    return trimmed
  }

  // 尝试作为索引（数字）
  const numIndex = parseInt(trimmed, 10)
  if (!isNaN(numIndex) && numIndex >= 0 && numIndex < columnNames.length) {
    return columnNames[numIndex]
  }

  // 尝试作为 Excel 列字母（A, B, C, ...）
  if (/^[A-Z]+$/i.test(trimmed)) {
    const index = excelColumnToIndex(trimmed.toUpperCase())
    if (index >= 0 && index < columnNames.length) {
      return columnNames[index]
    }
  }

  return null
}

/**
 * 导出查重结果为 Excel
 */
export interface ExportData {
  inputData: any
  matches: any[]
  parsedQuery?: any
}

export const exportToExcel = (results: ExportData[], filename: string = 'matmatch_results.xlsx') => {
  // 创建工作簿
  const workbook = XLSX.utils.book_new()

  // Sheet 1: 查重结果汇总
  const summaryData = results.map((result, index) => ({
    '行号': index + 1,
    '物料名称': result.inputData.material_name,
    '规格型号': result.inputData.specification,
    '单位': result.inputData.unit_name,
    '匹配数量': result.matches.length,
    '最高相似度': result.matches.length > 0 ? `${(result.matches[0].similarity_score * 100).toFixed(1)}%` : '0%',
    '第一匹配编码': result.matches.length > 0 ? result.matches[0].erp_code : '-',
    '第一匹配名称': result.matches.length > 0 ? result.matches[0].material_name : '-'
  }))
  const summarySheet = XLSX.utils.json_to_sheet(summaryData)
  XLSX.utils.book_append_sheet(workbook, summarySheet, '查重结果汇总')

  // Sheet 2: 详细匹配列表
  const detailData: any[] = []
  results.forEach((result, index) => {
    result.matches.forEach((match, matchIndex) => {
      detailData.push({
        '行号': index + 1,
        '输入-物料名称': result.inputData.material_name,
        '输入-规格型号': result.inputData.specification,
        '输入-单位': result.inputData.unit_name,
        '匹配排名': matchIndex + 1,
        '匹配-ERP编码': match.erp_code,
        '匹配-物料名称': match.material_name,
        '匹配-规格型号': match.specification,
        '匹配-单位': match.unit_name,
        '相似度': `${(match.similarity_score * 100).toFixed(1)}%`
      })
    })
  })
  const detailSheet = XLSX.utils.json_to_sheet(detailData)
  XLSX.utils.book_append_sheet(workbook, detailSheet, '详细匹配列表')

  // Sheet 3: 解析结果
  const parsedData = results
    .filter(r => r.parsedQuery)
    .map((result, index) => ({
      '行号': index + 1,
      '原始名称': result.inputData.material_name,
      '标准化名称': result.parsedQuery?.normalized_name || '-',
      '检测分类': result.parsedQuery?.detected_category || '-',
      '提取属性': result.parsedQuery?.extracted_attributes
        ? JSON.stringify(result.parsedQuery.extracted_attributes)
        : '-'
    }))
  const parsedSheet = XLSX.utils.json_to_sheet(parsedData)
  XLSX.utils.book_append_sheet(workbook, parsedSheet, '解析结果')

  // 导出文件
  XLSX.writeFile(workbook, filename)
}

/**
 * 验证文件
 */
export const validateFile = (file: File): { valid: boolean; error?: string } => {
  // 检查文件类型
  const validTypes = [
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', // .xlsx
    'application/vnd.ms-excel' // .xls
  ]
  const validExtensions = ['.xlsx', '.xls']

  const hasValidType = validTypes.includes(file.type)
  const hasValidExtension = validExtensions.some(ext => file.name.toLowerCase().endsWith(ext))

  if (!hasValidType && !hasValidExtension) {
    return {
      valid: false,
      error: '只支持 Excel 文件（.xlsx, .xls）'
    }
  }

  // 检查文件大小（10MB）
  const maxSize = 10 * 1024 * 1024
  if (file.size > maxSize) {
    return {
      valid: false,
      error: '文件大小不能超过 10MB'
    }
  }

  return { valid: true }
}
