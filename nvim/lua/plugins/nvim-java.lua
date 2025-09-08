return {
  "nvim-java/nvim-java",
  ft = { "java" },
  dependencies = {
    "neovim/nvim-lspconfig",
  },
  opts = {
    jdk = {
      auto_install = false,
      version = "21.0.1",
    },
  },
  config = function(_, opts)
    require("java").setup(opts)
    require("lspconfig").jdtls.setup {
      settings = {
        configuration = {
          runtimes = vim.g.java_runtimes,
          updateBuildConfiguration = "interactive",
        },
        -- Enable downloading archives from eclipse automatically
        eclipse = {
          downloadSource = true,
        },
        -- Enable downloading archives from maven automatically
        maven = {
          downloadSources = true,
        },
        -- Enable method signature help
        signatureHelp = {
          enabled = true,
        },
        -- Use the fernflower decompiler when using the javap command to decompile byte code back to java code
        contentProvider = {
          preferred = "fernflower",
        },
        -- Setup automatical package import oranization on file save
        saveActions = {
          organizeImports = true,
          cleanup = true,
        },
        -- enable code lens in the lsp
        referencesCodeLens = {
          enabled = true,
        },
        -- enable inlay hints for parameter names,
        inlayHints = {
          parameterNames = {
            enabled = "all",
          },
        },
      },
    }

    vim.api.nvim_create_autocmd("LspAttach", {
      callback = function(event)
        local client = vim.lsp.get_client_by_id(event.data.client_id)
        if client and client.name == "jdtls" then
          local map = function(keys, func, desc, mode)
            if mode == nil then
              mode = "n"
            end
            vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = "Java: " .. desc })
          end
          -- keymap
          map("<leader>rr", "<Cmd>JavaRunnerRunMain<CR>", "Run")
          map("<leader>rs", "<Cmd>JavaRunnerStopMain<CR>", "Stop")
          map("<leader>jt", "<Cmd>JavaTestRunCurrentMethod<CR>", "Run Current Test")
          map("<leader>jT", "<Cmd>JavaTestRunCurrentClass<CR>", "Run All Test")
          map("<leader>jv", "<Cmd>JavaRefactorExtractVariable<CR>", "Extract Variable")
          map("<leader>jV", "<Cmd>JavaRefactorExtractVariableAllOccurrence<CR>", "Extract All Variable")
          map("<leader>jc", "<Cmd>JavaRefactorExtractConstant<CR>", "Extract Constant")
          map("<leader>jm", "<Cmd>JavaRefactorExtractMethod<CR>", "Extract Method")
          map("<leader>jf", "<Cmd>JavaRefactorExtractField<CR>", "Extract Field")
        end
      end,
    })
  end,
}
