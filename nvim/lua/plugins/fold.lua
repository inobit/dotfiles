return {
  "kevinhwang91/nvim-ufo",
  event = { "BufReadPost", "BufWritePost", "BufNewFile" },
  dependencies = {
    "kevinhwang91/promise-async",
  },
  config = function()
    vim.o.foldcolumn = "1" -- '0' is not bad
    vim.o.foldlevel = 99 -- Using ufo provider need a large value, feel free to decrease the value
    vim.o.foldlevelstart = 99
    vim.o.foldenable = true
    local ftMap = {
      vim = "indent",
      python = { "indent" },
      git = "",
    }
    require("ufo").setup {
      provider_selector = function(_, filetype, _)
        return ftMap[filetype] or { "lsp", "indent" }
      end,
    }
    vim.keymap.set("n", "zR", require("ufo").openAllFolds)
    vim.keymap.set("n", "zM", require("ufo").closeAllFolds)
    vim.keymap.set("n", "zr", require("ufo").openFoldsExceptKinds)
    vim.keymap.set("n", "zm", require("ufo").closeFoldsWith) -- closeAllFolds == closeFoldsWith(0)
    vim.keymap.set("n", "zK", function()
      local winid = require("ufo").peekFoldedLinesUnderCursor()
      if not winid then
        -- choose one of coc.nvim and nvim lsp
        vim.fn.CocActionAsync "definitionHover" -- coc.nvim
        vim.lsp.buf.hover()
      end
    end)
  end,
}
