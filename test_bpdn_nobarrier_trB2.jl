# Julia Testing function
# Generate Compressive Sensing Data
using TRNC, Plots,Printf, Convex,SCS, Random, LinearAlgebra
include("./src/minconf_spg/oneProjector.jl")

#Here we just try to solve the l2-norm^2 data misfit + l1 norm regularization over the l1 trust region with -10≦x≦10
#######
# min_x 1/2||Ax - b||^2 + λ||x||₁
compound = 1
#m rows, n columns, k nonzeros
m,n = compound*120,compound*512
k = compound*20
p = randperm(n)
#initialize x
x0 = zeros(n,)
x0[p[1:k]]=sign.(randn(k))

A = randn(m,n)
(Q,_) = qr(A')
A = Matrix(Q)
A = Matrix(A')

b0 = A*x0
b = b0 + 0.005*randn(m,)
cutoff = 0.0
λ_T = norm(A'*b, Inf)/100


#define your smooth objective function
#merit function isn't just this though right?
function f_smooth(x) #gradient and hessian info are smooth parts, m also includes nonsmooth part
    r = A*x - b
    g = A'*r
    return norm(r)^2/2, g, A'*A
end

function h_nonsmooth(x)
    return λ_T*norm(x,1) #, g∈∂h
end



fval(s,qi,xi,νi) = norm(s.+qi)^2/(2*νi) + λ_T*norm(s.+xi,1) #note - this is supposed to be s+q, work out math tomorrow
projbox(y,qi,νi) = min.(max.(y, qi.-λ_T*νi),qi.+λ_T*νi) # different since through dual
# (s,f) = hardproxB2(fval, x, projbox, Doptions)

#set all options
first_order_options = s_options(norm(A'*A)^(2.0); λ=λ_T, maxIter=5)
# Doptions=s_options(1/ν; gk = g, Bk = A'*A, xk=x, Δ = τ)

parameters = IP_struct(f_smooth, h_nonsmooth; FO_options = first_order_options, s_alg=hardproxB2, prox_ψk=fval, χ_projector=projbox)
options = IP_options(;simple=0, ptf=10, Δk = 1.0, maxIter=100)
#put in your initial guesses
xi = ones(n,)/2

X = Variable(n)
problem = minimize(sumsquares(A * X - b) + λ_T*norm(X,1))
solve!(problem, SCSSolver())



TotalCount = 0
# x, zl, zu = barrier_alg(x,zl, zu, parameters, options; mu_tol=1e-4)
x, k = IntPt_TR(xi, TotalCount, parameters, options)


#print out l2 norm difference and plot the two x values
@printf("l2-norm CVX vs VP: %5.5e\n", norm(X.value - x)/norm(X.value))
@printf("l2-norm CVX vs True: %5.5e\n", norm(X.value - x0)/norm(X.value))
@printf("l2-norm VP vs True: %5.5e\n", norm(x0 - x)/norm(x0))

@printf("Full Objective - CVX: %5.5e     VP: %5.5e   True: %5.5e\n", f_smooth(X.value)[1] + h_nonsmooth(X.value), f_smooth(x)[1]+h_nonsmooth(x), f_smooth(x0)[1]+h_nonsmooth(x0))
@printf("f(x) - CVX: %5.5e     VP: %5.5e   True: %5.5e\n", f_smooth(X.value)[1],f_smooth(x)[1], f_smooth(x0)[1])
@printf("h(x) - CVX: %5.5e     VP: %5.5e   True: %5.5e\n", h_nonsmooth(X.value)/λ_T,h_nonsmooth(x)/λ_T, h_nonsmooth(x0)/λ_T)

plot(x0, xlabel="i^th index", ylabel="x", title="TR vs True x", label="True x")
plot!(x, label="tr", marker=2)
plot!(X.value, label="cvx")
savefig("figs/bpdn/xcomp.pdf")

plot(b0, xlabel="i^th index", ylabel="b", title="TR vs True x", label="True b")
plot!(b, label="Observed")
plot!(A*x, label="A*x: TR", marker=2)
plot!(A*X.value, label="A*x: CVX")
savefig("figs/bpdn/bcomp.pdf")
