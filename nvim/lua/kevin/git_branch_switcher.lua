-- git_branch_switcher.lua 
local M = {}

local Job     = require("plenary.job")
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local conf    = require("telescope.config").values

-- Kick off a background fetch so we always see the latest remotes
local function fetch_remotes()
  Job:new({
    command = "git",
    args    = { "fetch", "--all", "--prune" },
  }):start()       -- detached, so the UI never blocks
end

-- Ask Git for a clean list of origin/* branches with no whitespace
local function remote_branches()
  return vim.fn.systemlist(
    "git for-each-ref --format='%(refname:short)' refs/remotes/origin |" ..
    " grep -v '^origin/HEAD$' | sed 's|^origin/||'"
  )
end

local function checkout_branch(branch)
  -- Try to create a local branch tracking the remote
  local result = vim.fn.system({ "git", "switch", "-c", branch, "origin/" .. branch })
  if vim.v.shell_error == 0 then
    return true
  end

  -- If it already exists locally, just switch to it
  if result:match("already exists") then
    vim.fn.system({ "git", "switch", branch })
    return vim.v.shell_error == 0
  end

  -- Anything else is a real error
  vim.notify("Git switch failed:\n" .. result, vim.log.levels.ERROR)
  return false
end

function M.pick_remote_branch()
  fetch_remotes()

  pickers.new({}, {
    prompt_title = "Remote Git Branches",
    finder       = finders.new_table { results = remote_branches() },
    sorter       = conf.generic_sorter({}),
    attach_mappings = function(bufnr, map)
      local function select()
        local entry  = action_state.get_selected_entry()
        local branch = entry and vim.fn.trim(entry.value)
        if not branch or branch == "" then return end

        actions.close(bufnr)
        if checkout_branch(branch) then
          vim.notify("Checked out: " .. branch, vim.log.levels.INFO)
        end
      end

      map("i", "<CR>", select)
      map("n", "<CR>", select)
      return true
    end,
  }):find()
end

-- Key‑mapping (normal mode)
vim.keymap.set("n", "<leader>gC", M.pick_remote_branch, { desc = "Fuzzy‑checkout remote branch" })

return M

