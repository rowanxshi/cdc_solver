import Test, Random, CDCP

Test.@testset begin

function test_single(C::Integer = 5, z::Real = 1.; scdca::Bool = true)
	sub = falses(C)
	sup = trues(C)
	aux = falses(C)
	
	working = [(sub, sup, aux); ]
	converged = similar(working)
	Random.seed!(1)
	var = rand(C)
	function π(J::BitVector)
		δ = scdca ? 0.25 : 1.1
		f = range(0.1, length = C, step = 0.1)
		
		profits = z*sum(c -> J[c]*var[c], 1:C)^δ - sum(c -> J[c]*f[c], 1:C)
	end
	
	CDCP.solve!((sub, sup, aux), π, scdca)
	CDCP.solve!((sub, sup, aux), π, scdca, containers = (working, converged))

	CDCP.solve(C, π, scdca)
	CDCP.solve(C, π, scdca, containers = (working, converged))
end

Test.@test typeof(test_single(5)) <: AbstractVector{Bool}

function test_policy(C::Integer = 5, scdca::Bool = true)
	Random.seed!(1)
	var = rand(C)
	function π(J::AbstractVector{Bool}, z::Real)
		δ = scdca ? 0.25 : 1.1
		f = range(0.1, length = C, step = 0.1)
		
		profits = z*sum(c -> J[c]*var[c], 1:C)^δ - sum(c -> J[c]*f[c], 1:C)
	end
	function zero_D_j_π(j::Integer, J::AbstractVector{Bool})
		δ = scdca ? 0.25 : 1.1
		f = range(0.1, length = C, step = 0.1)
		
		bool_j = J[j]
		J[j] = true
		z = sum(c -> J[c]*var[c], 1:C)^δ
		J[j] = false
		z -= sum(c -> J[c]*var[c], 1:C)^δ
		J[j] = bool_j
		z = f[j]/z
	end
	function equalise_π((J1, J2))
		δ = scdca ? 0.25 : 1.1
		f = range(0.1, length = C, step = 0.1)
		
		z = sum(c -> J1[c]*var[c], 1:C)^δ - sum(c -> J2[c]*var[c], 1:C)^δ
		z = sum(c -> (J1[c] - J2[c])*f[c], 1:C)/z
	end
	
	CDCP.policy(C, π,  equalise_π, scdca)
end

(cutoffs, policies) = test_policy(15)
Test.@test typeof(cutoffs) == Vector{Float64}
Test.@test typeof(policies) == Vector{BitVector}

end
