return {
  'machakann/vim-sandwich',
  event = 'VeryLazy',
  config = function()
    vim.keymap.set({'n', 'x'}, 's', '<Nop>')
  end
}
