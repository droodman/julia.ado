clear
set seed 123918231
julia: SF_is_missing(1)

global mac 22
julia: SF_macro_use("mac",20)
julia: SF_macro_save("mac","asda")
julia: SF_macro_save("newmac","xcv")
di "$mac", "$newmac"

scalar sca = 45
julia: SF_scal_use("sca")
julia: SF_scal_save("sca",-3.67)
julia: SF_scal_save("newsca",42)
di sca, newsca

mat mat = 15,7, . \ 22, 3.1, .a
julia: SF_row("mat"), SF_col("mat") 
julia: SF_mat_el("mat",1,2)
julia: SF_mat_store("mat",1,2,55)
mat list mat

set obs 5
gen x = _n
gen xstr = string(44^x)
julia: SF_nobs(), SF_nvars(), SF_nvar()
julia: SF_var_is_string.(1:2) 
julia: SF_var_is_strl.(1:2) 
julia: SF_var_is_binary.(2,1:2)
julia: SF_sdatalen.(2,1:5)
julia: SF_vdata(1,2)
julia: SF_vstore(1,1,-32.4)
di x
julia: SF_sdata(2,2)
julia: SF_sstore(2,1,"-32.4")
di xstr

julia: SF_display("Hello world!")
qui julia: SF_display("Hello world!")
qui julia: SF_error("Hello world!")


clear
set obs 10
drawnorm x
julia PutVarsToDF x
julia: df
julia PutVarsToDFNoMissing x
julia: df
julia PutVarsToMat x, dest(X)
julia: X
julia PutVarsToMatNoMissing x, dest(X)
julia: X

julia PutVarsToDF x in 2/4
julia: df
replace x = .
julia GetVarsFromDFNoMissing x in 2/4, replace
list x

drawnorm y
julia PutVarsToDF x y
sum
replace x = .
cap noi julia GetVarsFromDFNoMissing x y
julia GetVarsFromDFNoMissing x y, replace
sum

julia: df[1,1] = NaN
julia GetVarsFromDFNoMissing x, replace
di x

julia: z = Float32[1.; 2.; 3.]
julia GetVarsFromMat z, source(z)
list z in 1/3
julia GetVarsFromMat z in 3/8, source(z) replace
list z, sep(0)

julia: X = rand(2,2)
julia GetMatFromMat X
mat list X