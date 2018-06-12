" vim-zen - a minimal plugin manager for vim 

let s:installation_path = ''

function! zen#init() abort
    let s:zen_win = 0
    let g:plugins = {}
    let g:plugin_names = []
endfunction


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


function! s:populate_window(message, flag) abort
    let l:heading = 'VimZen - ' . a:message 
    
    " when populating window for the first time
    if !(a:flag)
        call s:start_window()
        call append(0, l:heading)
        call append(1, repeat('=', len(l:heading)))
    else
        call setline(1, l:heading)
        call setline(2, repeat('=', len(l:heading)))
    endif
    normal! 2G
    redraw
endfunction 


function! s:load_plugin(plugin) abort
    let l:plugin = g:plugins[a:plugin]
    let l:plugin_path = l:plugin['path']
    let l:patterns = ['plugin/**/*.vim', 'after/plugin/**/*.vim']

    for pattern in l:patterns
        for vimfile in split(globpath(l:plugin_path, pattern), '\n')
            execute 'source' vimfile
            " execute 'source ' . vimfile
        endfor
    endfor
endfunction 


function! zen#add(remote, ...)
    let l:plugin_name = split(a:remote, '/')[-1]
    let l:plugin_dir = s:installation_path . '/' . l:plugin_name 

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

    let g:plugins[l:plugin_name] = {'name': l:plugin_name, 'remote': l:remote_name, 'path': l:plugin_dir}

    " execute "set rtp+=" . s:installation_path . '/' . l:plugin_name 
    execute "set rtp+=" . l:plugin_dir 
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
    call s:populate_window('Installing plugins...', 0)

    for key in keys(g:plugins)
        let l:plugin = g:plugins[key]
        let l:install_path = s:installation_path . "/" . l:plugin['name']
        if !isdirectory(l:install_path)
            let l:cmd = "git clone " . l:plugin['remote'] . " " . l:install_path 
            let l:cmd_result =  system(l:cmd)
            call append(line('$'), '- ' . l:plugin['name'] . ': ' . l:cmd_result)
            call s:load_plugin(l:plugin['name'])
        else
            call append(line('$'), '- ' . l:plugin['name'] . ': ' . 'Skipped')
        endif
        redraw 
    endfor 

    call s:populate_window('Installation finished!', 1)
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
    let l:cloned_plugins = split(globpath(s:installation_path, "*"), "\n")

    call s:populate_window('Removing unused plugins...', 0)

    if g:plugins == {}
        call append(line('$'), 'No plugins installed.')
    endif

    for l:dir in l:cloned_plugins 
        let l:plugin_dir_name = split(l:dir, '/')[-1]
        let l:plugin_dir_path = s:installation_path . "/" . l:plugin_dir_name 

        if !has_key(g:plugins, l:plugin_dir_name)
            call add(l:unused_plugins, l:plugin_dir_path)
            call append(line('$'), '- ' . l:plugin_dir_path)
        endif
    endfor

    if l:unused_plugins == []
        call append(line('$'), 'No plugins to remove.')
        return
    endif

    redraw
    if s:warning_prompt('Delete the following plugins?')
        normal! jdG
        for l:item in l:unused_plugins 
            let l:plugin_name = split(l:item, '/')[-1]
            let l:cmd_result = system('rm -rf ' . l:item)
            call append(line('$'), '- ' . l:item . ' - Removed!')
            call remove(g:plugin_names, l:plugin_name)
        endfor
    endif
    redraw
    call s:populate_window('Finished cleaning!', 1)
endfunction 

