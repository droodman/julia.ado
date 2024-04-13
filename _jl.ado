*! jl 1.0.0 9 April 2024
cap program drop _jl
program define _jl, rclass
  _on_colon_parse `0'
  local qui = cond(substr(`"`s(after)'"', strlen(`"`s(after)'"'), 1) == ";", "qui", "")
  cap noi plugin call _julia `=cond(c(k),"*","")', eval`qui' `"`s(after)'"'
  
  if _rc {
    local rc = _rc
    local __jlans: subinstr local __jlans "`" "'", all
    c_local ans: copy local __jlans
    cap noi if `"`__jlans'"' != "nothing" {
      if `rc' {  // print error type in red
        local t = strpos(`"`__jlans'"', ":")
        di as err substr(`"`__jlans'"', 1, `t') _c
        local __jlans = substr(`"`__jlans'"', `t'+1, .)
      }
      local t = strpos(`"`__jlans'"', char(10))
      while `t' {
        di as txt substr(`"`__jlans'"', 1, `t'-1)
        local __jlans = substr(`"`__jlans'"', `t'+1, .)
        local t = strpos(`"`__jlans'"', char(10))
      }
      di as txt `"`__jlans'"'
    }
  }
  return local ans: copy local __jlans  
end

program _julia, plugin using(jl.plugin)
