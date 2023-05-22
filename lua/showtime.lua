local M = {}

M.enabled = false
M.initial = {}

local function setfield(f, v)
  local t = _G
  for w, d in string.gmatch(f, '([%w_]+)(.?)') do
    if d == '.' then
      t[w] = t[w] or {}
      t = t[w]
    else
      t[w] = v
    end
  end
end

local function getfield(f)
  local v = _G
  for w in string.gmatch(f, '[%w_]+') do
    v = v[w]
  end
  return v
end

M.opts = {
  { name = 'vim.opt.colorcolumn', disabled = {} },
  { name = 'vim.opt.cursorline', disabled = false },
  { name = 'vim.opt.foldcolumn', disabled = '0' },
  { name = 'vim.opt.laststatus', disabled = 1 },
  { name = 'vim.opt.number', disabled = false },
  { name = 'vim.opt.relativenumber', disabled = false },
  { name = 'vim.opt.ruler', disabled = false },
  { name = 'vim.opt.showtabline', disabled = 0 },
  { name = 'vim.opt.signcolumn', disabled = 'no' },
  {
    name = 'vim.opt.guicursor',
    disabled = function()
      if vim.opt.termguicolors then
        cursor_highlight = vim.api.nvim_get_hl(0, { name = 'Cursor' })
        vim.api.nvim_set_hl(0, 'TransparentCursor', {
          bg = cursor_highlight.bg,
          fg = cursor_highlight.fg,
          blend = 100,
        })
        vim.opt.guicursor:append 'a:TransparentCursor'
      end
    end,
    initial = function()
      if vim.opt.termguicolors then
        vim.opt.guicursor:remove 'a:TransparentCursor'
      end
    end,
  },
}

local function toggle_opts(options)
  if M.enabled then
    for _, opt in pairs(M.opts) do
      if type(opt.disabled) == 'function' then
        opt.disabled()
      else
        if options.save then
          opt.initial = getfield(opt.name)
        end
        setfield(opt.name, opt.disabled)
      end
    end
  else
    for _, opt in pairs(M.opts) do
      if type(opt.initial) == 'function' then
        opt.initial()
      else
        setfield(opt.name, opt.initial)
      end
    end
  end
end

M.keymaps = {
  {
    lhs = ']',
    rhs = '<cmd>:bnext<CR>',
  },
  {
    lhs = '[',
    rhs = '<cmd>:bprev<CR>',
  },
}

M.disabled_keymaps = {}

local function toggle_keymaps()
  if M.enabled then
    for _, keymap in pairs(M.keymaps) do
      vim.keymap.set(
        'n',
        keymap.lhs,
        keymap.rhs,
        { buffer = 0, nowait = true, silent = true }
      )
    end

    vim.api.nvim_create_autocmd({ 'BufWinEnter' }, {
      callback = function()
        for _, keymap in pairs(M.keymaps) do
          vim.keymap.set(
            'n',
            keymap.lhs,
            keymap.rhs,
            { buffer = 0, nowait = true, silent = true }
          )
        end
        toggle_opts { save = false }
      end,
    })
  else
    local bufs = vim.api.nvim_list_bufs()
    for _, buf in pairs(bufs) do
      local buf_keymaps = vim.api.nvim_buf_get_keymap(buf, 'n')
      for _, keymap in pairs(M.keymaps) do
        for _, buf_keymap in pairs(buf_keymaps) do
          if buf_keymap.lhs == keymap.lhs then
            vim.keymap.del('n', keymap.lhs, { buffer = buf })
          end
        end
      end
    end
  end
end

function M.toggle()
  M.enabled = not M.enabled
  toggle_opts { save = true }
  toggle_keymaps()
end

return M
