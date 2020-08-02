if exists('g:loaded_thetto')
    finish
endif
let g:loaded_thetto = 1

if get(g:, 'thetto_debug', v:false)
    command! -nargs=* Thetto lua require("thetto/lib/module").cleanup("thetto"); require("thetto/entrypoint/command").open(<f-args>)
    command! -nargs=* -complete=custom,thetto#complete#action ThettoDo lua require("thetto/lib/module").cleanup("thetto"); require("thetto/entrypoint/command").execute(<f-args>)
else
    command! -nargs=* Thetto lua require("thetto/entrypoint/command").open(<f-args>)
    command! -nargs=* -complete=custom,thetto#complete#action ThettoDo lua require("thetto/entrypoint/command").execute(<f-args>)
endif

highlight default link ThettoSelected Statement
highlight default link ThettoInfo StatusLine
highlight default link ThettoColorLabelOthers StatusLine
highlight default link ThettoColorLabelBackground NormalFloat
