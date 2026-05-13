# vim-markdown

A lightweight Vim/Neovim plugin to preview Markdown files. Toggle between edit and preview with a single keymap. Supports four backends: **native** (default), **frogmouth**, **glow**, and **pandoc** (browser).

## Requirements

- Vim 8+ or Neovim
- The native backend requires Python 3 with `markdown-it-py` (see below)

## Backends

| Backend | Type | Requirement |
|---------|------|-------------|
| **native** *(default)* | ANSI renderer in a terminal split | `pip install markdown-it-py` |
| **frogmouth** | Interactive TUI browser | `pip install frogmouth` |
| **glow** | Terminal pager | `brew install glow` |
| **pandoc** | Browser (HTML) | `brew install pandoc` |

**native** — a built-in renderer that converts Markdown to styled terminal output using 24-bit ANSI colour codes. Opens in a vertical split. No external tool needed beyond Python and `markdown-it-py`.

- H1 in sky blue with `═══` underline decoration
- H2 in mint green with `───` underline decoration
- H3–H6 each with a distinct colour and `###` prefix
- Bold, italic, inline code, strikethrough, and links styled inline
- Code blocks on a dark background with a language label
- Blockquotes with a `│` bar and dimmed italic text
- Coloured `•` bullets and muted numbered list markers
- Re-renders automatically on every save

**frogmouth** — a full terminal Markdown browser. Opens in a vertical split, navigates links, and watches the file for changes automatically.

**glow** — renders Markdown with colours and structure in a terminal split. Re-renders on every save.

**pandoc** — converts the file to styled HTML and opens it in your default browser. Re-generates on every save; you refresh the tab manually.

## Installation

### vim-plug

```vim
Plug 'myneid/vim-markdown'
```

Then install the Python dependency:

```sh
pip install markdown-it-py
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
" Choose your backend (default: 'native')
let g:vim_markdown_previewer = 'native'      " built-in ANSI renderer
let g:vim_markdown_previewer = 'frogmouth'   " interactive TUI browser
let g:vim_markdown_previewer = 'glow'        " terminal pager
let g:vim_markdown_previewer = 'pandoc'      " browser (HTML)

" Override the toggle keymap (default: <leader>mp)
let g:vim_markdown_preview_key = '<F5>'
```

## Switching between edit and preview

The preview takes over the current window — no split. Press `<leader>mp` to enter preview mode; press `q` to exit the previewer and return to editing at the same cursor position.

| Backend | How to return to editing |
|---------|--------------------------|
| native | Press `q` to quit the pager |
| glow | Press `q` to quit the pager |
| frogmouth | Press `q` to quit frogmouth |
| pandoc | Stays in the browser — edit mode is unaffected |

## Refresh behaviour

| Backend | On save |
|---------|---------|
| native / glow / frogmouth | Toggle off, save, toggle on again |
| pandoc | HTML is regenerated — press `⌘R` / `F5` in the browser |

## Limitations

- The preview reflects the **saved** file. Run `:w` before toggling.
- The file must already exist on disk (not a new unnamed buffer).
- All terminal backends require a terminal that supports 24-bit ANSI colour.
