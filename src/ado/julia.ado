*! boottest 0.5.1 19 November 2023
*! Copyright (C) 2023 David Roodman

* This program is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.

* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
* GNU General Public License for more details.

* You should have received a copy of the GNU General Public License
* along with this program. If not, see <http://www.gnu.org/licenses/>.

*! Version history at bottom


* properly print a string with newlines
cap program drop display_multiline
program define display_multiline
  version 14.1
  tempname t
  local s `0'
  scalar `t' = strpos(`"`s'"', char(10))
  while `t' {
    di substr(`"`s'"', 1, `t'-1)
    local s = substr(`"`s'"', `t'+1, .)
    scalar `t' = strpos(`"`s'"', char(10))
  }
  di `"`s'"'
end

cap program drop assure_julia_started
program define assure_julia_started
  version 14.1

  if `"$julia_loaded"' == "" {
    cap findfile stataplugininterface.jl
    if _rc {
      di as err "Installation problem: can't find stataplugininterface.jl, which is part of the julia.ado Stata package."
      exit 198
    }
    plugin call _julia, start
    global julia_loaded 1  // put here to prevent infinite loop!
    cap noi {
      julia, qui: pushfirst!(LOAD_PATH, dirname(expanduser(raw"`r(fn)'")))
      julia, qui: using stataplugininterface
      cap findfile julia.plugin
      if _rc {
        di as err "Installation problem: can't find julia.plugin, which is part of the julia.ado Stata package."
        exit 198
      }
      julia, qui: stataplugininterface.setdllpath(expanduser(raw"`r(fn)'"))

      julia AddPkg DataFrames
      julia, qui: using DataFrames
    }
    if _rc global julia_loaded
  }
end

cap program drop julia
program define julia, rclass
  version 14.1

  cap _on_colon_parse `0'
  if _rc {
    if `"`1'"'=="stop" {
      plugin call _julia, stop
      global julia_loaded
      exit
    }
    
    assure_julia_started
    
    local cmd `1'
    tokenize `"`0'"', parse(" ,")
    macro shift
    local 0 `*'
    
    if `"`cmd'"'=="AddPkg" {
      syntax namelist
      if c(os)=="Unix" cap !julia -E"using Pkg; Pkg.add(\"`pkg'\")"
      else {
        julia, qui: using Pkg; vals = values(Pkg.dependencies())
        foreach pkg in `namelist' {
          qui julia: mapreduce(v->v.name=="`pkg'", +, vals)
          if !`r(ans)' {
            di _n "The Julia package `pkg' is not installed. " _c
            di "Attempting to install it. This could take a few minutes."
            mata displayflush() 
            cap julia, qui: Pkg.add("`pkg'")  // this is crashing Stata in Ubuntu 22.04
            if _rc local failed `failed' `pkg'
          }
        }
      }
      if "`failed'"!="" {
        di as err _n "Failed to automatically install the Julia " plural("package", `:word count `failed'') as cmd "`failed'"
        di as err `"You should be able to install each missing package by running Julia and typing: _n as cmd "using Pkg"
        foreach pkg in `failed' {
          di `"Pkg.add("`pkg'")"'
        }
        di _n
        exit 198
      }
    }
    else if `"`cmd'"'=="UpPkg" {
      syntax namelist
      if c(os)=="Unix" cap !julia -E"using Pkg; Pkg.update(\"`pkg'\")"
      else {
        julia, qui: using Pkg; vals = values(Pkg.dependencies())
        foreach pkg in `namelist' {
          qui julia: mapreduce(v->v.name=="`pkg'", +, vals)
          if !`r(ans)' {
            di _n "The Julia package `pkg' is not installed." _c
            di "Attempting to install instead of update it. This could take a few minutes."
            mata displayflush() 
            cap julia, qui: Pkg.add("`pkg'")
            if _rc local failed `failed' `pkg'
          }
        }
      }
      if "`failed'"!="" {
        di as err _n "Failed to automatically update the Julia " plural("package", `:word count `failed'') as cmd "`failed'"
        di as err `"You should be able to update each missing package by running Julia and typing:" _n as cmd "using Pkg"
        foreach pkg in `failed' {
          di `"Pkg.add("`pkg'")"'
        }
        di _n
        exit 198
      }
    }
    else if inlist(`"`cmd'"', "PutVarsToDF", "PutVarsToDFNoMissing") {
      syntax [varlist] [if] [in], [DESTination(string) cols(string)]
      if `"`destination'"'=="" local destination df
        else confirm names `destination'
      if `"`cols'"'=="" local cols `varlist'
      else {
        confirm names `cols'
        _assert `:word count `cols''>=cond("`varlist'"=="",c(k),`:word count `varlist''), msg("Too few destination columns specified.") rc(198) 
      }
      plugin call _julia `varlist' `if' `in', `cmd' `"`destination'"' _cols `:strlen local cols'
    }
    else if inlist(`"`cmd'"', "PutVarsToMat", "PutVarsToMatNoMissing") {
      syntax [varlist] [if] [in], DESTination(string)
      confirm names `destination'
      plugin call _julia `varlist' `if' `in', `cmd' `"`destination'"'
    }
    else if `"`cmd'"'=="GetVarsFromMat" {
      syntax namelist [if] [in], source(string asis) [replace]
      confirm names `source'
      if "`replace'"=="" confirm new var `namelist'
      foreach var in `namelist' {
        cap gen double `var' = .
      }
      plugin call _julia `namelist' `if' `in', GetVarsFromMat `"`source'"'
    }
    else if inlist(`"`cmd'"', "GetVarsFromDF", "GetVarsFromDFNoMissing") {
      syntax namelist [if] [in], [source(string) replace cols(string asis)]
      if `"`source'"'=="" local source df
      if `"`cols'"'=="" local cols `namelist'
      else {
        confirm names `cols'
        _assert `:word count `cols''<=cond("`varlist'"=="",c(k),`:word count `varlist''), msg("Too few destination variables specified.") rc(198) 
      }
      if "`replace'"=="" confirm new var `namelist'
      foreach var in `namelist' {
        cap gen double `var' = .
      }
      plugin call _julia `namelist' `if' `in', `cmd' `"`source'"' _cols `:strlen local cols'
    }
    else if `"`cmd'"'=="GetMatFromMat" {
      syntax name, [source(string asis)]
      if `"`source'"'=="" local source `namelist'
      qui julia: size(`source', 1)
      local rows `r(ans)'
      qui julia: size(`source', 2)
      mat `namelist' = J(`rows', `r(ans)', .)
      plugin call _julia, GetMatFromMat `namelist' `"`source'"'
    }
    else if `"`cmd'"'=="PutMatToMat" {
      syntax name, [DESTination(string)]
      if `"`destination'"'=="" local destination `namelist'
      plugin call _julia, PutMatToMat `namelist' `destination'
    }
    else {
      di as err `"`cmd' is not a valid subcommand."'
      exit 198
    }
  }
  else {  // "julia: ..."
    local before = `"`s(before)'"'
    local after = `"`s(after)'"'
    
    assure_julia_started

    local 0 `before'
    syntax, [QUIetly]
    if "`quietly'"!="" plugin call _julia `=cond(c(k),"*","")', evalqui `"`after'"'
    else {
      plugin call _julia `=cond(c(k),"*","")', eval `"`after'"'
      return local ans `ans'
      local ans `ans'  // strips quote marks
      if `"`ans'"' != "nothing" display_multiline `ans'
    }
  }
  return local ans `ans'
end

cap program drop _julia
program _julia, plugin using(julia.plugin)


* Version history
* 0.5.0 Initial commit
* 0.5.1 Fixed memory leak in C code. Added documentation. Bug fixes.