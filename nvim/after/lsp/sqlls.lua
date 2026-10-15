-- sqlls 静态语法检查（补全由 sqmeow 提供，格式化由 sqlfmt 负责）
-- 风格类 lint 规则与 sqlfmt 的紧凑风格冲突，全部关闭，只保留语法错误诊断；
-- 规则经 workspace/didChangeConfiguration 下发（覆盖 .sqlintrc.json 文件配置）
return {
  cmd = { "sql-language-server", "up", "--method", "stdio" },
  filetypes = { "sql", "mysql" },
  settings = {
    sqlLanguageServer = {
      lint = {
        rules = {
          ["align-column-to-the-first"] = "off",
          ["align-where-clause-to-the-first"] = "off",
          ["column-new-line"] = "off",
          ["linebreak-after-clause-keyword"] = "off",
          ["require-as-to-rename-column"] = "off",
          ["reserved-word-case"] = "off",
          ["space-surrounding-operators"] = "off",
          ["where-clause-new-line"] = "off",
        },
      },
    },
  },
}
