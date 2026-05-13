let s:active   = 0
let s:html     = ''
let s:augroup  = 'VimMarkdownRefresh'

" ── public ────────────────────────────────────────────────────────────────────

function! vim_markdown#toggle() abort
  if s:active | call vim_markdown#stop() | else | call vim_markdown#start() | endif
endfunction

function! vim_markdown#start() abort
  if &filetype !=# 'markdown'
    echohl WarningMsg
    echo 'vim-markdown: filetype is "' . &filetype . '", expected "markdown"'
    echohl None
    return
  endif

  let l:pandoc = s:find_pandoc()
  if empty(l:pandoc)
    echohl ErrorMsg
    echo 'vim-markdown: pandoc not found (checked PATH and /opt/homebrew/bin)'
    echohl None
    return
  endif

  if empty(expand('%:p')) || !filereadable(expand('%:p'))
    echohl WarningMsg
    echo 'vim-markdown: save the file first'
    echohl None
    return
  endif

  let s:html = tempname() . '.html'
  let l:err  = s:render(l:pandoc)

  if !empty(l:err)
    echohl ErrorMsg | echo 'vim-markdown: ' . l:err | echohl None
    return
  endif

  call s:open_browser(s:html)

  execute 'augroup ' . s:augroup
    autocmd!
    autocmd BufWritePost <buffer> call vim_markdown#refresh()
  execute 'augroup END'

  let s:active = 1
  echo 'vim-markdown: preview open — save to refresh'
endfunction

function! vim_markdown#stop() abort
  execute 'augroup ' . s:augroup
    autocmd!
  execute 'augroup END'

  if !empty(s:html) && filereadable(s:html)
    call delete(s:html)
  endif
  let s:html   = ''
  let s:active = 0
  echo 'vim-markdown: preview stopped'
endfunction

function! vim_markdown#refresh() abort
  if !s:active | return | endif
  let l:pandoc = s:find_pandoc()
  let l:err    = s:render(l:pandoc)
  if !empty(l:err)
    echohl ErrorMsg | echo 'vim-markdown: ' . l:err | echohl None
  else
    echo 'vim-markdown: refreshed — reload browser tab'
  endif
endfunction

function! vim_markdown#debug() abort
  echo '=== vim-markdown debug ==='
  echo 'filetype   : ' . &filetype
  echo 'file       : ' . expand('%:p')
  echo 'file exists: ' . filereadable(expand('%:p'))
  echo 'active     : ' . s:active
  echo 'html path  : ' . s:html
  let l:pandoc = s:find_pandoc()
  echo 'pandoc     : ' . (empty(l:pandoc) ? 'NOT FOUND' : l:pandoc)
  echo 'shell      : ' . &shell
  echo 'PATH       : ' . $PATH
endfunction

" ── private ───────────────────────────────────────────────────────────────────

function! s:find_pandoc() abort
  if executable('pandoc')
    return 'pandoc'
  endif
  " Homebrew on Apple Silicon puts binaries in /opt/homebrew/bin
  if executable('/opt/homebrew/bin/pandoc')
    return '/opt/homebrew/bin/pandoc'
  endif
  if executable('/usr/local/bin/pandoc')
    return '/usr/local/bin/pandoc'
  endif
  return ''
endfunction

function! s:render(pandoc) abort
  let l:src   = expand('%:p')
  let l:css   = tempname() . '.css'
  let l:title = fnamemodify(l:src, ':t:r')

  call writefile(split(s:css(), "\n"), l:css)

  let l:cmd = a:pandoc
        \ . ' --standalone --embed-resources --from=gfm --to=html5'
        \ . ' --metadata title=' . shellescape(l:title)
        \ . ' --css=' . shellescape(l:css)
        \ . ' -o ' . shellescape(s:html)
        \ . ' ' . shellescape(l:src)

  let l:out = system(l:cmd)
  call delete(l:css)

  if v:shell_error != 0
    return 'pandoc failed (exit ' . v:shell_error . '): ' . l:out
  endif
  if !filereadable(s:html)
    return 'pandoc ran but did not produce output'
  endif
  return ''
endfunction

function! s:open_browser(path) abort
  if has('mac') || has('macunix')
    call system('open ' . shellescape(a:path))
  elseif has('unix')
    call system('xdg-open ' . shellescape(a:path) . ' &')
  elseif has('win32') || has('win64')
    call system('start ' . shellescape(a:path))
  endif
endfunction

function! s:css() abort
  return join([
        \ 'body{font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Helvetica,Arial,sans-serif;',
        \ '  font-size:16px;line-height:1.6;color:#24292f;background:#fff;',
        \ '  max-width:860px;margin:0 auto;padding:2rem 3rem 4rem;}',
        \ 'h1,h2,h3,h4,h5,h6{margin-top:1.5em;margin-bottom:.5em;font-weight:600;line-height:1.25;}',
        \ 'h1{font-size:2em;border-bottom:1px solid #d0d7de;padding-bottom:.3em;}',
        \ 'h2{font-size:1.5em;border-bottom:1px solid #d0d7de;padding-bottom:.3em;}',
        \ 'a{color:#0969da;text-decoration:none;}',
        \ 'a:hover{text-decoration:underline;}',
        \ 'code{font-family:ui-monospace,SFMono-Regular,Menlo,monospace;',
        \ '  font-size:.9em;background:#f6f8fa;padding:.2em .4em;border-radius:6px;}',
        \ 'pre{background:#f6f8fa;border-radius:6px;padding:1em;overflow:auto;}',
        \ 'pre code{background:none;padding:0;font-size:.9em;}',
        \ 'blockquote{margin:0;padding:0 1em;color:#57606a;border-left:4px solid #d0d7de;}',
        \ 'table{border-collapse:collapse;width:100%;margin:1em 0;}',
        \ 'th,td{border:1px solid #d0d7de;padding:.4em .8em;text-align:left;}',
        \ 'th{background:#f6f8fa;font-weight:600;}',
        \ 'tr:nth-child(even){background:#f6f8fa;}',
        \ 'img{max-width:100%;}',
        \ 'hr{border:none;border-top:1px solid #d0d7de;margin:2em 0;}',
        \ 'ul,ol{padding-left:1.5em;}',
        \ 'li+li{margin-top:.25em;}',
        \ '@media(prefers-color-scheme:dark){',
        \ '  body{color:#e6edf3;background:#0d1117;}',
        \ '  h1,h2{border-color:#30363d;}',
        \ '  code,pre{background:#161b22;}',
        \ '  blockquote{color:#8b949e;border-color:#30363d;}',
        \ '  th,td{border-color:#30363d;}',
        \ '  th,tr:nth-child(even){background:#161b22;}',
        \ '  a{color:#58a6ff;}',
        \ '  hr{border-color:#30363d;}}',
        \ ], "\n")
endfunction
