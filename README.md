# For Users

## Problem

Say you have a window `W` associated with a modified buffer `A`. When you try to load a file `B` using `netrw` into the window `W`, the buffer `A` is discarded without any prompt, which is extremely disastrous.

## How to Reproduce

1. Execute `vim A` command from shell.

2. Edit the buffer associated with `A` in some way. Now `&modified == 1`.

3. Execute `:Lexplore`<sup>†1</sup> command to enable the side pane of `netrw`.

4. In the side pane, press <kbd>Enter</kbd> on an arbitrary file `B`.

<sub>†1: The problem is not specific to `:Lexplore` command. `Netrw` opened via `:Explore` or `:e` also shows the behavior.</sub>

## Cause

The cause is that `:e!` is called instead of `:e` inside `s:NetrwBrowseChgDir()`, which is defined in `autoload/netrw.vim`. Note, contrary to the name of the function, it is used not only to change the directory but also to edit a file, according to the comment in the file.

## Fix

To fix the bug, apply the patch incorporated in this project by the command below.

```bash
$ patch netrw.vim patch
```

## Known Bugs

The patch is written for us and not tested very well.

# For Developers

## Algorithm

The patch follows the algorithm below.

1. Trying to loading `B` calls three functions: `s:NetrwGetWord()`, `s:NetrwBrowseChgDir()` and `netrw#LocalBrowseCheck()`. The patch keeps the first and the third functions untouched since they do nothing which will be broken if the second function is modified.

2. Inside `s:NetrwBrowseChgDir()`, the patch replaces inappropriate `e!` to `:e`.

3. The replacement causes a side effect. If the flag `dolockout` is set, `:setl ma noro nomod` is called before exiting the function. And `nomod` is evil; `set`ting `nomod[ified]` in a modified buffer is to say "I'm modified but please treat me as an unmodified buffer." As a result, the modified `A` is discarded if you try to open `B` twice. The first trial fails since the buffer is modified but the second trial succeeds since the buffer disguises itself to be unmodified. Thus, the patch additionally un`set`s the flag.

## How to Debug `Netrw`

The way of debugging `netrw` is described in `:help netrw` but it is far from complete. Here is the more detailed instructions.

1. Install the latest [`Netrw`](http://www.drchip.org/astronaut/vim/index.html#NETRW) and [`Decho`](http://www.drchip.org/astronaut/vim/index.html#DECHO), where the latter is a debugging plugin. To install them, download `.vbs.gz` files from the links, open each in vim, and execute `:source %` command. By this, plugins are installed under `~/.vim/`. (To uninstall them, just delete appropriate files under the directory.)

2. Create a minimal configuration file `minimal_vimrc` whose contents are shown below.

```vim
set nocp
so $HOME/.vim/plugin/Decho.vim
so $HOME/.vim/plugin/netrwPlugin.vim
```

3. Open `~/.vim/plugin/netrwPlugin.vim` and `~/.vim/autoload/netrw.vim` in `vim` and execute `:DechoOn`, then save and exit. This turns on debugging outputs.

4. Execute the following command to start debugging.

```bash
$ vim -u `minimal_vimrc` --noplugins -i NONE [<file>]
```

<!-- vim: set spell: -->

