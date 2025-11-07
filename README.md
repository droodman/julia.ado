# julia.ado
This Stata package gives Stata users access to Julia. It contains three kinds of tools:
1.  A `jl:` prefix command that lets you send single-line commands from the Stata prompt to Julia and see the results. Or, if typed by itself, `jl` starts an interactive Julia session in Stata.
2.  Subcommands such as `jl save` and `jl use` for copying data between Julia and Stata.
3.  Julia functions for reading and writing Stata variables, macros, scalars, and matrices.

## Installation
```
ssc install julia
```

## Documentation
After installing, type `help jl`. Also see the [working paper](https://github.com/droodman/julia.ado/blob/master/doc/julia.pdf) in the /doc folder.

## Requirements
* Julia 1.11.1 or later, installed following the instructions obtained via `help jl` in Stata after installing this pacakge.
* Stata 14.1 or later
  
## Examples

```julia
. jl: "Hello world!"
Hello world!

. jl: sqrt(2)
1.4142135623730951

. jl: X = rand(3,100); X+X
3×100 Matrix{Float64}:
 0.708848  1.88261    0.600082  …  1.8036   0.660445  1.40321  1.98992
 1.21193   1.64774    0.389649     1.04665  0.584996  1.88493  1.50712
 0.701329  0.0138349  1.9605       1.35383  1.77841   1.93254  1.26002

. sysuse auto
(1978 automobile data)

. jl save auto   // copy data set to Julia DataFrame called "auto"

. jl: using GLM  // load generalized linear regression package

. jl: m = lm(@formula(price ~ mpg + headroom), auto)
StatsModels.TableRegressionModel{LinearModel{GLM.LmResp{Vector{Float64}}, GLM.DensePredChol{Float64, LinearAlgebra.CholeskyPivoted{Float64, Matrix{Float64}, Vec
> tor{Int64}}}}, Matrix{Float64}}

price ~ 1 + mpg + headroom

Coefficients:
─────────────────────────────────────────────────────────────────────────
                 Coef.  Std. Error      t  Pr(>|t|)  Lower 95%  Upper 95%
─────────────────────────────────────────────────────────────────────────
(Intercept)  12683.3     2074.5      6.11    <1e-07   8546.88   16819.7
mpg           -259.106     58.4248  -4.43    <1e-04   -375.602   -142.61
headroom      -334.021    399.55    -0.84    0.4060  -1130.7      462.658
─────────────────────────────────────────────────────────────────────────

. jl: SF_scal_save("adjR2", adjr2(m))

. display adjR2
.20542069
```
