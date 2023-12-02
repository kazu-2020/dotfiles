return {
  'smoka7/hop.nvim',
  event = 'VeryLazy',
  config = function()
    local hop = require('hop')
    local hop_hint = require('hop.hint')

    hop.setup()

    vim.keymap.set('', 'f', function()
      hop.hint_char1({
        direction = hop_hint.HintDirection.AFTER_CURSOR,
        current_line_only = true
      })
    end, { desc = 'デフォルトの f の挙動を hop に置き換え' })

    vim.keymap.set('', 'F', function()
      hop.hint_char1({
        direction = hop_hint.HintDirection.BEFORE_CURSOR,
        current_line_only = true
      })
    end, { desc = 'デフォルトの F の挙動を hop に置き換え' })


    vim.keymap.set('n', '<leader>w', function()
      hop.hint_words()
    end, { desc = '任意の単語に移動する' })

    vim.keymap.set('v', '<leader>w', function()
      hop.hint_words({
        direction = hop_hint.HintDirection.AFTER_CURSOR,
        hint_position = require('hop.hint').HintPosition.END
      })
    end, { desc = 'カーソル以降にある任意の単語の末尾に移動する' })

    vim.keymap.set('n', '<leader>f', function()
      hop.hint_patterns()
    end, { desc = '曖昧検索を使用して、カーソル移動を行う' })

    vim.keymap.set('v', '<leader>f', function()
      hop.hint_patterns({
        direction = hop_hint.HintDirection.AFTER_CURSOR,
        hint_position = hop_hint.HintPosition.END
      })
    end, { desc = '曖昧検索を使用して、カーソル以降にある任意の単語の末尾に移動する' })
  end
}
