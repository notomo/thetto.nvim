if exists('g:loaded_thetto')
    finish
endif
let g:loaded_thetto = 1

if get(g:, 'thetto_debug', v:false)
    command! -nargs=* Thetto lua require("thetto/cleanup")("thetto"); require("thetto/command").open(<f-args>)
    command! -nargs=* ThettoDo lua require("thetto/cleanup")("thetto"); require("thetto/command").execute(<f-args>)
else
    command! -nargs=* Thetto lua require("thetto/command").open(<f-args>)
    command! -nargs=* ThettoDo lua require("thetto/command").execute(<f-args>)
endif
