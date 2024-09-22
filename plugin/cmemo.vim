let s:save_cpo = &cpoptions
set cpoptions&vim

if exists('g:loaded_cmemo')
	finish
endif
let g:loaded_cmemo = 1

command! -nargs=0 -range CMemo call cmemo#start(<range>, <line1>, <line2>)

let &cpoptions = s:save_cpo
unlet s:save_cpo
