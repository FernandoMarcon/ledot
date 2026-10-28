" -----------------------------------------------------------------------------
" Mapeamento de teclas
" -----------------------------------------------------------------------------

" Teclar ';' para entrar no modo comando... {{{1

" Conflita com a repetição dos comandos f, F, t e T!
" nnoremap ; :
" vnoremap ; :

" Mover entre linhas visuais... {{{1
map j gj
map k gk
map <down> gj
map <up> gk

" Navegar opções com as setas ou navegar entre linhas visuais... {{{1
imap <expr> <up> pumvisible() ? '<c-p>' : '<c-o>gk'
imap <expr> <down> pumvisible() ? '<c-n>' : '<c-o>gj'

" Aceitar opção do icomplete com 'Enter' ou seta para a direita... {{{1
inoremap <expr> <right> pumvisible() ? '<c-y>' : '<right>'
inoremap <expr> <cr> pumvisible() ? '<c-y>' : '<cr>'

" Cancelar icomplete com a seta para a esquerda... {{{1
inoremap <expr> <left> pumvisible() ? '<c-e>' : '<left>'

" Fechamento de pares... {{{

inoremap '' ''<left>
inoremap "" ""<left>
inoremap () ()<left>
inoremap <> <><left>
inoremap [] []<left>
inoremap {} {}<left>
inoremap {<cr> {<cr><cr>}<c-o>k<c-t>
inoremap ({ ({  })<c-o>2h
inoremap (( ((  ))<c-o>2h
inoremap [[ [[  ]]<c-o>2h

" vnoremap " c""<esc>P
vnoremap ' c''<esc>P
vnoremap ( c()<esc>P
vnoremap [ c[]<esc>P
vnoremap { c{}<esc>P
vnoremap ` c``<esc>P
vnoremap * c**<esc>P

" Restaura a seleção ao indentar... {{{1
vmap < <gv
vmap > >gv

" Rolar meia página com Ctrl+Up/Down... {{{1
nmap <c-down> <c-d>
imap <c-down> <c-d>
nmap <c-up> <c-u>
imap <c-up> <c-u>

" Centraliza rolagem de página... {{{1
nmap <c-d> <c-d>zz
" imap <c-d> <c-d>zz
nmap <c-u> <c-u>zz
" "imap <c-u> <c-u>zz

" Abre menu para inserção de snippets... NOVO! {{{1
nmap <c-s>  :-1read ~/.config/vim/snippets/<c-z>

" }}}

" -----------------------------------------------------------------------------
" Teclas de função
" -----------------------------------------------------------------------------

" Alterna numeração relativa/absoluta... {{{1
map <f1> :set rnu!<cr>

" Alternar correção ortográfica... {{{1
map <f2> :set spell!<cr>

" Alternar quebra de linha... {{{1
map <f3> :set wrap!<cr>

" Abrir o terminal... {{{1
map <f4> :term<cr>

" Abrir o terminal para executar o arquivo em edição... {{{1
map <f5> :term %:p<cr>

" Alternar caracteres invisíveis... {{{1
map <f6> :set list!<cr>

" Exibe estatísticas do arquivo... {{{1
map <f7> g<c-g>
imap <f7> <c-o>g<c-g>

" Abre debugger no terminal... {{{1
map <f8> :term gdb<cr>

" Executar 'make' (requer makefile no diretório)... {{{1
map <f9> :term make<cr>
" }}}

" -----------------------------------------------------------------------------
" Mapeamentos com a tecla 'leader'
" -----------------------------------------------------------------------------

" Tecla líder (espaço)... {{{1
let mapleader = ' '

" Destaque de busca... {{{1
map <silent> <leader>hh :set hls!<cr>
map <silent> <leader>hc :let @/ = ""<cr>

" Copiar e recortar seleção para a área de transferência do Xorg... {{{1
" Prefer native +clipboard; fall back to xclip/xsel for plain vim builds
if has('clipboard')
    vmap <silent> <leader>yy "+y
    vmap <silent> <leader>dd "+c
elseif executable('xclip')
    vmap <silent> <leader>yy y:call system('xclip -selection clipboard', @")<CR>
    vmap <silent> <leader>dd y:call system('xclip -selection clipboard', @")<CR>gvd
elseif executable('xsel')
    vmap <silent> <leader>yy y:call system('xsel --clipboard --input', @")<CR>
    vmap <silent> <leader>dd y:call system('xsel --clipboard --input', @")<CR>gvd
endif

" Salvar apenas se houver mudanças... {{{1
map <leader>w :update<cr>

" Colar última cópia em vez do último recorte... {{{1
map <leader>p "0p
map <leader>P "0P

" Novo buffer vazio... {{{1
map <leader>bn :enew<cr>

" Navegar entre buffers... {{{1
map <leader>, :bp<cr>
map <leader>. :bn<cr>

" Destaque de coluna... {{{1
map <silent> <leader>cc :execute "set cc=" . (&colorcolumn == "" ? "80" : "")<cr>

" Insere marcas de dobra (observe o espaço no final)... {{{1
map <leader>zz :.!~/.config/vim/scripts/foldmark 

" Abas... {{{1
map <leader>ta :tab ball<cr>
map <leader>to :tabonly<cr>

" Explorador de arquivos... {{{1
map <leader>e :30Lex<cr>

" More info about code (Dash plugin)
nmap <silent> <leader>d <Plug>DashSearch<CR>




