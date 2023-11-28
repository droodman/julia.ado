# julia.ado
This Stata package gives Stata users access to Julia. It contains three kinds of tools:
1.  A "jl:" prefix command that lets you send single-line commands from the Stata prompt to Julia and see the results.
2.  Subcommands such as PutVarsToDF for high-speed copying of data between Julia and Stata.
3.  Julia functions for reading and writing Stata variables, macros, matrices, and scalars.

This package requires that Julia be installed, and the Julia directory be added to the system path. The easiest way to assure that state
of affairs in Linux and macOS is to install Julia [via the installation manager juliaup](https://github.com/JuliaLang/juliaup#mac-and-linux). Unfortunately, the easiest way to do that
in Windows is to [install the latest version of Julia directly](https://julialang.org/downloads/platform/), making sure to check the box for "Add Julia To PATH".

## Requirements
* Julia 1.9.4 or later
* Stata 14.1 or later
  
## Examples, all run in Stata

```
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

. jl PutVarsToDF   // push all numeric data to Julia DataFrame, named df by default

. jl: using GLM  // load generalized linear regression package

. jl: m = lm(@formula(price ~ mpg + headroom), df)
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

## Possible future extensions
1. Run `jl:` commands asynchronously in order to allow Ctrl-Break.
2. Provide fuller Julia REPL experience.
3. Multi-thread the data copying subcommands.
