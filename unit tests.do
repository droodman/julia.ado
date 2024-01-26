clear
set seed 123918231
jl: SF_is_missing(1)

global mac 22
jl: SF_macro_use("mac",20)
jl: SF_macro_save("mac","asda")
jl: SF_macro_save("newmac","xcv")
di "$mac", "$newmac"

scalar sca = 45
jl: SF_scal_use("sca")
jl: SF_scal_save("sca",-3.67)
jl: SF_scal_save("newsca",42)
di sca, newsca

mat mat = 15,7, . \ 22, 3.1, .a
jl: SF_row("mat"), SF_col("mat") 
jl: SF_mat_el("mat",1,2)
jl: SF_mat_store("mat",1,2,55)
mat list mat

set obs 5
gen x = _n
gen xstr = string(44^x)
jl: SF_nobs(), SF_nvars(), SF_nvar()
jl: SF_var_is_string.(1:2) 
jl: SF_var_is_strl.(1:2) 
jl: SF_var_is_binary.(2,1:2)
jl: SF_sdatalen.(2,1:5)
jl: SF_vdata(1,2)
jl: SF_vstore(1,1,-32.4)
di x
jl: SF_sdata(2,2)
jl: SF_sstore(2,1,"-32.4")
di xstr

jl: SF_display("Hello world!")
qui jl: SF_display("Hello world!")
qui jl: SF_error("Hello world!")


clear
set obs 10
drawnorm x
jl PutVarsToDF x
jl: df
jl PutVarsToDFNoMissing x
jl: df
jl PutVarsToMat x, dest(X)
jl: X
jl PutVarsToMatNoMissing x, dest(X)
jl: X

jl PutVarsToDF x in 2/4
jl: df
replace x = .
jl GetVarsFromDFNoMissing x in 2/4, replace
list x

drawnorm y
jl PutVarsToDF x y
sum
replace x = .
cap noi jl GetVarsFromDFNoMissing x y
jl GetVarsFromDFNoMissing x y, replace
sum

jl: df[1,1] = NaN
jl GetVarsFromDFNoMissing x, replace
di x

jl: z = Float32[1.; 2.; 3.]
jl GetVarsFromMat z, source(z)
list z in 1/3
jl GetVarsFromMat z in 3/8, source(z) replace
list z, sep(0)

jl: X = rand(2,2)
jl GetMatFromMat X
mat list X