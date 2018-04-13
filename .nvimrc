" ====================
" Plugins

" Specify a directory for plugins
call plug#begin('~/.config/nvim/plugged')

" Make sure you use single quotes
Plug 'airblade/vim-gitgutter'
Plug 'ajh17/Spacegray.vim'
Plug 'autozimu/LanguageClient-neovim', {
    \ 'branch': 'next',
    \ 'do': 'bash install.sh',
    \ }
Plug 'chriskempson/base16-vim'
Plug 'christoomey/vim-tmux-navigator'
Plug 'djoshea/vim-autoread'
Plug 'edkolev/tmuxline.vim'
Plug 'haya14busa/incsearch.vim'
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'
Plug 'mhinz/vim-grepper'
Plug 'mxw/vim-jsx'
Plug 'pangloss/vim-javascript'
Plug 'roxma/nvim-completion-manager'
Plug 'rking/ag.vim'
Plug 'scrooloose/nerdtree'
Plug 'sjl/vitality.vim'
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-sensible'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-unimpaired'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'w0rp/ale'

" Initialize plugin system
call plug#end()

" ========================
" Keybindings

let mapleader="," "change leader
nnoremap \ :NERDTreeToggle<CR> 
nnoremap \| :NERDTreeFind<CR> 
nnoremap <leader>f :GFiles --exclude-standard --cached --others<CR> 
nnoremap <leader>a :Grepper<CR>
nnoremap <leader>s :%s/
nnoremap <leader>g :Gblame<CR>
nnoremap <leader>gs :Gstatus<CR>
nnoremap <leader><space> :ALEFix<CR>

" navigate splits without C-W
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>

" vim tabs
nnoremap <C-[> :tabp<CR>
nnoremap <C-]> :tabn<CR>
nnoremap <C-t> :Te<CR>

" search
map /  <Plug>(incsearch-forward)
map ?  <Plug>(incsearch-backward)
map g/ <Plug>(incsearch-stay)

" =========================
" Settings

set number		"display linenumbers

set tabstop=2       " number of visual spaces per TAB
set softtabstop=2   " number of spaces in tab when editing
set shiftwidth=2    " number of spaces to use for autoindent
set expandtab       " tabs are space
set autoindent
set copyindent      " copy indent from the previous line
set list            " show whitespace
set listchars=trail:·
set showmatch       " show matching braces
set splitright
set splitbelow
set colorcolumn=81

set showcmd                  " show command in bottom bar
set cursorline               " highlight current line

set nobackup
set noswapfile
set autoread
set nohlsearch    "disable highlighting after the search

" ========================
" Autosave

" decrease timeout length when hitting escape
set timeoutlen=1000 ttimeoutlen=0

" Write all writeable buffers when changing buffers or losing focus.
set autowriteall                " Save when doing various buffer-switching things.
autocmd InsertLeave,BufLeave,FocusLost * nested silent! wall  " Save anytime we leave a buffer or we lose focus.

" =======================
" Autocomplete

let g:LanguageClient_serverCommands = {
\ 'javascript': ['flow-language-server', '--stdio'],
\ 'javascript.jsx': ['flow-language-server', '--stdio'],
\ }

" (Optionally) automatically start language servers.
let g:LanguageClient_autoStart = 1

inoremap <expr> <Tab> pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"

nnoremap <silent> K :call LanguageClient_textDocument_hover()<CR>
nnoremap <silent> gd :call LanguageClient_textDocument_definition()<CR>
nnoremap <silent> <F2> :call LanguageClient_textDocument_rename()<CR>

" =======================
" Linting

" Add flow syntax to vim-javascript
let g:javascript_plugin_flow = 1

" Run prettier as an ALE fixer
let g:ale_fixers = {'javascript': ['prettier']}

"  =======================
" Colors & themes

set background=dark

let $NVIM_TUI_ENABLE_TRUE_COLOR=1
if has("termguicolors")     " set true colors
    set t_8f=\[[38;2;%lu;%lu;%lum
    set t_8b=\[[48;2;%lu;%lu;%lum
    set termguicolors
endif

set fillchars="" "remove the pipe operator from splits

function! MyHighlights() abort
  highlight SignColumn guibg=NONE

  highlight LineNr guibg=NONE guifg=#27292D
  highlight CursorLineNr guibg=NONE

  highlight ALEErrorSign ctermfg=9 ctermbg=15 guifg=#cc6666 guibg=NONE
  highlight ALEWarningSign ctermfg=11 ctermbg=15 guifg=#f0c674 guibg=NONE

  highlight GitGutterAdd guibg=NONE
  highlight GitGutterChange guibg=NONE
  highlight GitGutterDelete guibg=NONE
  highlight GitGutterChangeDelete guibg=NONE
endfunction

augroup MyColors
    autocmd!
    autocmd ColorScheme * call MyHighlights()
augroup END

colorscheme base16-tomorrow-night " set colorscheme
let g:airline_theme='zenburn'

" GitGutter
if exists('&signcolumn')  " Vim 7.4.2201
	set signcolumn=yes
else
	let g:gitgutter_sign_column_always = 1
endif

autocmd BufWritePost * GitGutter

" air-line
 let g:airline_powerline_fonts = 1

 if !exists('g:airline_symbols')
   let g:airline_symbols = {}
 endif

" =======================
" Symbols

" ale symbols
let g:ale_sign_error = "┃"
let g:ale_sign_warning = "┃"

" gitgutter symbols
let g:gitgutter_sign_added = '+'
let g:gitgutter_sign_modified = '~'
let g:gitgutter_sign_removed = '-'

" unicode symbols
let g:airline_left_sep = '»'
let g:airline_left_sep = '▶'
let g:airline_right_sep = '«'
let g:airline_right_sep = '◀'
let g:airline_symbols.linenr = '␊'
let g:airline_symbols.linenr = '␤'
let g:airline_symbols.linenr = '¶'
let g:airline_symbols.branch = '⎇'
let g:airline_symbols.paste = 'ρ'
let g:airline_symbols.paste = 'Þ'
let g:airline_symbols.paste = '∥'
let g:airline_symbols.whitespace = 'Ξ'

" airline symbols
let g:airline_left_sep = ''
let g:airline_left_alt_sep = ''
let g:airline_right_sep = ''
let g:airline_right_alt_sep = ''
let g:airline_symbols.branch = ''
let g:airline_symbols.readonly = ''
let g:airline_symbols.linenr = ''
