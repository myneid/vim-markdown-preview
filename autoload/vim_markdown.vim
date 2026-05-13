let s:plugin_root   = expand('<sfile>:p:h:h')
let s:active        = 0
let s:html          = ''
let s:preview_bufnr = -1
let s:augroup       = 'VimMarkdownRefresh'

let s:install_hints = {
      \ 'frogmouth': 'pip install frogmouth',
      \ 'glow':      'brew install glow',
      \ 'pandoc':    'brew install pandoc',
      \ 'native':    '(built-in — requires: pip install markdown-it-py)',
      \ }

" ── public ────────────────────────────────────────────────────────────────────

function! vim_markdown#toggle() abort
  if s:active | call vim_markdown#stop() | else | call vim_markdown#start() | endif
endfunction

function! vim_markdown#start() abort
  if &filetype !=# 'markdown'
    echohl WarningMsg
    echo 'vim-markdown: filetype is "' . &filetype . '", expected "markdown" — try :set ft=markdown'
    echohl None
    return
  endif
  if empty(expand('%:p')) || !filereadable(expand('%:p'))
    echohl WarningMsg | echo 'vim-markdown: save the file first' | echohl None
    return
  endif

  let l:prev = s:previewer()

  if l:prev ==# 'pandoc'
    call s:pandoc_start()
  else
    call s:terminal_start(l:prev)
  endif
endfunction

function! vim_markdown#stop() abort
  execute 'augroup ' . s:augroup
    autocmd!
  execute 'augroup END'

  if s:preview_bufnr > 0 && bufexists(s:preview_bufnr)
    execute 'bdelete! ' . s:preview_bufnr
    let s:preview_bufnr = -1
  endif
  if !empty(s:html) && filereadable(s:html)
    call delete(s:html)
    let s:html = ''
  endif
  let s:active = 0
  echo 'vim-markdown: preview stopped'
endfunction

function! vim_markdown#refresh() abort
  if !s:active | return | endif
  let l:prev = s:previewer()
  if l:prev ==# 'pandoc'
    let l:err = s:pandoc_render(s:find_binary('pandoc'))
    if !empty(l:err)
      echohl ErrorMsg | echo 'vim-markdown: ' . l:err | echohl None
    else
      echo 'vim-markdown: refreshed — reload browser tab'
    endif
  elseif l:prev ==# 'glow' || l:prev ==# 'native'
    call s:terminal_reopen(l:prev)
  endif
  " frogmouth watches the file itself — nothing to do
endfunction

function! vim_markdown#debug() abort
  let l:prev = s:previewer()
  echo '=== vim-markdown debug ==='
  echo 'previewer  : ' . l:prev
  echo 'filetype   : ' . &filetype
  echo 'file       : ' . expand('%:p')
  echo 'file exists: ' . filereadable(expand('%:p'))
  echo 'active     : ' . s:active
  let l:bin = s:find_binary(l:prev)
  echo l:prev . ' bin  : ' . (empty(l:bin) ? 'NOT FOUND' : l:bin)
  if l:prev ==# 'pandoc'
    echo 'html path  : ' . s:html
  else
    echo 'preview buf: ' . s:preview_bufnr
  endif
  if l:prev ==# 'native'
    echo 'script     : ' . s:plugin_root . '/bin/mdrender'
  endif
  echo 'PATH       : ' . $PATH
endfunction

" ── private: routing ──────────────────────────────────────────────────────────

function! s:previewer() abort
  return get(g:, 'vim_markdown_previewer', 'native')
endfunction

function! s:find_binary(name) abort
  if a:name ==# 'native'
    return s:find_native_cmd()
  endif
  if executable(a:name) | return a:name | endif
  for l:prefix in ['/opt/homebrew/bin', '/usr/local/bin', expand('~/.local/bin')]
    let l:path = l:prefix . '/' . a:name
    if executable(l:path) | return l:path | endif
  endfor
  return ''
endfunction

function! s:find_native_cmd() abort
  let l:script = s:plugin_root . '/bin/mdrender'
  if !filereadable(l:script)
    return ''
  endif
  " Find a python3 that has markdown-it-py
  for l:py in ['python3.11', 'python3.12', 'python3.10', 'python3', 'python']
    if !executable(l:py) | continue | endif
    let l:check = system(l:py . ' -c "import markdown_it" 2>/dev/null')
    if v:shell_error == 0
      return l:py
    endif
  endfor
  return ''
endfunction

" ── private: terminal previewers (frogmouth / glow) ───────────────────────────

function! s:terminal_start(prev) abort
  let l:bin = s:find_binary(a:prev)
  if empty(l:bin)
    echohl ErrorMsg
    echo 'vim-markdown: ' . a:prev . ' not found'
    let l:hint = get(s:install_hints, a:prev, '')
    if !empty(l:hint) | echo '  install with: ' . l:hint | endif
    echohl None
    return
  endif

  let l:file = expand('%:p')
  let l:cmd  = s:build_cmd(a:prev, l:bin, l:file)
  call s:open_terminal_split(l:cmd)

  " native and glow are static renders — refresh on save
  " frogmouth watches the file itself
  if a:prev ==# 'glow' || a:prev ==# 'native'
    execute 'augroup ' . s:augroup
      autocmd!
      autocmd BufWritePost <buffer> call vim_markdown#refresh()
    execute 'augroup END'
  endif

  let s:active = 1
  echo 'vim-markdown: ' . a:prev . ' preview open'
endfunction

function! s:terminal_reopen(prev) abort
  if s:preview_bufnr > 0 && bufexists(s:preview_bufnr)
    execute 'bdelete! ' . s:preview_bufnr
    let s:preview_bufnr = -1
  endif
  let l:bin  = s:find_binary(a:prev)
  let l:file = expand('%:p')
  let l:cmd  = s:build_cmd(a:prev, l:bin, l:file)
  call s:open_terminal_split(l:cmd)
endfunction

function! s:build_cmd(prev, bin, file) abort
  if a:prev ==# 'native'
    " bin is just the python executable; script path is resolved separately
    return [a:bin, s:plugin_root . '/bin/mdrender', '--no-pager', a:file]
  endif
  return [a:bin, a:file]
endfunction

function! s:open_terminal_split(cmd) abort
  vsplit
  if has('nvim')
    enew
    let s:preview_bufnr = bufnr('%')
    call termopen(a:cmd, {'on_exit': function('s:on_terminal_exit')})
    setlocal nobuflisted bufhidden=wipe
  else
    let s:preview_bufnr = term_start(a:cmd, {
          \ 'curwin':    1,
          \ 'norestore': 1,
          \ 'exit_cb':   function('s:on_terminal_exit_vim'),
          \ })
    call setbufvar(s:preview_bufnr, '&buflisted', 0)
  endif
  wincmd p
endfunction

function! s:on_terminal_exit(job_id, code, event) abort
  " Neovim callback — clean up state when the previewer exits
  let s:active        = 0
  let s:preview_bufnr = -1
endfunction

function! s:on_terminal_exit_vim(job, status) abort
  " Vim callback
  let s:active        = 0
  let s:preview_bufnr = -1
endfunction

" ── private: pandoc (browser) ─────────────────────────────────────────────────

function! s:pandoc_start() abort
  let l:bin = s:find_binary('pandoc')
  if empty(l:bin)
    echohl ErrorMsg
    echo 'vim-markdown: pandoc not found — install with: brew install pandoc'
    echohl None
    return
  endif

  let s:html = tempname() . '.html'
  let l:err  = s:pandoc_render(l:bin)
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
  echo 'vim-markdown: browser preview open — save to refresh'
endfunction

function! s:pandoc_render(bin) abort
  let l:src   = expand('%:p')
  let l:css   = tempname() . '.css'
  let l:title = fnamemodify(l:src, ':t:r')

  call writefile(split(s:css(), "\n"), l:css)

  let l:cmd = a:bin
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
    return 'pandoc ran but produced no output'
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
