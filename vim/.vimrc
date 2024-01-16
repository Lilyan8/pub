" Header {{{
source $VIMRUNTIME/vimrc_example.vim
" }}}
" Bundle {{{
"插件管理
set nocompatible " 去掉vim的扩展，和vi保持兼容
filetype off " 关闭文件类型检测

" set the runtime path to include Vundle and initialize
" 设置运行时路径包括Vundle和初始化
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
" let Vundle manage Vundle, required 让Vundle管理Vundle
Plugin 'VundleVim/Vundle.vim'
Plugin 'kshenoy/vim-signature'
Plugin 'vhda/verilog_systemverilog.vim'
Plugin 'scrooloose/nerdtree'
Plugin 'jiangmiao/auto-pairs'
Plugin 'preservim/nerdcommenter'
"Plugin 'skywind3000/vim-auto-popmenu'
"Plugin 'skywind3000/vim-dict'
Plugin 'godlygeek/tabular'
Plugin 'vim-scripts/AutoComplPop'

call vundle#end()
" }}}
" Startup {{{
filetype indent plugin on


" vim 文件折叠方式为 marker
augroup ft_vim
    au!

    au FileType vim setlocal foldmethod=marker
augroup END
" }}}
" General {{{
set nocompatible
set nobackup
set noundofile
set noswapfile
set history=1024
set autochdir
set whichwrap=b,s,<,>,[,]
set nobomb
set virtualedit=all
set backspace=indent,eol,start whichwrap+=<,>,[,]
" Vim 的默认寄存器和系统剪贴板共享
set clipboard+=unnamed
" 设置 alt 键不映射到菜单栏
set winaltkeys=no
" }}}
" Lang & Encoding {{{
set fileencodings=utf-8,gbk2312,gbk,gb18030,cp936
set encoding=utf-8
set langmenu=zh_CN
let $LANG = 'en_US.UTF-8'
"language messages zh_CN.UTF-8
" }}}
" GUI {{{
"colorscheme Tomorrow-Night
colorscheme darkblue

source $VIMRUNTIME/delmenu.vim
source $VIMRUNTIME/menu.vim
set cuc
set cul
set hlsearch
set number
" 窗口大小
set lines=35 columns=140
" 分割出来的窗口位于当前窗口下边/右边
set splitbelow
set splitright
"不显示工具/菜单栏
"set guioptions-=T
"set guioptions-=m
"set guioptions-=L
"set guioptions-=r
"set guioptions-=b
" 使用内置 tab 样式而不是 gui
"set guioptions-=e
set nolist
" set listchars=tab:?\ ,eol:?,trail:·,extends:>,precedes:<
set guifont=Courier\ 14
" }}}
" Format {{{
"set autoindent
"set smartindent
"set cindent
set tabstop=2
set softtabstop=2
set shiftwidth=2
set expandtab
set nowrap
"set foldmethod=indent
syntax on
" }}}
" Keymap {{{

inoremap _{  {{1'b0}}<Esc>5ba
nmap _B bi{<Esc>ea{1'b0}}<Esc>
inoremap scmt // ---------------------->
inoremap cmt <Esc>I// --------------------------------<cr><cr>--------------------------------<Esc>



let mapleader=","

nmap <leader>s :source $VIM/_vimrc<cr>
nmap <leader>e :e $VIM/_vimrc<cr>

nmap <leader>c <Esc>bvey
nmap <leader>v <Esc>p

map <leader>tn :tabnew<cr>
map <leader>tc :tabclose<cr>
map <leader>th :tabp<cr>
map <leader>tl :tabn<cr>

" 移动分割窗口
nmap <C-j> <C-W>j
nmap <C-k> <C-W>k
nmap <C-h> <C-W>h
nmap <C-l> <C-W>l

" 正常模式下 alt+j,k,h,l 调整分割窗口大小
nnoremap <M-j> :resize +5<cr>
nnoremap <M-k> :resize -5<cr>
nnoremap <M-h> :vertical resize -5<cr>
nnoremap <M-l> :vertical resize +5<cr>

" 插入模式移动光标 alt + 方向键
inoremap <M-j> <Down>
inoremap <M-k> <Up>
inoremap <M-h> <left>
inoremap <M-l> <Right>

" IDE like delete
inoremap <C-BS> <Esc>bdei

nnoremap vv ^vg_
" 转换当前行为大写
inoremap <C-u> <esc>mzgUiw`za
" 命令模式下的行首尾
cnoremap <C-a> <home>
cnoremap <C-e> <end>

nnoremap <F2> :setlocal number!<cr>
nnoremap <leader>w :set wrap!<cr>

nmap <A-c> "+y
vmap <A-c> "+y
imap <A-c> "+y
nmap <A-v> "+gp
vmap <A-v> "+gp
imap <A-v> <Esc>"+gp


vnoremap <BS> d
"vnoremap <C-C> "+y
"vnoremap <C-Insert> "+y
"imap <C-V>		"+gP
map <S-Insert>		"+gp
cmap <C-V>		<C-R>+
cmap <S-Insert>		<C-R>+

exe 'inoremap <script> <C-V>' paste#paste_cmd['i']
exe 'vnoremap <script> <C-V>' paste#paste_cmd['v']

" 打开当前目录 windows
map <leader>ex :!start explorer %:p:h<CR>

" 打开当前目录CMD
map <leader>cmd :!start<cr>
" 打印当前时间
" map <F3> a<C-R>=strftime("%Y-%m-%d %a %I:%M %p")<CR><Esc>

" 复制当前文件/路径到剪贴板
nmap ,fn :let @*=substitute(expand("%"), "/", "\\", "g")<CR>
nmap ,fp :let @*=substitute(expand("%:p"), "/", "\\", "g")<CR>

" 设置切换Buffer快捷键"
nnoremap <C-left> :bn<CR>
nnoremap <C-right> :bp<CR>

" }}}
" Function {{{
" Remove trailing whitespace when writing a buffer, but not for diff files.
" From: Vigil
" @see http://blog.bs2.to/post/EdwardLee/17961
function! RemoveTrailingWhitespace()
    if &ft != "diff"
        let b:curcol = col(".")
        let b:curline = line(".")
        silent! %s/\s\+$//
        silent! %s/\(\s*\n\)\+\%$//
        call cursor(b:curline, b:curcol)
    endif
endfunction
autocmd BufWritePre * call RemoveTrailingWhitespace()

autocmd! BufNewFile *.v exec ":call SetTitle()"
autocmd! BufNewFile *.tcl exec ":call SetTitle()"
autocmd! BufNewFile *.py exec ":call SetTitle()"

function SetTitle()
        if &filetype == 'python'
                call setline(1, "\#coding=utf8")
                call setline(2, "\"\"\"")
                call setline(3, "\# Author: ".$USER)
                call setline(4, "\# Created Time : ".strftime("%c"))
                call setline(5, "")
                call setline(6, "\# File Name: ".expand("%"))
                call setline(7, "\# Description:")
                call setline(8, "")
                call setline(9, "\"\"\"")
                call setline(10,"")
        endif
        if &filetype == 'tcl'
                call setline(1, "//coding=utf8")
                call setline(2, "/*************************************************************************")
                call setline(3, "\ @Author: ".$USER)
                call setline(4, "\ @Created Time : ".strftime("%c"))
                call setline(5, "")
                call setline(6, "\ @File Name: ".expand("%"))
                call setline(7, "\ @Description:")
                call setline(8, "")
                call setline(9, " ************************************************************************/")
                call setline(10,"")
        endif
		if &filetype == "verilog_systemverilog"
		    call setline(1, "//******************************************************************************")
				call setline(2, "// // (c) Copyright 2022-2032 %s, Inc. All rights reserved.")
				call setline(3, "// Module Name  : ".expand("%"))
				call setline(4, "// Design Name  : ".$USER)
				call setline(5, "// Project Name : ")
				call setline(6, "// Create Date  : ".strftime("%c"))
				call setline(7, "// Description  : Need Modified")
		    call setline(8, "// ")
		    call setline(9, "//******************************************************************************")
				call setline(10, "module ".expand("%:t:r"))
				call setline(11, "   #(")
				call setline(12, "    parameter AAA                      = 32,")
				call setline(13, "    parameter BBB                      = 8")
				call setline(14, "    )")
				call setline(15, "    (")
				call setline(16, "    input                                        aaa,")
				call setline(17, "    output                                       bbb,")
				call setline(18, "    output                                       ccc")
				call setline(19, "    );")
				call setline(20, "")
				call setline(21, "//--------------------------------------------------------------------")
				call setline(22, "// parameter declaration")
				call setline(23, "//--------------------------------------------------------------------")
				call setline(24, "//localparameter AAA                     = 32;")
				call setline(25, "")
				call setline(26, "//--------------------------------------------------------------------")
				call setline(27, "// io declaration")
				call setline(28, "//--------------------------------------------------------------------")
				call setline(29, "//wire                                             xxx;")
				call setline(30, "//reg                                              yyy;")
				call setline(31, "//--------------------------------------------------------------------")
				call setline(32, "// reg declared begin")
				call setline(33, "//--------------------------------------------------------------------")
				call setline(34, "//reg                                              zzz;")
				call setline(35, "")
				call setline(36, "//--------------------------------------------------------------------")
				call setline(37, "// main code")
				call setline(38, "//--------------------------------------------------------------------")
				call setline(39, "")
				call setline(40, "endmodule")
				call setline(41, "")
        call setline(42, "//********Modify Logs***********************************************************")
				call setline(43, "// Initial Version By ".$USER)
				call setline(44, "// ".strftime("%D %T"))
		    call setline(45, "//******************************************************************************")
		endif
endfunction

" }}}
" Config {{{
" Nerdtree set
" autocmd vimenter NERDTtree
map <F3> :NERDTreeMirror<CR>
map <F3> :NERDTreeToggle<CR>
map <F4> :silent Valign<CR>

" apc set beign
" enable this plugin for filetypes, '*' for all files.
let g:apc_enable_ft = {'text':1, 'verilog_systemverilog':1, 'vim':1}

" source for dictionary, current or other loaded buffers, see ':help cpt'
set cpt=.,k~/.vim/bundle/vim-dict/dict/*,w,b

" don't select the first item.
set completeopt=menu,menuone,noselect

" suppress annoy messages.
set shortmess+=c

" dict set beign
let g:vim_dict_dict = [
    \ '~/.vim/dict',
    \ '~/.config/nvim/dict',
    \ ]

"let g:vim_dict_config = {'verilog_systemverilog':'verilog'}
let g:vim_dict_config = {'verilog':'verilog_systemverilog','vimsss':'vim'}
let b:verilog_disable_indent_lst="module"


" Create default mappings
let g:NERDCreateDefaultMappings = 1

" Add spaces after comment delimiters by default
let g:NERDSpaceDelims = 1

" Use compact syntax for prettified multi-line comments
let g:NERDCompactSexyComs = 1

" Align line-wise comment delimiters flush left instead of following code indentation
let g:NERDDefaultAlign = 'left'

" Set a language to use its alternate delimiters by default
let g:NERDAltDelims_java = 1

" Add your own custom formats or override the defaults
let g:NERDCustomDelimiters = { 'c': { 'left': '/**','right': '*/' } }

" Allow commenting and inverting empty lines (useful when commenting a region)
let g:NERDCommentEmptyLines = 1

" Enable trimming of trailing whitespace when uncommenting
let g:NERDTrimTrailingWhitespace = 1

" Enable NERDCommenterToggle to check all selected lines is commented or not
let g:NERDToggleCheckAllLines = 1

map <F12> <plug>NERDCommenterSexy
map <c-F12> <plug>NERDCommenterUncomment
" AutoPairs
let g:AutoPairs = {'(':')', '[':']', '"':'"', '```':'```', '"""':'"""', "'''":"'''"}

" }}}
