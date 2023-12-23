# see also https://www.stata.com/plugins

module stataplugininterface
export SF_sdatalen, SF_var_is_string, SF_var_is_strl, SF_var_is_binary, SF_nobs, SF_nvars, SF_nvar, SF_ifobs, SF_in1, SF_in2, SF_col, SF_row, SF_is_missing, SF_missval, SF_vstore, SF_sstore, SF_mat_store, SF_macro_save, SF_scal_save, SF_display, SF_error, SF_vdata, SF_sdata, SF_mat_el, SF_macro_use, SF_scal_use, SF_varindex

global const dllpath = Ref{String}(raw"c:\ado\plus\j\jl.plugin")  # where to look for plugin with accessible wrappers for Stata interface functions

setdllpath(s::String) = (dllpath[] = s)


"""
    SF_varindex(s::AbstractString)

Returns the numeric index in the Stata data set for the variable named s.
"""
SF_varindex(s::AbstractString) = @ccall dllpath[].jlSF_varindex(s::Cstring, 1::Cint)::Cint

"""
    SF_sdatalen(i::Int, j::Int)

Returns the length, in bytes, of the jth observation of the ith variable of the Stata data set, if it is a string.
"""
SF_sdatalen(i::Int, j::Int) = @ccall dllpath[].jlSF_sdatalen(i::Cint, j::Cint)::Cint

"""
    SF_var_is_string(i::Int)

Checks the ith variable of the Stata data set and returns 1 if the variable is a string variable (meaning str# or strL) and 0 if the variable is a numeric variable
"""
SF_var_is_string(i::Int) = @ccall dllpath[].jlSF_var_is_string(i::Cint)::Cchar

"""
    SF_var_is_strl(i::Int)

Checks whether variable i of the Stata data set is a str# variable or a strL variable. It returns 1 if the variable is a strL and 0 otherwise.
"""
SF_var_is_strl(i::Int) = @ccall dllpath[].jlSF_var_is_strl(i::Cint)::Cchar

"""
    SF_var_is_binary(i::Int, j::Int)

Checks the jth observation of the ith variable of the Stata data set. It returns 1 if the value is a binary strL and 0 otherwise.
"""
SF_var_is_binary(i::Int, j::Int) = @ccall dllpath[].jlSF_var_is_binary(i::Cint, j::Cint)::Cchar

"""
    SF_nobs()

Returns the number of observations in the Stata data set.
"""
SF_nobs() = @ccall dllpath[].jlSF_nobs()::Cint

"""
    SF_nvar()

Returns the number of variables in the Stata data set.
"""
SF_nvar() = @ccall dllpath[].jlSF_nvar()::Cint

SF_nvars() = @ccall dllpath[].jlSF_nvars()::Cint
SF_ifobs(j::Int) = @ccall dllpath[].jlSF_ifobs(j::Cint)::Cchar
SF_in1()= @ccall dllpath[].jlSF_in1()::Cint
SF_in2() = @ccall dllpath[].jlSF_in2()::Cint

"""
    SF_col(mat::AbstractString)
returns the number of columns of Stata matrix mat, or 0 if the matrix doesn't exist or some other error.
"""
SF_col(mat::AbstractString) = @ccall dllpath[].jlSF_col(mat::Cstring)::Cint

"""
    SF_row(mat::AbstractString)
returns the number of rows of Stata matrix mat, or 0 if the matrix doesn't exist or some other error.
"""
SF_row( mat::AbstractString) = @ccall dllpath[].jlSF_row(mat::Cstring)::Cint

"""
    SF_is_missing(z::Real)

Check if z is  Stata "missing".
"""
SF_is_missing(z::Real) = @ccall dllpath[].jlSF_is_missing(z::Cdouble)::Cchar

"""
    SV_missval()

Returns a representation of Stata "missing" as a Float64.
"""
SF_missval() = @ccall dllpath[].jlSF_missval()::Cdouble

"""
    SF_vstore(i::Int, j::Int, val::Real)

Stores val in the jth observation of variable i of the Stata data set.
"""
SF_vstore(i::Int, j::Int, val::Real) = begin rc = @ccall dllpath[].jlSF_vstore(i::Cint, j::Cint, val::Cdouble)::Cint; rc!=0 && throw(rc); nothing end

"""
    SF_sstore(i::Int, j::Int, s::AbstractString)

Stores s in the jth observation of variable i of the Stata data set.
"""
SF_sstore(i::Int, j::Int, s::AbstractString) = begin rc = @ccall dllpath[].jlSF_sstore(i::Cint, j::Cint, s::Cstring)::Cint; rc!=0 && throw(rc); nothing end

"""
    SF_mat_store(mat::AbstractString, i::Int, j::Int, val::Real)

Stores val as the [i,j] element of Stata matrix mat. Returns a nonzero return code if an error is encountered.
"""
SF_mat_store(mat::AbstractString, i::Int, j::Int, val::Real) = begin rc = @ccall dllpath[].jlSF_mat_store(mat::Cstring, i::Cint, j::Cint, val::Cdouble)::Cint; rc!=0 && throw(rc); nothing end

"""
    SF_macro_save(mac::AbstractString, tosave::AbstractString)

Creates/recreates a Stata macro named by mac and stores tosave in it. Returns a nonzero return code on error.
"""
SF_macro_save(mac::AbstractString, tosave::AbstractString) = begin rc = @ccall dllpath[].jlSF_macro_save(mac::Cstring, tosave::Cstring)::Cint; rc!=0 && throw(rc); nothing end

"""
    SF_scal_save(scal::AbstractString, val::Real)

Creates/recreates a Stata scalar named by scal and stores val in it. Returns a nonzero return code on error.
"""
SF_scal_save(scal::AbstractString, val::Real) = begin rc = @ccall dllpath[].jlSF_scal_save(scal::Cstring, val::Cdouble)::Cint; rc!=0 && throw(rc); nothing end

"""
    SF_display(s::AbstractString)

Sends the string s to the Stata results window after running it through the Stata SMCL interpreter.
"""
SF_display(s::AbstractString) = begin rc = @ccall dllpath[].jlSF_display(s::Cstring)::Cint; rc!=0 && throw(rc); nothing end

"""
    SF_error(s::AbstractString)

Sends the string s to the Stata results window, even when run quietly, after running it through the Stata SMCL interpreter.
"""
SF_error(s::AbstractString) = begin rc = @ccall dllpath[].jlSF_error(s::Cstring)::Cint; rc!=0 && throw(rc); nothing end

"""
    SF_vdata(i::Int, j::Int)

Returns the jth observation of (numeric) variable i of the Stata data set. Throws an error for non-numeric variables.
"""
SF_vdata(i::Int, j::Int) =
  begin 
      z = Vector{Float64}(undef,1)
      rc = ccall((:jlSF_vdata, dllpath[]), Cint, (Cint, Cint, Ref{Cdouble}), i, j, pointer(z))
      rc!=0 && throw(rc)
      z[] 
  end

"""
    SF_sdata(i::Int, j::Int)

Returns the jth observation of (string) variable i of the Stata data set. Throws an error for non-string variables.
"""
SF_sdata(i::Int, j::Int) =
  begin 
      s = pointer(Vector{Int8}(undef,SF_sdatalen(i,j)+1))
      rc = @ccall dllpath[].jlSF_sdata(i::Cint, j::Cint, s::Cstring)::Cint
      rc!=0 && throw(rc)
      GC.@preserve s unsafe_string(Cstring(s)) 
  end

"""
    SF_mat_el(mat::AbstractString, i::Int, j::Int)

Returns the [i,j] element of Stata matrix mat.
"""
SF_mat_el(mat::AbstractString, i::Int, j::Int) =
  begin 
      z = Vector{Float64}(undef,1)
      rc = ccall((:jlSF_mat_el, dllpath[]), Cint, (Cstring, Cint, Cint, Ref{Cdouble}), mat, i, j, pointer(z))
      rc!=0 && throw(rc)
      z[] 
  end

"""
    SF_macro_use(mac::AbstractString, maxlen::Int)

Returns the first maxlen characters of Stata macro mac. Local macros can be accessed prefixing their names with "_".
"""
SF_macro_use(mac::AbstractString, maxlen::Int) =
  begin 
      s = pointer(Vector{Int8}(undef,maxlen+1))
      rc=@ccall dllpath[].jlSF_macro_use(mac::Cstring, s::Cstring, maxlen::Cint)::Cint 
      rc!=0 && throw(rc)
      GC.@preserve s unsafe_string(Cstring(s)) 
  end

"""
    SF_scal_use(scal::AbstractString)

Returns the Stata scalar scal, as a Float64.
"""
SF_scal_use(scal::AbstractString) =
  begin 
      z=Vector{Float64}(undef,1)
      rc = ccall((:jlSF_scal_use, dllpath[]), Cint, (Cstring, Ref{Cdouble}), scal, pointer(z))
      rc!=0 && throw(rc);
      z[] 
  end

end
