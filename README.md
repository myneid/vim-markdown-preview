# vim-markdown

A lightweight Vim/Neovim plugin to preview Markdown files. Toggle between edit and preview with a single keymap. Supports four backends: **native** (default), **frogmouth**, **glow**, and **pandoc** (browser).

## Requirements

- Vim 8+ or Neovim
- The native backend requires Python 3 with two packages:

```sh
pip install -r requirements.txt
```

Or individually:

```sh
pip install markdown-it-py rich-pyfiglet
```

## Backends

| Backend | Type | Requirement |
|---------|------|-------------|
| **native** *(default)* | ANSI renderer, same-window | `pip install markdown-it-py rich-pyfiglet` |
| **frogmouth** | Interactive TUI browser | `pip install frogmouth` |
| **glow** | Terminal pager | `brew install glow` |
| **pandoc** | Browser (HTML) | `brew install pandoc` |

### native

The built-in renderer converts Markdown to styled terminal output using 24-bit ANSI colour codes and ASCII art headings. No external tool needed beyond Python and the two pip packages.

**Headings** use Rich Figlet (`rich-pyfiglet`) to render colour-gradient ASCII art banners, sized by level:

| Level | Font | Height | Separator |
|-------|------|--------|-----------|
| H1 | `ansi_shadow` | large | `═══` |
| H2 | `ansi_shadow` | large | `───` |
| H3 | `standard` | compact | `╌╌╌` |
| H4–H6 | `####` prefix | 1 line | — |

If a heading is too long to fit the ASCII art in the terminal width, or if `rich-pyfiglet` is not installed, headings fall back to the **boxed** style automatically.

**Everything else:**

- Bold, italic, inline code, strikethrough, and links styled inline
- Code blocks on a dark background with a language label
- Blockquotes with a `│` bar and dimmed italic text
- Coloured `•` bullets and muted numbered list markers
- Mouse wheel scrolling supported (requires `set mouse=a`)

### frogmouth

A full terminal Markdown browser. Takes over the current window, navigates links, and watches the file for changes automatically. Press `q` to return to editing.

### glow

Renders Markdown with colours and structure in a terminal pager. Press `q` to return to editing.

### pandoc

Converts the file to styled HTML (GitHub-style CSS with dark mode support) and opens it in your default browser. Re-generates the HTML on every save; you refresh the browser tab manually (`⌘R` / `F5`).

## Installation

### vim-plug

```vim
Plug 'myneid/vim-markdown'
```

```sh
pip install -r ~/.vim/plugged/vim-markdown/requirements.txt
```

### lazy.nvim

```lua
{ "myneid/vim-markdown" }
```

```sh
pip install -r ~/.local/share/nvim/lazy/vim-markdown/requirements.txt
```

### Manual

```vim
set runtimepath+=/path/to/vim-markdown
```

```sh
pip install -r /path/to/vim-markdown/requirements.txt
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

`<leader>` is `\` by default in Vim. Many people remap it to `,` or `<Space>`.

The keymap is only active in `filetype=markdown` buffers.

## Switching between edit and preview

The preview takes over the current window — no split. Press `<leader>mp` to enter preview mode, and `q` to quit the previewer and return to editing at the same cursor position.

| Backend | How to return to editing |
|---------|--------------------------|
| native | Press `q` to quit the pager |
| glow | Press `q` to quit the pager |
| frogmouth | Press `q` to quit frogmouth |
| pandoc | Stays in the browser — edit mode is unaffected |

## Configuration

```vim
" Preview backend (default: 'native')
let g:vim_markdown_previewer = 'native'      " built-in ANSI renderer
let g:vim_markdown_previewer = 'frogmouth'   " interactive TUI browser
let g:vim_markdown_previewer = 'glow'        " terminal pager
let g:vim_markdown_previewer = 'pandoc'      " browser (HTML)

" Header style for the native backend (default: 'ascii')
let g:vim_markdown_header_style = 'ascii'    " ASCII art banners via rich-pyfiglet
let g:vim_markdown_header_style = 'boxed'    " box-drawing characters

" Toggle keymap (default: <leader>mp)
let g:vim_markdown_preview_key = '<F5>'
```

## Refresh behaviour

| Backend | On save |
|---------|---------|
| native / glow / frogmouth | Toggle off (`:w`), toggle on again |
| pandoc | HTML regenerates automatically — refresh the browser tab |

## Limitations

- The preview reflects the **saved** file. Run `:w` before toggling.
- The file must already exist on disk (not a new unnamed buffer).
- All terminal backends require a terminal with 24-bit ANSI colour support.
- ASCII art headers (`rich-pyfiglet`) may fall back to boxed style for very long headings.
