# About

## About

This project supplies a patch for a bug of [*netrw*](https://www.vim.org/scripts/script.php?script_id=1075). The bug is explained in [Problem](#problem) section.

## Current Status

The patch was partially adopted in `netrw 170e` and fully adopted in `netrw 170f` on April 30, 2020. Now the documentation `pi_netrw.txt` says

```
v170:   Mar 11, 2020   ...
        Apr 13, 2020   ...
        Apr 30, 2020   * (reported by Manatsu Takahashi) while
                         using Lexplore, a modified file could
                         be overwritten.  Sol'n: will not overwrite,
                         but will emit an |E37| (although one cannot
                         add an ! to override)
```

However, I suspect it will take long for the version of `netrw` to be included in the upstream of `vim`. Till the day, if you'd like to remove the bug, manually download the plugin from the [official](http://www.drchip.org/astronaut/vim/index.html#NETRW) and install it.

# For Users

## Problem

Say you have a window `W` associated with a modified buffer `A`. When you try to load a file `B` using `netrw` into the window `W`, the buffer `A` is discarded without any prompt, which is extremely disastrous. This bug was first discussed in [this StackExchange question](https://vi.stackexchange.com/questions/24994/netrw-discards-changes-without-asking).

## How to Reproduce

1. Execute `vim A` command from shell.

2. Edit the buffer associated with `A` in some way. Now `&modified == 1`.

3. Execute `:Lexplore`<sup>†1</sup> command to enable the side pane of `netrw`.

4. In the side pane, press <kbd>Enter</kbd> on an arbitrary file `B`.

<sub>†1: The problem is not specific to `:Lexplore` command. `Netrw` opened via `:Explore` or `:e` also shows the behavior.</sub>

## Cause

The cause is that `:e!` is called instead of `:e` inside `s:NetrwBrowseChgDir()`, which is defined in `autoload/netrw.vim`. Note, contrary to the name of the function, it is used not only to change the directory but also to edit a file, according to the comment in the file.

If you are a developer, see [Algorithm](#algorithm) for the detailed explanation.

## Fix

To fix the bug, just apply the patch incorporated in this project by, for example, the command below.

```bash
$ patch netrw.vim patch
```

## Environments

The problem was reproduced under Arch Linux, Arch Linux ARM, Raspbian Buster and FreeBSD. Even in the latest `vim 8.2` and `netrw 170c Mar 30, 2020`, we can observe it.

The patch is tested under Arch Linux with the following commands though recompiling `vim` is essentially not needed.

```bash
$ git clone "https://github.com/vim/vim"
$ cd vim
$ ./configure --prefix=/usr/local --with-features=huge --enable-python3interp=dynamic\
  && make\
  && patch runtime/autoload/netrw.vim <path to patch>\
  && sudo make install
```

## Known Bugs

The patch is written for us and not tested very well.

# For Developers

## Algorithm

The patch follows the algorithm below.

1. Trying to load `B` calls three functions: `s:NetrwGetWord()`, `s:NetrwBrowseChgDir()` and `netrw#LocalBrowseCheck()`. The patch keeps the first and the third functions untouched since they do nothing which will be broken if the second function is modified.

2. Inside `s:NetrwBrowseChgDir()`, the patch replaces inappropriate `e!` with `:e`.

3. The replacement causes a side effect. If the flag `dolockout` is set, `:setl ma noro nomod` is called before exiting the function. And `nomod` is evil; `set`ting `nomod[ified]` in a modified buffer is to say "I'm modified but please treat me as an unmodified buffer." As a result, the modified `A` is discarded if you try to open `B` twice. The first trial fails since the buffer is modified but the second trial succeeds since the buffer disguises itself to be unmodified. Thus, the patch additionally un`set`s the flag.

## How to Debug `Netrw`

The way of debugging `netrw` is described in `:help netrw` but it is far from complete. Here is the more detailed instructions.

1. Install the latest [`Netrw`](http://www.drchip.org/astronaut/vim/index.html#NETRW) and [`Decho`](http://www.drchip.org/astronaut/vim/index.html#DECHO), where the latter is a debugging plugin. To install them, download `.vba.gz` files from the links and follow either the following ways.
    
    - Open each file in vim, and execute `:source %` command or `:UseVimball ~/.vim/` command. By this, the plugins are installed under `~/.vim/`. To uninstall them, just delete appropriate files under the directory. In this case, `:RmVimball` command doesn't work unless you manually remove the part `.gz` from the contents of `~/.vim/.VimballRecord` file.

    - *(Recommended)* Execute `gunzip --keep <vba.gz file>` command to get `*.vba` files, open each in vim, and execute `:source %` command or `:UseVimball ~/.vim/` command. By this, the plugins are installed under `~/.vim/`. To uninstall them, execute `:RmVimball <plugin> ~/.vim/` command, where `<plugin>` is the name of the file used to install the plugin minus the extension `.vba` (e.g. `netrw_170e` for `netrw_170e.vba`).

2. Create a minimal configuration file `minimal_vimrc` whose contents are shown below. This file is included in this project.

```vim
set nocp
so $HOME/.vim/plugin/Decho.vim
so $HOME/.vim/plugin/netrwPlugin.vim
```

3. Open `~/.vim/plugin/netrwPlugin.vim` and `~/.vim/autoload/netrw.vim` in `vim` and execute `:DechoOn`, then save and exit. This turns on debugging outputs.

4. Execute the following command to start debugging. We also provide the script `start_debugging.sh`, where `./start_debugging.sh [<file>]` is essentially the same as the command below.

```bash
$ vim -u minimal_vimrc --noplugins -i NONE [<file>]
```

<!-- vim: set spell: -->

