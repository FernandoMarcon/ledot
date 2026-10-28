" ~/.config/vim/functions.vim

function! RunScript()
	if &filetype == 'python'
		execute 'terminal python3 %'
	elseif &filetype == 'r'
		execute 'terminal Rscript %'
	elseif &filetype == 'sh'
		execute 'terminal bash %'
	elseif &filetype == 'javascript'
		execute 'terminal node %'
	else
		echo "No run command defined for filetype:" &filetype
	endif
endfunction
