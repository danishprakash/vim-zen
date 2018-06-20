" ==========================================================
" Name:         vim-zen: Vim plugin manager
" Maintainer:   Danish Prakash
" HomePage:     https://github.com/prakashdanish/vim-zen
" Version:      1.0.0
" ==========================================================


function! zen#init() abort
    let s:zen_win = 0
    let g:plugins = {}
    let g:plugin_names = []
    let s:installation_path = ''
    let s:plugin_display_order = {}

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


" syntax highlighting
function! s:syntax() abort
    syntax clear
    syntax match ZenSep /^=.*=/
    syntax match ZenTitle /^vim-zen/
    syntax match ZenPlus /\[+].*:/
    syntax match ZenMinus /\[-].*:/ 
    syntax match ZenSpace /\[ ].*:/ 
    syntax match ZenDelete /\[x.\{-}:/

    highlight link ZenPlus Function
    highlight link ZenMinus Type
    highlight link ZenSpace Comment
    highlight link ZenSep Comment
    highlight link ZenTitle Special
    highlight link ZenDelete Exception 
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
    let l:count = 4
    for l:plugin in keys(g:plugins)
        call append(line('$'), '[ ] ' . g:plugins[l:plugin]['name'] . ': ')
        let s:plugin_display_order[g:plugins[l:plugin]['name']] = l:count 
        let l:count = l:count + 1
    endfor
    call s:syntax()
    redraw 
endfunction 


function! s:populate_window(message, flag) abort
    let l:heading = 'vim-zen - ' . '[ ' . a:message . ' ]'
    
    " when populating window for the first time
    if !(a:flag)
        call s:start_window()
        call append(0, l:heading)
        call append(1, repeat('=', len(l:heading)))
    else
        call setline(1, l:heading)
        call setline(2, repeat('=', len(l:heading)))
    endif
    call s:syntax()
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


" user defined commands for functions
function! s:define_commands() abort
    command! -nargs=+ -bar Plugin call zen#add(<args>)
    command! -nargs=* -bar -bang -complete=customlist,s:names ZenInstall call zen#install()
    command! -nargs=* -bar -bang -complete=customlist,s:names ZenRemove call zen#remove()
    command! -nargs=* -bar -bang -complete=customlist,s:names ZenUpdate call zen#update()
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
    let name = '[vim-zen]'
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
    let l:plugins_to_install = []
    let l:populate_window_message = 'Installation finished'
    call s:populate_window('Installing plugins...', 0)
    call s:list_plugins()

    for key in keys(g:plugins)
        let l:plugin = g:plugins[key]
        let l:install_path = s:installation_path . "/" . l:plugin['name']
        if !isdirectory(l:install_path)
            let l:cmd = "git clone " . l:plugin['remote'] . " " . l:install_path 
            call add(l:plugins_to_install, l:cmd)
        else
            call setline(l:count, '[-] ' . l:plugin['name'] . ': ' . 'Already installed.')
        endif
        let l:count = l:count + 1
        redraw 
    endfor 

    if len(l:plugins_to_install) == 0
        :
    elseif len(l:plugins_to_install) > 1
        call s:parallel_operation_python('install', l:plugins_to_install)
        return
    else
        let l:plugin_name = split(cmd, '/')[-1]
        let l:cmd_result =  system(l:cmd)
        if l:cmd_result =~ 'fatal'
            let l:installation_status = 'x'
            let l:cmd_result = 'Failed (' . l:cmd_result . ')'
            let l:populate_window_message = l:populate_window_message . ' with errors'
        else
            let l:cmd_result = 'Installed'
            let l:installation_status = '+'
        endif
        call setline(s:plugin_display_order[l:plugin_name], '[' . l:installation_status . '] ' . l:plugin_name . ': ' . l:cmd_result)
        call s:load_plugin(l:plugin_name)
    endif
    redraw
    call s:populate_window(l:populate_window_message, 1)
endfunction


" display warning prompt and ask for input
function! s:warning_prompt(message) abort
    call inputsave()
    echohl WarningMsg
    let l:choice = input(a:message . ' (y/n): ')
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
            call setline(l:count, '[ ] ' . l:plugin_dir_path)
            let l:count = l:count + 1
            redraw
        endif
    endfor

    if l:unused_plugins == []
        call append(line('$'), 'No plugins to remove.')
        call s:populate_window('Done', 1)
        return
    endif

    let l:count = 4
    if s:warning_prompt('Delete the following plugins?')
        for l:item in l:unused_plugins 
            let l:plugin_name = split(l:item, '/')[-1]
            let l:cmd_result = system('rm -rf ' . l:item)
            call setline(l:count, '[x] ' . l:item . ': Removed!')
            let l:count = l:count + 1
            redraw
        endfor
    endif
    call s:populate_window('Finished cleaning!', 1)
endfunction 


" update plugins
function! zen#update() abort 
    call s:populate_window('Updating plugins..', 0)
    call s:list_plugins()
    call s:parallel_operation_python('update', [])
endfunction 


" python code for multithreaded operations
function! s:parallel_operation_python(mode, plugins_to_install) abort
let py_exe = has('python') ? 'python' : 'python3'
execute py_exe "<< EOF"
import vim
import time
import Queue
import commands
import threading

class ZenThread(threading.Thread):
    def __init__(self, cmd, queue):
        threading.Thread.__init__(self)
        self.cmd = cmd
        self.queue = queue 

    def run(self):
        (status, output) = commands.getstatusoutput(self.cmd)
        self.queue.put((self.cmd, output, status))


def install():
    count = 4
    thread_list = list()
    result_queue = Queue.Queue()
    plugins = vim.eval('g:plugins')
    path = vim.eval('s:installation_path')
    plugins_to_install = vim.eval('a:plugins_to_install')
    plugin_display_order = vim.eval('s:plugin_display_order')

    if plugins_to_install == []:
        return

    start_time = time.time()
    for cmd in plugins_to_install:
        plugin_name = cmd.split('/')[-1]
        plugin_path = path + '/' + plugin_name 
        to_install = vim.eval('!isdirectory("{}")'.format(plugin_path))
        if to_install:
            thread = ZenThread(cmd, result_queue)
            thread_list.append(thread)
            thread.start()
            vim.eval('setline({0}, "[+] {1}: Installing...")'.format(plugin_display_order[plugin_name], plugin_name))
        else:
            vim.eval('setline({0}, "[-] {1}: Already installed.")'.format(plugin_display_order[plugin_name], plugin_name))
        vim.command('redraw') 
        count += 1

    while threading.active_count() > 1 or not result_queue.empty():
        while not result_queue.empty():
            (cmd, output, status) = result_queue.get()
            plugin_name = cmd.split('/')[-1]
            if status == 0:
                vim.eval('s:load_plugin("{}")'.format(plugin_name))
                vim.eval('setline({0}, "[+] {1}: Installed")'.format(plugin_display_order[plugin_name], plugin_name))
            else:
                vim.eval('setline({0}, "[x] {1}: [ERROR] {2}")'.format(plugin_display_order[plugin_name], plugin_name, output))
            vim.command('redraw')

    for thread in thread_list:
        thread.join()

    vim.eval('s:populate_window("Installation finished!\t|\t Time: {0}", 1)'.format(time.time()-start_time))


def update():
    commands = list()
    git_cmd = 'git -C'
    result_queue = Queue.Queue()
    plugins = vim.eval('g:plugins') 
    populate_window_message = 'Finished installation'
    plugin_display_order = vim.eval('s:plugin_display_order')
    start_time = time.time()

    for key, value in plugins.items():
        cmd = str(git_cmd + ' \"' + value['path'] + '\" pull')
        thread = ZenThread(cmd, result_queue)
        thread.start()

    while threading.active_count() > 1 or not result_queue.empty():
        while not result_queue.empty():
            (cmd, output, status) = result_queue.get()
            plugin_name = cmd.split('/')[-1].split('"')[0]  # plugin name from git pull command
            if status == 0:
                # TODO: add check if already updated or not update status_message accordingly (+, -)
                vim.eval('s:load_plugin("{}")'.format(plugin_name))
                vim.eval('setline({0}, "[+] {1}: {2}")'.format(plugin_display_order[plugin_name], plugin_name, output))
            else:
                populate_window_message = 'Finished installation with errors'
                vim.eval('setline({0}, "[x] {1}: [ERROR] {2}")'.format(plugin_display_order[plugin_name], plugin_name, output))
            vim.command('redraw')

    vim.eval('s:populate_window("{0} | Time: {1}", 1)'.format(populate_window_message, time.time() - start_time))

mode = vim.eval('a:mode')
update() if mode == 'update' else install()
EOF

endfunction
