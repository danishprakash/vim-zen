" vim-zen - a minimal plugin manager for vim 

let s:installation_path = ''
let s:zen_win = 0
let g:plugins = {}
let g:plugin_names = []

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
	" sanitize remote uri
	if a:remote =~ '^https:\/\/.\+'
		let l:remote_name = a:remote
	elseif a:remote =~ '^http:\/\/.\+'
		let l:remote_name = a:remote
		let l:remote_name = substitute(l:remote, '^http:\/\/.\+', 'https://', '')
	elseif a:remote =~ '^.\+/.\+'
        let l:remote_name = 'https://github.com/' . a:remote . '.git'
	else
		echom "Failed to create remote repository path"
    endif

    let l:plugin_name = split(a:remote, '/')[-1]
    let g:plugins[l:plugin_name] = {'name': l:plugin_name, 'remote': l:remote_name}

    call add(g:plugin_names, l:plugin_name)

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
    call s:start_window()
    call append(0, "VimZen - Installing plugins...")
    call append(1, "==============================")
    normal! 2G
    redraw

    for key in keys(g:plugins)
        let l:plugin = g:plugins[key]
        let l:install_path = s:installation_path . "/" . l:plugin['name']
        if !isdirectory(l:install_path)
            let l:cmd = "git clone " . l:plugin['remote'] . " " . l:install_path 
            let l:cmd_result =  system(l:cmd)
            call append(line('$'), '- ' . l:plugin['name'] . ': ' . l:cmd_result)
        else
            call append(line('$'), '- ' . l:plugin['name'] . ': ' . 'Skipped')
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
    command! -nargs=* -bar -bang -complete=customlist,s:names ZenRemove call zen#remove()
endfunction 


function! s:warning_prompt(message) abort
    call inputsave()
    echohl WarningMsg
    let l:choice = input(a:message . ' (Y/N): ')
    echohl None
    call inputrestore()
    echo "\r"
    return (l:choice =~? '^y') ? 1 : 0
endfunction 


" remove unused plugins
function! zen#remove() abort
    let l:unused_plugins = []

    call s:start_window()
    call append(0, "VimZen - Removing unused plugins...")
    call append(1, "===================================")

    if g:plugins == {}
        call append(line('$'), 'No plugins installed.')
    endif

    let l:cloned_plugins = split(globpath(s:installation_path, "*"), "\n")
    for l:dir in l:cloned_plugins 
        let l:plugin_dir_name = split(l:dir, '/')[-1]
        let l:plugin_dir_path = s:installation_path . "/" . l:plugin_dir_name 

        if index(g:plugin_names, l:plugin_dir_name) == -1
            echom string(l:plugin_dir_name)
            call add(l:unused_plugins, l:plugin_dir_path)
            call append(line('$'), '- ' . l:plugin_dir_path)
        endif
    endfor
    echom string(l:unused_plugins)

    if l:unused_plugins == []
        call append(line('$'), 'No plugins to remove.')
        return
    endif

    redraw
    if s:warning_prompt('Delete the following plugins?')
        normal! jdG
        for l:item in l:unused_plugins 
            let l:plugin_name = split(l:item, '/')[-1]
            call remove(g:plugins, l:plugin_name)
            call remove(g:plugin_names, l:plugin_name)
            call delete(expand(l:item), 'rf')
            call append(line('$'), '- ' . l:item . ' - Removed!')
            " unlet g:plugins[l:plugin_name]
            " unlet g:plugin_names[l:plugin_name]
        endfor
    endif
    redraw
endfunction 

