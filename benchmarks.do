* Derived from https://github.com/FixedEffects/FixedEffectModels.jl/blob/master/benchmark/benchmark.md

drop _all
set obs 10000000
scalar K = 100
gen id1 = floor(runiform() * (_N+1)/K)
gen id2 = floor(runiform() * (K+1))
gen x1 = runiform() 
gen x2 = runiform()
gen y = 3 * x1 + 2 * x2 + sin(id1) + cos(id2) + runiform()

set rmsg on
//
// reg y x1 x2
// reghdfe y x1 x2, a(id1)
// reghdfe y x1 x2, a(id1 id2)
// reg y x1 x2, cl(id1)
// ivreg2 y x1 x2, cluster(id1 id2)
//
// reghdfejl y x1 x2
// reghdfejl y x1 x2, a(id1)
set processors 1
reghdfe   y x1 x2, a(id1 id2) cluster(id1)
set processors 6
reghdfe   y x1 x2, a(id1 id2) cluster(id1)
reghdfejl y x1 x2, a(id1 id2) cluster(id1)
// reghdfejl y x1 x2, cl(id1)
// reghdfejl y x1 x2, cluster(id1 id2)
