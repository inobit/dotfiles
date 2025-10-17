function _G.conf_formatter()
  local start_line = vim.v.lnum
  local count = vim.v.count
  local end_line = start_line + count - 1
  -- delete leading whitespace
  vim.cmd(string.format("%d,%ds/^\\s*//", start_line, end_line))
  -- add spaces around '='
  vim.cmd(string.format("%d,%ds/\\v(\\S)(\\s*)\\=(\\s*)(\\S)/\\1 = \\4/g", start_line, end_line))
  -- add spaces on the right of ','
  vim.cmd(string.format("%d,%ds/\\v(\\S)(\\s*)\\,(\\s*)(\\S)/\\1, \\4/g", start_line, end_line))
  vim.cmd "nohlsearch"
  return 0
end
vim.o.formatexpr = "v:lua.conf_formatter()"
