" ====================
" Plugins

" Specify a directory for plugins
call plug#begin('~/.local/share/nvim/site/plugged')

" Make sure you use single quotes
Plug 'ajh17/Spacegray.vim'
Plug 'chriskempson/base16-vim'
Plug 'christoomey/vim-tmux-navigator'
Plug 'cocopon/lightline-hybrid.vim'
Plug 'djoshea/vim-autoread'
Plug 'dunckr/js_alternate.vim'
Plug 'github/copilot.vim'
Plug 'haya14busa/incsearch.vim'
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'
Plug 'itchyny/lightline.vim'
Plug 'machakann/vim-highlightedyank'
Plug 'mhinz/vim-grepper'
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'Olical/vim-enmasse'
Plug 'scrooloose/nerdtree'
Plug 'sheerun/vim-polyglot'
Plug 'sjl/vitality.vim'
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-sensible'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-unimpaired'
Plug 'vimwiki/vimwiki'

" Initialize plugin system
call plug#end()

let mapleader="," "change leader

" ==========================
" Language Server Protocol

augroup lsp_aucommands
  au!
  au CursorMoved *.ts,*.tsx,*.less,*.js,*.jsx call CocActionAsync('highlight')
  au CursorHold *.py call CocActionAsync('highlight')
  autocmd CursorHold * silent call CocActionAsync('highlight')
augroup END

inoremap <silent><expr> <Tab> coc#pum#visible() ? coc#pum#confirm() : "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"
inoremap <silent><expr> <C-x><C-z> coc#pum#visible() ? coc#pum#stop() : "\<C-x>\<C-z>"
" remap for complete to use tab and <cr>
inoremap <silent><expr> <C-j>
    \ coc#pum#visible() ? coc#pum#next(1):
    \ <SID>check_back_space() ? "\<C-j>" :
    \ coc#refresh()
inoremap <expr><C-k> coc#pum#visible() ? coc#pum#prev(1) : "\<C-h>"
inoremap <silent><expr> <c-space> coc#refresh()

function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

" Close preview window after the completion is finished
autocmd InsertLeave,CompleteDone * if pumvisible() == 0 | pclose | endif

function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  else
    call CocAction('doHover')
  endif
endfunction

let g:grepper               = {}
let g:grepper.tools         = ['git', 'rg']

" Keybindings
nmap <silent> <space> :call <SID>show_documentation()<CR>
nmap <silent> <leader>d <Plug>(coc-definition)
nmap <silent> <leader>q <Plug>(coc-list-location)
nmap <silent> <leader>t <Plug>(coc-type-definition)
nmap <silent> <leader>i <Plug>(coc-implementation)
nmap <silent> <leader>rn <Plug>(coc-rename)
nmap <silent> <leader>r <Plug>(coc-references)
nmap <leader><space> <Plug>(coc-format-selected)
vmap <leader><space> <Plug>(coc-format-selected)
au FileType typescript.tsx,typescript,javascript,json nmap <leader><space> :CocCommand eslint.executeAutofix<CR>
au FileType typescript.tsx,typescript,javascript,json vmap <leader><space> :CocCommand eslint.executeAutofix<CR>
au FileType py nmap <leader><space> :CocCommand ruff.executeAutofix<CR>
au FileType py vmap <leader><space> :CocCommand ruff.executeAutofix<CR>
nmap <silent> [g <Plug>(coc-diagnostic-prev)
nmap <silent> ]g <Plug>(coc-diagnostic-next)
" Navigate chunks of current buffer
nmap [G <Plug>(coc-git-prevchunk)
nmap ]G <Plug>(coc-git-nextchunk)
" Ppen actions panel
" nmap <silent> [a :CocCommand actions.open<cr>
nmap [a  <Plug>(coc-codeaction-selected)w

" Extensions
let s:coc_extensions = [
      \  'coc-actions',
      \  'coc-css',
      \  'coc-eslint',
      \  'coc-git',
      \  'coc-highlight',
      \  'coc-html',
      \  'coc-jest',
      \  'coc-json',
      \  'coc-prettier',
      \  'coc-tsserver',
      \  'coc-yaml',
      \ ]

set statusline^=%{coc#status()}%{get(b:,'coc_current_function','')}

" ========================
" Keybindings

nnoremap \ :NERDTreeToggle<CR> 
nnoremap \| :NERDTreeFind<CR> 
nnoremap <leader>f :GFiles --exclude-standard --cached --others<CR> 
nnoremap <leader>a :Grepper<CR>
nnoremap <C-P> :Rg!<CR>
nnoremap <leader>A :call js_alternate#run()<CR>
nnoremap <leader>s :%s/
nnoremap <leader>g :Git blame<CR>
nnoremap <leader>G :Gstatus<CR>

nnoremap } <C-d>
nnoremap { <C-u>

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
set hidden
set nowritebackup
set shortmess+=c
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
set mouse=a       "allow scrolling with mouse in terminal
set scroll=8
set re=0          "recommended by yats.vim

set cmdheight=1

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
set timeoutlen=300 ttimeoutlen=100

" Write all writeable buffers when changing buffers or losing focus.
set autowriteall                " Save when doing various buffer-switching things.
set bufhidden=delete
autocmd InsertLeave,BufLeave,FocusLost * nested silent! wall  " Save anytime we leave a buffer or we lose focus.

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

set fillchars+=vert:│

function! MyHighlights() abort
  highlight SignColumn guibg=NONE

  highlight LineNr guibg=NONE guifg=#4f5b66
  highlight CursorLineNr guibg=NONE guifg=#C0C5CE
  hi VertSplit ctermbg=NONE guibg=NONE

  highlight CocErrorSign ctermfg=9 ctermbg=15 guifg=#EC5f67 guibg=NONE
  highlight CocWarningSign ctermfg=11 ctermbg=15 guifg=#FAC863 guibg=NONE
  highlight CocInfoSign ctermfg=11 ctermbg=15 guifg=#6699CC guibg=NONE
  highlight CocHighlightText cterm=underline gui=underline
  highlight CocDiagnosticsError ctermfg=9 ctermbg=15 guifg=#EC5f67 guibg=NONE
  highlight CocErrorFloat ctermfg=9 ctermbg=15 guifg=#EC5f67 guibg=NONE
  highlight CocWarningFloat ctermfg=11 ctermbg=15 guifg=#FAC863 guibg=NONE
  highlight CocInfoFloat ctermfg=11 ctermbg=15 guifg=#6699CC guibg=NONE

  highlight GitGutterAdd guibg=NONE
  highlight GitGutterChange guibg=NONE
  highlight GitGutterDelete guibg=NONE
  highlight GitGutterChangeDelete guibg=NONE
endfunction

augroup MyColors
    autocmd!
    autocmd ColorScheme * call MyHighlights()
augroup END

syntax enable
colorscheme base16-oceanic-dark " set colorscheme

set signcolumn=auto:2

let g:lightline = {
\ 'colorscheme': 'one',
\ 'active': {
\   'left': [ [ 'mode', 'paste' ],
\             [ 'readonly', 'relativepath', 'modified' ] ]
\ },
\ }

let g:fzf_colors =
\ { 'fg':      ['fg', 'Normal'       ],
  \ 'bg':      ['bg', 'Normal'       ],
  \ 'hl':      ['fg', 'Comment'      ],
  \ 'fg+':     ['fg', 'CursorColumn' , 'Normal', 'CursorLine'],
  \ 'bg+':     ['bg', 'CursorColumn', 'CursorLine' ],
  \ 'hl+':     ['fg', 'Statement'    ],
  \ 'info':    ['fg', 'PreProc'      ],
  \ 'prompt':  ['fg', 'Conditional'  ],
  \ 'pointer': ['fg', 'Exception'    ],
  \ 'marker':  ['fg', 'Keyword'      ],
  \ 'spinner': ['fg', 'Label'        ],
  \ 'header':  ['fg', 'Comment'      ] }

let g:NERDTreeHighlightCursorline = 0
let g:highlightedyank_highlight_duration = 500 " highlight yanked region

nmap <leader>sp :call <SID>SynStack()<CR>
function! <SID>SynStack()
  if !exists("*synstack")
    return
  endif
  echo map(synstack(line('.'), col('.')), 'synIDattr(v:val, "name")')
endfunc

" =======================
" Symbols

" gitgutter symbols
let g:gitgutter_sign_added = '+'
let g:gitgutter_sign_modified = '~'
let g:gitgutter_sign_removed = '-'

augroup VimwikiKeyMap
    autocmd!
    autocmd FileType vimwiki inoremap <silent><buffer> <CR>
                \ <C-]><Esc>:VimwikiReturn 1 5<CR>
augroup END
