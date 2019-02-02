scriptencoding utf-8

if exists('g:loaded_filexplorer')
    finish
endif
let g:loaded_filexplorer = 1

let s:cpo_save = &cpo
set cpo&vim

command! -nargs=? FileExp let path=<q-args>|:call filexplorer#getCwdFileList(path==""?getcwd():path,'','',1)

let &cpo = s:cpo_save
unlet s:cpo_save
