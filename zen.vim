" vim-zen - a minimal plugin manager for vim 

let s:installation_path = ''
let s:zen_win = 0
let g:plugins = []

" set installation path for plugins
if has('nvim')
	if !isdirectory($HOME . '/.local/share/nvim/plugged')
		call mkdir($HOME . '/.local/share/nvim/plugged')
	endif
	let s:installation_path = $HOME . '/.local/share/nvim/plugged'
else
	if !isdirectory($HOME . '.vim/plugged')
		call mkdir($HOME . '.vim/plugged')
	endif
	let s:installation_path = $HOME . '.vim/plugged'
endif


function! zen#add(remote, ...)
    call add(g:plugins, split(a:remote, "/")[-1])

    " TODO: sanitize remote url
	" create path for remote
	" if a:remote =~ '^https:\/\/.\+'
	" 	let l:remote = a:remote
	" elseif a:remote =~ '^http:\/\/.\+'
	" 	let l:remote = a:remote
	" 	let l:remote = substitute(l:remote, '^http:\/\/.\+', 'https://', '')
	" elseif a:remote =~ '^.\+/.\+'
	" 	l:remote = 'https://github.com/' . a:remote . '.git'
	" else
	" 	echom "Failed to create remote repository path"
	" 	stop

    " TODO: add enable config
    if a:0 == 1
        let l:options = a:1
    endif
    call s:define_commands()
endfunction


" assign name to the plugin buffer window
function! s:assign_buffer_name() abort
    let name = '[VimZen]'
    silent! execute "f " . l:name 
endfunction 


" start a new buffer window for plugin operations
function! s:start_window() abort
    execute s:zen_win . 'wincmd w'
    if !exists('b:plug')
        vertical new
        nnoremap <silent> <buffer> q :q<cr>
        let b:plug = 1
        let s:zen_win = winnr()
    else
        %d
    endif
    setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile nowrap cursorline
    call s:assign_buffer_name()
endfunction 


" Check if plugin is already installed
" git clone if not and add path to rtp
function! zen#install() abort
    let l:arguments = g:plugins

    call s:start_window()
    call append(0, "VimZen - Installing plugins...")
    call append(1, "==============================")
    normal! 2G
    redraw

    for l:plugin in l:arguments 
        let l:install_path = s:installation_path . "/" . split(l:plugin, "/")[-1]
        if !isdirectory(l:install_path)
            let l:cmd = "git clone " . "https://github.com/" . l:plugin . ".git" . " " . l:install_path 
            let l:cmd_result =  system(l:cmd)
            call append(line('$'), '- ' . l:plugin . ': ' . l:cmd_result)
        else
            call append(line('$'), '- ' . l:plugin . ': ' . 'Skipped')
        endif
        execute "set rtp+=" . l:install_path 
        redraw 
    endfor 

    call setline(1, "VimZen - Installation finished!")
    call setline(2, "===============================")
    redraw 

endfunction


function! s:define_commands() abort
    command! -nargs=* -bar -bang -complete=customlist,s:names ZenInstall call zen#install()
    command! -nargs=* -bar -bang -complete=customlist,s:names ZenClean call zen#clean()
endfunction 


" remove unused plugins
" TODO: mv clean remove
function! zen#clean() abort
    call s:start_window()
    call append(0, "VimZen - Removing unused plugins...")
    call append(1, "===================================")

    if g:plugins == []
        call append(line('$'), 'No plugins installed.')
    endif

    let l:cloned_plugins = split(globpath(s:installation_path, "*"), "\n")
    for l:dir in l:cloned_plugins 
        let l:unused_plugins = []
        let l:plugin_dir_name = split(l:dir, "/")[-1]
        let l:plugin_dir_path = s:installation_path . "/" . l:plugin_dir_name 

        if index(g:plugins, l:plugin_dir_name) == -1
            call add(l:unused_plugins, l:plugin_dir_path)
        endif

        for l:item in l:unused_plugins
            call append(line('$'), '- ' . l:item)
        endfor
    endfor
endfunction 

