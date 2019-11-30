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
Plug 'cocopon/lightline-hybrid.vim'
Plug 'djoshea/vim-autoread'
Plug 'dunckr/js_alternate.vim'
Plug 'haya14busa/incsearch.vim'
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'
Plug 'itchyny/lightline.vim'
Plug 'machakann/vim-highlightedyank'
Plug 'majutsushi/tagbar'
Plug 'mhinz/vim-grepper'
Plug 'Olical/vim-enmasse'
Plug 'rking/ag.vim'
Plug 'scrooloose/nerdtree'
Plug 'sheerun/vim-polyglot'
Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
Plug 'sjl/vitality.vim'
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-sensible'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-unimpaired'
Plug 'w0rp/ale'
Plug 'cseelus/vim-colors-tone'

" Initialize plugin system
call plug#end()

" ========================
" Language Server

let g:deoplete#enable_at_startup = 1

" function! LspMaybeHover(is_running) abort
"   if a:is_running.result
"     call LanguageClient_textDocument_hover()
"   endif
" endfunction

function! LspMaybeHighlight(is_running) abort
  if a:is_running.result
    call LanguageClient#textDocument_documentHighlight()
  endif
endfunction

augroup lsp_aucommands
  au!
  " au CursorHold *.ts,*.tsx call LanguageClient#isAlive(function('LspMaybeHover'))
  au CursorMoved *.ts,*.tsx call LanguageClient#isAlive(function('LspMaybeHighlight'))
augroup END

" (Optionally) automatically start language servers.
let g:LanguageClient_autoStart = 1
" Disable text after end of line
let g:LanguageClient_useVirtualText=0
let g:LanguageClient_useFloatingHover=1
" Logging
let g:LanguageClient_loggingFile = '/tmp/LanguageClient.log'
let g:LanguageClient_loggingLevel = 'INFO'
let g:LanguageClient_serverStderr = '/tmp/LanguageServer.log'

let g:LanguageClient_rootMarkers = {
\ 'typescript': ['tsconfig.json'],
\ 'typescript.tsx': ['tsconfig.json'],
\ }

let g:LanguageClient_serverCommands = {
\ 'javascript': ['javascript-typescript-stdio'],
\ 'javascript.jsx': ['javascript-typescript-stdio'],
\ 'typescript': ['typescript-language-server', '--stdio'],
\ 'typescript.tsx': ['typescript-language-server', '--stdio'],
\ 'terraform': ['terraform-lsp'],
\ }
let g:LanguageClient_diagnosticsList = 'Location'

inoremap <expr> <Tab> pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"

" Close preview window after the completion is finished
autocmd InsertLeave,CompleteDone * if pumvisible() == 0 | pclose | endif

" ========================
" Keybindings

let mapleader="," "change leader

command! -nargs=1 Workspace :call LanguageClient_workspace_symbol(<f-args>)

" Language Client
nnoremap <silent> <space> :call LanguageClient_textDocument_hover()<CR>
nnoremap <silent> <leader>d :call LanguageClient_textDocument_definition()<CR>
nnoremap <silent> <leader>r :call LanguageClient_textDocument_rename()<CR>
nnoremap <silent> <leader>q :call LanguageClient_textDocument_documentSymbol()<CR>
nnoremap <silent> <leader>w :Workspace 
nnoremap <silent> <leader>Q :call LanguageClient_textDocument_references()<CR>
" nnoremap <silent> <leader>F :call LanguageClient_textDocument_formatting()<CR>
" nnoremap <silent> ta :call LanguageClient_textDocument_codeAction()<CR>

nnoremap \ :NERDTreeToggle<CR> 
nnoremap \| :NERDTreeFind<CR> 
nnoremap <leader>f :GFiles --exclude-standard --cached --others<CR> 
nnoremap <leader>a :Grepper<CR>
nnoremap <leader>A :call js_alternate#run()<CR>
nnoremap <leader>s :%s/
nnoremap <leader>g :Gblame<CR>
nnoremap <leader>G :Gstatus<CR>
nnoremap <leader><space> :ALEFix<CR>

" navigate splits without C-W
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>

" resize split with Shift+Arrow Keys
nnoremap <S-Left> :vertical resize -3<CR>
nnoremap <S-Right> :vertical resize +3<CR>
nnoremap <S-Up> :resize -3<CR>
nnoremap <S-Down> :resize +3<CR>

" allow copying from nvim to system clipboard within tmux
vnoremap <S-y> "+y

" search
map /  <Plug>(incsearch-forward)
map ?  <Plug>(incsearch-backward)
map g/ <Plug>(incsearch-stay)

" tabs
nnoremap tn  :tabnew<CR>
nnoremap t]  :tabnext<CR>
nnoremap t[  :tabprev<CR>
nnoremap td  :tabclose<CR>

" =========================
" Settings

set number          "display linenumbers

set tabstop=2       " number of visual spaces per TAB
set softtabstop=2   " number of spaces in tab when editing
set shiftwidth=2    " number of spaces to use for autoindent
set expandtab       " tabs are space
set autoindent
set copyindent      " copy indent from the previous line
set list            " show whitespace
set showmatch       " show matching braces
set splitright
set splitbelow
set colorcolumn=81
set noshowmode      " don't show default Vim --INSERT-- text
set inccommand=nosplit       " see results of sed immediately
set updatetime=300

set showcmd                  " show command in bottom bar
set cursorline               " highlight current line

set nobackup
set noswapfile
set autoread
set nohlsearch    "disable highlighting after the search
set nofoldenable

set cmdheight=2

if has("multi_byte")
  " ▒ ▩ ▨ ▢ ▞ ╳
  set listchars=nbsp:▒,tab:▸\ ,extends:>,precedes:<,trail:·
  let &sbr = nr2char(8618).' '
else
  set listchars=tab:\│\ ,trail:-,extends:>,precedes:<,nbsp:+
  let &sbr = '+++ '
endif


" ========================
" Autosave

" decrease timeout length when hitting escape
set timeoutlen=1000 ttimeoutlen=0

" Write all writeable buffers when changing buffers or losing focus.
set autowriteall                " Save when doing various buffer-switching things.
autocmd InsertLeave,BufLeave,FocusLost * nested silent! wall  " Save anytime we leave a buffer or we lose focus.

" =======================
" Linting

" Add flow syntax to vim-javascript
let g:javascript_plugin_flow = 1

let g:ale_echo_msg_format = '[%linter%] %s'
let g:ale_linters = { 'javascript': ['flow', 'eslint'], 'typescript': ['eslint'] }

" Setup Ale fixers
let g:ale_fixers = {'javascript': ['prettier', 'eslint'], 'typescript': ['prettier', 'eslint'], 'terraform': ['terraform']}
autocmd BufNewFile,BufRead *.tsx set filetype=typescript.tsx

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

let g:lightline = {
\ 'colorscheme': 'hybrid',
\ 'active': {
\   'left': [ [ 'mode', 'paste' ],
\             [ 'readonly', 'relativepath', 'modified' ] ]
\ },
\ }

let g:highlightedyank_highlight_duration = 500 " highlight yanked region

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
