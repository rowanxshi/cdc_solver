"""
	policy(C::Integer, π, zero_D_j_π, equalise_π, scdca::Bool)
	policy(C::Integer, π, equalise_π, scdca::Bool)
Find the policy function for a combinatorial discrete choice problem over `C` choices and one dimension of heterogeneity with SCD-C from above if `scdca` is `true` (otherwise, from below) and SCD-T. The solver uses the objective function `π(J, z)`, which must accept as argument a Boolean vector with length `C` and the heterogeneous component `z`; the *optional* `zero_D_j_π(j, J)` function, which identifies the `z` where the marginal value of item `j` to set `J` is zero; and the `equalise_π((J1, J2))` function, which identifies the `z` where the agent is indifferent between the pair `(J1, J2)`.

If the `zero_D_j_π` function is not provided, the solver automatically constructs one using the `equalise_π` function.
"""
function policy(C::Integer, π, zero_D_j_π, equalise_π, scdca::Bool)
	sub = falses(C)
	sup = trues(C)
	aux = falses(C)
	emptyset = falses(C)
	int = interval(sub, sup, aux, -Inf, Inf)
	working = Vector{interval}(undef, 0)
	converged = similar(working)
	done = similar(working)
	memo = Dict{Tuple{typeof(1), typeof(sub)}, typeof(Inf)}()
	
	# initial converge
	push!(working, int)
	converge!((working, converged), zero_D_j_π, scdca, memo, emptyset)
	
	# branch if necessary: local optimal stored in done
	converge_branches!((working, converged, done), zero_D_j_π, scdca, memo, emptyset)
	
	# brute force among local optima; final policy function stored in converged
	brute((working, converged, done), π, equalise_π, scdca::Bool)
end
function policy(C::Integer, π, equalise_π, scdca::Bool)
	holder = falses(C)
	function zero_D_j_π(j::Integer, J::AbstractVector{Bool})
		holder .= J
		bool_j = J[j]
		J[j] = true
		holder[j] = false
		z = equalise_π((J, holder))
		J[j] = bool_j
		return z
	end
	
	policy(C, π, zero_D_j_π, equalise_π, scdca::Bool)
end
