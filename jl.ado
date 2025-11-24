*! jl 1.2.1 8 November 2025
*! Copyright (C) 2023-25 David Roodman

* This program is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.

* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
* GNU General Public License for more details.

* You should have received a copy of the GNU General Public Licensejl
* along with this program. If not, see <http://www.gnu.org/licenses/>.

* Version history at bottom
  
global JULIA_COMPAT_VERSION 1.11

// Take 1 argument, possible path for julia executable, return workable path, if any, in caller's libpath and libname locals; error otherwise
cap program drop wheresjulia
program define wheresjulia, rclass
  version 14.1
  tempfile stdio stderr
  tempname rc
  foreach bindir in "" `=cond(c(os)!="Windows", "~/.juliaup/bin/", "")' {
    !`bindir'juliaup -h > "`stdio'" 2> "`stderr'"
    cap mata _fget(_julia_fh = _fopen("`stderr'", "r")); st_numscalar("`rc'", fstatus(_julia_fh))  // if previous command good, then stderr empty and fget hit EOF, causing fstatus!=0
    cap mata _fclose(_julia_fh)
    if `rc' {
      return local bindir `bindir'
      return scalar success = 1
      continue, break
    }
  }
end

cap program drop assure_julia_started
program define assure_julia_started
  version 14.1

  nobreak if `"$julia_loaded"' == "" {
    tempfile stdio stderr
    tempname rc

    if c(os)=="MacOSX" & c(machine_type)=="Macintosh (Intel 64-bit)" {
      !sysctl -n sysctl.proc_translated > "`stdio'"
      cap mata st_local("rc", _fget(_julia_fh = _fopen("`stdio'", "r")))
      cap mata fclose(_julia_fh)
      _assert "`rc'"!="1", msg("Can't load Julia when running under Rosetta. Disable Rosetta for Stata, restart Stata, and reinstall the julia package with {cmd:ssc install julia, replace}.") rc(198)
    }
    
    syntax, [threads(string) channel(string)]
    if !inlist(`"`threads'"', "", "auto") {
      cap confirm integer number `threads'
      _assert !_rc & `threads'>0, msg(`"threads() option must be "auto" or a positive integer"') rc(198)
    }

    if "`channel'"=="" local channel $JULIA_COMPAT_VERSION  // only guaranteed compatible with this Julia version
    
    cap noi {
      wheresjulia      
      if !0`r(success)' {  // can't find juliaup so try to install it
        if c(os)=="Windows" {
          !winget install julia -s msstore --accept-package-agreements
        }
        else {
          !curl -fsSL https://install.julialang.org | sh -s -- -y
        }
                       
        wheresjulia
        if !0`r(success)' exit 198  // still can't run juliaup: give up
      }
      local bindir `r(bindir)'

      qui !`bindir'julia +`channel' -e '1' 2> "`stderr'"
      qui mata _fget(_julia_fh = _fopen("`stderr'", "r")); st_numscalar("`rc'", !fstatus(_julia_fh))  // if previous command good, then stderr empty and fget hit EOF, causing fstatus!=0
      cap mata _fclose(_julia_fh)
      if `rc' {
        di as txt `"Attempting to add/update `channel' channel in the local Julia installation."'
        di "This will not affect which version of Julia runs by default when you call it from outside of Stata."
        di "To learn more about the Julia version manager, type or click on {stata !juliaup --help}."
        di "This version of the {cmd:julia} Stata package is only guaranteed stable with Julia $JULIA_COMPAT_VERSION." _n
        qui !`bindir'juliaup rm `channel'  // in case channel existed and was incompletely uninstalled
        !`bindir'juliaup add `channel'  
        !`bindir'juliaup up  `channel'  
      }

      cap {
        !`bindir'julia +`channel' -e "using Libdl; println(dlpath(\"libjulia\"))" > "`stdio'"  // fails in RH Linux
        mata pathsplit(_fget(_julia_fh = _fopen("`stdio'", "r")), _juliapath="", _julialibname="")
      }
      if _rc & c(os)!="Windows" cap {
        !`bindir'julia +`channel' -e 'using Libdl; println(dlpath( "libjulia" ))' > "`stdio'"  // fails in Windows
        mata pathsplit(_fget(_julia_fh = _fopen("`stdio'", "r")), _juliapath="", _julialibname="")
      }
      cap mata _fclose(_julia_fh)
      mata st_local("libpath", _juliapath); st_local("libname", _julialibname)

      di as txt `"Starting Julia `=cond(`"`threads'"'!="", "with threads=`threads'", "")'"'
      mata displayflush() 

      plugin call _julia, start "`libpath'/`libname'" "`libpath'" `threads'
    }
    if _rc {
      di as err "Can't access Julia and Juliaup. {cmd:jl} requires that Julia be installed, along with the version manager Juliaup, and that"
      di as err `"you are able to start both by typing "julia" and "juliaup" in a terminal window (though you won't normally need to)."'
      di as err `"See the Installation section of the {help jl##installation:jl help file}."'
      exit 198
    }
 
    cap noi {
      plugin call _julia, evalqui "using Pkg"
      AddPkg DataFrames, ver(1.8.1)
      AddPkg CategoricalArrays, ver(1.0.2)
      plugin call _julia, evalqui "using DataFrames, CategoricalArrays, Dates, InteractiveUtils"

      qui findfile stataplugininterface.jl
      plugin call _julia, evalqui `"pushfirst!(LOAD_PATH, dirname(expanduser(raw"`r(fn)'")))"'
      plugin call _julia, evalqui "using stataplugininterface"
      qui findfile jl.plugin
      plugin call _julia, evalqui `"stataplugininterface.setdllpath(expanduser(raw"`r(fn)'"))"'
    }
    global julia_loaded = !_rc
  }
end

cap program drop AddPkg
program define AddPkg
  version 14.1
  syntax name, [MINversion(string) VERsion(string)]
  _assert `"`minversion'"'=="" | `"`ver'"'=="", msg("Specify version() or minversion() but not both.") rc(198) 
  plugin call _julia, eval `"Int(!("`namelist'" in keys(Pkg.project().dependencies)))"'
  local notinstalled: copy local __jlans
  if !`notinstalled' & "`minversion'"!="" plugin call _julia, eval `"length([1 for v in values(Pkg.dependencies()) if v.name=="`namelist'" && v.version<v"`minversion'"])"'
  if !`notinstalled' & "`version'"!=""    plugin call _julia, eval `"length([1 for v in values(Pkg.dependencies()) if v.name=="`namelist'" && v.version!=v"`version'"])"'
  if `notinstalled' | 0`__jlans' {
    di as txt _n "The Julia package `namelist' is not installed and up-to-date in this package environment. Attempting to update it. This could take a few minutes."
    mata displayflush() 
    local version `version' `minversion'
    cap plugin call _julia, evalqui `"Pkg.add(PackageSpec(name=String(:`namelist') `=cond("`version'"=="", "", `", version=VersionNumber(`:subinstr local version "." ",", all') "')'))"'
    if _rc {
      di as err _n "Failed to update the Julia package `namelist'."
      di as err "You should be able to install it by running Julia and typing:" _n `"{cmd:using Pkg; Pkg.update("`namelist'")}"'
      exit 198
    }
  }
end

cap program drop GetVarsFromDF
program define GetVarsFromDF
  version 14.1
  syntax [namelist] [if] [in], [source(string) replace COLs(string asis) noMISSing]
  if `"`source'"'=="" local source df
  if "`namelist'"=="" & `"`cols'"'!="" local namelist `cols'
  if `"`cols'"'=="" local cols `namelist'
    else {
      confirm names `cols'
      _assert `:word count `cols''<=cond("`varlist'"=="",c(k),`:word count `varlist''), msg("Too few destination variables specified.") rc(198) 
    }
  if "`replace'"=="" confirm new var `namelist'
  cap noi plugin call _julia, eval `"stataplugininterface.statatypes(`source', "`cols'")"'
  local __jlans = subinstr(`__jlans', "`", "'", .)
  _assert !_rc, msg(`"`__jlans'"') rc(198)

  local types `__jlans'
  local ncols: word count `cols'
  forvalues v=1/`ncols' {
    local type: word `v' of `types'
    local col : word `v' of `cols'
    local name: word `v' of `namelist'
    cap gen `type' `name' = `=cond(substr("`type'",1,3)=="str", `""""', ".")'

    cap noi plugin call _julia, eval "Int(`source'.`col' isa CategoricalVector)"
    local __jlans = subinstr("`__jlans'", "`", "'", .)
    _assert !_rc, msg(`"`__jlans'"') rc(198)
    if `__jlans' {
      cap noi plugin call _julia, evalqui `"st_local("labeldef", join([string(i) * " %" * l * "% " for (i,l) in enumerate(levels(`source'.`col'))], " "))"'
      local __jlans = subinstr("`__jlans'", "`", "'", .)
      _assert !_rc, msg(`"`__jlans'"') rc(198)
      label define `name' `=subinstr(`"`labeldef'"', "%", `"""', .)', replace
      label values `name' `name'
    }
  }
  cap noi plugin call _julia `namelist' `if' `in', GetVarsFromDF`missing' `"`source'"' _cols `:strlen local cols' `ncols'
  local __jlans = subinstr("`__jlans'", "`", "'", .)
  _assert !_rc, msg(`"`__jlans'"') rc(198)
  
  forvalues v=1/`ncols' {
    local col : word `v' of `cols'
    local name: word `v' of `namelist'
    cap noi plugin call _julia, eval "Int(`source'.`col' |> eltype |> nonmissingtype <: Date)"
    local __jlans = subinstr("`__jlans'", "`", "'", .)
    _assert !_rc, msg(`"`__jlans'"') rc(198)
    if `__jlans' format %td `name'
    cap noi plugin call _julia, eval "Int(`source'.`col' |> eltype |> nonmissingtype <: DateTime)"
    local __jlans = subinstr("`__jlans'", "`", "'", .)
    _assert !_rc, msg(`"`__jlans'"') rc(198)
    if `__jlans' format %tc `name'  // NOT %tC
  }
end

cap program drop PutVarsToDF
program define PutVarsToDF
  version 14.1
  syntax [varlist] [if] [in], [DESTination(string) COLs(string) DOUBLEonly noMISSing noLABel]
  if `"`destination'"'=="" local destination df
  local ncols = cond("`varlist'"=="", c(k), `:word count `varlist'')
  if `"`cols'"'=="" unab cols: `varlist'
  else {
    confirm names `cols'
    _assert `:word count `cols''!=`ncols', msg("Source and destination variable lists different lengths.") rc(198) 
  }
  if "`doubleonly'"=="" {
    foreach col in `cols' {
      local type: type `col'
      local types `types' `=cond(substr("`type'",1,3)=="str", "str", "`type'")'
    }
  }
  else local types = "double " * `ncols'
  if "`doubleonly'"=="" local dfcmd `destination' = DataFrame([n=>Vector{stataplugininterface.S2Jtypedict[t]}(undef,%i) for (n,t) in zip(eachsplit("`cols'"), eachsplit("`types'"))])

  plugin call _julia `varlist' `if' `in', PutVarsToDF`missing' `"`destination'"' `"`dfcmd'"' `"`if'`in'"'

  if "`missing'"=="" plugin call _julia, evalqui `"stataplugininterface.NaN2missing(`destination')"'
  if "`doubleonly'"!="" plugin call _julia, evalqui `"rename!(`destination', vec(split("`cols'")))"'
  else if "`label'"=="" {
    foreach col in `cols' {
      local labname: value label `col'
      if "`labname'" != "" {
        local recodecmd
        qui levels `col'
        foreach l in `r(levels)' {
          local lab: label(`col') `l'
          if "`lab'"!="" {
            local recodecmd `recodecmd', `l'=>raw"`lab'"
          }
        }
        cap noi plugin call _julia, evalqui `"`destination'.`col' = CategoricalVector(recode(`destination'.`col' `recodecmd'))"'
      }
    }      
  }
    
//   foreach char in `:char _dta[]' {
//     plugin call _julia, evalqui `"metadata!(`destination', `char', """`:char _dta[`char']'""", style=:note)"'
//   }
//   foreach var in `cols' {
//     foreach char in `:char `var'[]' {
//       plugin call _julia, evalqui `"colmetadata!(`destination', `var', `char', """`:char `var'[`char']'""", style=:note)"'
//     }
//   }
end

cap program drop jl
program define jl, rclass
  version 14.1

  if `"`0'"'=="version" {
    return local version 1.2.1
    exit
  }

  cap _on_colon_parse `0'

  if _rc & `"`0'"'!="" {
    tokenize `"`0'"', parse(" ,")
    local cmd `1'
    macro shift
    local 0 `*'

    if `"`cmd'"'=="stop" {
      if 0$julia_loaded {
        plugin call _julia, stop
        global julia_loaded
      }
      exit
    }

    if `"`cmd'"'=="start" {
      if 0$julia_loaded exit
      syntax, [Threads(passthru) CHANnel(passthru)]
      assure_julia_started, `threads' `channel'
      exit
    }

    assure_julia_started

    if inlist(`"`cmd'"',"SetEnv","GetEnv") {
      qui if "`cmd'"=="SetEnv" {
        local 1: subinstr local 1 "@" ""
        if `"`1'"'=="" plugin call _julia, evalqui "Pkg.activate()"  // return to default environment
                  else plugin call _julia, evalqui `"Pkg.activate("`1'", shared=true)"'  // named, shared environment
//         plugin call _julia, evalqui `"Pkg.activate(joinpath(dirname(Base.load_path_expand("@v#.#")), "`1'"))"'  // move to an environment specific to this package
        AddPkg DataFrames, ver(1.8.1)
        AddPkg CategoricalArrays, ver(1.0.2)
      }
      plugin call _julia, eval `"dirname(Base.active_project())"'
      local __jlans `__jlans'  // strip quotes
      local envdir: subinstr local __jlans "\\" "\", all
      plugin call _julia, eval `"dirname(Base.load_path_expand("@v#.#"))"'
      local __jlans: subinstr local __jlans "\\" "\", all
      if "`envdir'" == `__jlans' return local env @v$JULIA_COMPAT_VERSION
      else {
        plugin call _julia, eval `"splitpath(Base.active_project())[end-1]"'
        return local env `__jlans'  // strip quotes
      }
      di as txt `"Current environment: `=cond("`return(env)'"==".","(default)","`return(env)'")', at `return(envdir)'"' _n
      jlcmd: Pkg.status()
    }
    else if `"`cmd'"'=="AddPkg" AddPkg `0'
    else if `"`cmd'"'=="use" {
      syntax namelist [using/], [clear]
      if c(changed) & "`clear'"=="" error 4
      drop _all
      if `"`using'"'=="" {
        _assert `:word count `namelist''==1, msg("Just specify one source DataFrame.") rc(198) 
        local source `namelist'
        plugin call _julia, eval `"join(names(`source'), " ")"'
        local cols `__jlans'
      }
      else {
        local source `using'
        local cols `namelist'
      }
      plugin call _julia, eval "size(`source',1)"
      qui set obs `__jlans'
      GetVarsFromDF `cols', source(`source') 
    }
    else if `"`cmd'"'=="PutVarsToDF" {
      PutVarsToDF `0'
    }
    else if `"`cmd'"'=="save" {
      syntax [namelist(max=1)], [NOLABel DOUBLEonly NOMISSing]
      if "`namelist'"=="" local namelist df
      PutVarsToDF, dest(`namelist') `nolabel' `doubleonly' `nomissing'
      di as txt "Data saved to DataFrame `namelist' in Julia"
    }
    else if `"`cmd'"'=="PutVarsToMat" {
      syntax [varlist] [if] [in], DESTination(string) [noMISSing]
      plugin call _julia `varlist' `if' `in', `cmd'`missing' `"`destination'"' `"`if'`in'"'
    }
    else if `"`cmd'"'=="GetVarsFromMat" {
      syntax namelist [if] [in], source(string asis) [replace]
      if "`replace'"=="" confirm new var `namelist'
      foreach var in `namelist' {
        cap gen double `var' = .
      }
      plugin call _julia `namelist' `if' `in', GetVarsFromMat `"`source'"' `"`if'`in'"'
    }
    else if `"`cmd'"'=="GetVarsFromDF" {
      GetVarsFromDF `0'
    }
    else if `"`cmd'"'=="GetMatFromMat" {
       syntax name, [source(string asis)]

       if `"`source'"'=="" local source `namelist'
       plugin call _julia, eval `"size(`source',1)"'
       local rows: copy local __jlans
       plugin call _julia, eval `"size(`source',2)"'
       _assert `rows' & `__jlans', rc(198) msg("cannot get matrix with height or width 0")
       mat `namelist' = J(`rows', `__jlans', .)
       plugin call _julia, GetMatFromMat `namelist' `"`source'"'
    }
    else if `"`cmd'"'=="PutMatToMat" {
      syntax name, [DESTination(string)]
      if `"`destination'"'=="" local destination `namelist'
      plugin call _julia, PutMatToMat `namelist' `destination'
    }
    else {
      di as err `"`cmd' is not a valid subcommand. Did you forget the ":" after "jl"?"'
      exit 198
    }
  }
  else {  // "jl: ..."
    local after = `"`s(after)'"'
    local before `"`s(before)'"'

    assure_julia_started

    if `"`after'"' != "" {
      _assert strlen(`"`after'"')<4991, rc(1003) msg("jl command line longer than 4990 characters")
      jlcmd `before': `after'
      foreach macro in `locals' {
        c_local `macro': copy local `macro'
      }
    }
    else {
      display as txt "{hline 48} Julia (type {cmd:exit()} to exit) {hline}"
      while 1 {
        di as res "jl> " _request(_cmdline)
        local cmdline = strtrim(`"`cmdline'"')
        if `"`cmdline'"'=="" continue
        if `"`cmdline'"'=="exit()" {
          di as txt "{hline}"
          continue, break
        }
        plugin call _julia, reset  // clear any previous command lines
        cap noi jlcmd `before':`cmdline'
        if 0`r(exit)' continue, break
        foreach macro in `locals' {
          c_local `macro': copy local `macro'
        }
      }
    }
  }
  return local ans: copy local ans
end

cap program drop jlcmd
program define jlcmd, rclass
  version 14.1
  cap _on_colon_parse `0'
  local __jlcmd  = trim(`"`s(after)'"')
  local 0 `"`s(before)'"'
  syntax, [QUIetly INTERruptible noREPL]
  local varlist = cond(c(k),"*","")
  local noisily = "`quietly'"=="" & substr(`"`__jlcmd'"', strlen(`"`__jlcmd'"'), 1) != ";"  // also suppress output if command ends with ";"
  if substr(`"`__jlcmd'"',1,1)=="?" {
    if `"`__jlcmd'"'=="?" {
      di as err "Julia help mode not supported. But you can prefix single commands with "?". Example: ?sum."
      exit
    }
    local __jlcmd = "@doc "+ substr(`"`__jlcmd'"',2,.)
  }
  local multiline = cond("`repl'"=="","multiline","")
  
  local __jlcomplete 0
  while !`__jlcomplete' {
    local __jlcomplete 1

    if "`interruptible'" != "" {  // Run Julia 1 sec at a time to allow Ctrl-Break, checking if task finished every .01 sec
      plugin   call _julia `varlist', evalqui `"stataplugininterface.julia_task = @async (`__jlcmd')"'
      local __jlans 1
      while `__jlans' {
        cap noi plugin call _julia, eval `"stataplugininterface.julia_time=time()+1; for _ in 1:100 (istaskdone(stataplugininterface.julia_task) || time()>stataplugininterface.julia_time) && break; sleep(.01) end; Int(!istaskdone(stataplugininterface.julia_task))"'
        if _rc continue, break
      }
      if `noisily' cap noi plugin call _julia, eval fetch(stataplugininterface.julia_task)
      if _rc continue, break
    }
    else cap noi plugin call _julia `varlist', eval`multiline'`=cond(`noisily',"","qui")' `"`__jlcmd'"'

    if _rc | "`multiline'"=="" {
      plugin call _julia, reset  // clear any previous command lines
      continue, break
    }

    if !`__jlcomplete' di as txt "  .." _request(___jlcmd)  // (plugin overwrites `__jlcomplete')
    if strtrim(`"`__jlcmd'"')=="exit()" {
      return local exit 1
      exit
    }
  }

  if `noisily' | _rc {
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
  
  c_local locals: copy local __jllocals
  foreach macro in `__jllocals' {
    c_local `macro': copy local `macro'
  }
end

cap program drop _julia
program _julia, plugin using(jl.plugin)


* Version history
* 0.5.0  Initial commit
* 0.5.1  Fixed memory leak in C code. Added documentation. Bug fixes.
* 0.5.4  Bug and documentation fixes.
* 0.5.5  Tweaks
* 0.5.6  File reorganization
* 0.6.0  Implemented dynamic runtime loading of libjulia for robustness to Julia installation type
* 0.6.2  Fixed 0.6.0 crashes in Windows
* 0.7.0  Dropped UpPkg and added minver() option to AddPkg
* 0.7.1  Try single as well as double quotes in !julia. Further attack on Windows crashes on errors.
* 0.7.2  Better handling of exceptions in Julia 
* 0.7.3  Fixed bug in PutMatToMat
* 0.8.0  Added SetEnv command
* 0.8.1  Recompiled in Ubuntu 20.04; fixed Unix AddPkg bug
* 0.9.0  Added interruptible option and multithreaded variable copying
* 0.9.1  Reverted to complex syntax for C++ variable copying routines, to avoid limit on # of vars
* 0.10.0 Full support for Stata data types, including strings. Map CategoricalVector's to data labels. Add use and save commands.
* 0.10.1 Fixed memory leak
* 0.10.2 threads() option on start
* 0.10.3 Bug fix for 0.10.2
* 1.0.0 Add GetEnv, support for closing ";", and interactive mode
* 1.0.1 Drop confirm names on Julia source and destination matrices so they can be views or other things
* 1.0.2 Fix crashes on really long included regressor lists; add status call to GetEnv & SetEnv; bug fixes
* 1.1.0 Fix bug in GetVarsFromDF, nomissing. Now requires Julia >=1.11.
* 1.1.1 Fixed crash in 1.1.0 in Mac ARM
* 1.1.2 Switch to using a dedicated 1.11 Juliaup channel; automatically install Julia
* 1.1.3 Bug fixes. Make GetVarsFromDF varlist default to cols() option.
* 1.1.4 Make sure to close all temp files opened in Mata, which otherwise can crash other programs
* 1.1.5 Add date/datetime support to -jl use-
* 1.1.6 Fix 1.1.5 crash
* 1.1.7 Automatically load InteractiveUtils
* 1.1.8 Error if running under Rosetta
* 1.1.9 Fix st_data() crash in macOS.Made st_data() and st_view() accept varname for sample marker
* 1.1.10 Strip backticks from returned errors messages to prevent "unmatched quote" error.
* 1.2.0  Add version() option to AddPkg to give complete control of installed version.
