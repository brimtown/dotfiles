" Specify a directory for plugins
call plug#begin('~/.config/nvim/plugged')

" Make sure you use single quotes
Plug 'airblade/vim-gitgutter'
Plug 'ajh17/Spacegray.vim'
Plug 'christoomey/vim-tmux-navigator'
Plug 'djoshea/vim-autoread'
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'
Plug 'mxw/vim-jsx'
Plug 'pangloss/vim-javascript'
Plug 'rking/ag.vim'
Plug 'scrooloose/nerdtree'
Plug 'sjl/vitality.vim'
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
nnoremap <leader>a :Ag 
nnoremap <leader>s :%s/

" navigate splits without C-W
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>

nnoremap <C-[> :tabp<CR>
nnoremap <C-]> :tabn<CR>
nnoremap <C-t> :Te<CR>
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

set showcmd                  " show command in bottom bar
set cursorline               " highlight current line

set nobackup
set noswapfile
set autoread

" Write all writeable buffers when changing buffers or losing focus.
set autowriteall                " Save when doing various buffer-switching things.
autocmd InsertLeave,BufLeave,FocusLost * silent! wall  " Save anytime we leave a buffer or we lose focus.

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

colorscheme spacegray " set colorscheme
let g:airline_theme='zenburn'

" Add flow syntax to vim-javascript
let g:javascript_plugin_flow = 1

" Run prettier as an ALE fixer
let g:ale_fixers = {'javascript': ['prettier']}
let g:ale_fix_on_save = 1

" GitGutter
if exists('&signcolumn')  " Vim 7.4.2201
	set signcolumn=yes
else
	let g:gitgutter_sign_column_always = 1
endif

" air-line
 let g:airline_powerline_fonts = 1

 if !exists('g:airline_symbols')
   let g:airline_symbols = {}
 endif

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