<h1 align="center">vim-zen</h1>
<p align="center">Barebones Vim Plugin Manager</p>

<p align="center">
<a href="https://i.imgur.com/1oyhPPd.gif"><img src="https://i.imgur.com/1oyhPPd.gif" alt="Asciicast" width="640"/></a>
</p>

### Features
- Does 3 things and does them well - Install, Remove, Update
- Parallel install & update using Python multithreading.
- Easy setup and simple usage.

### Installation
Put the [zen.vim](https://raw.githubusercontent.com/danishprakash/vim-zen/master/zen.vim) file into the `autoload` directory. 

#### Unix
##### Neovim
```bash
curl -o ~/.local/share/nvim/site/autoload/zen.vim --create-dirs https://raw.githubusercontent.com/danishprakash/vim-zen/master/zen.vim
```

##### Vim
```bash
curl -o ~/.vim/autoload/zen.vim --create-dirs https://raw.githubusercontent.com/danishprakash/vim-zen/master/zen.vim
```

### Usage
- Add a `vim-zen` section in your vimrc.
- Add `call zen#init()` method at the beginnning of the section.
- Add plugins using the `Plugin` command. 
- Reload `.vimrc`.
- Run `ZenInstall` from within vim.


### Example vim-zen section
```vim
" begin section
call zen#init()
Plugin 'junegunn/goyo.vim' 
Plugin 'https://github.com/danishprakash/vimport'
" end section
```
See [this](https://github.com/danishprakash/dotfiles/blob/master/nvim/init.vim) for reference.

### Commands

1. `ZenInstall`: Install plugins.
2. `ZenUpdate`: Update plugins.
3. `ZenDelete`: Remove unused plugins.

### Why?
I wanted something really simple, all other plugin managers out there did the things that I wanted along with other stuff. I wanted a plugin manager that helped me `install`, `remove`, and `update` the plugins I use.

### Links
- [Changelog Nightly (21/6)](http://nightly.changelog.com/2018/06/21/)

### License
MIT
