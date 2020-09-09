if exists('g:loaded_thetto')
    finish
endif
let g:loaded_thetto = 1

if get(g:, 'thetto_debug', v:false)
    command! -nargs=* -range=0 -complete=custom,thetto#complete#source Thetto lua require("thetto/lib/module").cleanup("thetto"); require("thetto/entrypoint/command").start_by_excmd(<count>, {<line1>, <line2>}, {<f-args>})
    command! -nargs=* -range=0 -complete=custom,thetto#complete#action ThettoDo lua require("thetto/lib/module").cleanup("thetto"); require("thetto/entrypoint/command").execute(<count>, {<line1>, <line2>}, {<f-args>})
    command! -nargs=* ThettoSetup lua require("thetto/lib/module").cleanup("thetto"); require("thetto/entrypoint/command").setup({<f-args>})
else
    command! -nargs=* -range=0 -complete=custom,thetto#complete#source Thetto lua require("thetto/entrypoint/command").start_by_excmd(<count>, {<line1>, <line2>}, {<f-args>})
    command! -nargs=* -range=0 -complete=custom,thetto#complete#action ThettoDo lua require("thetto/entrypoint/command").execute(<count>, {<line1>, <line2>}, {<f-args>})
    command! -nargs=* ThettoSetup lua require("thetto/entrypoint/command").setup({<f-args>})
endif
