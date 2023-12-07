*! jl 0.7.0 7 December 2023
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

// Take 1 argument, possible path for julia executable, return workable path, if any, in caller's libpath and libname locals; error otherwise
cap program drop wheresjulia
program define wheresjulia, rclass
  tempfile tempfile
  !`1'julia -e "using Libdl; println(dlpath(\"libjulia\"))" > `tempfile'
  mata pathsplit(fget(fh = fopen("`tempfile'", "r")), _juliapath="", _julialibname=""); _fclose(fh)
  mata st_local("libpath", _juliapath); st_local("libname", _julialibname)
  c_local libpath `libpath'
  c_local libname `libname'
end

cap program drop assure_julia_started
program define assure_julia_started
  version 14.1

  if `"$julia_loaded"' == "" {
    cap {
      cap wheresjulia
      cap if _rc & c(os)!="Windows" wheresjulia ~/.juliaup/bin/
      cap if _rc & c(os)=="MacOSX" {
        forvalues v=9/20 {  // https://github.com/JuliaLang/juliaup/issues/758#issuecomment-1836577702
          cap wheresjulia /Applications/Julia-1.`v'.app/Contents/Resources/julia/bin/
          if !_rc continue, break
        }
      }
      if _rc error _rc
      plugin call _julia, start "`libpath'/`libname'" "`libpath'"
    }
    if _rc {
      di as err "Can't access Julia. {cmd:jl} requires that Julia be installed and that you are"
      di as err `"able to start it by typing "julia" in a terminal window (though you won't normally need to)."'
      di as err `"Installation via {browse "https://github.com/JuliaLang/juliaup#installation":juliaup} is recommended."'
      exit 198
    }
    global julia_loaded 1  // set now to prevent infinite loop from following jl calls!

    qui jl: Int(VERSION < v"1.9.4")
    if `r(ans)' {
      di as err _n "jl requires that Julia 1.9.4 or higher be installed and accessible by default."
      di as err "See the Installation section of the {help jl##installation:jl help file}."
      global julia_loaded
      exit 198
    }

    qui findfile stataplugininterface.jl
    cap noi {
      jl, qui: pushfirst!(LOAD_PATH, dirname(expanduser(raw"`r(fn)'")))
      jl, qui: using stataplugininterface
      qui findfile jl.plugin
      jl, qui: stataplugininterface.setdllpath(expanduser(raw"`r(fn)'"))

      jl AddPkg DataFrames
      jl, qui: using DataFrames
    }
    if _rc global julia_loaded
  }
end

cap program drop jl
program define jl, rclass
  version 14.1

  cap _on_colon_parse `0'
  if _rc {
    if `"`1'"'=="stop" {
      if 0$julia_loaded {
        plugin call _julia, stop
        global julia_loaded
      }
      exit
    }
    
    assure_julia_started
    
    local cmd `1'
    tokenize `"`0'"', parse(" ,")
    macro shift
    local 0 `*'
    
    if `"`cmd'"'=="AddPkg" {
      syntax name, [MINver(string)]
      jl, qui: using Pkg
      qui jl: Int("`namelist'" in keys(Pkg.project().dependencies))
      if `r(ans)' {
        if `"`minver'"'!="" {
          qui jl: length([1 for v in values(Pkg.dependencies()) if v.name=="`namelist'" && v"`minver'">v.version])
          if `r(ans)' {
            di as txt "The Julia package `namelist' is not up to date. Attempting to update it. This could take a few minutes." _n 
            mata displayflush() 
            cap {
              if c(os)=="Unix" {
                !julia -E"using Pkg; Pkg.update(\"`namelist'\")"
              }
              else jl, qui: Pkg.update("`namelist'")  // this crashes Stata in Ubuntu 22.04
            }
            if _rc {
              di as err _n "Failed to update the Julia package `namelist'."
              di as err "You should be able to install it by running Julia and typing:" _n as cmd `"using Pkg; Pkg.update("`namelist'")"'
              exit 198
            }
          }
        }
      }
      else {
        di as txt "The Julia package `namelist' is not installed. Attempting to install it. This could take a few minutes." _n 
        mata displayflush() 
        cap {
          if c(os)=="Unix" {
            !julia -E"using Pkg; Pkg.add(\"`namelist'\")"
          }
          else jl, qui: Pkg.add("`namelist'")  // this crashes Stata in Ubuntu 22.04
        }
        if _rc {
          di as err _n "Failed to install the Julia package `namelist'."
          di as err "You should be able to install it by running Julia and typing:" _n as cmd `"using Pkg; Pkg.add("`namelist'")"'
          exit 198
        }
      }
    }
    else if inlist(`"`cmd'"', "PutVarsToDF", "PutVarsToDFNoMissing") {
      syntax [varlist] [if] [in], [DESTination(string) COLs(string)]
      if `"`destination'"'=="" local destination df
        else confirm names `destination'
      if `"`cols'"'=="" local cols `varlist'
      else {
        confirm names `cols'
        _assert `:word count `cols''>=cond("`varlist'"=="",c(k),`:word count `varlist''), msg("Too few destination columns specified.") rc(198) 
      }
      plugin call _julia `varlist' `if' `in', PutVarsToDFNoMissing `"`destination'"' _cols `:strlen local cols'
      if "`cmd'"=="PutVarsToDF" {
        jl, qui: allowmissing!(`destination')
        jl, qui: replace!.(x -> x >= reinterpret(Float64, 0x7fe0000000000000) ? missing : x, eachcol(`destination'))
      }
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
      syntax namelist [if] [in], [source(string) replace COLs(string asis)]
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
      if "`cmd'"=="GetVarsFromDF" jl, qui: replace!.(eachcol(`source'), missing=>NaN)
      plugin call _julia `namelist' `if' `in', `cmd' `"`source'"' _cols `:strlen local cols'
    }
    else if `"`cmd'"'=="GetMatFromMat" {
      syntax name, [source(string asis)]
      if `"`source'"'=="" local source `namelist'
      qui jl: size(`source', 1)
      local rows `r(ans)'
      qui jl: size(`source', 2)
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
  else {  // "jl: ..."
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
program _julia, plugin using(jl.plugin)


* Version history
* 0.5.0 Initial commit
* 0.5.1 Fixed memory leak in C code. Added documentation. Bug fixes.
* 0.5.4 Bug and documentation fixes.
* 0.5.5 Tweaks
* 0.5.6 File reorganization
* 0.6.0 Implemented dynamic runtime loading of libjulia for robustness to Julia installation type
* 0.6.2 Fixed 0.6.0 crashes in Windows
* 0.7.0 Dropped UpPkg and added minver() option to AddPkg