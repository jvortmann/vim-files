# vim-files

A Neovim configuration in Lua. [lazy.nvim](https://github.com/folke/lazy.nvim)
manages the plugins, and the color scheme is solarized8. Floating windows use
the color of the popup menu.

## Requirements

Neovim 0.12 or newer, and git. lazy.nvim installs itself on the first start.

| Tool | Used by |
| --- | --- |
| `tree-sitter` CLI | nvim-treesitter (main branch) builds the parsers with it |
| `fzf` | fzf-lua needs the binary on `PATH`. Install it with Homebrew |
| ripgrep (`rg`) | ack.vim searches with it when `rg` exists. It also serves the grep keys of fzf-lua |
| `fd` | fzf-lua lists files with it when it exists, optional |
| Nerd Font | the file icons of nvim-web-devicons |
| universal-ctags | tagbar |
| prettier | conform.nvim, optional |

mason.nvim installs the language servers into `~/.local/share/nvim/mason`.
It installs each missing server on the first interactive start. mise
provides the language toolchains: ruby, node, go, rust and zig.

conform.nvim runs the `node_modules/.bin/prettier` of the project, or a
global `prettier` when the project has none. It formats on save only in a
project that has a prettier config.

## Install

```sh
git clone <this repository> && cd <the clone>
./setup.sh
```

`setup.sh` runs `symlink.sh`, then `nvim --headless "+Lazy! restore" +qa` to
install the plugins at the versions in `lazy-lock.json`. Then it opens Neovim.

`symlink.sh` runs `rm -r ~/.vim`, so it deletes your current `~/.vim`. It then
links this folder to `~/.vim` and to `~/.config/nvim`. If `~/.config/nvim` is a
real folder, `ln` puts the link inside it, so move that folder away first.
Keep both links: the config reads `conf/` through `~/.vim`.

Put your own settings in `~/.vimrc.local`. The config loads it after the
other files. `~/.vimrc.force` loads last.

## Language servers

nvim-lspconfig configures seven servers.

| Server | Language |
| --- | --- |
| `vtsls`, `eslint` | TypeScript and JavaScript |
| `ruby_lsp` | Ruby |
| `lua_ls` | Lua |
| `gopls` | Go |
| `zls` | Zig |
| `rust_analyzer` | Rust |

A server starts only inside a project root, never for a single file. It
stops after one hour without use, and starts again on the next use of its
buffer. `vim.g.lsp_idle_ms` sets the limit in milliseconds.

Diagnostics show the signs `x`, `!` and `i`. The message shows as virtual text
on the cursor line only.

## Herdr

Inside a Herdr terminal, `<C-h>`, `<C-j>`, `<C-k>` and `<C-l>` also move
across Herdr panes. Neovim saves one session file for each Herdr terminal.

## Layout

- `init.lua` is the entry. It loads the modules of `lua/config/`: `defaults`,
  `guioptions`, `autocmds/`, `keymaps/` and `plugins/`.
- `lua/plugins/<name>.lua` holds one lazy.nvim spec for each plugin.
- `conf/` holds `force_default` and the settings that are still VimScript:
  `neosnippet`. It holds no maps.
- `spell/` holds the spell file that `zg` writes.

## Tests

```sh
./tests/run.sh
```

It runs every `tests/*_test.lua` in headless Neovim. It exits with status 1
when a file fails.

## Shortcuts

The leader is `\`. Press `<Leader>h` for the list of all maps. `<M-…>` is the
Alt key, which is Option on macOS.

Modes: `n` normal, `i` insert, `v` visual and select, `x` visual only, `o`
operator-pending.

### Editing

| Key | Mode | Action |
| --- | --- | --- |
| `<M-/>`, `<Leader>/` | n | Toggle line comment |
| `<M-/>`, `<Leader>/` | x | Toggle selection comment |
| `<M-S-Down>`, `<M-S-j>` | n, i | Move the line down |
| `<M-S-Down>`, `<M-S-j>` | v | Move the selected lines down |
| `<M-S-Up>`, `<M-S-k>` | n, i | Move the line up |
| `<M-S-Up>`, `<M-S-k>` | v | Move the selected lines up |
| `<M-S-d>`, `<Leader>d` | n, v, o | Duplicate the line |
| `<M-a>` | n, v, o | Select the whole buffer |
| `>` | v | Indent, and keep the selection |
| `<` | v | Unindent, and keep the selection |
| `Y` | n | Yank to the end of the line |
| `<CR>` | n | Clear the search highlight |

### Movement and windows

| Key | Mode | Action |
| --- | --- | --- |
| `<S-Up>` | n, v, o | Up one line, not one page |
| `<S-Down>` | n, v, o | Down one line, not one page |
| `<Space><Space>` | n, v, o | Maximize the window |
| `<Space>=` | n, v, o | Equalize the window sizes |
| `<Space>_` | n, v, o | Maximize the window height |
| `<Space><Bar>` | n, v, o | Maximize the window width |
| `<Space>o` | n, v, o | Close all other windows |
| `<Space>r` | n, v, o | Rotate the windows |

### Quickfix and location list

All of these are in modes n, v and o. Each quickfix map has two keys:
`<Leader>q…` and `<Leader><Leader>…`.

| Key | Action |
| --- | --- |
| `<Leader>qo`, `<Leader><Leader>o` | Open the quickfix list |
| `<Leader>qc`, `<Leader><Leader>c` | Close the quickfix list |
| `<Leader>qt`, `<Leader><Leader>t` | Open the quickfix list, or close it if empty |
| `<Leader>qn`, `<Leader><Leader>n` | Go to the next quickfix entry |
| `<Leader>qp`, `<Leader><Leader>p` | Go to the previous quickfix entry |
| `<Leader>lo` | Open the location list |
| `<Leader>lc` | Close the location list |
| `<Leader>lt` | Open the location list, or close it if empty |
| `<Leader>ln` | Go to the next location |
| `<Leader>lp` | Go to the previous location |

In the quickfix window (mode n):

| Key | Action |
| --- | --- |
| `<CR>` | Open the entry under the cursor |
| `h` | Move the cursor left |
| `v`, `<C-v>`, `<Leader><CR>` | Open the entry in a vertical split (QFEnter) |
| `s`, `<C-s>`, `<C-x>`, `<C-CR>`, `<Leader><Space>` | Open the entry in a horizontal split (QFEnter) |
| `<Leader><Tab>` | Open the entry in a new tab (QFEnter) |

### Build, git and alternate files

| Key | Mode | Action |
| --- | --- | --- |
| `<F5>` | n, v, o | Run `makeprg` |
| `<F6>` | n, v, o | Run `makeprg` on the current file |
| `<F7>` | n, v, o | Git blame, with `.git-blame-ignore-revs` when it exists |
| `<S-F7>` | n, v, o | Git diff in a vertical split |
| `<F3>`, `<Leader>t`, `<Leader>t<Space>` | n, v, o | Open the alternate file |
| `<S-F3>`, `<Leader>ts` | n, v, o | Open the alternate file in a horizontal split |
| `<Leader>tv` | n, v, o | Open the alternate file in a vertical split |

### Find and browse

| Key | Mode | Action |
| --- | --- | --- |
| `<Leader>ff`, `<Leader>f` | n, v, o | Find files |
| `<Leader>fl` | n, v, o | Find lines in the current buffer |
| `<Leader>fla` | n, v, o | Find lines in the open buffers |
| `<Leader>fm` | n, v, o | Find marks |
| `<Leader>fo`, `<Leader>o` | n, v, o | Find open buffers |
| `<Leader>ft` | n, v, o | Find tags in the current buffer |
| `<Leader>fta` | n, v, o | Find tags |
| `<Leader>fg` | n, v, o | Grep the files, as you type |
| `<Leader>fw` | n, v, o | Grep the word under the cursor |
| `<Leader>fh` | n, v, o | Find recent files and the open buffers |
| `<F2>` | n, v, o | Toggle the file tree (nvim-tree) |
| `<M-i>`, `<Leader>ii` | n, v, o | Open tagbar, close it after a jump |
| `<M-S-i>`, `<Leader>i`, `<Leader>i<Space>` | n, v, o | Toggle tagbar |

`:e .` still opens netrw, because nvim-tree does not take over folders.

### Git hunks

| Key | Mode | Action |
| --- | --- | --- |
| `]c` | n | Go to the next git hunk |
| `[c` | n | Go to the previous git hunk |
| `<Leader>gs` | n, v | Stage the hunk, or the selected lines |
| `<Leader>gr` | n, v | Reset the hunk, or the selected lines |
| `<Leader>gp` | n | Preview the hunk |
| `<Leader>gb` | n | Show the git blame of the line |
| `ih` | o, x | Select the hunk |

In a diff window, `]c` and `[c` keep their built-in jumps.

### Language server

These keys exist only in a buffer with a running server. Without one, `K`
does nothing. `<C-w>d` is the exception, because Neovim defines it for every
buffer.

| Key | Mode | Action |
| --- | --- | --- |
| `K` | n | Show the documentation of the symbol |
| `gd` | n | Go to the definition |
| `grn` | n | Rename the symbol |
| `gra` | n, x | Show the code actions |
| `grr` | n | List the references |
| `gri` | n | List the implementations |
| `gO` | n | List the symbols of the buffer |
| `]d` | n | Go to the next diagnostic |
| `[d` | n | Go to the previous diagnostic |
| `<C-w>d` | n | Show the diagnostic message |
| `<C-s>` | i, s | Show the signature of the function |

### Format, surround and snippets

| Key | Mode | Action |
| --- | --- | --- |
| `<Leader>p` | n, x | Format the buffer or the selection |
| `ys{motion}{char}` | n | Surround the text with a pair (mini.surround) |
| `yss{char}` | n | Surround the line |
| `S{char}` | x | Surround the selection |
| `cs{old}{new}` | n | Change the surrounding pair |
| `ds{char}` | n | Delete the surrounding pair |
| `<C-k>` | i, s | Expand a snippet or jump to the next field (neosnippet) |
| `<C-k>` | x | Expand the selection as a snippet (neosnippet) |
| `<Leader>h` | n, x | Show all shortcuts (which-key) |

mini.pairs closes a pair in insert mode. A bracket pairs only when no
backslash comes before it and no word character comes after it.

### Disabled keys

| Key | Mode | Effect |
| --- | --- | --- |
| `<F1>` | n | No help |
| `Q` | n | No register replay |
| `K` | n | No keyword lookup, except in a buffer with a language server |
