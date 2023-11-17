module StataPluginInterface
export SF_sdatalen, SF_var_is_string, SF_var_is_strl, SF_var_is_binary, SF_nobs, SF_nvars, SF_nvar, SF_ifobs, SF_in1, SF_in2, SF_col, SF_row, SF_is_missing, SF_vstore, SF_sstore, SF_mat_store, SF_macro_save, SF_scal_save, SF_display, SF_error, SF_vdata, SF_sdata, SF_mat_el, SF_macro_use, SF_scal_use

global const path = Ref{String}(raw"c:\ado\plus\j\julia.plugin")

setdllpath(s::String) = (path[] = s)

SF_sdatalen(     i::Int, j::Int     ) = @ccall path[].jlSF_sdatalen(i::Cint, j::Cint)::Cint
SF_var_is_string(i::Int             ) = @ccall path[].jlSF_var_is_string(i::Cint)::Cchar
SF_var_is_strl(  i::Int             ) = @ccall path[].jlSF_var_is_strl(i::Cint)::Cchar
SF_var_is_binary(i::Int, j::Int     ) = @ccall path[].jlSF_var_is_binary(i::Cint, j::Cint)::Cchar
SF_nobs(                            ) = @ccall path[].jlSF_nobs()::Cint
SF_nvars(                           ) = @ccall path[].jlSF_nvars()::Cint
SF_nvar(                            ) = @ccall path[].jlSF_nvar()::Cint
SF_ifobs(        j::Int             ) = @ccall path[].jlSF_ifobs(j::Cint)::Cchar
SF_in1(                             ) = @ccall path[].jlSF_in1()::Cint
SF_in2(                             ) = @ccall path[].jlSF_in2()::Cint
SF_col(          mat::AbstractString) = @ccall path[].jlSF_col(mat::Cstring)::Cint
SF_row(          mat::AbstractString) = @ccall path[].jlSF_row(mat::Cstring)::Cint
SF_is_missing(   z::Real            ) = @ccall path[].jlSF_is_missing(z::Cdouble)::Cchar

SF_vstore(    i::Int, j::Int, val::Real                     ) = begin rc = @ccall path[].jlSF_vstore(i::Cint, j::Cint, val::Cdouble)::Cint; rc!=0 && throw(rc); nothing end
SF_sstore(    i::Int, j::Int, s::AbstractString             ) = begin rc = @ccall path[].jlSF_sstore(i::Cint, j::Cint, s::Cstring)::Cint; rc!=0 && throw(rc); nothing end
SF_mat_store( mat::AbstractString, i::Int, j::Int, val::Real) = begin rc = @ccall path[].jlSF_mat_store(mat::Cstring, i::Cint, j::Cint, val::Cdouble)::Cint; rc!=0 && throw(rc); nothing end
SF_macro_save(mac::AbstractString, tosave::AbstractString   ) = begin rc = @ccall path[].jlSF_macro_save(mac::Cstring, tosave::Cstring)::Cint; rc!=0 && throw(rc); nothing end
SF_scal_save( scal::AbstractString, val::Real               ) = begin rc = @ccall path[].jlSF_scal_save(scal::Cstring, val::Cdouble)::Cint; rc!=0 && throw(rc); nothing end
SF_display(   s::AbstractString                             ) = begin rc = @ccall path[].jlSF_display(s::Cstring)::Cint; rc!=0 && throw(rc); nothing end
SF_error(     s::AbstractString                             ) = begin rc = @ccall path[].jlSF_error(s::Cstring)::Cint; rc!=0 && throw(rc); nothing end

SF_vdata(i::Int, j::Int) =
  begin 
      z=Vector{Float64}(undef,1)
      rc = ccall((:jlSF_vdata, path[]), Cint, (Cint, Cint, Ref{Cdouble}), i, j, pointer(z))
      rc!=0 && throw(rc)
      z[] 
  end
SF_sdata(i::Int, j::Int) =
  begin 
      s = pointer(Vector{Int8}(undef,SF_sdatalen(i,j)+1))
      rc = @ccall path[].jlSF_sdata(i::Cint, j::Cint, s::Cstring)::Cint
      rc!=0 && throw(rc)
      GC.@preserve s unsafe_string(Cstring(s)) 
  end
SF_mat_el(mat::AbstractString, i::Int, j::Int) =
  begin 
      z = Vector{Float64}(undef,1)
      rc = ccall((:jlSF_mat_el, path[]), Cint, (Cstring, Cint, Cint, Ref{Cdouble}), mat, i, j, pointer(z))
      rc!=0 && throw(rc)
      z[] 
  end
SF_macro_use(mac::AbstractString, maxlen::Int) =
  begin 
      s = pointer(Vector{Int8}(undef,maxlen+1))
      rc=@ccall path[].jlSF_macro_use(mac::Cstring, s::Cstring, maxlen::Cint)::Cint 
      rc!=0 && throw(rc)
      GC.@preserve s unsafe_string(Cstring(s)) 
  end
SF_scal_use(scal::AbstractString) =
  begin 
      z=Vector{Float64}(undef,1)
      rc = ccall((:jlSF_scal_use, path[]), Cint, (Cstring, Ref{Cdouble}), scal, pointer(z))
      rc!=0 && throw(rc);
      z[] 
  end
end # module Stata