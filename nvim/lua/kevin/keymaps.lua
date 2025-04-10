local keymap = vim.keymap

keymap.set("i", "jk", "<Esc>", { noremap = true, silent = true })
keymap.set("n", "<leader>bn", ":bnext<CR>", { desc = "Next buffer" })
keymap.set("n", "<leader>bp", ":bprev<CR>", { desc = "Previous buffer" })
keymap.set("n", "<leader>bd", ":bd<CR>", { desc = "Delete buffer" })
keymap.set("n", "<Tab>", ":BufferLineCycleNext<CR>", { desc = "Next buffer" })
keymap.set("n", "<S-Tab>", ":BufferLineCyclePrev<CR>", { desc = "Previous buffer" })
keymap.set("n", "<leader>dm", ":DiffviewOpen master...HEAD<CR>", { desc = "Diff vs master" })
