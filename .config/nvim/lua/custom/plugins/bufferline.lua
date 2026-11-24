-- Snazzy buffer line for Neovim
-- https://github.com/akinsho/bufferline.nvim
--
-- mini.icons is already mocked as nvim-web-devicons in init.lua, so bufferline
-- can use those icons without an explicit web-devicons dependency.

vim.pack.add { 'https://github.com/akinsho/bufferline.nvim' }

require('bufferline').setup {
  options = {
    -- Use mini.bufremove for closing so Neo-tree doesn't swallow the window
    close_command = function(bufnum) require('mini.bufremove').delete(bufnum, false) end,
    right_mouse_command = function(bufnum) require('mini.bufremove').delete(bufnum, false) end,

    -- Keep bufferline from drawing over the Neo-tree sidebar
    offsets = {
      {
        filetype = 'neo-tree',
        text = 'Neo-tree',
        highlight = 'Directory',
        text_align = 'left',
        separator = true,
      },
    },
  },
}
