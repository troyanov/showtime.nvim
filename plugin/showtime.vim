if !has('nvim-0.8')
  echohl WarningMsg
  echom "Showtime requires Neovim >= 0.8"
  echohl None
  finish
endif

command! Showtime lua require("showtime").toggle() print(" ")
