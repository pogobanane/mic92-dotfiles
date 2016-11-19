let s:python_interpreter = 'python2'

" Leader
let mapleader = " "

if has("nocompatible")
  set nocompatible " Use Vim settings, rather then Vi settings
end
set mouse =
set ruler " show the cursor position all the time
set cursorline " highlight current line
set showcmd " display incomplete commands
set incsearch " do incremental searching
set laststatus=2 " Always display the status line
set smartcase
set ignorecase
set showmatch     " Show matching bracets when text indicator is over them
set autowrite     " write a modified buffer on each :next ,  ...

set modeline      " React on modlines in files
set hlsearch      " highlightthe last used search pattern
set nojoinspaces
set autoread

set wildignore=*.bak,*.o,*.e,*~      " wildmenu: ignore these extensions
set iskeyword+=_,-  " these characters also belong to a word
set wrap                             " do wrap lines
set noerrorbells                     " disable error bells
set novisualbell                     " disable beep
set backspace=indent,eol,start       " backspacing over everything in insert mode
set browsedir=current                " which directory to use for the file browser
set shell=bash
" Softtabs, 2 spaces
set tabstop=2
set shiftwidth=2
set expandtab
set textwidth=80

if ! $SSH_CONNECTION
  set clipboard+=unnamedplus
endif

set undofile
set undoreload=10000
set undodir=$HOME/.vimundo
set backupdir =$HOME/.vim.backup
set directory=$HOME/.vim.temp
silent !mkdir -p "$HOME/.vim.temp" "$HOME/.vim.backup"

" enable spelling
"set spell
"set complete+=kspell

" Open new split panes to right and bottom, which feels more natural
set splitbelow
set splitright

if &termencoding == ""
  let &termencoding = &encoding
endif
set encoding=utf-8
setglobal fileencodings=ucs-bom,utf-8,default,latin1

syntax on
filetype plugin indent on

runtime macros/matchit.vim

call plug#begin('~/.vim/plugged')
Plug 'bling/vim-airline'
Plug 'pearofducks/ansible-vim'
Plug 'Raimondi/delimitMate'
Plug 'scrooloose/nerdtree'
Plug 'bronson/vim-trailing-whitespace'
Plug 'altercation/vim-colors-solarized'
Plug 'scrooloose/syntastic'
Plug 'airblade/vim-gitgutter'
if has("python")
  Plug 'Valloric/YouCompleteMe', { 'do': 'python2 ./install.py --clang-completer --gocode-completer --tern-completer --racer-completer' }
  Plug 'SirVer/ultisnips'
  Plug 'Trevoke/ultisnips-rspec'
endif
Plug 'kien/ctrlp.vim'
Plug 'freitass/todo.txt-vim'
Plug 'dhruvasagar/vim-table-mode'
Plug 'fatih/vim-go'
Plug 'rking/ag.vim'
Plug 'ompugao/uncrustify-vim', { 'for': ['c', 'cpp'] }
Plug 'rust-lang/rust.vim'
call plug#end()

" Switch syntax highlighting on, when the terminal has colors
" Also switch on highlighting the last used search pattern.
if (&t_Co > 2 || has("gui_running"))
  " Enable 256 colors
  set t_Co=256
  "colorscheme zenburn
  let g:solarized_termcolors=256
  set background=light
  "set background=dark
  colorscheme solarized
endif


augroup vimrcEx
  au!

  " For all text files set 'textwidth' to 78 characters.
  "   autocmd FileType text setlocal textwidth=78  au!
  "
  " For all text files set 'textwidth' to 78 characters.
  autocmd FileType text setlocal textwidth=78
  autocmd BufReadPost *
    \ if line("'\"") > 0 && line("'\"") <= line("$") |
    \   exe "normal g`\"" |
    \ endif
augroup END

" Display extra whitespace
set list listchars=tab:»·,trail:·

map <C-n> :NERDTreeToggle<CR>

" Use Ag (https://github.com/ggreer/the_silver_searcher) instead of Grep when
" available
if executable('ag')
" Use Ag over Grep
  set grepprg=ag\ --nogroup\ --nocolor

" Use ag in CtrlP for listing files. Lightning fast and respects .gitignore
  let g:ctrlp_user_command = 'ag %s -l --nocolor --hidden -g ""'

" ag is fast enough that CtrlP doesn't need to cache
  let g:ctrlp_use_caching = 0

endif
let g:ctrlp_working_path_mode = 'ra'
let g:ctrlp_dont_split = 'NERD_tree_2'
" bind K to grep word under cursor
nnoremap K :grep! "\b<C-R><C-W>\b"<CR>:cw<CR>

" Tab completion
" will insert tab at beginning of line,
" will use completion if not at beginning
set wildmode=list:longest,list:full
set complete=.,w,t
function! InsertTabWrapper()
    let col = col('.') - 1
    if !col || getline('.')[col - 1] !~ '\k'
        return "\<tab>"
    else
        return "\<c-p>"
    endif
endfunction
inoremap <Tab> <c-r>=InsertTabWrapper()<cr>

" Exclude Javascript files in :Rtags via rails.vim due to warnings when parsing
let g:Tlist_Ctags_Cmd="ctags --exclude='*.js'"

" Index ctags from any project, including those outside Rails
map <Leader>ct :!ctags -R .<CR>

" Switch between the last two files
nnoremap <leader><leader> <c-^>

" Treat <li> and <p> tags like the block tags they are
let g:html_indent_tags = 'li\|p'

" check file change every 4 seconds ('CursorHold') and reload the buffer upon detecting change
au CursorHold * checktime

" Markdown files end in .md
au BufEnter *.md set filetype=markdown

" python setup
au BufEnter *.py set ai sw=4 ts=4 sta et fo=croql

" rust setup
au BufEnter *.rs set ai sw=4 ts=4 sta et fo=croql

" go setup
au BufEnter *.go setlocal noet ts=4 sw=4 sts=4 list!

" tabs for C/C++ projects
au BufEnter *.h setlocal noet ts=4 sw=4 sts=4 list!
au BufEnter *.c setlocal noet ts=4 sw=4 sts=4 list!
au BufEnter *.cpp setlocal noet ts=4 sw=4 sts=4 list!

let g:UltiSnipsExpandTrigger="<leader><Tab>"
let g:UltiSnipsJumpForwardTrigger="<leader><Tab>"
let g:UltiSnipsJumpBackwardTrigger="<leader><s-Tab>"
let g:UltiSnipsSnippetsDir        = expand('~/.vim/UltiSnips')
let g:UltiSnipsSnippetDirectories = [expand('~/.vim/UltiSnips')]

"open zipped files
au BufReadCmd *.jar,*.xpi,*.wgt call zip#Browse(expand("<amatch>"))

" geojson
au BufNewFile,BufRead *.geojson set filetype=json

" go in normal mode with jj
inoremap jj <Esc>

" I18n translations
vmap <Leader>z :call I18nTranslateString()<CR>

" change in the directory of the current file
"autocmd BufEnter * :lchdir %:p:h

let g:tagbar_type_ruby = {
    \ 'kinds' : [
        \ 'm:modules',
        \ 'c:classes',
        \ 'd:describes',
        \ 'C:contexts',
        \ 'f:methods',
        \ 'F:singleton methods'
    \ ]
\ }

" Repeat "." in visual mode
vnoremap . :norm.<CR>

" Highlight VCS conflict markers
match ErrorMsg '^\(<\|=\|>\)\{7\}\([^=].\+\)\?$'

set pastetoggle=<F3>

" autocmd! BufWritePost * Neomake

" conflict with YouCompleteMe
let g:UltiSnipsExpandTrigger="<c-j>"
let g:UltiSnipsJumpForwardTrigger="<c-j>"
let g:UltiSnipsJumpBackwardTrigger="<c-k>"

nnoremap <leader>jd :YcmCompleter GoToDeclaration<CR>
nnoremap <leader>je :YcmCompleter GotoDefinition<CR>
nnoremap <leader>jf :YcmCompleter FixIt<CR>
nnoremap <leader>jt :YcmCompleter GetType<CR>

command! -bar SudoWrite :
      \ setlocal nomodified |
      \ exe (has('gui_running') ? '' : 'silent') 'write !sudo tee % >/dev/null' |
      \ let &modified = v:shell_error

cmap w!! SudoWrite

if has("python")
  :command! -nargs=+ Calc :py print <args>
  :py from math import *
else
  command! -nargs=+ Calc :!python -c "from math import *; print <args>"
end

au FileType go nmap <Leader>s <Plug>(go-implements)
au FileType go nmap <Leader>i <Plug>(go-info)
au FileType go nmap <Leader>gd <Plug>(go-doc)
au FileType go nmap <Leader>gv <Plug>(go-doc-vertical)
au FileType go nmap <Leader>gb <Plug>(go-doc-browser)

au FileType go nmap <leader>r <Plug>(go-run)
au FileType go nmap <leader>b <Plug>(go-build)
au FileType go nmap <leader>t <Plug>(go-test)
au FileType go nmap <leader>c <Plug>(go-coverage)
au FileType go nmap <Leader>ds <Plug>(go-def-split)
au FileType go nmap <Leader>dv <Plug>(go-def-vertical)
au FileType go nmap <Leader>dt <Plug>(go-def-tab)

au FileType go nmap <Leader>e <Plug>(go-rename)

let g:go_highlight_functions = 1
let g:go_highlight_methods = 1
let g:go_highlight_structs = 1
let g:go_highlight_operators = 1
let g:go_highlight_build_constraints = 1
let g:go_fmt_command = "goimports"
let g:syntastic_go_checkers = ['golint', 'govet', 'errcheck']
let g:syntastic_mode_map = { 'mode': 'active', 'passive_filetypes': ['go'] }

let g:rustfmt_autosave = 1

" copy current filename:line to clipboard,
" usefull for gdb breakpoints
function! LineToClipboard()
  let path = resolve(expand(@%))
  call system('xclip', (path . ":" . line(".")))
endfunction
nmap <leader>l :call LineToClipboard()<CR>

" Local config
if filereadable($HOME . "/.vimrc.local")
  source ~/.vimrc.local
endif

if filereadable($LOCAL_VIMRC)
  source $LOCAL_VIMRC
endif
