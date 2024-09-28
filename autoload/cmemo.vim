let s:save_cpo = &cpoptions
set cpoptions&vim

let s:menu = []

"*******************************************************
" draw_buffer
"*******************************************************
function! s:draw_buffer() abort
	setlocal modifiable

	" Delete the contents of the buffer to the black-hole register
	silent! %delete _

	silent! 0put = s:menu

	" Delete the empty line at the end of the buffer
	silent! $delete _

	" Move the cursor to the beginning of the file
	call setpos(".", [0, 1, 1, 0])

	setlocal nomodifiable
endfunction

"*******************************************************
" Open_buffer
"*******************************************************
function! s:open_window() abort
	let winnum = bufwinnr("-cmemo-")
	if winnum != -1
		" Already in the window, jump to it
		exe winnum . 'wincmd w'
	else
		" Open a new window at the bottom
		exe 'silent! botright '.len(s:menu).'split '."-cmemo-"
	endif

	setlocal buftype=nofile
	setlocal bufhidden=delete
	setlocal noswapfile
	setlocal nobuflisted
	setlocal nowrap
	setlocal winfixheight winfixwidth
	setlocal filetype=CMEMO
	setlocal nocursorline
	setlocal nonumber

	" Setup the cpoptions properly for the maps to work
	let old_cpoptions = &cpoptions
	set cpoptions&vim

	call s:draw_buffer()

	" Restore the previous cpoptions settings
	let &cpoptions = old_cpoptions

	" Add syntax highlighting
	syntax match CmemoCate '\ \[.\{-}]'
	syntax match CmemoKey ' . -'
	highlight default link CmemoCate Title
	highlight default link CmemoKey Identifier
endfunction

"*******************************************************
" Repeat space
"*******************************************************
function! s:space(line) abort
	return repeat (' ', 45 - len(s:menu[a:line]))
endfunction

"*******************************************************
" Make menu
"*******************************************************
function! s:make_menu() abort
	let s:menu = []

	let pass = getcwd()
	if strlen(pass) > 33
		let pass = "..".strpart(pass, strlen(pass) - 33)
	endif

	call add(s:menu, " [ Settings ]")
	call add(s:menu, "   t - Tabstop toggle 4/8 [" . &tabstop . "]")
	call add(s:menu, "   m - Modifiable [" . (&modifiable ? "+" : "-") ."]")
	call add(s:menu, "   r - R/W control [" . (&readonly ? "RO" : "RW") . "]")
	call add(s:menu, "   c - Disply control code [" . (&list ? "On" : "Off") . "]")
	call add(s:menu, "   i - Case sensitive [" . (&ignorecase ? "Off" : "On") . "]")
	call add(s:menu, "")
	call add(s:menu, " [ etc ]")
	call add(s:menu, "   n - Terminal")
	call add(s:menu, "   e - Reset errorformat")
	call add(s:menu, "   f - Set file path to clipboard")
	call add(s:menu, "   d - Change current directory")
	call add(s:menu, "       [".pass."]")
	call add(s:menu, "   q - Quit")

	let s:menu[0] .= s:space(0) . " [ Tab and space conversion ]"
	let s:menu[1] .= s:space(1) . "   1 - Replace spaces with tabs (space2tab)"
	let s:menu[2] .= s:space(2) . "   2 - Replace tabs with spaces (tab2space)"
	let s:menu[3] .= s:space(3) . "   3 - Remove spaces and tabs at end of lines"
	let s:menu[4] .= ""
	let s:menu[5] .= s:space(5) . " [ Encording conversion ]"
	let s:menu[6] .= s:space(6) . "   4 - Reopen with specified encording"
	let s:menu[7] .= s:space(7) . "   5 - Convert to specified encording"
	let s:menu[8] .= ""
	let s:menu[9] .= s:space(9) . " [ NL code conversion ]"
	let s:menu[10].= s:space(10). "   6 - Reopen with specified NL-code"
	let s:menu[11].= s:space(11). "   7 - Convert to specified NL-code"
	let s:menu[12].= s:space(12). "   8 - Remove NL-code"
endfunction

"*******************************************************
" Convert space to tab
"*******************************************************
function! s:space2tab() abort
	let s = substitute(execute("set expandtab?"), '[ \|\n]', "", "ge")
	execute ':set noexpandtab'
	if s:range['range']
		execute ':'.s:range['start'].','.s:range['end'].'retab!'
	else
		execute ':retab!'
	endif
	execute ':set '.s
endfunction

"*******************************************************
" Convert tab to space
"*******************************************************
function! s:tab2space() abort
	let s = substitute(execute("set expandtab?"), '[ \|\n]', "", "ge")
	execute ':set expandtab'
	if s:range['range']
		execute ':'.s:range['start'].','.s:range['end'].'retab'
	else
		execute ':retab'
	endif
	execute ':set '.s
endfunction

"*******************************************************
" Remove spaces and tabs at end of lines
"*******************************************************
function! s:remove_space() abort
	let pos = getpos(".")
	if s:range['range']
		silent execute ':'.s:range['start'].','.s:range['end'].'s/\s\+$//eg'
	else
		silent execute ':%s/\s\+$//e'
	endif
	call setpos('.', pos)
endfunction

"*******************************************************
" Reset errorformat
"*******************************************************
function! s:reset_errorformat() abort
	let bufs = filter(range(1, bufnr('$')), '
			\ buflisted(v:val)
			\ && getbufvar(v:val, "&buftype") == "quickfix"
			\ ')

	if len(bufs) && bufwinnr(bufs[0]) > 0
		exe bufwinnr(bufs[0]) . 'wincmd w'
		execute 'set errorformat=%f\|%l\ col\ \%c-\%k\|\ %m'
		silent cgetbuffer
		set modifiable
	else
		echohl WarningMsg | echomsg 'This buffer type is not quickfix' | echohl None
		return
	endif
endfunction

"*******************************************************
" Input a character
"*******************************************************
function! s:input_char(str, list) abort
	let s = ""
	for v in a:list
		let s = s.(strlen(s) ? ", " : "").strpart(v,0,1).":".v
	endfor
	let c = input(a:str." [".s."] : ")
	echo "\r"

	let ret = ""
	if !empty(c)
		for v in a:list
			if stridx(v, c) == 0
				let ret = v
				break
			endif
		endfor
	endif
	return ret
endfunction

"*******************************************************
" Window close
"*******************************************************
function! s:close_window() abort
	silent! close
	call win_gotoid(s:win_id)
endfunction

"*******************************************************
" Selected handler of menu
"*******************************************************
function! s:yesno() abort
	return input("Continue OK? [y/n] : ") == "y" ? 1 : 0
endfunction

"*******************************************************
" Selected handler of menu
"*******************************************************
function! s:cmemo_selected_handler(key) abort
	if strlen(a:key) == 0 | echo "\r" | call s:close_window() | endif

	" [ Settings ]
	if	   a:key == "t"
		" Tabstop
		call s:close_window()
		let tab = &tabstop == 4 ? 8 : 4
		echo tab
		execute 'set tabstop='.tab
		execute 'set shiftwidth='.tab

	elseif a:key == "m"
		" modifiable / nomodifiable
		call s:close_window()
		execute &modifiable ? 'set nomodifiable' : 'set modifiable'

	elseif a:key == "r"
		" R/W (ReadOnly / WriteAllow)
		call s:close_window()
		execute &readonly ? 'set noro' : 'set ro'

	elseif a:key == "c"
		" Control-code (Display / Undisplay)
		call s:close_window()
		execute &list ? 'set nolist' : 'set list'

	elseif a:key == "i"
		" Search-case (noignorecase / ignorecase)
		call s:close_window()
		execute &ignorecase ? 'set noignorecase' : 'set ignorecase'

	" [ etc ]
	elseif a:key == "n"
		call s:close_window()
		execute 'lcd '.expand("%:h")
		if has('nvim')
			belowright new
			terminal
			startinsert
		else
			bot terminal
		endif

	elseif a:key == "e"
		" Reset errorformat
		call s:close_window()
		call s:reset_errorformat()

	elseif a:key == "d"
		" Change current directory
		call s:close_window()
		execute 'lcd '.(input('Set current directory: ', expand("%:h"), 'dir'))

	elseif a:key == "f"
		" Directory path copy to clip board
		call s:close_window()
		let @* = expand("%:p")
		echohl MoreMsg | echomsg "Set file path to clipboard (".@*.")" | echohl None

	" [ Tab and space conversion ]
	elseif a:key == "1"
		" Tab --> Space (Replace tabs with spaces
		if s:yesno()
			call s:close_window()
			call s:space2tab()
		endif

	elseif a:key == "2"
		" Space --> Tab (Replace spaces with tabs
		if s:yesno()
			call s:close_window()
			call s:tab2space()
		endif

	elseif a:key == "3"
		" Remove spaces and tabs at end of lines
		if s:yesno()
			call s:close_window()
			call s:remove_space()
		endif

	" [ Encording conversion ]
	elseif a:key == "4"
		" Reopen with specified encording
		let encord_type = s:input_char('Reopen encord type', ['utf8', 'sjis'])
		if !empty(encord_type) && s:yesno()
			call s:close_window()
			execute 'e ++enc='.encord_type
		endif

	elseif a:key == "5"
		" Convert to specified encording
		let encord_type = s:input_char('Convert encord type', ['utf8', 'sjis'])
		if !empty(encord_type) && s:yesno()
			call s:close_window()
			execute 'set fenc='.encord_type
		endif

	elseif a:key == "6"
		" Reopen with specified NL-code
		let NL_code = s:input_char('Reopen NL code', ['unix', 'dos', 'mac'])
		if !empty(NL_code) && s:yesno()
			call s:close_window()
			execute 'edit ++fileformat='.NL_code
		endif

	elseif a:key == "7"
		" Convert to specified NL-code
		let NL_code = s:input_char('Convert NL code', ['unix', 'dos', 'mac'])
		if !empty(NL_code) && s:yesno()
			call s:close_window()
			execute 'set fileformat='.NL_code
		endif

	elseif a:key == "8"
		" Remove NL-code
		call s:close_window() && s:yesno()
		execute '%s/\n//g'

	elseif a:key == "q"
		call s:close_window()

	endif
endfunction

"*******************************************************
" Input key
"*******************************************************
function! s:input_key(timer) abort
	echo "Please select a key : "
	let c = nr2char(getchar())
	echo "\r"
	call s:cmemo_selected_handler(c)
	if bufwinnr("-cmemo-") != -1
		call timer_start(200, function("s:input_key"))
	endif
endfunction

"*******************************************************
" Start tools
"*******************************************************
function! cmemo#start(range, start, end) abort
	let s:win_id = win_getid()
	let s:range = {'range':a:range, 'start':a:start, 'end':a:end}
	call s:make_menu()
	call s:open_window()
	call timer_start(200, function("s:input_key"))
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo

