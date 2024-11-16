using NLPModels, CUTEst
using ProximalOperators
using RegularizedOptimization

problem_name = "HS8"
nlp = CUTEstModel(problem_name)
@assert !has_bounds(nlp)
@assert equality_constrained(nlp)

h = NormL1(1.0)

options = ROSolverOptions(ϵa = 1e-6, verbose = 1)
stats = AL(nlp, h, options)
print(stats)

finalize(nlp)