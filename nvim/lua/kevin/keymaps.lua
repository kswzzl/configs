# vim: set tabstop=2 shiftwidth=2 expandtab:

local keymap = vim.keymap

keymap.set("i", "jk", "<Esc>", { noremap = true, silent = true })
keymap.set("n", "qq", ":qall<CR>", { desc = "quit all" })
keymap.set("n", "<leader>bn", ":bnext<CR>", { desc = "next buffer" })
keymap.set("n", "<leader>bp", ":bprev<CR>", { desc = "previous buffer" })
keymap.set("n", "<Tab>", ":BufferLineCycleNext<CR>", { desc = "Next buffer" })
keymap.set("n", "<S-Tab>", ":BufferLineCyclePrev<CR>", { desc = "Previous buffer" })
keymap.set("n", "<leader>dm", ":DiffviewOpen master...HEAD<CR>", { desc = "diff vs master" })
keymap.set("n", "<leader>dx", ":DiffviewClose<CR>", { desc = "exit diffview" })
