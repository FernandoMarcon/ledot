hi statusline   gui=bold guibg=#98C379 guifg=#101120
hi statuslinenc gui=NONE cterm=NONE guibg=#3E4452 guifg=#B0B1C0

augroup ModeEvents
    autocmd!
    au InsertEnter * hi statusline guibg=#61AFEF
    au InsertLeavePre * hi statusline guibg=#98C379
    au ModeChanged *:[vV\x16]* hi statusline guibg=#C678DD
    au Modechanged [vV\x16]*:* hi statusline guibg=#98C379
    au ModeChanged *:[R]* hi statusline guibg=#EB6E6E
    au ModeChanged [R]* hi statusline guibg=#98C379
augroup end

function! ActiveStatusLine()

    let g:currentmode={
        \ 'n'  : 'Normal',
        \ 'no' : 'Normal-Operator Pending',
        \ 'v'  : 'Visual',
        \ 'V'  : 'V-Line',
        \ '' : 'V-Block',
        \ 's'  : 'Select',
        \ 'S'  : 'S-Line',
        \ '' : 'S-Block',
        \ 'i'  : 'Insert',
        \ 'R'  : 'Replace',
        \ 'Rv' : 'V-Replace',
        \ 'c'  : 'Command',
        \ 'cv' : 'Vim Ex',
        \ 'ce' : 'Ex',
        \ 'r'  : 'Prompt',
        \ 'rm' : 'More',
        \ 'r?' : 'Confirm',
        \ '!'  : 'Shell',
        \ 't'  : 'Terminal'
        \}

    set statusline=%0*\ %{toupper(g:currentmode[mode()])}
    set statusline+=\ %1*\ [%n]\ %t%{&modified!=''?'\ \|\ +':''}

    set statusline+=\ %2*%=
    
    set statusline+=%{&ff}\ \|\ %{&fenc!=''?&fenc:&enc}
    set statusline+=\ \|\ %{&filetype!=''?tolower(&filetype):'no\ ft'}

    set statusline+=\ %1*\ %p%%\ %0*\ \ %l:%c\ \ 

    hi User1 gui=NONE cterm=NONE guifg=#b0b1c0 guibg=#3E4452
    hi User2 gui=NONE cterm=NONE guifg=#b0b1c0 guibg=#2C324D

endfunction

call ActiveStatusLine()

