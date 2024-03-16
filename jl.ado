*! jl 0.10.1 6 March 2024
*! Copyright (C) 2023-24 David Roodman

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
      _assert !_rc & `threads'>0, msg("threads() option must be "auto" or a positive integer") rc(198)
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

      di as txt "Starting Julia" _c
      if `"`threads'"' != "" di " with threads=`threads'"
      mata displayflush() 
      plugin call _julia, start "`libpath'/`libname'" "`libpath'" `threads'
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

    cap noi {
      jl AddPkg DataFrames, minver(1.6.1)
      jl AddPkg CategoricalArrays, minver(0.10.8)
      jl, qui: using DataFrames, CategoricalArrays

      qui findfile stataplugininterface.jl
      jl, qui: pushfirst!(LOAD_PATH, dirname(expanduser(raw"`r(fn)'")))
      jl, qui: using stataplugininterface
      qui findfile jl.plugin
      jl, qui: stataplugininterface.setdllpath(expanduser(raw"`r(fn)'"))

      jl, qui: const stataplugininterface.type2intDict = Dict(Int8=>1, Int16=>2, Int32=>3, Int64=>4, Float32=>5, Float64=>6, String=>7)
    }
    if _rc global julia_loaded
  }
end

cap program drop jl
program define jl, rclass
  version 14.1

  if `"`0'"'=="version" {
    return local version 0.10.0
    exit
  }

  cap _on_colon_parse `0'
  if _rc {
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
      if 0$julia_loaded & `"`threads'"'!="" di as txt "threads() option ignored because Julia is already started."
      assure_julia_started, `threads'
      exit
    }
    
    assure_julia_started
    
    if `"`cmd'"'=="SetEnv" {
      jl, qui: using Pkg; Pkg.activate(joinpath(dirname(Base.load_path_expand("@v#.#")), "`1'"))  // move to an environment specific to this package
      jl AddPkg DataFrames
      jl AddPkg CategoricalArrays
    }
    else if `"`cmd'"'=="AddPkg" {
      syntax name, [MINver(string)]
      jl, qui: using Pkg
      qui jl: Int(!("`namelist'" in keys(Pkg.project().dependencies)))
      local notinstalled `r(ans)'
      if !`notinstalled' & "`minver'"!="" qui jl: length([1 for v in values(Pkg.dependencies()) if v.name=="`namelist'" && v.version<v"`minver'"])
      if `notinstalled' | `r(ans)' {
        di as txt "The Julia package `namelist' is not installed and up-to-date in this package environment. Attempting to update it. This could take a few minutes." _n 
        mata displayflush() 
        jl, qui: Pkg.add(PackageSpec(name=String(:`namelist') `=cond("`minver'"=="", "", `", version=VersionNumber(`:subinstr local minver "." ",", all') "')'))
        if _rc {
          di as err _n "Failed to update the Julia package `namelist'."
          di as err "You should be able to install it by running Julia and typing:" _n `"{cmd:using Pkg; Pkg.update("`namelist'")}"'
          exit 198
        }
      }
    }
    else if `"`cmd'"'=="use" {
      syntax namelist [using/], [clear]
      if c(changed) & "`clear'"=="" error 4
      drop _all
      if `"`using'"'=="" {
        _assert `:word count `namelist''==1, msg("Just specify one source DataFrame.") rc(198) 
        local source `namelist'
        qui jl: join(names(`source'), " ")
        local cols `r(ans)'
      }
      else {
        local source `using'
        local cols `namelist'
      }
      qui jl: size(`source',1)
      qui set obs `r(ans)'
      jl GetVarsFromDF `cols', source(`source') 
    }
    else if `"`cmd'"'=="PutVarsToDF" {
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
      if "`missing'"=="" jl, qui: stataplugininterface.NaN2missing(`destination')
      if "`doubleonly'"!="" jl, qui: rename!(`destination', vec(split("`cols'")))
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
            cap noi jl, qui: `destination'.`col' = CategoricalVector(recode(`destination'.`col' `recodecmd'))
          }
        }        
      }
    }
    else if `"`cmd'"'=="save" {
      syntax [namelist(max=1)], [NOLABel DOUBLEonly NOMISSing]
      jl PutVarsToDF, dest(`namelist') `nolabel' `doubleonly' `nomissing'
    }
    else if `"`cmd'"'=="PutVarsToMat" {
      syntax [varlist] [if] [in], DESTination(string) [noMISSing]
      confirm names `destination'
      plugin call _julia `varlist' `if' `in', `cmd'`missing' `"`destination'"'
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
    else if `"`cmd'"'=="GetVarsFromDF" {
      syntax namelist [if] [in], [source(string) replace COLs(string asis) noMISSing]
      if `"`source'"'=="" local source df
      if `"`cols'"'=="" local cols `namelist'
        else {
          confirm names `cols'
          _assert `:word count `cols''<=cond("`varlist'"=="",c(k),`:word count `varlist''), msg("Too few destination variables specified.") rc(198) 
        }
      if "`replace'"=="" confirm new var `namelist'
      qui jl: stataplugininterface.statatypes(`source', "`cols'")
      local types `r(ans)'
      local ncols: word count `cols'
      forvalues v=1/`ncols' {
        local type: word `v' of `types'
        local col : word `v' of `cols'
        local name: word `v' of `namelist'
        cap gen `type' `name' = `=cond(substr("`type'",1,3)=="str", `""""', ".")'
        qui jl: Int(`source'.`col' isa CategoricalVector)
        if `r(ans)' {
          qui jl: join([string(i) * " \"" * l * "\"" for (i,l) in enumerate(levels(`source'.`col'))], " ")
          label define `name' `=subinstr(`"`r(ans)'"', `"\""', `"""', .)', replace
          label values `name' `name'
        }
      }
      plugin call _julia `namelist' `if' `in', GetVarsFromDF`nomissing' `"`source'"' _cols `:strlen local cols' `ncols'
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
    local after = `"`s(after)'"'
    local 0 `"`s(before)'"'
    syntax, [QUIetly INTERruptible]
    local varlist = cond(c(k),"*","")
    assure_julia_started

    if "`interruptible'" != "" {  // Run Julia 1 sec at a time to allow Ctrl-Break, checking if task finished every .01 sec
      plugin   call _julia `varlist', evalqui `"stataplugininterface.julia_task = @async (`after')"'
      plugin   call _julia, eval `"stataplugininterface.julia_time=time()+1; for _ in 1:100 (istaskdone(stataplugininterface.julia_task) || time()>stataplugininterface.julia_time) && break; sleep(.01) end; Int(!istaskdone(stataplugininterface.julia_task))"'
      while `ans' {
        plugin call _julia, eval `"stataplugininterface.julia_time=time()+1; for _ in 1:100 (istaskdone(stataplugininterface.julia_task) || time()>stataplugininterface.julia_time) && break; sleep(.01) end; Int(!istaskdone(stataplugininterface.julia_task))"'
      }
      if "`quietly'"=="" plugin call _julia, eval fetch(stataplugininterface.julia_task)
    }
    else plugin call _julia `varlist', eval`=cond("`quietly'"!="","qui","")' `"`after'"'

    if "`quietly'"=="" {
      return local ans: copy local ans
      cap noi local ans `ans'  // strips quote marks
      cap noi if `"`ans'"' != "nothing" display_multiline `ans'
    }
  }
  return local ans: copy local ans
end

program _julia, plugin using(jl.plugin)

* properly print a string with newlines
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