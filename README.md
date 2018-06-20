<h1 align="center">vim-zen</h1>
<p align="center">Barebones Vim Plugin Manager</p>

<p align="center">
<a href="https://i.imgur.com/1oyhPPd.gif"><img src="https://i.imgur.com/1oyhPPd.gif" alt="Asciicast" width="570"/></a>
</p>

### Features
- Does 3 things and does them well - Install, Remove, Update
- Parallel install & update using Python multithreading.
- Easy setup and simple usage.

### Installation
Put the [zen.vim](https://raw.githubusercontent.com/prakashdanish/vim-zen/master/zen.vim) file into the `autoload` directory. 

#### Unix
##### Neovim
```bash
curl https://raw.githubusercontent.com/prakashdanish/vim-zen/master/zen.vim -o --create-dirs ~/.local/share/nvim/site/autoload/zen.vim
```

##### Vim
```bash
curl https://raw.githubusercontent.com/prakashdanish/vim-zen/master/zen.vim -o --create-dirs ~/.local/share/nvim/site/autoload/zen.vim
```

### Usage
- Add a `vim-zen` section in your vimrc.
- Add `call zen#init()` method at the beginnning of the section.
- Add plugins using the `Plugin` command. 
- Reload `.vimrc`.
- Run `ZenInstall` from within vim.


#### Example vim-zen section
```vim
" begin section
call zen#init()
Plugin 'junegunn/goyo.vim' 
Plugin 'https://github.com/prakashdanish/vimport'
" end section
```
See [this](https://github.com/prakashdanish/dotfiles/blob/master/nvim/init.vim) for reference.

### Commands

1. `ZenInstall`: Install plugins.
2. `ZenUpdate`: Update plugins.
3. `ZenDelete`: Remove unused plugins.

### Why?
I wanted something really simple, all other plugin managers out there did the things that I wanted along with other stuff. I wanted a plugin manager that helped me `install`, `remove`, and `update` the plugins I use.

### License
MIT
