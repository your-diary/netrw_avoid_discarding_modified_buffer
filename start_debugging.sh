#!/bin/bash

set -e

if [[ ! -f "${HOME}/.vim/plugin/Decho.vim" ]]; then
    echo 'ERROR: `Decho.vim` is not found.'
    exit 1
fi
if [[ ! -f "${HOME}/.vim/plugin/netrwPlugin.vim" ]]; then
    echo 'ERROR: `netrwPlugin.vim` is not found.'
    exit 1
fi

vim -u "./minimal_vimrc" --noplugins -i NONE "$@"

