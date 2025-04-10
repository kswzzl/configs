-- leader key
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- load configs
require("kevin.options")
require("kevin.keymaps")
require("kevin.plugins")
require("kevin.git")
require("kevin.git_branch_switcher")
