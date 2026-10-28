" -----------------------------------------------------------------------------
" Autocomandos
" -----------------------------------------------------------------------------

" Descomente as duas linhas abaixo se quiser salvar e carregar visualizações...
" autocmd BufWinLeave ?* mkview
" autocmd BufWinEnter ?* silent loadview

" Tabulações para arquivos .asm...
autocmd filetype asm setlocal noexpandtab ts=8 sw=8 sts=8

" Não expande tabulações em arquivos make...
autocmd filetype make setlocal noexpandtab 

" Redimensionar janelas quando terminal mudar de tamanho...
autocmd vimresized * wincmd =


