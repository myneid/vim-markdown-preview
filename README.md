# vim-markdown

A lightweight Vim/Neovim plugin to preview Markdown files in the browser, rendered with GitHub-style CSS. Toggle the preview on and off with a single keymap — the HTML updates automatically every time you save.

## Requirements

- Vim 8+ or Neovim
- [pandoc](https://pandoc.org/installing.html) in your `PATH`

On macOS:

```sh
brew install pandoc
```

## Installation

### vim-plug

```vim
Plug '/path/to/vim-markdown'         " local
" or after pushing to GitHub:
Plug 'yourname/vim-markdown'
```

### lazy.nvim

```lua
{ dir = "/path/to/vim-markdown" }
-- or after pushing to GitHub:
{ "yourname/vim-markdown" }
```

### Manual

Add this to your `~/.vimrc` or `init.vim`:

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

The keymap is only active in `filetype=markdown` buffers.

**Workflow:**
1. Press `<leader>mp` — the rendered page opens in your default browser.
2. Edit your file normally in Vim.
3. Save (`:w`) — the HTML regenerates automatically.
4. Refresh the browser tab to see the update (`⌘R` / `F5`).
5. Press `<leader>mp` again to stop the preview and clean up the temp file.

## Configuration

Override the default keymap before the plugin loads:

```vim
let g:vim_markdown_preview_key = '<F5>'
```

## What gets rendered

The plugin uses pandoc with GitHub-Flavored Markdown (`--from=gfm`) so everything GFM supports is rendered correctly:

- Headings, bold, italic, strikethrough
- Fenced code blocks (with language tag)
- Tables
- Blockquotes
- Ordered and unordered lists, task lists
- Links and images
- Horizontal rules
- Inline HTML

The output is a fully self-contained `.html` file — no network requests, no external dependencies at view time.

## Styling

The preview uses an embedded GitHub-style CSS with automatic dark mode support (`prefers-color-scheme: dark`). No configuration needed — it follows your system appearance.

## How it works

1. On toggle-on: pandoc converts the current buffer's file to a standalone HTML file in `/tmp`, then opens it with the system default browser (`open` on macOS, `xdg-open` on Linux, `start` on Windows).
2. A `BufWritePost` autocommand is registered on the buffer — every save rerenders the HTML file in place.
3. On toggle-off: the autocommand is removed and the temp file is deleted.

## Limitations

- The browser tab does not auto-refresh — you need to press `⌘R` / `F5` after saving.
- The preview reflects the **saved** file, not the unsaved buffer.
- Requires the file to already be saved to disk (not a new unnamed buffer).
