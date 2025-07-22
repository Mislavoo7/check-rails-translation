# Rails Translation Checker

A Vim plugin for Ruby on Rails developers that checks translation patterns in your code against your locale files.

## Features

- **Pattern Detection**: Detects Rails translation patterns like `t('pages_nav.discounts')`, `t('pages_nav.about')`, `t('pages_nav.news')`, etc.
- **Validation**: Checks if translations exist in your `config/locales` YAML files
- **Conflict Detection**: Identifies when the same translation key exists in multiple locale files (but when the duplication is in the same will - I will fix that in the future)
- **Missing Translation Alerts**: Warns when translations are missing from your locale files
- **AI Translation Suggestions**: Uses [tgpt](https://github.com/aandrew-me/tgpt) to suggest translations for missing keys (optional)

## Installation

### Using vim-plug
```vim
Plug 'yourusername/rails-translation-checker'
```

### Using Vundle
```vim
Plugin 'yourusername/rails-translation-checker'
```

### Using Pathogen
```bash
cd ~/.vim/bundle
git clone https://github.com/yourusername/rails-translation-checker.git
```

## Usage

### Command
Place your cursor over a translation pattern (e.g., `t('pages_nav.discounts')`) and run:
```vim
:CheckTranslationPattern
```
Or map it to key combination.

### Key Mapping (Recommended)
Add this to your `.vimrc` for quick access:
```vim
nnoremap <leader>i :CheckTranslationPattern<CR>
```

With this mapping, simply press `<leader>i` while your cursor is over a translation pattern.

## Output
It will open a popup with the results.

![untitled (1)](https://github.com/user-attachments/assets/e4359140-0066-4289-b4f2-83aed3863c6a)


## AI 
Uses [tgpt](https://github.com/aandrew-me/tgpt) to suggest translations for missing keys. To turn off tgpt-powered translation suggestions:
```
let g:rails_translation_checker_use_tgpt = 0
```

## TODO
- Find conflicts inside a file
