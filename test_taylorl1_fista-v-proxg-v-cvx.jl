# Julia Testing function
# Generate Compressive Sensing Data
using TRNC, Plots,Printf, Convex,SCS, Random, LinearAlgebra, IterativeSolvers

#Here we just try to solve an easy example
#######
# min_s ||As - b||^2 + λ||s||_1
compound=1
m,n = compound*120,compound*512
p = randperm(n)
k = compound*20
#initialize x
x0 = zeros(n,)
c = randn(n,)
x0[p[1:k]]=sign.(randn(k))

A,_ = qr(randn(n,m))
B = Matrix(A')
b0 = B*x0
b = b0 + 0.001*rand(n,)
λ = .1*maximum(abs.(B'*b))
g = -2*B'*b



S = Variable(n)
problem = minimize(sumsquares(B*S) + g'*S + b'*b + λ*norm(vec(S+c), 1))
solve!(problem, SCSSolver())

function proxp(z, α)
    n = length(z)
    temp = zeros(n)
    for i=1:n
        z[i]< α ? temp[i] = z[i] - α
        z[i]>-α ? temp[i] = z[i] + α: continue
    # return sign.(z).*max(abs.(z).-(α)*ones(size(z)), zeros(size(z)))
    return temp
end

function funcF(z)
    f = b'*b +g'*(z-c) + (z-c)'*B'*B*(z-c)
    grad = g + B'*B*(z-c)
    return f, grad
end

#input β, λ
pg_options=s_options(norm(B)^2; maxIter=10000, verbose=1, λ=λ, optTol=1e-6)
sp = zeros(n)
up, hispg, fevalpg = PG(funcF, sp, proxp,pg_options)
sp = up-c

fista_options=s_options(norm(B)^2; maxIter=10000, verbose=5, λ=λ, optTol=1e-6)
sf = randn(n)
uf, hisf, fevalpg = FISTA(funcF, sf, proxp,pg_options)
sf = uf - c
@printf("PG l2-norm CVX: %5.5e\n", norm(S.value - sp)/norm(S.value))
@printf("FISTA l2-norm CVX: %5.5e\n", norm(S.value - sf)/norm(S.value))
@printf("CVX: %5.5e     PG: %5.5e   FISTA: %5.5e\n", norm(B*S.value)^2 + λ*norm(vec(S.value),1), funcF(sp+c)[1]+λ*norm(sp+c,1), funcF(sf+c)[1]+λ*norm(sf+c,1))
@printf("True l2-norm CVX: %5.5e\n", norm(S.value - x0)/norm(x0))
@printf("True l2-norm PG: %5.5e\n", norm(sp - x0)/norm(x0))
@printf("True l2-norm FISTA: %5.5e\n", norm(sf - x0)/norm(x0))
