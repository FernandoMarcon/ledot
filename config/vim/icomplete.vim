" -----------------------------------------------------------------------------
" Inserir hashbang
" -----------------------------------------------------------------------------
function! Hashbangs()
    let hb = ['#!/bin/bash',
                \ '#!/usr/bin/env python',
                \ '#!/usr/bin/env r',
                \ '#!/usr/bin/env bash',
                \ '#!/bin/sh',
                \ '#!/usr/bin/awk -f']
    call complete(col('.'), hb)
    return ''
endfunction

imap <c-x>h <c-r>=Hashbangs()<cr>
" -----------------------------------------------------------------------------
"
"



