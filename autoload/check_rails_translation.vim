function! check_rails_translation#run_check_translation_pattern() abort
  let rails_root = s:FindRailsRoot()
  let results = []
  if rails_root == ''
    echo 'Not in a Rails project'
    return
  endif
  let locales = s:GetAvailableLocales(rails_root)

  let line = getline('.')
  let cursor_col = col('.') - 1 " Convert to 0-based index

  " Pattern to match t("key") or t('key'), and capture the key
  let pattern = '\vt\((["''])\zs[^"'']+\ze\1\)'

  let start_col = 0
  while 1
    " Search for next match starting from current offset
    let match_start = match(line, pattern, start_col)
    if match_start == -1
      break
    endif
    let match_end = matchend(line, pattern, start_col)

    " Check if cursor is inside this match
    if cursor_col >= match_start && cursor_col < match_end
      let key = matchstr(line, pattern, start_col)
      if key != ''
        for locale in locales
          let all_translations = s:LoadTranslations(rails_root, locale, key)
          let results = add(results, all_translations)
        endfor
      else
        echo "Cursor not on a translation key"
      endif
    else
      echo "Cursor not on a translation key"
    endif

    " Move to next match
    let start_col = match_end
  endwhile

  let suggestions = s:TryToMakeSuggestions(results)
endfunction

function! s:GetAvailableLocales(rails_root)
  let app_config = a:rails_root . '/config/application.rb'
  if !filereadable(app_config)
    return ['en']
  endif

  let lines = readfile(app_config)
  for line in lines
    " Match either config.i18n.available_locales OR I18n.available_locales
    if line =~ '\v(i18n|I18n)\.available_locales'
      " Match things like [:en, :hr, :de] or %i[en hr de]
      let list_match = matchstr(line, '\[\zs[^]]*\ze\]')
      if list_match != ''
        " Remove colons and whitespace, split by comma or space
        let raw = substitute(list_match, '[:\s]', '', 'g')
        let locales = split(raw, '[, ]\+')
        return filter(locales, 'v:val != ""')
      endif
    endif
  endfor

  return ['en']
endfunction

function! s:FindRailsRoot()
  let current_dir = expand('%:p:h')
  while current_dir != '/'
    if filereadable(current_dir . '/config/application.rb')
      return current_dir
    endif
    let current_dir = fnamemodify(current_dir, ':h')
  endwhile
  return ''
endfunction

function! s:LoadTranslations(rails_root, locale, key)
  let base = fnamemodify(a:rails_root, ':p')

  let results = []

  let pattern1 = base . '/config/locales/*.' . a:locale . '.yml'
  let files = glob(pattern1, 0, 1)
  for file in files
    let value = s:FindYamlKey(file, a:key, a:locale)
    if type(value) == type([]) && len(value) == 2
      call add(results, value)
    endif
  endfor

  let pattern2 = base . '/config/locales/' . a:locale . '.yml'
  let value = s:FindYamlKey(pattern2, a:key, a:locale)
  if type(value) == type([]) && len(value) == 2
    call add(results, value)
  endif

  " return the results
  let count_results = len(results)
  if count_results == 0
    let final_result = a:locale . ': TRANSLATION MISSING'
    return final_result
  elseif count_results == 1
    let entry = results[0]
    let filename = '/' . fnamemodify(entry[1], ':t')
    let final_result = a:locale . ': ' . entry[0] . " -> " . filename
    return final_result
  else
    let filenames = []
    for entry in results
      let filename = '/' . fnamemodify(entry[1], ':t')
      let filenames = add(filenames, filename)
    endfor

    let final_result = a:locale . ': CONFLICT ' . ' -> ' . join(filenames, ",")
    return final_result
  endif
endfunction

function! s:FindYamlKey(filename, class_key, locale)
  if !filereadable(a:filename)
    echom 'Error: File "' . a:filename . '" is not readable.'
    retur
  endif

  let lines = readfile(a:filename)
  let keys = split(a:class_key, '\.')
  let current_indent = -1
  let target_indents = []
  let found_keys = []

  for i in range(len(lines))
    let line = lines[i]
    let trimmed = substitute(line, '^\s*', '', '')

    " Skip empty lines and comments
    if empty(trimmed) || trimmed[0] == '#'
      continue
    endif

    " Calculate indentation level
    let indent = len(line) - len(trimmed)

    " Extract key from line (everything before the colon)
    let key_match = matchstr(trimmed, '^[^:]*')
    if empty(key_match)
      continue
    endif

    let key_name = substitute(key_match, '^\s*\|\s*$', '', 'g')

    " looking for the first key and this matches
    if len(found_keys) == 0 && key_name == keys[0]
      let found_keys = [key_name]
      let target_indents = [indent]
      let current_indent = indent
    " found some keys, look for the next one
    elseif len(found_keys) > 0 && len(found_keys) < len(keys)
      " Check if this line has the correct indentation (child of previous key)
      if indent > current_indent && key_name == keys[len(found_keys)]
        call add(found_keys, key_name)
        call add(target_indents, indent)
        let current_indent = indent
      " reset if moved to a different branch at the same or higher level
      elseif indent <= target_indents[0]
        if key_name == keys[0]
          let found_keys = [key_name]
          let target_indents = [indent]
          let current_indent = indent
        else
          let found_keys = []
          let target_indents = []
          let current_indent = -1
        endif
      endif
    endif

    " extract the value
    if len(found_keys) == len(keys)
      let value_match = matchstr(trimmed, ':\s*\zs.*')
      if !empty(value_match)
        " Clean up quotes if present
        let value = substitute(value_match, '^["'']\|["'']$', '', 'g')
        return [value, a:filename]
      else
        return 0 
      endif
    endif
  endfor

  return 0 
endfunction


function! s:ShowStyledTranslationPopup(lines) abort
  " Add close button to the lines
  let display_lines = ['[x] Close'] + a:lines

  return popup_create(display_lines, {
        \ 'line': 'cursor+1',
        \ 'col': 'cursor',
        \ 'pos': 'botleft',
        \ 'padding': [0,1,0,1],
        \ 'border': [],
        \ 'minwidth': 30,
        \ 'maxheight': 10,
        \ 'wrap': v:false,
        \ 'zindex': 10,
        \ 'moved': 'word',
        \ 'close': 'click',
        \ 'filter': 'popup_filter_menu',
        \ 'mapping': 0,
        \ 'callback': 's:PopupCallback'
        \ })
endfunction

function! s:PopupCallback(id, result) abort
  " Handle the callback if needed
  if a:result == 1
    " User clicked on first line ([x] Close)
    call popup_close(a:id)
  endif
endfunction

function! s:TryToMakeSuggestions(results) abort
  let default_text = ''
  let missing_locales = []
  let suggestions = []

  " Step 1: Find the first valid translation
  for result in a:results
    if result =~# 'TRANSLATION MISSING'
      " Step 2: Extract locale code (e.g., 'hu')
      let locale = matchstr(result, '^\zs\w\+\ze:')
      call add(missing_locales, locale)
    else
      " Extract the translation text
      let text = matchstr(result, ':\s\zs.\{-}\ze\s*->')
      if default_text == ''
        let default_text = text
      endif
    endif
  endfor

  " Step 3: Use `tgpt` for translation suggestions
  if default_text != '' && executable('tgpt') && g:rails_translation_checker_use_tgpt == 1
    for locale in missing_locales
      let command = 'Translate the phrase: \"' . default_text . '\" to locale \"' . locale . '\" no explaining, no intro, no original phrase just the raw output, just the result, no locale, dont tell me what you are doing and add a pipe | before the phrase'

      " Call tgpt - assuming it's available in $PATH and async use isn't required
      let output = system('tgpt "' . command . '"')

      let clean_output = matchstr(output, '\v\|\s*\zs.*')
      let clean_output_2 = 'Suggestion for ' . locale . ": " . substitute(clean_output, '[[:cntrl:][:punct:]]', '', 'g')
      let suggestions = add(suggestions, clean_output_2)
    endfor
  endif

  let results_with_suggestions = a:results + suggestions

  call s:ShowStyledTranslationPopup(results_with_suggestions)
endfunction

