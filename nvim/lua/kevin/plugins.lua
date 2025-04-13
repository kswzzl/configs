# vim: set tabstop=2 shiftwidth=2 expandtab:

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


require("lazy").setup({
  -- File explorer
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("nvim-tree").setup({})
      vim.keymap.set("n", "<leader>e", ":NvimTreeToggle<CR>", { desc = "Toggle file explorer" })
    end,
  },

  -- Telescope
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope-fzf-native.nvim",
    },
    build = "make",
    config = function()
      require("telescope").setup({
        defaults = {
          layout_config = { prompt_position = "top" },
          sorting_strategy = "ascending",
        },
      })
      require("telescope").load_extension("fzf")
      local builtin = require("telescope.builtin")
      vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Find files" })
      vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Grep" })
      vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Buffers" })
      vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Help" })
      vim.keymap.set("n", "<leader>fr", builtin.resume, { desc = "Resume last Telescope search" })
    end,
  },
  {
    "folke/tokyonight.nvim",
    priority = 1000,
    config = function()
      vim.cmd.colorscheme("tokyonight-night") -- or "tokyonight-storm"
    end,
  },
  --{
  --  "akinsho/bufferline.nvim",
  --  version = "*",
  --  dependencies = { "nvim-tree/nvim-web-devicons" },
  --  config = function()
  --    require("bufferline").setup({
  --      options = {
  --        diagnostics = "nvim_lsp",
  --        show_buffer_close_icons = true,
  --        show_close_icon = false,
  --        separator_style = "slant", -- or "thin", "padded_slant", etc.
  --      },
  --    })
  --    vim.opt.termguicolors = true
  --    vim.opt.showtabline = 2
  --  end,
  --},
  {
    "echasnovski/mini.bufremove",
    version = "*",
    config = function()
      local bufremove = require("mini.bufremove")
      vim.keymap.set("n", "<leader>bd", bufremove.delete, { desc = "Smart buffer delete" })
    end,
  },
  {
    "sindrets/diffview.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require("diffview").setup({})
    end,
  },
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("lualine").setup({
        options = {
          theme = "auto",
          section_separators = { left = "", right = "" },
          component_separators = "|",
          icons_enabled = true,
        },
        sections = {
          lualine_a = { "mode" },
          lualine_b = { "branch", "diff", "diagnostics" },
          lualine_c = { "filename" },
          lualine_x = { "encoding", "filetype" },
          lualine_y = { "location" },
          lualine_z = { "progress" },
        },
      })
    end,
  },
  {
    "folke/which-key.nvim",
    config = function()
      require("which-key").setup({})
    end,
  },
  { "lewis6991/gitsigns.nvim" },
  { "tpope/vim-fugitive" },
  --{ "reachingforthejack/cursortab.nvim"},
  {
    dir = vim.fn.expand("~/.config/nvim/lua/kevin/kevin-llm"),
    name = "kevin-llm",
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
      local system_prompt =
        'You should replace the code that you are sent, only following the comments. Do not talk at all. Only output valid code. Do not provide any backticks that surround the code. Never ever output backticks like this ```. Any comment that is asking you for something should be removed after you satisfy them. Other comments should left alone. Do not output backticks'
      local helpful_prompt = 'You are a helpful assistant. What I have sent are my notes so far.'
      local dingllm = require('kevin.kevin-llm')

      local function handle_open_router_spec_data(data_stream)
        local success, json = pcall(vim.json.decode, data_stream)
        if success then
          if json.choices and json.choices[1] and json.choices[1].text then
            local content = json.choices[1].text
            if content then
              dingllm.write_string_at_cursor(content)
            end
          end
        else
          print("non json " .. data_stream)
        end
      end

      local function custom_make_openai_spec_curl_args(opts, prompt)
        local url = opts.url
        local api_key = opts.api_key_name and os.getenv(opts.api_key_name)
        local data = {
          prompt = prompt,
          model = opts.model,
          temperature = 0.7,
          stream = true,
        }
        local args = { '-N', '-X', 'POST', '-H', 'Content-Type: application/json', '-d', vim.json.encode(data) }
        if api_key then
          table.insert(args, '-H')
          table.insert(args, 'Authorization: Bearer ' .. api_key)
        end
        table.insert(args, url)
        return args
      end

      local function grok_replace()
        dingllm.invoke_llm_and_stream_into_editor({
          url = 'https://api.x.ai/v1/chat/completions',
          model = 'grok-3-mini-beta',
          api_key_name = 'GROK_API_KEY',
          system_prompt = system_prompt,
          replace = true,
        }, dingllm.make_openai_spec_curl_args, dingllm.handle_openai_spec_data)
      end

      local function grok_help()
        dingllm.invoke_llm_and_stream_into_editor({
          url = 'https://api.x.ai/v1/chat/completions',
          model = 'grok-3-mini-beta',
          api_key_name = 'GROK_API_KEY',
          system_prompt = helpful_prompt,
          replace = false,
        }, dingllm.make_openai_spec_curl_args, dingllm.handle_openai_spec_data)
      end

      local function anthropic_help()
        dingllm.invoke_llm_and_stream_into_editor({
          url = 'https://api.anthropic.com/v1/messages',
          model = 'claude-3-7-sonnet-20250219',
          api_key_name = 'ANTHROPIC_API_KEY',
          system_prompt = helpful_prompt,
          replace = false,
        }, dingllm.make_anthropic_spec_curl_args, dingllm.handle_anthropic_spec_data)
      end

      local function anthropic_replace()
        dingllm.invoke_llm_and_stream_into_editor({
          url = 'https://api.anthropic.com/v1/messages',
          model = 'claude-3-7-sonnet-20250219',
          api_key_name = 'ANTHROPIC_API_KEY',
          system_prompt = system_prompt,
          replace = true,
        }, dingllm.make_anthropic_spec_curl_args, dingllm.handle_anthropic_spec_data)
      end

      -- grok
      vim.keymap.set('n', '<leader>lgi', dingllm.prompt_grok_replace, { desc = 'LLM prompt input with Grok' })
      vim.keymap.set({ 'n', 'v' }, '<leader>lgr', grok_replace, { desc = 'llm grok' })
      vim.keymap.set({ 'n', 'v' }, '<leader>lgh', grok_help, { desc = 'llm grok_help' })
      -- anthropic
      vim.keymap.set('n', '<leader>lci', dingllm.prompt_anthropic_replace, { desc = 'LLM prompt input with Claude' })
      vim.keymap.set({ 'n', 'v' }, '<leader>lcr', anthropic_replace, { desc = 'llm anthropic' })
      vim.keymap.set({ 'n', 'v' }, '<leader>lch', anthropic_help, { desc = 'llm anthropic_help' })
    end,
  },
})

