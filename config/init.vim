" neovim is nocompatible by default, just set it out of spite
set nocompatible

let mapleader=" "

" Colors
" enables 24-bit colors for TUI
" don't remove this
set termguicolors
syntax enable
set fillchars+=vert:│
runtime colors.vim

colorscheme nord
set background=dark
let g:lightline = { 'colorscheme': 'nord' }

" Use the damn clipboard
set clipboard=unnamedplus

" Activate Plugins
filetype plugin on

" line numbers
set number

" except for terminals
autocmd TermOpen * setlocal nonumber

" Wrap lines
set linebreak
let &showbreak = '\ '

" highlight substitutions
set inccommand=nosplit

" Enable indentation
filetype indent on

" Filetype recognition
filetype on

set autoindent

set tabstop=8

" don't use tabs
set shiftwidth=4
set softtabstop=4
set expandtab

" disable arbitrary code execution on file open
set nomodeline

" Shut up
set noerrorbells
set novisualbell

" Usable search
set ignorecase
set smartcase
set hlsearch
set incsearch

" center search results
nnoremap <silent> n nzz
nnoremap <silent> N Nzz
nnoremap <silent> * *zz
nnoremap <silent> # #zz
nnoremap <silent> g* g*zz

" Navigate wrapped lines properly
nnoremap j gj
nnoremap k gk
vnoremap j gj
vnoremap k gk

" Show min 2 lines above and below cursor
set scrolloff=2

" Show matching brackets when cursor is over them
set showmatch

" Enable mouse interaction
set mouse=a

" make vim regex suck less
set magic

" Normal backspace
set backspace=indent,eol,start

" not useless status line
set ruler

" remove annoying bar
set laststatus=2

" this is important
set hidden

" persistent undo
set undofile
let &undodir = expand('~/.local/share/nvim/undir')
call mkdir(&undodir, 'p')

" When editing a file, always jump to the last known cursor position.
" Don't do it when the position is invalid or when inside an event handler
" (happens when dropping a file on gvim).
autocmd BufReadPost *
            \ if line("'\"") > 0 && line("'\"") <= line("$") |
            \   exe "normal g`\"" |
            \ endif

" Y should work like D
nnoremap Y y$

set shortmess=Iatc

" highlight trailing whitespace
highlight trailing_ws ctermbg = gray guibg = gray
match trailing_ws /\s\+\%#\@<!$/

vnoremap > >gv
vnoremap < <gv
tnoremap <Esc> <C-\><C-n>
tnoremap <C-w> <C-\><C-n><C-w>

" listen for file changes outside of nvim
" https://github.com/neovim/neovim/issues/2127
augroup checktime
    autocmd!
    if !has("gui_running")
        "silent! necessary otherwise throws errors when using command
        "line window.
        autocmd BufEnter,FocusGained,BufEnter,FocusLost,WinLeave * checktime
    endif
augroup END

" disable offscreen matching
let g:matchup_matchparen_offscreen={}

" highlight current line
set cursorline
