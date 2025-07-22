" Title:        Check rails translation
" Description:  A plugin to find translations and add suggestions if missing.
" Last Change:  2025-07-22
" Maintainer:   Mislav Kvesic <https://github.com/Mislavoo7>

if exists("g:loaded_check_rails_translation")
  finish
endif
let g:loaded_check_rails_translation = 1

if !exists("g:rails_translation_checker_use_tgpt")
  let g:rails_translation_checker_use_tgpt = 1
endif


" Exposes the plugin's functions for use as commands in Vim.
command! -nargs=0 CheckTranslationPattern call check_rails_translation#run_check_translation_pattern()
