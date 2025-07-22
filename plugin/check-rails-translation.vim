" Title:        Check rails translation
" Description:  A plugin to find translations and add suggestions if missing.
" Last Change:  2025-07-22
" Maintainer:   Mislav Kvesic <https://github.com/Mislavoo7>

if exists("g:loaded_check_rails_translation")
    finish
endif
let g:loaded_check_rails_translation = 1

" Exposes the plugin's functions for use as commands in Vim.
command! -nargs=0 DisplayTime call check-rails-translation#SayHello()
    
