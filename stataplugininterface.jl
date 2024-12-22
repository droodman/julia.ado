module stataplugininterface
export SF_sdatalen, SF_var_is_string, SF_var_is_strl, SF_var_is_binary, SF_nobs, SF_nvars, SF_nvar, SF_ifobs, SF_in1, SF_in2, SF_col, 
       SF_row, SF_is_missing, SV_missval, SF_vstore, SF_sstore, SF_mat_store, SF_macro_save, SF_scal_save, SF_display, SF_error, 
       SF_vdata, SF_sdata, SF_mat_el, SF_macro_use, SF_scal_use, st_varindex, st_matrix, st_numscalar, st_data, st_view, st_local, st_global,
       st_nobs, st_nvar

using DataFrames, CategoricalArrays

global const dllpath = Ref{String}(raw"c:\ado\plus\j\jl.plugin")  # where to look for plugin with accessible wrappers for Stata interface functions
setdllpath(s::String) = (dllpath[] = s)

global x, s, julia_task, julia_time, M  # used by C++ plugin to avoid contaminating Main name space
public setdllpath, x, s, julia_task, julia_time

global macrobuf = Vector{Int8}(undef, 15_480_200+1)  # can hold maximum-sized Stata macro

"""
    st_varindex(s::AbstractString, abbrev::Bool=true)

Returns the numeric index in the Stata data set for the variable named s. Allows abbreviated names
if abbrev=true _and_ Stata has "set varabbrev" on.
"""

st_varindex(s::AbstractString, abbrev::Bool=true) = @ccall dllpath[].jlSF_varindex(s::Cstring, abbrev::Cint)::Cint

"""
    SF_sdatalen(j::Integer, i::Integer)

Returns the length, in bytes, of the jth observation of the ith variable of the Stata data set, if it is a string.
"""
SF_sdatalen(j::Integer, i::Integer) = @ccall dllpath[].jlSF_sdatalen(i::Cint, j::Cint)::Cint

"""
    SF_var_is_string(i::Integer)

Checks the ith variable of the Stata data set and returns 1 if the variable is a string variable (meaning str# or strL) and 0 if the variable is a numeric variable
"""
SF_var_is_string(i::Integer) = @ccall dllpath[].jlSF_var_is_string(i::Cint)::Cchar

"""
    SF_var_is_strl(i::Integer)

Checks whether variable i of the Stata data set is a str# variable or a strL variable. It returns 1 if the variable is a strL and 0 otherwise.
"""
SF_var_is_strl(i::Integer) = @ccall dllpath[].jlSF_var_is_strl(i::Cint)::Cchar

"""
    SF_var_is_binary(j::Integer, i::Integer)

Checks the jth observation of the ith variable of the Stata data set. It returns 1 if the value is a binary strL and 0 otherwise.
"""
SF_var_is_binary(j::Integer, i::Integer) = @ccall dllpath[].jlSF_var_is_binary(i::Cint, j::Cint)::Cchar

"""
    SF_nobs()

Returns the number of observations in the Stata data set.
"""
SF_nobs() = @ccall dllpath[].jlSF_nobs()::Cint

"""
    st_nobs()

Returns the number of observations in the Stata data set.
"""
st_nobs = SF_nobs

"""
    SF_nvar()

Returns the number of variables in the Stata data set.
"""
SF_nvar() = @ccall dllpath[].jlSF_nvar()::Cint
SF_nvars() = @ccall dllpath[].jlSF_nvars()::Cint

"""
    st_nvar()

Returns the number of variables in the Stata data set.
"""
st_nvar = SF_nvar

SF_ifobs(j::Integer) = @ccall dllpath[].jlSF_ifobs(j::Cint)::Cchar
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
SV_missval() = @ccall dllpath[].jlSF_missval()::Cdouble

"""
    SF_vstore(j::Integer, i::Integer, val::Real)

Stores val in the jth observation of variable i of the Stata data set.
"""
function SF_vstore(j::Integer, i::Integer, val::Real)
    rc = @ccall dllpath[].jlSF_vstore(i::Cint, j::Cint, val::Cdouble)::Cint
    rc!=0 && throw(rc)
    nothing
end

"""
    SF_sstore(j::Integer, i::Integer, s::AbstractString)

Stores s in the jth observation of variable i of the Stata data set.
"""
function SF_sstore(j::Integer, i::Integer, s::AbstractString)
    rc = @ccall dllpath[].jlSF_sstore(i::Cint, j::Cint, s::Cstring)::Cint
    rc!=0 && throw(rc)
    nothing
end

"""
    SF_mat_store(mat::AbstractString, i::Integer, j::Integer, val::Real)

Stores val as the [i,j] element of Stata matrix mat. Returns a nonzero return code if an error is encountered.
"""
function SF_mat_store(mat::AbstractString, i::Integer, j::Integer, val::Real)
    rc = @ccall dllpath[].jlSF_mat_store(mat::Cstring, i::Cint, j::Cint, val::Cdouble)::Cint
    rc!=0 && throw(rc)
    nothing
end

"""
    SF_macro_save(mac::AbstractString, tosave::AbstractString)

Creates/recreates a Stata macro named by mac and stores tosave in it. Returns a nonzero return code on error.
"""
function SF_macro_save(mac::AbstractString, tosave::AbstractString)
    rc = @ccall dllpath[].jlSF_macro_save(mac::Cstring, tosave::Cstring)::Cint
    rc!=0 && throw(rc)
    nothing
end

"""
    SF_scal_save(scal::AbstractString, val::Number)

Creates/recreates a Stata scalar named by scal and stores val in it. Returns a nonzero return code on error.
"""
function SF_scal_save(scal::AbstractString, val::Number)
    rc = @ccall dllpath[].jlSF_scal_save(scal::Cstring, val::Cdouble)::Cint
    rc!=0 && throw(rc)
    nothing
end

"""
    SF_display(s::AbstractString)

Sends the string s to the Stata results window after running it through the Stata SMCL interpreter.
"""
function SF_display(s::AbstractString)
    rc = @ccall dllpath[].jlSF_display(s::Cstring)::Cint
    rc!=0 && throw(rc)
    nothing
end

"""
    SF_error(s::AbstractString)

Sends the string s to the Stata results window, even when run quietly, after running it through the Stata SMCL interpreter.
"""
function SF_error(s::AbstractString)
    rc = @ccall dllpath[].jlSF_error(s::Cstring)::Cint
    rc!=0 && throw(rc)
    nothing
end

"""
    SF_vdata(j::Integer, i::Integer)

Returns the jth observation of (numeric) variable i of the Stata data set. Throws an error for non-numeric variables.
"""
function SF_vdata(j::Integer, i::Integer)
  z = Vector{Float64}(undef,1)
  rc = ccall((:jlSF_vdata, dllpath[]), Cint, (Cint, Cint, Ref{Cdouble}), i, j, pointer(z))
  rc!=0 && throw(rc)
  z[] 
end

"""
    SF_sdata(j::Integer, i::Integer)

Returns the jth observation of (string) variable i of the Stata data set. Throws an error for non-string variables.
"""
function SF_sdata(j::Integer, i::Integer)
  s = pointer(Vector{Int8}(undef,SF_sdatalen(j,i)+1))
  rc = @ccall dllpath[].jlSF_sdata(i::Cint, j::Cint, s::Cstring)::Cint
  rc!=0 && throw(rc)
  GC.@preserve s unsafe_string(Cstring(s)) 
end

"""
    SF_mat_el(mat::AbstractString, i::Integer, j::Integer)

Returns the [i,j] element of Stata matrix mat.
"""
function SF_mat_el(mat::AbstractString, i::Integer, j::Integer)
  z = Vector{Float64}(undef,1)
  rc = ccall((:jlSF_mat_el, dllpath[]), Cint, (Cstring, Cint, Cint, Ref{Cdouble}), mat, i, j, pointer(z))
  rc!=0 && throw(rc)
  z[] 
end

"""
    SF_macro_use(mac::AbstractString)

Return Stata global macro mac.
"""
function SF_macro_use(mac::AbstractString)
  rc = @ccall dllpath[].jlSF_macro_use(mac::Cstring, pointer(macrobuf)::Cstring, 15_480_200::Cint)::Cint 
  rc!=0 && throw(rc)
  unsafe_string(Cstring(pointer(macrobuf)))
end

"""
    SF_scal_use(scal::AbstractString)

Returns the Stata scalar scal, as a Float64.
"""
function SF_scal_use(scal::AbstractString)
  z = Vector{Float64}(undef,1)
  rc = ccall((:jlSF_scal_use, dllpath[]), Cint, (Cstring, Ref{Cdouble}), scal, pointer(z))
  rc!=0 && throw(rc);
  z[] 
end


"""
    st_global(mac::AbstractString)::String
    st_global(mac::AbstractString, tosave::AbstractString)

Reads or writes the Stata global macro named mac.
"""
st_global(mac::AbstractString) = SF_macro_use(mac)
st_global(mac::AbstractString, tosave::AbstractString) = SF_macro_save(mac, tosave)

"""
    st_local(mac::AbstractString, tosave::AbstractString)

Creates/recreates a Stata local macro named by mac and stores tosave in it.
"""
function st_local(mac::AbstractString, tosave::AbstractString)
    rc = @ccall dllpath[].jlSF_macro_save(("_"*mac)::Cstring, tosave::Cstring)::Cint
    rc!=0 && throw(rc)
    mac ∉ Set(("___jlans","___jlcomplete")) &&
        SF_macro_save("___jllocals", SF_macro_use("___jllocals") * " " * mac)  # add to Stata local "__jllocals"
    nothing
end

"""
    st_matrix(matname::AbstractString)::Matrix{Float64}
    st_matrix(matname::AbstractString, jlmat::AbstractMatrix{<:Number})

Returns or assigns to the Stata matrix of the given name. For assignment, large-enough Stata matrix must already exist.
"""
function st_matrix(matname::AbstractString)
    @ccall dllpath[].copymatS2J(matname::Cstring, "stataplugininterface.M"::Cstring)::Cvoid
    stataplugininterface.M
end
function st_matrix(matname::AbstractString, jlmat::VecOrMat{<:Number})
    @assert SF_row(matname) ≥ size(jlmat,1) && SF_col(matname) ≥ size(jlmat,2) "receiving matrix does not exist or is too small"
    @ccall dllpath[].copymatJ2S(jlmat::Any, matname::Cstring)::Cvoid
    nothing
end

"""
    st_numscalar(scalarname::AbstractString)::Float64
    st_numscalar(scalarname::AbstractString, val::Number)

Reads or writes Stata scalar.
"""
st_numscalar(scalarname) = SF_scal_use(scalarname);
st_numscalar(scalarname, val) = begin SF_scal_save(scalarname, val); nothing end


"""
    st_data(varnames::AbstractVector{<:AbstractString}, sample::Vector{Bool}=Bool[])::Matrix{Float64}
    st_data(varnames::AbstractString, sample::Vector{Bool}=Bool[])::Matrix{Float64}

Return one or more variables in a matrix. `varnames` is a vector of strings or space-delimited string of variable names.
"""
function st_data(varnames::AbstractVector{<:AbstractString}, sample::Vector{Bool}=Bool[])
    ind = st_varindex.(varnames)
    @assert !any(Bool ∘ SF_var_is_string, ind) "st_data() is for numeric variables"
    if iszero(length(sample))
        @ccall stataplugininterface.dllpath[].st_data(pointer(ind)::Ref{Cint}, length(varnames)::Cint, 
                     SF_nobs()::Cint, 1::Cint, SF_nobs()::Cint, C_NULL::Ptr{Cchar}, "stataplugininterface.M"::Cstring, 0::Cchar)::Cvoid
    else
        @assert length(sample)==SF_nobs() "sample vector, if provided, must have same height as data set"
        @ccall stataplugininterface.dllpath[].st_data(pointer(ind)::Ref{Cint}, length(varnames)::Cint, 
                     sum(sample)::Cint, 1::Cint, SF_nobs()::Cint, pointer(sample)::Ptr{Cchar}, "stataplugininterface.M"::Cstring, 0::Cchar)::Cvoid
    end
    stataplugininterface.M
end
st_data(varnames::AbstractString, sample::Vector{Bool}=Bool[]) = st_data(split(varnames), sample)

"""
    st_view(varnames::AbstractVector{<:AbstractString}, sample::Vector{Bool}=Bool[])::Matrix{Float64}
    st_view(varnames::AbstractString, sample::Vector{Bool}=Bool[])::Matrix{Float64}

Return a matrix-like view onto one or more Stata variables. `varnames` is a vector of strings or space-delimited string of variable names.
"""
struct st_view{S} <: AbstractMatrix{Float64}  # S is Val(true) for views with defined samples
    nrows::Int64
    ncols::Int32
    varindex::Vector{Int32}
    sample::Vector{Int64}
end
function st_view(varnames::AbstractVector{<:AbstractString}, sample::Vector{Bool}=Bool[])
    ind = st_varindex.(varnames)
    @assert !any(Bool ∘ SF_var_is_string, ind) "st_view() is for numeric variables"
    if iszero(length(sample))
        st_view{Val(false)}(SF_nobs(), length(varnames), ind, Int64[])
    else
        @assert iszero(length(sample)) || length(sample)==SF_nobs() "sample vector, if provided, must have same height as data set"
        s = findall(sample)
        st_view{Val(true)}(length(s), length(varnames), ind, s)
    end
end
st_view(varnames::AbstractString, sample::Vector{Bool}=Bool[]) = st_view(split(varnames), sample)

import Base.size, Base.getindex, Base.setindex!
size(v::st_view) = v.nrows, v.ncols

@inline getindex(v::st_view{Val(false)}, i::Integer, j::Integer) = SF_vdata(i, v.varindex[j])
@inline getindex(v::st_view{Val(true)}, i::Integer, j::Integer) = SF_vdata(v.sample[i], v.varindex[j])
@inline getindex(v::st_view, i::Integer) = getindex(v, i, 1)
@inline getindex(v::st_view, I::CartesianIndex{1}) = getindex(v, I[1], 1)
@inline getindex(v::st_view, I::CartesianIndex{2}) = getindex(v, I[1], I[2])

@inline function setindex!(v::st_view{Val(false)}, val::Number, i::Integer, j::Integer)
    SF_vstore(i, v.varindex[j], val)
    nothing
end
@inline function setindex!(v::st_view{Val(true)}, val::Number, i, j)
    SF_vstore(v.sample[i], v.varindex[j], val)
    nothing
end
@inline setindex!(v::st_view, val::Number, i::Integer) = setindex!(v, val, i, 1)
@inline setindex!(v::st_view, val::Number, I::CartesianIndex{1}) = setindex!(v, val, I[1], 1)
@inline setindex!(v::st_view, val::Number, I::CartesianIndex{2}) = setindex!(v, val, I[1], I[2])

# stuff called by jl.ado & jl.plugin
const type2intDict = Dict(Int8=>1, Int16=>2, Int32=>3, Int64=>4, Float32=>5, Float64=>6, String=>7)
const S2Jtypedict = Dict("float"=>Float32, "double"=>Float64, "byte"=>Int8, "int"=>Int16, "long"=>Int32, "str"=>String, "str1"=>Char);

cvindextype(::Type{CategoricalValue{T, N}}) where {T, N} = N

# Given data column, return appropriate Stata type
function statatype(v::AbstractVector)::String
    jltype = v |> eltype |> nonmissingtype
    jltype <: CategoricalValue && (jltype = cvindextype(jltype))

    jltype <: AbstractString ? "str" * string(min(2045, mapreduce(length, max, v, init=0))) :
    jltype <: Integer ?
        typemax(jltype)≤32_741 ? "int"   : (typemax(jltype)≤2_147_483_620 ? "long" : "double") :
        jltype == Float32      ? "float" : "double"
end

# Stata types for columns in a DF named in a string, returned in a string
statatypes(df::DataFrame, colnames::String) = join(statatype.(eachcol(df[!,split(colnames)])), " ")

function NaN2missing(df::DataFrame)
    allowmissing!(df)
    Threads.@threads for x ∈ eachcol(df)
        t = x |> eltype |> nonmissingtype
        t<:Number && replace!(x, (t<:Integer ? typemax(t) : t==Float32 ? NaN32 : reinterpret(Float64, 0x7fe0000000000000)) => missing)
    end
end

end
