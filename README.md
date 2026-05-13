# vim-markdown

A lightweight Vim/Neovim plugin to preview Markdown files. Toggle between edit and preview with a single keymap. Supports three backends: **frogmouth** (default), **glow**, and **pandoc** (browser).

## Requirements

- Vim 8+ or Neovim
- At least one preview backend (see below)

## Backends

| Backend | Type | Install |
|---------|------|---------|
| **frogmouth** *(default)* | Interactive TUI browser | `pip install frogmouth` |
| **glow** | Terminal pager | `brew install glow` |
| **pandoc** | Browser (HTML) | `brew install pandoc` |

**frogmouth** — a full terminal Markdown browser. Opens in a vertical split, navigates links, and watches the file for changes automatically.

**glow** — renders Markdown with colors and structure in a terminal pager inside a vertical split. Re-renders on every save.

**pandoc** — converts the file to styled HTML and opens it in your default browser. Re-generates on every save; you refresh the tab manually.

## Installation

### vim-plug

```vim
Plug 'myneid/vim-markdown'
```

### lazy.nvim

```lua
{ "myneid/vim-markdown" }
```

### Manual

```vim
set runtimepath+=/path/to/vim-markdown
```

## Usage

Open any Markdown file, then:

| Action | Default |
|--------|---------|
| Toggle preview on / off | `<leader>mp` |
| Open preview | `:MarkdownPreview` |
| Close preview | `:MarkdownPreviewStop` |
| Toggle preview | `:MarkdownPreviewToggle` |
| Show debug info | `:MarkdownPreviewDebug` |

The keymap is only active in `filetype=markdown` buffers.

## Configuration

```vim
" Choose your backend (default: 'frogmouth')
let g:vim_markdown_previewer = 'frogmouth'   " or 'glow' or 'pandoc'

" Override the toggle keymap (default: <leader>mp)
let g:vim_markdown_preview_key = '<F5>'
```

## Refresh behaviour

| Backend | On save |
|---------|---------|
| frogmouth | Automatic — watches the file itself |
| glow | Preview split closes and reopens with updated render |
| pandoc | HTML is regenerated — press `⌘R` / `F5` in the browser |

## Limitations

- The preview reflects the **saved** file. Run `:w` before toggling.
- The file must already exist on disk (not a new unnamed buffer).
- The pandoc browser tab does not auto-refresh — you refresh it manually.
- frogmouth and glow require a terminal that supports ANSI colours.
