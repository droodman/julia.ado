*! jl 1.0.0 9 April 2024
cap program drop _jl
program define _jl, rclass
  _on_colon_parse `0'
  local qui = cond(substr(`"`s(after)'"', strlen(`"`s(after)'"'), 1) == ";", "qui", "")
  plugin call _julia `=cond(c(k),"*","")', eval`qui' `"`s(after)'"'
  foreach macro in `__jllocals' {
    c_local `macro': copy local `macro'
  }
  return local ans: copy local __jlans  
end

program _julia, plugin using(jl.plugin)