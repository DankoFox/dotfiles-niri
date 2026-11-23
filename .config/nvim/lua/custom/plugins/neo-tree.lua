-- Neo-tree is a Neovim plugin to browse the file system
-- https://github.com/nvim-neo-tree/neo-tree.nvim

vim.pack.add {
  { src = 'https://github.com/nvim-neo-tree/neo-tree.nvim', version = vim.version.range '*' },
  'https://github.com/nvim-lua/plenary.nvim',
  'https://github.com/MunifTanjim/nui.nvim',
}

local toggle_neotree_focus = function()
  if vim.bo.filetype == 'neo-tree' then
    vim.cmd.wincmd 'p'
    if vim.bo.filetype == 'neo-tree' then
      vim.cmd.wincmd 'w'
    end
  else
    vim.cmd 'Neotree focus'
  end
end

vim.keymap.set('n', '<leader>e', toggle_neotree_focus, { desc = 'Neo-tree: Toggle focus with editor' })
vim.keymap.set('n', '<leader>E', toggle_neotree_focus, { desc = 'Neo-tree: Toggle focus with editor' })
vim.keymap.set('n', '<C-n>', '<Cmd>Neotree reveal<CR>', { desc = 'NeoTree reveal', silent = true })

require('neo-tree').setup {
  filesystem = {
    window = {
      mappings = {
        ['<C-n>'] = 'close_window',
      },
    },
  },
}
