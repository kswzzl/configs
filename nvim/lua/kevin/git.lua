require("gitsigns").setup({
  current_line_blame = true,
  current_line_blame_opts = {
    delay = 100,
    virt_text_pos = "eol",
  },
  on_attach = function(bufnr)
    local gs = package.loaded.gitsigns
    local map = vim.keymap.set

    map("n", "]c", gs.next_hunk, { buffer = bufnr, desc = "Next hunk" })
    map("n", "[c", gs.prev_hunk, { buffer = bufnr, desc = "Previous hunk" })
    map("n", "<leader>gb", gs.toggle_current_line_blame, { buffer = bufnr, desc = "Toggle blame" })
    map("n", "<leader>gs", gs.stage_hunk, { buffer = bufnr, desc = "Stage hunk" })
    map("n", "<leader>gr", gs.reset_hunk, { buffer = bufnr, desc = "Reset hunk" })
    map("n", "<leader>gS", gs.stage_buffer, { buffer = bufnr, desc = "Stage buffer" })
    map("n", "<leader>gu", gs.undo_stage_hunk, { buffer = bufnr, desc = "Undo stage" })
    map("n", "<leader>gd", gs.diffthis, { buffer = bufnr, desc = "Diff this file" })
  end,
})

-- fuzzy remote branch pull function
local pick_remote_branch = function()
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  local conf = require("telescope.config").values

  -- Get remote branches (strip remotes/origin/)
  local branches = vim.fn.systemlist("git branch -r | grep -v HEAD | sed 's|origin/||' | sort -u")

  pickers.new({}, {
    prompt_title = "Remote Git Branches",
    finder = finders.new_table {
      results = branches,
    },
    sorter = conf.generic_sorter({}),
    attach_mappings = function(_, map)
      actions.select_default:replace(function()
        actions.close()
        local selection = action_state.get_selected_entry()[1]
        -- Checkout the remote branch locally
        vim.cmd("Git checkout -b " .. selection .. " origin/" .. selection)
      end)
      return true
    end,
  }):find()
end

-- vim-fugitive keybindings
vim.keymap.set("n", "<leader>g", ":Git<CR>", { desc = "Open Git UI" })
vim.keymap.set("n", "<leader>gl", ":Git log<CR>", { desc = "Git log" })
vim.keymap.set("n", "<leader>gc", ":Git commit<CR>", { desc = "Git commit" })
vim.keymap.set("n", "<leader>gp", ":Git push<CR>", { desc = "Git push" })
vim.keymap.set("n", "<leader>gbf", ":Git blame<CR>", { desc = "Git blame full" })

