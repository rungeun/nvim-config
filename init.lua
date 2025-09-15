-- 기본 설정
vim.g.mapleader = " " -- 리더 키를 스페이스로 설정
vim.g.maplocalleader = " "

-- 기본 옵션들
vim.opt.number = true         -- 줄 번호 표시
vim.opt.relativenumber = true -- 상대 줄 번호
vim.opt.mouse = "a"          -- 마우스 지원
vim.opt.ignorecase = true    -- 검색시 대소문자 무시
vim.opt.smartcase = true     -- 대문자가 있으면 대소문자 구분
vim.opt.hlsearch = false     -- 검색 하이라이트 끄기
vim.opt.wrap = false         -- 줄 바꿈 안함
vim.opt.breakindent = true   -- 들여쓰기 유지
vim.opt.tabstop = 2          -- 탭 크기
vim.opt.shiftwidth = 2       -- 들여쓰기 크기
vim.opt.expandtab = true     -- 탭을 스페이스로 변환
vim.opt.termguicolors = true -- 24비트 색상 지원
vim.opt.signcolumn = "yes"   -- 항상 사인 열 표시
vim.opt.clipboard = "unnamedplus" -- 시스템 클립보드 사용
vim.opt.cursorline = true    -- 현재 줄 강조
vim.opt.scrolloff = 8        -- 스크롤시 여백
vim.opt.updatetime = 250     -- 업데이트 시간 단축
vim.opt.timeoutlen = 300     -- 키 시퀀스 대기 시간

-- OSC 52 클립보드 설정
vim.g.clipboard = {
  name = 'OSC 52',
  copy = {
    ['+'] = require('vim.ui.clipboard.osc52').copy('+'),
    ['*'] = require('vim.ui.clipboard.osc52').copy('*'),
  },
  paste = {
    ['+'] = require('vim.ui.clipboard.osc52').paste('+'),
    ['*'] = require('vim.ui.clipboard.osc52').paste('*'),
  },
}

-- lazy.nvim 자동 설치
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- 플러그인 설정
require("lazy").setup({
  -- 색상 테마
  {
  "catppuccin/nvim",
  name = "catppuccin",
  priority = 1000,
  config = function()
    vim.cmd.colorscheme "catppuccin-latte"  -- mocha를 latte로 변경
  end,
  },
  -- 파일 탐색기
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
    },
    config = function()
      require("neo-tree").setup({
        close_if_last_window = true,
        window = {
          width = 30,
        },
      })
    end,
  },

  -- 퍼지 파인더
  {
    'nvim-telescope/telescope.nvim',
    tag = '0.1.8',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
      require('telescope').setup({
        defaults = {
          mappings = {
            i = {
              ['<C-u>'] = false,
              ['<C-d>'] = false,
            },
          },
        },
      })
    end,
  },

  -- 구문 강조
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = { "lua", "vim", "vimdoc", "python", "javascript", "typescript", "c", "rust", "kotlin"},
        auto_install = true,
        highlight = {
          enable = true,
        },
        indent = {
          enable = true,
        },
      })
    end,
  },

  -- LSP 설정
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "j-hui/fidget.nvim",
    },
    config = function()
      require("mason").setup()
      require("mason-lspconfig").setup({
        ensure_installed = {
          "lua_ls",
          "pyright",
          "ts_ls",
          --"kotlin_language_server",
        },
      })
      require("fidget").setup()

      -- LSP 서버 설정
      local lspconfig = require('lspconfig')
      local capabilities = vim.lsp.protocol.make_client_capabilities()

      -- Lua
      lspconfig.lua_ls.setup({
        capabilities = capabilities,
        settings = {
          Lua = {
            diagnostics = {
              globals = { "vim" },
            },
          },
        },
      })

      -- Python
      lspconfig.pyright.setup({
        capabilities = capabilities,
      })

      -- TypeScript
      lspconfig.ts_ls.setup({
        capabilities = capabilities,
      })

      -- Kotlin LSP 설정 부분을 이렇게 변경
      --[[
      lspconfig.kotlin_language_server.setup({
        capabilities = capabilities,
        cmd = { "kotlin-language-server" },
        filetypes = { "kotlin" },
        root_dir = lspconfig.util.root_pattern("settings.gradle", "settings.gradle.kts", "build.gradle", "build.gradle.kts", ".git"),
        settings = {
          kotlin = {
            compiler = {
              jvm = {
                target = "17"
              }
            }
          }
        },
        init_options = {
          storagePath = vim.fn.stdpath('data') .. '/kotlin-language-server'
        },
        on_attach = function(client, bufnr)
          -- JSON 파싱 오류 방지
          client.config.settings = vim.tbl_deep_extend('force', client.config.settings or {}, {})
        end,
      })
      --]]

    end,
  },

  -- 자동완성
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
      "rafamadriz/friendly-snippets",
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")
      require("luasnip.loaders.from_vscode").lazy_load()

      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-p>"] = cmp.mapping.select_prev_item(),
          ["<C-n>"] = cmp.mapping.select_next_item(),
          ["<C-b>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-e>"] = cmp.mapping.abort(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { "i", "s" }),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip" },
        }, {
          { name = "buffer" },
          { name = "path" },
        }),
      })
    end,
  },

  -- Git 표시
  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require('gitsigns').setup({
        signs = {
          add = { text = '+' },
          change = { text = '~' },
          delete = { text = '_' },
          topdelete = { text = '‾' },
          changedelete = { text = '~' },
        },
      })
    end,
  },

  -- 상태줄
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require('lualine').setup({
        options = {
          theme = 'catppuccin',
        },
      })
    end,
  },

  -- 주석 처리
  {
    "numToStr/Comment.nvim",
    config = function()
      require('Comment').setup()
    end,
  },

  -- 괄호 자동 완성
  {
    "windwp/nvim-autopairs",
    config = function()
      require("nvim-autopairs").setup()
    end,
  },

  -- 들여쓰기 가이드
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    config = function()
      require("ibl").setup()
    end,
  },

  -- 키 바인딩 가이드
  {
    "folke/which-key.nvim",
    config = function()
      require("which-key").setup()
    end,
  },

  -- 빠른 이동
  {
    "ggandor/leap.nvim",
    config = function()
      require('leap').create_default_mappings()
    end,
  },
})

-- 키맵 설정
local keymap = vim.keymap

-- 일반 키맵
keymap.set("n", "<leader>w", ":w<CR>", { desc = "Save file" })
keymap.set("n", "<leader>q", ":q<CR>", { desc = "Quit" })
keymap.set("n", "<leader>x", ":x<CR>", { desc = "Save and quit" })

-- 창 이동
keymap.set("n", "<C-h>", "<C-w>h", { desc = "Move to left window" })
keymap.set("n", "<C-j>", "<C-w>j", { desc = "Move to bottom window" })
keymap.set("n", "<C-k>", "<C-w>k", { desc = "Move to top window" })
keymap.set("n", "<C-l>", "<C-w>l", { desc = "Move to right window" })

-- Neo-tree
keymap.set("n", "<leader>e", ":Neotree toggle<CR>", { desc = "Toggle file explorer" })

-- Telescope
keymap.set('n', '<leader>ff', require('telescope.builtin').find_files, { desc = 'Find files' })
keymap.set('n', '<leader>fg', require('telescope.builtin').live_grep, { desc = 'Live grep' })
keymap.set('n', '<leader>fb', require('telescope.builtin').buffers, { desc = 'Find buffers' })
keymap.set('n', '<leader>fh', require('telescope.builtin').help_tags, { desc = 'Help tags' })

-- Kotlin 실행
-- F5는 인자 없이, F6는 인자와 함께
vim.keymap.set('n', '<F5>', ':split | terminal kotlinc % -include-runtime -d /tmp/%.jar && java -jar /tmp/%.jar<CR>')
vim.keymap.set('n', '<F6>', function()
  local args = vim.fn.input("Arguments: ")
  vim.cmd('split | terminal kotlinc % -include-runtime -d /tmp/%.jar && java -jar /tmp/%.jar ' .. args)
end)

-- 스크립트 실행 (.kts 파일용)
vim.keymap.set('n', '<F7>', ':!kotlinc -script %<CR>')

-- LSP 키맵
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('UserLspConfig', {}),
  callback = function(ev)
    local opts = { buffer = ev.buf }
    keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
    keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
    keymap.set('n', 'K', vim.lsp.buf.hover, opts)
    keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
    keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, opts)
    keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
    keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts)
    keymap.set('n', 'gr', vim.lsp.buf.references, opts)
    keymap.set('n', '<leader>f', function()
      vim.lsp.buf.format { async = true }
    end, opts)
  end,
})
