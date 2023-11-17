# julia.ado
This package gives Stata users access to Julia, in three ways:
1.  A "julia:" prefix command that lets you send single-line commands from the Stata prompt to Julia and see the results.
2.  Subcommands such as PutVarsToDF for high-speed copying of data between Julia and Stata.
3.  A set d of Julia functions for reading and writing Stata variables, macros, matrices, and scalars.

## Examples, all run in Stata

```
. julia: "Hello world!"
Hello world!

. julia: sqrt(2)
1.4142135623730951

. julia: X = rand(3,100); X+X
3×100 Matrix{Float64}:
 0.708848  1.88261    0.600082  …  1.8036   0.660445  1.40321  1.98992
 1.21193   1.64774    0.389649     1.04665  0.584996  1.88493  1.50712
 0.701329  0.0138349  1.9605       1.35383  1.77841   1.93254  1.26002

. julia: SF_scal_save("a", cos(pi))

. display a
-1

. set obs 1000000
Number of observations (_N) was 0, now 1,000,000.

. drawnorm x e

. gen y = x + e

. julia PutVarsToDF y x  // push data to Julia DataFrame, named df by default

. julia: using GLM  // load generalized linear regression package

. julia: lm(@formula(y ~ x), df)  // regress y on x
StatsModels.TableRegressionModel{LinearModel{GLM.LmResp{Vector{Float64}}, GLM.DensePredChol{Float64, LinearAlgebra.CholeskyPivoted{Float64, Matrix{Float64}
> , Vector{Int64}}}}, Matrix{Float64}}

y ~ 1 + x

Coefficients:
──────────────────────────────────────────────────────────────────────────────────
                   Coef.   Std. Error       t  Pr(>|t|)    Lower 95%     Upper 95%
──────────────────────────────────────────────────────────────────────────────────
(Intercept)  -0.00294632  0.000999724   -2.95    0.0032  -0.00490575  -0.000986899
x             0.999008    0.00099963   999.38    <1e-99   0.997049     1.00097
──────────────────────────────────────────────────────────────────────────────────
```
