*! jl 1.0.0 12 April 2024
*! Copyright (C) 2023-24 David Roodman

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


// Take 1 argument, possible path for julia executable, return workable path, if any, in caller's libpath and libname locals; error otherwise
cap program drop wheresjulia
program define wheresjulia, rclass
  version 14.1
  tempfile tempfile
  cap {
    cap mata _fclose(fh)
    !`1'julia -e "using Libdl; println(dlpath(\"libjulia\"))" > `tempfile'  // fails in RH Linux
    mata pathsplit(_fget(fh = _fopen("`tempfile'", "r")), _juliapath="", _julialibname="")
  }
  if _rc cap {
    !`1'julia -e 'using Libdl; println(dlpath( "libjulia" ))' > `tempfile'  // fails in Windows
    mata pathsplit(_fget(fh = _fopen("`tempfile'", "r")), _juliapath="", _julialibname="")
  }
  local rc = _rc
  cap mata _fclose(fh)
  error `rc'
  mata st_local("libpath", _juliapath); st_local("libname", _julialibname)
  c_local libpath `libpath'
  c_local libname `libname'
end

cap program drop assure_julia_started
program define assure_julia_started
  version 14.1

  if `"$julia_loaded"' == "" {
    syntax, [threads(string)]
    if !inlist(`"`threads'"', "", "auto") {
      cap confirm integer number `threads'
      _assert !_rc & `threads'>0, msg(`"threads() option must be "auto" or a positive integer"') rc(198)
    }

    cap noi {
      cap wheresjulia
      cap if _rc & c(os)!="Windows" wheresjulia ~/.juliaup/bin/
      cap if _rc & c(os)=="MacOSX" {
        forvalues v=9/20 {  // https://github.com/JuliaLang/juliaup/issues/758#issuecomment-1836577702
          cap wheresjulia /Applications/Julia-1.`v'.app/Contents/Resources/julia/bin/
          if !_rc continue, break
        }
      }
      error _rc

      di as txt `"Starting Julia `=cond(`"`threads'"'!="", "with threads=`threads'", "")'"'
      mata displayflush() 

      plugin call _julia, start "`libpath'/`libname'" "`libpath'" `threads'
    }
    if _rc {
      di as err "Can't access Julia. {cmd:jl} requires that Julia be installed and that you are"
      di as err `"able to start it by typing "julia" in a terminal window (though you won't normally need to)."'
      di as err `"Installation via {browse "https://github.com/JuliaLang/juliaup#installation":juliaup} is recommended."'
      exit 198
    }
 
    plugin call _julia, eval `"Int(VERSION < v"1.9.4")"'
    if `__jlans' {
      di as err _n "jl requires that Julia 1.9.4 or higher be installed and accessible by default."
      di as err "See the Installation section of the {help jl##installation:jl help file}."
      global julia_loaded
      exit 198
    }

    cap noi {
      plugin call _julia, evalqui "using Pkg"
      AddPkg DataFrames, minver(1.6.1)
      AddPkg CategoricalArrays, minver(0.10.8)
      plugin call _julia, evalqui "using DataFrames, CategoricalArrays"

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
  syntax name, [MINver(string)]
  plugin call _julia, eval `"Int(!("`namelist'" in keys(Pkg.project().dependencies)))"'
  local notinstalled: copy local __jlans
  if !`notinstalled' & "`minver'"!="" plugin call _julia, eval `"length([1 for v in values(Pkg.dependencies()) if v.name=="`namelist'" && v.version<v"`minver'"])"'
  if `notinstalled' | 0`__jlans' {
    di as txt "The Julia package `namelist' is not installed and up-to-date in this package environment. Attempting to update it. This could take a few minutes." _n 
    mata displayflush() 
    cap plugin call _julia, evalqui `"Pkg.add(PackageSpec(name=String(:`namelist') `=cond("`minver'"=="", "", `", version=VersionNumber(`:subinstr local minver "." ",", all') "')'))"'
    if _rc {
      di as err _n "Failed to update the Julia package `namelist'."
      di as err "You should be able to install it by running Julia and typing:" _n `"{cmd:using Pkg; Pkg.update("`namelist'")}"'
      exit 198
    }
  }
end

cap program drop GetVarsFromDF
program define GetVarsFromDF
  syntax namelist [if] [in], [source(string) replace COLs(string asis) noMISSing]
  if `"`source'"'=="" local source df
  if `"`cols'"'=="" local cols `namelist'
    else {
      confirm names `cols'
      _assert `:word count `cols''<=cond("`varlist'"=="",c(k),`:word count `varlist''), msg("Too few destination variables specified.") rc(198) 
    }
  if "`replace'"=="" confirm new var `namelist'
  plugin call _julia, eval `"stataplugininterface.statatypes(`source', "`cols'")"'
  local types `__jlans'
  local ncols: word count `cols'
  forvalues v=1/`ncols' {
    local type: word `v' of `types'
    local col : word `v' of `cols'
    local name: word `v' of `namelist'
    cap gen `type' `name' = `=cond(substr("`type'",1,3)=="str", `""""', ".")'
    plugin call _julia, eval "Int(`source'.`col' isa CategoricalVector)"
    if `__jlans' {
      plugin call _julia, evalqui `"st_local("labeldef", join([string(i) * " %" * l * "% " for (i,l) in enumerate(levels(`source'.`col'))], " "))"'
      label define `name' `=subinstr(`"`labeldef'"', "%", `"""', .)', replace
      label values `name' `name'
    }
  }
  plugin call _julia `namelist' `if' `in', GetVarsFromDF`nomissing' `"`source'"' _cols `:strlen local cols' `ncols'
end

cap program drop PutVarsToDF
program define PutVarsToDF
  syntax [varlist] [if] [in], [DESTination(string) COLs(string) DOUBLEonly noMISSing noLABel]
  if `"`destination'"'=="" local destination df
    else confirm names `destination'
  local ncols = cond("`varlist'"=="",c(k),`:word count `varlist'')
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
end

cap program drop jl
program define jl, rclass
  version 14.1

  if `"`0'"'=="version" {
    return local version 1.0.0
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
      syntax, [Threads(passthru)]
      if 0$julia_loaded & `"`threads'"'!="" di as txt "threads() option ignored because Julia is already running."
      assure_julia_started, `threads'
      exit
    }

    assure_julia_started

    if inlist(`"`cmd'"',"SetEnv","GetEnv") {
      if "`cmd'"=="SetEnv" {
        plugin call _julia, evalqui `"Pkg.activate(joinpath(dirname(Base.load_path_expand("@v#.#")), "`1'"))"'  // move to an environment specific to this package
        AddPkg DataFrames
        AddPkg CategoricalArrays
      }
      return local env: subinstr local __jlans "\\" "\", all
      plugin call _julia, eval `"dirname(Base.active_project())"'
      local __jlans `__jlans'  // strip quotes
      return local envdir: subinstr local __jlans "\\" "\", all
      plugin call _julia, eval `"dirname(Base.load_path_expand("@v#.#"))"'
      local __jlans: subinstr local __jlans "\\" "\", all
      if "`return(envdir)'" == `__jlans' return local env .
      else {
        plugin call _julia, eval `"splitpath(Base.active_project())[end-1]"'
        return local env `__jlans'  // strip quotes
      }
      di as txt `"Current environment: `=cond("`return(env)'"==".","(default)","`return(env)'")', at `return(envdir)'"'
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
      confirm names `destination'
      plugin call _julia `varlist' `if' `in', `cmd'`missing' `"`destination'"' `"`if'`in'"'
    }
    else if `"`cmd'"'=="GetVarsFromMat" {
      syntax namelist [if] [in], source(string asis) [replace]
      confirm names `source'
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
       mat `namelist' = J(`rows', `__jlans', .)
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
    local after = `"`s(after)'"'
    local before `"`s(before)'"'

    assure_julia_started

    if `"`after'"' != "" {
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

    if _rc | "`multiline'"=="" continue, break

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
*  1.0.0 Add GetEnv, support for closing ";", and interactive mode
