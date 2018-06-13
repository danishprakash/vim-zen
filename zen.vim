" ==========================================================
" Name:         vim-zen: Vim plugin manager
" Author:       Danish Prakash
" HomePage:     https://github.com/prakashdanish/vim-zen
" Version:      1.0.0
" ==========================================================


function! zen#init() abort
    let s:zen_win = 0
    let g:plugins = {}
    let g:plugin_names = []
    let s:installation_path = ''

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

    call s:define_commands()
    autocmd VimEnter * call s:git_installed()
endfunction


function! s:git_installed() abort
    if !executable('git')
        echohl ErrorMsg
        echom "[vim-zen] git is required."
        echohl None
    endif
endfunction 


" list all installed plugins
function! s:list_plugins() abort
    for l:plugin in keys(g:plugins)
        call append(line('$'), '- ' . g:plugins[l:plugin]['name'] . ': ')
    endfor
    redraw 
endfunction 


function! s:populate_window(message, flag) abort
    let l:heading = 'vim-zen - ' . '[ ' . a:message . ' ]'
    
    " when populating window for the first time
    if !(a:flag)
        call s:start_window()
        call append(0, l:heading)
        call append(1, repeat('─', len(l:heading)))
    else
        call setline(1, l:heading)
        call setline(2, repeat('─', len(l:heading)))
    endif
    redraw
endfunction 


" source plugin files
function! s:load_plugin(plugin) abort
    let l:plugin_path = g:plugins[a:plugin]['path']
    let l:patterns = ['plugin/**/*.vim', 'after/plugin/**/*.vim']
    for pattern in l:patterns
        for vimfile in split(globpath(l:plugin_path, pattern), '\n')
            execute 'source' vimfile
        endfor
    endfor
endfunction 


" load `g:plugins` with plugins in .vimrc
function! zen#add(remote, ...)
    let l:plugin_name = split(a:remote, '/')[-1]
    let l:plugin_dir = s:installation_path . '/' . l:plugin_name 

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
    execute "set rtp+=" . l:plugin_dir 
    call add(g:plugin_names, l:plugin_name)

    " TODO: add enable config
    if a:0 == 1
        let l:options = a:1
    endif
endfunction


" assign name to the plugin buffer window
function! s:assign_buffer_name() abort
    let name = '[vim-zZen]'
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


" install plugins
function! zen#install() abort
    let l:count = 4
    call s:populate_window('Installing plugins...', 0)
    call s:list_plugins()
    for key in keys(g:plugins)
        let l:plugin = g:plugins[key]
        let l:install_path = s:installation_path . "/" . l:plugin['name']
        if !isdirectory(l:install_path)
            let l:cmd = "git clone " . l:plugin['remote'] . " " . l:install_path 
            let l:cmd_result =  system(l:cmd)
            call setline(l:count, '- ' . l:plugin['name'] . ': ' . l:cmd_result)
            call s:load_plugin(l:plugin['name'])
        else
            call setline(l:count, '- ' . l:plugin['name'] . ': ' . 'Skipped')
        endif
        redraw 
        let l:count = l:count + 1
    endfor 
    call s:populate_window('Installation finished!', 1)
endfunction


" user defined commands for functions
function! s:define_commands() abort
    command! -nargs=+ -bar Plugin call zen#add(<args>)
    command! -nargs=* -bar -bang -complete=customlist,s:names ZenInstall call zen#install()
    command! -nargs=* -bar -bang -complete=customlist,s:names ZenRemove call zen#remove()
    command! -nargs=* -bar -bang -complete=customlist,s:names ZenUpdate call zen#update()
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
    let l:count = 4
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
            echom string(l:count)
            call add(l:unused_plugins, l:plugin_dir_path)
            call setline(l:count, '- ' . l:plugin_dir_path)
            let l:count = l:count + 1
            redraw
        endif
    endfor

    if l:unused_plugins == []
        call append(line('$'), 'No plugins to remove.')
        return
    endif

    let l:count = 4
    if s:warning_prompt('Delete the following plugins?')
        for l:item in l:unused_plugins 
            let l:plugin_name = split(l:item, '/')[-1]
            let l:cmd_result = system('rm -rf ' . l:item)
            call setline(l:count, '- ' . l:item . ' - Removed!')
            let l:count = l:count + 1
        endfor
    endif
    redraw
    call s:populate_window('Finished cleaning!', 1)
endfunction 


" update plugins
function! zen#update() abort 
    let l:count = 4
    call s:populate_window('Updating plugins..', 0)
    call s:list_plugins()
    for l:plugin in keys(g:plugins)
        let l:plugin_path = g:plugins[l:plugin]['path']
        let l:cmd = 'git -C "' . l:plugin_path . '" pull'
        let l:output = system(l:cmd)
        
        if l:output =~# '\mAlready up to date.'
            call setline(l:count, '- ' . g:plugins[l:plugin]['name'] . ': Skipped (latest)')
        elseif l:output =~# '\mFrom'
            call setline(l:count, '- ' . g:plugins[l:plugin]['name'] . ': Updated')
        else
            call setline(l:count, '- ' . g:plugins[l:plugin]['name'] . ': ERROR ' . l:output)
        endif

        redraw 
        let l:count = l:count + 1
    endfor
    call s:populate_window('Finished updating plugins!', 1)
endfunction 

