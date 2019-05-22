scriptencoding utf-8

if !exists('g:loaded_filexplorer')
    finish
endif

let s:cpo_save = &cpo
set cpo&vim

let s:f=filexplorer#funclib#new()
let s:encode1='utf-8'
let s:new_window_hight=''
let s:cnt=0
let s:File = vital#filexplorer#new().import("System.File")
function! s:getParentCwd()
    let ret =substitute(s:getCwd(),'\v.\zs\/$','','g')
    let ret = fnamemodify(ret, ':h')
    return ret
endfunction
function! s:getCwdDirName()
    let ret =substitute(s:getCwd(),'\v.\zs\/$','','g')
    let ret = fnamemodify(ret, ':t')
    return ret
endfunction
function! s:getCwd()
    let ret = exists('w:cwd') ? w:cwd : b:cwd
    if ret != '/'
        let ret = ret . '/'
    endif
    return ret
endfunction
function! s:glob()
    if executable('cmd') && 0
        let list=split(iconv(system('dir'),'sjis','utf8'),'\n')
        let dirlist=filter(list[:],{_,x->x =~ '\v^[0-9].*\s(\<SYMLINKD\>|\<SYMLINK\>|\<DIR\>) +'})
        let dirlist=map(dirlist,{_,x->substitute(x,'\v^[0-9].*\s(\<SYMLINKD\>|\<SYMLINK\>|\<DIR\>|[0-9,]+) +(.*)','\2','')})
        let dirlist=map(dirlist,{_,x->substitute(x,'\v\s+\[.+\]$','','')})
        let dirlist=filter(dirlist,{_,x->x !~ '\v^\.+$'})
        let filelist=filter(list[:],{_,x->x =~ '\v^[0-9].*\s([0-9,]+) +'})
        let filelist=map(filelist,{_,x->substitute(x,'\v^[0-9].*\s(\<SYMLINKD\>|\<SYMLINK\>|\<DIR\>|[0-9,]+) +(.*)','\2','')})
        let filelist=map(filelist,{_,x->substitute(x,'\v\s+\[.+\]$','','')})
        let filelist=filter(filelist,{_,x->x !~ '\v^\.+$'})
    else
        let list=glob('.*\|*',1,1,1)
        let dirlist=filter(copy(list),{_,x->isdirectory(x) && x!~'\.$'})
        let filelist=filter(copy(list),{_,x->!isdirectory(x)})
    endif
    "echom string(dirlist)
    "echom string(filelist)
    return [dirlist,filelist]
endfunction
function! s:start(path)
    let path=substitute(a:path,'\tselect','','')
    let path=substitute(path,'/','\','g')
    let path=shellescape(path)
    call system(' start " " ' . path)
endfunction
function! s:open(path)
    let path=substitute(a:path,'\tselect','','')
    if filereadable(path)
        exe 'e ' . path
    else
        call filexplorer#getCwdFileList(s:getCwd() . substitute(getline('.'),'/','',''),getline('.'),'l',0)
    endif
endfunction
let s:historydict={}
function! filexplorer#getCwdFileList(path,prekeyword,mode,initFlg,...)
    let prebufnr=bufnr('%')
    let s:selectlist=[]
    let matchadds=[]
    call add(matchadds,['Directory','.*\/$'])
    call add(matchadds,['Comment','^\*.*'])
    call add(matchadds,['Comment','^".*'])
    call add(matchadds,['Label','\v^".{-}\:\zs.*'])
    let path=substitute(a:path,'^\*','','')
    if isdirectory(path)
        let fname=expand('%:p:t')
        if a:initFlg == 1 || !exists('w:bufname') || len(s:f.getwidlist(w:bufname)) > 1
            let s:cnt+=1
            let bufname='filexplorer' . s:cnt
            call s:f.enew(bufname,1)
            let w:bufname=bufname
            let sll=matchstr(&statusline,'\v\zs.{-}\ze\%\=')
            let slr=matchstr(&statusline,'\v\%\=\zs.*')
            exe 'setl statusline=' . sll
            "setl statusline+=[CWD=%{b:cwd}]
            exe 'setl statusline+=\%\=' . slr
        elseif empty(s:f.getwidlist(w:bufname))
            call s:f.enew(w:bufname,1)
        endif
        if !exists('b:prebufnr')
            let b:prebufnr=prebufnr
        endif
        let cwd =substitute(path,'\v[\\/]','/','g')
        let cwd =substitute(cwd,'\v.\zs\/$','','g')
        let b:cwd=''
        let precwd=getcwd()
        let precwd =substitute(precwd,'\v[\\/]','/','g')
        let precwd =substitute(precwd,'\v.\zs\/$','','g')
        if cwd == precwd && a:mode == 'h'
            return 0
        endif
        let w:cwd =cwd
        let b:cwd =w:cwd
        if !exists('w:historydict')
            let w:historydict=s:historydict
        endif
        if a:prekeyword != '' && a:mode == 'l'
            let w:historydict[precwd]=a:prekeyword
            let s:historydict[precwd]=a:prekeyword
        endif
        if a:prekeyword != '' && a:mode == 'h'
            let w:historydict[w:cwd]=a:prekeyword
            let s:historydict[w:cwd]=a:prekeyword
        endif
        if w:cwd == '/'
            silent! exe 'lcd ' . w:cwd
        else
            silent! exe 'lcd ' . w:cwd . '/'
        endif
        call s:f.noreadonly()
        call s:clearbuf()
        let [dirlist,filelist]=s:glob()
        let dirlist=map(dirlist,{_,x->fnamemodify(x, ':t') . '/'})
        let filelist=map(filelist,{_,x->fnamemodify(x, ':t')})
        let dirlist=map(dirlist,{_,x->[x,getftime(x),getfsize(x)]})
        let filelist=map(filelist,{_,x->[x,getftime(x),getfsize(x)]})
        if !exists('b:sortidx')
            let b:sortidx=0
        endif
        if get(a:,1,0) != 0
            let b:sortidx+=1
        endif
        if b:sortidx>1
            let b:sortidx=0
        endif
        let dirlist=sort(dirlist,{x,y->x[b:sortidx] == y[b:sortidx] ? 0 : x[b:sortidx] > y[b:sortidx] ? 1 : -1})
        let filelist=sort(filelist,{x,y->x[b:sortidx] == y[b:sortidx] ? 0 : x[b:sortidx] > y[b:sortidx] ? 1 : -1})
        let w:disableline = []
        call add(w:disableline,1)
        call add(w:disableline,2)
        call add(w:disableline,3)
        call add(w:disableline,4)
        call s:append('$',['"Quick Help: my:COPY mc:CUT mp:PASTE mk:MKDIR mf:NEWFILE md:DELETE mr:RENAME <SPACE>:SELECT'])
        call s:append('$',['"          : \:ROOT ~:HOME L:OPENDIR {H,-}:BACK x:SYSTEM s:SORT q:QUITE'])
        call s:append('$',['"      SORT: ' . ['name','time','size'][b:sortidx]])
        call s:append('$',['"       CWD: ' . w:cwd])

        if b:sortidx == 1
            call s:append('$',reverse(map(extend(dirlist,filelist),{_,x->x[0]})))
        else
            call s:append('$',map(dirlist,{_,x->x[0]}))
            call s:append('$',map(filelist,{_,x->x[0]}))
        endif
        call s:f.readonly()
        norm gg4j
        if a:prekeyword != '' && fnamemodify(w:cwd,':t') != fnamemodify(a:prekeyword,':h:t')
            let prekeyword=substitute(a:prekeyword,'^\*','','')
            let prekeyword=substitute(a:prekeyword,'\/','','g')
            silent! call search('\v' . prekeyword . '>')
        elseif has_key(w:historydict,w:cwd)
            let prekeyword=substitute(w:historydict[w:cwd],'\/','','g')
            silent! call search('\v' . prekeyword . '>')
        elseif fname != ''
            silent! call search('^\V' . fname . '\v>')
        endif
        norm 0
        nmap <buffer> <nowait> <silent> q :call <SID>quite()<CR>
        nmap <buffer> <nowait> <silent> \ :<C-u>call filexplorer#getCwdFileList(fnamemodify('/',':p') ,'','',0)<CR>
        nmap <buffer> <nowait> <silent> ~ :<C-u>call filexplorer#getCwdFileList(expand('~') ,'','',0)<CR>
        nmap <buffer> <nowait> <silent> L :<C-u>call filexplorer#getCwdFileList(<SID>getCwd()  . substitute(getline('.'),'/','',''),getline('.'),'l',0)<CR>
        nmap <buffer> <nowait> <silent> - :<C-u>call filexplorer#getCwdFileList(<SID>getParentCwd(),<SID>getCwdDirName(),'h',0)<CR>
        nmap <buffer> <nowait> <silent> H :<C-u>call filexplorer#getCwdFileList(<SID>getParentCwd(),<SID>getCwdDirName(),'h',0)<CR>
        nmap <buffer> <nowait> <silent> <CR> :<C-u>call <SID>open(<SID>getCwd()  . substitute(getline('.'),'^\*','',''))<CR>
        nmap <buffer> <nowait> <silent> x :<C-u>call <SID>start(<SID>getCwd()  . substitute(getline('.'),'^\*','',''))<CR>
        nmap <buffer> <nowait> <silent> s :<C-u>call <SID>filesort()<CR>
        nmap <buffer> <nowait> <silent> <SPACE> :<C-u>call <SID>FileSelect(line('.'))<CR>
        vmap <buffer> <nowait> <silent> <SPACE> :call <SID>FilesSelect()<CR>
        nmap <buffer> <nowait> <silent> <C-R> <nop>
        nmap <buffer> <nowait> <silent> my :<C-u>call <SID>fileCopy()<CR>
        nmap <buffer> <nowait> <silent> mc :<C-u>call <SID>fileCut()<CR>
        nmap <buffer> <nowait> <silent> mp :<C-u>call <SID>filePaste()<CR>
        nmap <buffer> <nowait> <silent> mk :<C-u>call <SID>fileMkdir()<CR>
        nmap <buffer> <nowait> <silent> mf :<C-u>call <SID>newFile()<CR>
        nmap <buffer> <nowait> <silent> md :<C-u>call <SID>fileDelete()<CR>
        nmap <buffer> <nowait> <silent> mr :<C-u>call <SID>fileRename()<CR>
    endif
    let b:matches_filexplorer = matchadds
    call s:sethl()
endfunction
let s:filelist=[]
let s:selectdict={}
let s:copymode=0
function! s:quite()
    if exists('b:prebufnr') && bufexists(b:prebufnr)
        exe 'b ' . b:prebufnr
    else
        q!
    endif
endfunction
function! s:FilesSelect() range
    let s:selectdict={}
    if s:isDisableline(a:firstline, a:lastline)
        return
    endif
    for line in range(a:firstline, a:lastline)
        call s:FileSelect(line)
    endfor
endfunction
function! s:FileSelect(line,...)
    for key in keys(s:selectdict)
        if isdirectory(key)
            let cwd=substitute(fnamemodify(key,':p:h:h'),'\\','/','g')
        else
            let cwd=substitute(fnamemodify(key,':p:h'),'\\','/','g')
        endif
        if cwd != substitute(fnamemodify(getcwd(),':p:h'),'\\','/','g')
            let s:selectdict={}
            break
        endif
    endfor
    let line=a:line
    if s:isDisableline()
        return
    endif
    let opt=get(a:,1,{})
    if getline(line) !~ "^\*"
        let s:selectdict[s:getCwd()  . getline(line)] = 1
        if get(opt,'empty',0) != 1
            call s:f.noreadonly()
            call s:setline(line,'*' . getline(line))
            call s:f.readonly()
        endif
    elseif getline(line) =~ "^\*"
        let prestr=substitute(getline(line),'^\*','','')
        call remove(s:selectdict,s:getCwd()  . prestr)
        call s:f.noreadonly()
        call s:setline(line,prestr)
        call s:f.readonly()
    endif
endfunction
function! s:fileMkdir()
    let dirnm = input('mkdir:' . w:cwd . '/')
    echom " "
    call mkdir(w:cwd . '/' . dirnm,'p')
    let save_cursor = getcurpos()
    call filexplorer#getCwdFileList(s:getCwd() ,getline('.'),'',0)
    call setpos('.', save_cursor)
endfunction
function! s:fileDelete()
    let s:copymode=3
    if empty(s:selectdict)
        call s:FileSelect(line('.'),{'empty':1})
    endif
    let s:filelist=uniq(sort(keys(s:selectdict)))
    let s:selectdict={}
    let all=0
    for file in s:filelist
        let tofile=w:cwd . '/' . fnamemodify(file, ':t')
        if all==0
            let answer = toupper(input('Confirm deletion of file<' . file . '> [y(es),n(o),a(ll),q(uit)):'))[0:0]
            echom " "
            if answer == 'Q'
                break
            elseif answer == 'A'
                let all=1
                let answer = 'Y'
            endif
        else
            let answer = 'Y'
        endif
        if answer == 'Y'
            call delete(file,'rf')
        endif
    endfor
    let save_cursor = getcurpos()
    call filexplorer#getCwdFileList(s:getCwd() ,getline('.'),'',0)
    call setpos('.', save_cursor)
endfunction
function! s:selectRenames(list,bufnm)
    call s:f.newBuffer('Renames','','utf-8')
    call s:append(0,a:list)
    norm gg$
    exe "nmap <buffer> <silent> <CR> :call <SID>commitRenames2('" . a:bufnm . "')<CR>"
    nmap <buffer> <nowait> <silent> d <nop>
endfunction
function! s:commitRenames(old,new)
    if len(a:old) == len(a:new)
        for i in range(len(a:old))
            call rename(a:old[i],a:new[i])
        endfor
    endif
endfunction
function! s:commitRenames2(bufnm)
    call s:commitRenames(s:renamelist,getbufline(bufname('%'),0,'$'))
    q!
    call s:f.gotoWin(a:bufnm)
    let save_cursor = getcurpos()
    call filexplorer#getCwdFileList(s:getCwd() ,getline('.'),'',0)
    call setpos('.', save_cursor)
endfunction
function! s:newFile()
    let fname=input('NewFile:','')
    if fname != ""
        call writefile([],fname)
    endif
    let save_cursor = getcurpos()
    call filexplorer#getCwdFileList(s:getCwd() ,getline('.'),'',0)
    call setpos('.', save_cursor)
endfunction
let s:renamelist=[]
function! s:fileRename()
    let s:copymode=4
    if empty(s:selectdict)
        call s:FileSelect(line('.'),{'empty':1})
    endif
    let s:filelist=uniq(sort(keys(s:selectdict)))
    let s:selectdict={}
    let s:renamelist=[]
    for file in s:filelist
        call add(s:renamelist,file)
    endfor
    call s:selectRenames(s:renamelist,bufname('%'))
endfunction
function! s:filesort()
    call filexplorer#getCwdFileList(s:getCwd() ,getline('.'),'',0,1)
endfunction
function! s:fileCopy()
    let s:copymode=1
    if empty(s:selectdict)
        call s:FileSelect(line('.'),{'empty':1})
    endif
    let s:filelist=uniq(sort(keys(s:selectdict)))
    let s:selectdict={}
    let save_cursor = getcurpos()
    call filexplorer#getCwdFileList(s:getCwd() ,getline('.'),'',0)
    call setpos('.', save_cursor)
    echom string(len(s:filelist)) . ' copied file'
endfunction
function! s:fileCut()
    let s:copymode=2
    if empty(s:selectdict)
        call s:FileSelect(line('.'),{'empty':1})
    endif
    let s:filelist=uniq(sort(keys(s:selectdict)))
    let s:selectdict={}
    let save_cursor = getcurpos()
    call filexplorer#getCwdFileList(s:getCwd() ,getline('.'),'',0)
    call setpos('.', save_cursor)
    echom string(len(s:filelist)) . ' cut file'
endfunction
function! s:filePaste()
    let all=0
    for file in s:filelist
        let tofile=w:cwd . '/' . fnamemodify(file, ':t')
        if substitute(tofile,'\V\','/','g') == substitute(file,'\V\','/','g')
            let cnt=1
            let tofilebas = substitute(fnamemodify(tofile,':r'),'\v(.*)_[0-9]+$','\1','')
            if fnamemodify(tofile,':e') == ''
                let tofile = tofilebas . '_' . cnt
            else
                let tofile = tofilebas . '_' . cnt . '.' . fnamemodify(tofile,':e')
            endif
            while filereadable(tofile)
                let cnt+=1
                if fnamemodify(tofile,':e') == ''
                    let tofile = tofilebas . '_' . cnt
                else
                    let tofile = tofilebas . '_' . cnt . '.' . fnamemodify(tofile,':e')
                endif
            endwhile
        elseif stridx(substitute(tofile,'\V\','/','g'),substitute(file,'\V\','/','g')) == 0
            echom 'destination directory and source directory the area of wearing.'
            continue
        endif
        let answer = 'N'
        if filereadable(tofile) && all==0
            let answer = toupper(input('Confirm overwrite of file<' . tofile . '> [y(es),n(o),a(ll),q(uit)):'))[0:0]
            echom " "
            if answer == 'Q'
                break
            elseif answer == 'A'
                let all=1
                let answer = 'Y'
            endif
        else
            let answer = 'Y'
        endif
        let stat=1
        if answer == 'Y'
            if filereadable(file)
                if s:copymode == 1
                    echom 'copy ' . shellescape(file) . ' to ' . tofile
                    if has('unix')
                        let stat=s:File.copy(file,tofile)
                    else
                        let stat=s:File.copy(shellescape(file),tofile)
                    endif
                elseif s:copymode == 2
                    if has('unix')
                        let stat=s:File.move(file,w:cwd)
                    else
                        let stat=s:File.move(shellescape(file),w:cwd)
                    endif
                endif
            elseif isdirectory(file)
                if !isdirectory(w:cwd . '/' . fnamemodify(file, ':h:t'))
                    call mkdir(w:cwd . '/' . fnamemodify(file, ':h:t'),'p')
                endif
                echom 'copy ' . fnamemodify(file, ':h') . ' to ' . w:cwd . '/' . fnamemodify(file, ':h:t')
                if s:copymode == 1
                    let stat=s:File.copy_dir(fnamemodify(file, ':h'),w:cwd . '/' . fnamemodify(file, ':h:t'))
                elseif s:copymode == 2
                    let stat=s:File.copy_dir(fnamemodify(file, ':h'),w:cwd . '/' . fnamemodify(file, ':h:t'))
                    if fnamemodify(file, ':h') != w:cwd . '/' . fnamemodify(file, ':h:t')
                        call delete(file,'rf')
                    endif
                endif
            endif
        endif
        if stat == 0
            echoerr 'error'
        endif
    endfor
    let save_cursor = getcurpos()
    call filexplorer#getCwdFileList(s:getCwd() ,getline('.'),'',0)
    call setpos('.', save_cursor)
endfunction
function! s:isDisableline(...)
    if exists('w:disableline')
        for dl in w:disableline
            if mode() == 'n'
                 if line('.') == dl
                     return 1
                 endif
             elseif mode() == 'v' || mode() == 'V'
                 for line in range(a:1,a:2)
                     if line == dl
                         return 1
                     endif
                 endfor
             endif
        endfor
    endif
    return 0
endfunction
function! s:clearbuf()
    let old_undolevels = &undolevels
    setl undolevels=-1
    silent 0,$delete_
    let &undolevels = old_undolevels
endfunction
function! s:setline(line,str)
    let old_undolevels = &undolevels
    setl undolevels=-1
    call setline(a:line,a:str)
    let &undolevels = old_undolevels
endfunction
function! s:append(line,list)
    let old_undolevels = &undolevels
    setl undolevels=-1
    call append(a:line,a:list)
    silent g/^$/ delete_
    let &undolevels = old_undolevels
endfunction
function! s:sethl()
    if exists('w:matches_filexplorer')
        call map(w:matches_filexplorer,{_,x->matchdelete(x)})
        unlet w:matches_filexplorer
    endif
    if exists('b:matches_filexplorer')
        let w:matches_filexplorer =  []
        for x in b:matches_filexplorer
            call add(w:matches_filexplorer,matchadd(x[0],x[1],0,-1))
        endfor
    endif
endfunction
augroup BufEnterFileExplorer
    autocmd WinNew,BufEnter * call s:sethl()
augroup END

let &cpo = s:cpo_save
unlet s:cpo_save

" vim:fdm=marker:nowrap:ts=4:expandtab:
