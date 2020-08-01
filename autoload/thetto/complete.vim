
function! thetto#complete#action(current_arg, line, cursor_position) abort
    if get(g:, 'thetto_debug', v:false)
        lua require("thetto/cleanup")("thetto")
    endif
    return luaeval('require("thetto/entrypoint/complete").action(unpack(_A))', a:000)
endfunction
