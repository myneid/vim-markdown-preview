if exists('g:loaded_vim_markdown') | finish | endif
let g:loaded_vim_markdown = 1

if !exists('g:vim_markdown_preview_key')
  let g:vim_markdown_preview_key = '<leader>mp'
endif

command! MarkdownPreview       call vim_markdown#start()
command! MarkdownPreviewStop   call vim_markdown#stop()
command! MarkdownPreviewToggle call vim_markdown#toggle()

augroup VimMarkdownFt
  autocmd!
  autocmd FileType markdown execute 'nnoremap <buffer> <silent> '
        \ . g:vim_markdown_preview_key
        \ . ' :MarkdownPreviewToggle<CR>'
augroup END
