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

  -- Optional: fetch all remotes first
  vim.fn.system("git fetch --all")

  -- Get a list of remote branches (remove origin/ prefix)
  local branches = vim.fn.systemlist("git branch -r | grep -v HEAD | sed 's|origin/||' | sort -u")

  pickers.new({}, {
    prompt_title = "Remote Git Branches",
    finder = finders.new_table {
      results = branches,
    },
    sorter = conf.generic_sorter({}),
    attach_mappings = function(prompt_bufnr, map)
      local checkout = function()
        local selection = action_state.get_selected_entry()
        local branch = selection and selection.value
        if branch then
          actions.close(prompt_bufnr)

          -- Run Git checkout command and capture output
          local result = vim.fn.system("git checkout -b " .. branch .. " origin/" .. branch)
          local code = vim.v.shell_error

          if code ~= 0 then
            vim.notify("Git checkout failed:\n" .. result, vim.log.levels.ERROR)
          else
            vim.notify("Checked out remote branch: " .. branch, vim.log.levels.INFO)
          end
        end
      end

      map("i", "<CR>", checkout)
      map("n", "<CR>", checkout)
      return true
    end,
  }):find()
end

vim.keymap.set("n", "<leader>gC", pick_remote_branch, { desc = "Fuzzy checkout remote branch" })

-- vim-fugitive keybindings
vim.keymap.set("n", "<leader>g", ":Git<CR>", { desc = "Open Git UI" })
vim.keymap.set("n", "<leader>gl", ":Git log<CR>", { desc = "Git log" })
vim.keymap.set("n", "<leader>gc", ":Git commit<CR>", { desc = "Git commit" })
vim.keymap.set("n", "<leader>gp", ":Git push<CR>", { desc = "Git push" })
vim.keymap.set("n", "<leader>gbf", ":Git blame<CR>", { desc = "Git blame full" })

