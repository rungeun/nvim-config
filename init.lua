-- 기본 설정
vim.g.mapleader = " " -- 리더 키를 스페이스로 설정
vim.g.maplocalleader = " "
vim.g.neovide_scale_factor = 1.2  -- 기본 크기를 1.2배로 설정

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
      vim.cmd.colorscheme "catppuccin-latte"
    end,
  },
  
  -- 코드 실행기 추가 (Java 스마트 실행 포함)
  {
    "CRAG666/code_runner.nvim",
    config = function()
      require('code_runner').setup({
        mode = "term",  -- 터미널 모드 (입력 지원)
        focus = true,   -- 실행 시 포커스 이동
        startinsert = true,  -- 입력 모드로 시작
        term = {
          position = "bot",  -- 하단에 터미널 열기
          size = 15,         -- 터미널 크기
        },
        filetype = {
          cpp = "cd $dir && g++ $fileName -o $fileNameWithoutExt && ./$fileNameWithoutExt",
          c = "cd $dir && gcc $fileName -o $fileNameWithoutExt && ./$fileNameWithoutExt",
          kotlin = "cd $dir && kotlinc $fileName -include-runtime -d /tmp/$fileNameWithoutExt.jar && java -jar /tmp/$fileNameWithoutExt.jar",
          java = function()
            -- 현재 파일 정보
            local file = vim.fn.expand('%:p')
            local dir = vim.fn.expand('%:p:h')
            local filename = vim.fn.expand('%:t')
            local classname = vim.fn.expand('%:t:r')
            
            -- 파일 내용 분석
            local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
            local package = nil
            local has_main = false
            
            -- 패키지명과 main 메서드 찾기
            for _, line in ipairs(lines) do
              -- 패키지 선언 찾기
              local pkg_match = line:match("^package%s+([%w%.]+)")
              if pkg_match then
                package = pkg_match
              end
              -- main 메서드 찾기
              if line:match("public%s+static%s+void%s+main") then
                has_main = true
              end
            end
            
            -- 실행 명령어 생성
            if has_main then
              -- 현재 파일에 main이 있는 경우
              if package then
                -- 패키지가 있는 경우
                local package_path = package:gsub("%.", "/")
                -- 패키지 루트 디렉토리 찾기
                local root = dir
                local path_parts = {}
                for part in string.gmatch(package, "[^.]+") do
                  table.insert(path_parts, part)
                  root = vim.fn.fnamemodify(root, ':h')
                end
                
                return string.format(
                  "cd %s && mkdir -p build && javac -d build %s/*.java && java -cp build %s.%s",
                  root, package_path, package, classname
                )
              else
                -- 패키지가 없는 경우
                return string.format(
                  "cd %s && mkdir -p build && javac -d build *.java && java -cp build %s",
                  dir, classname
                )
              end
            else
              -- 현재 파일에 main이 없는 경우 - 같은 디렉토리에서 main 찾기
              if package then
                -- 패키지가 있는 경우
                local package_path = package:gsub("%.", "/")
                local root = dir
                local path_parts = {}
                for part in string.gmatch(package, "[^.]+") do
                  table.insert(path_parts, part)
                  root = vim.fn.fnamemodify(root, ':h')
                end
                
                -- grep으로 main 메서드가 있는 클래스 찾기
                return string.format(
                  [[cd %s && mkdir -p build && javac -d build %s/*.java && MAIN_CLASS=$(grep -l "public static void main" %s/*.java 2>/dev/null | head -1 | xargs -r basename | sed 's/.java//') && if [ -n "$MAIN_CLASS" ]; then java -cp build %s.$MAIN_CLASS; else echo "No main method found in package %s"; fi]],
                  root, package_path, package_path, package, package
                )
              else
                -- 패키지가 없는 경우
                return string.format(
                  [[cd %s && mkdir -p build && javac -d build *.java && MAIN_CLASS=$(grep -l "public static void main" *.java 2>/dev/null | head -1 | sed 's/.java//') && if [ -n "$MAIN_CLASS" ]; then java -cp build $MAIN_CLASS; else echo "No main method found"; fi]],
                  dir
                )
              end
            end
          end,
          python = "python3",
          javascript = "node",
          typescript = "ts-node",
          rust = "cd $dir && rustc $fileName && ./$fileNameWithoutExt",
          go = "go run",
        },
      })
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
        ensure_installed = { "lua", "vim", "vimdoc", "python", "javascript", "typescript", "c", "rust", "kotlin", "java"},
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
          -- "jdtls",  -- Java LSP (선택사항)
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

      -- Java LSP (선택사항 - 주석 해제하여 사용)
      -- lspconfig.jdtls.setup({
      --   capabilities = capabilities,
      -- })
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

-- Code Runner
keymap.set('n', '<F5>', ':RunCode<CR>', { desc = 'Run Code' })
keymap.set('n', '<F6>', ':RunFile<CR>', { desc = 'Run File' })
keymap.set('n', '<F7>', ':RunClose<CR>', { desc = 'Close Runner' })

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

vim.keymap.set({"n", "i"}, "<C-=>", function()
  change_scale_factor(1.05)
end)
vim.keymap.set({"n", "i"}, "<C-->", function()
  change_scale_factor(0.95)
end)
