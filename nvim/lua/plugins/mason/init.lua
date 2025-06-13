return {
  "WhoIsSethDaniel/mason-tool-installer.nvim",
  event = { "BufReadPost", "BufWritePost", "BufNewFile" },
  dependencies = {
    -- install LSPs and related tools to stdpath for neovim
    { "mason-org/mason.nvim", opts = {} },
  },
  config = function()
    local tools = require "plugins.mason.tools"
    local lsp_servers = tools.lsp_servers
    local debugger_adapter = tools.debugger_adapter
    local formatters = tools.formatters
    local linters = tools.linters

    local ensure_installed = vim.list_extend({}, lsp_servers)
    vim.list_extend(ensure_installed, debugger_adapter)
    vim.list_extend(ensure_installed, formatters)
    vim.list_extend(ensure_installed, linters)

    -- map mason name to tool name, depend on mason
    local _ = require "mason-core.functional"
    local registry = require "mason-registry"
    local package_to_lspconfig = {}
    for _, pkg_spec in ipairs(registry.get_all_package_specs()) do
      -- mason package alias name
      local lspconfig = vim.tbl_get(pkg_spec, "neovim", "lspconfig") or pkg_spec.name
      if vim.tbl_contains(ensure_installed, lspconfig) then
        package_to_lspconfig[lspconfig] = pkg_spec.name
      end
    end

    -- install
    require("mason-tool-installer").setup {
      ensure_installed = vim.tbl_values(package_to_lspconfig),
    }
  end,
}
