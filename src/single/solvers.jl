"""
	solve!((sub, sup, aux)::NTuple{3, Any}, π, D_j_π, scdca::Bool; containers)
	solve!((sub, sup, aux)::NTuple{3, Any}, π, scdca::Bool)

Solve in-place a combinatorial discrete choice problem with SCD-C from above if `scdca` is `true` (otherwise, from below). The solver uses the preallocated Boolean vectors `(sub, sup, aux)` as well as the objective function `π(J)`. The objective function `π` must accept as argument a Boolean vector with length corresponding to the number of items in the problem.

The solver can optionally take `D_j_π(j, J)`, a user-supplied marginal value function; otherwise it will construct one automatically given `π`. It may also optionally take preallocated `containers = (working, converged)`, where `working` and `converged` are both `Vectors` with element type matching `(sub, sup, aux)`. These are used for the branching step and will be automatically allocated if not supplied.
"""
function solve!((sub, sup, aux)::NTuple{3, Any}, π::F, D_j_π::G, scdca::Bool; containers) where {F<:Function, G<:Function}
	fill!(sub, false)
	fill!(sup, true)
	fill!(aux, false)

	# squeeze
	converge!((sub, sup, aux), D_j_π, scdca)
	isequal(sub, sup) && return sub

	# if no convergence from squeezing, branch
	(working, converged) = containers
	empty!(working)
	append!(working, collect(branch((sub, sup, aux))))
	empty!(converged)
	converge_branches!((working, converged), D_j_π, scdca)

	# among results in converged, choose best
	i_argmax = 0
	max_prof = -Inf
	for (i, option) in enumerate(converged)
		prof = π(first(option))
		if prof > max_prof
			max_prof = prof
			i_argmax = i
		end
	end
	first(converged[i_argmax])
end
function solve!((sub, sup, aux)::NTuple{3, Any}, π::F, D_j_π::G, scdca::Bool) where {F<:Function, G<:Function}
	working = [(sub, sup, aux); ]
	converged = similar(working)

	solve!((sub, sup, aux), π, D_j(π), scdca, containers = (working, converged))
end
solve!((sub, sup, aux)::NTuple{3, Any}, π::F, scdca::Bool; containers) where F<:Function = solve!((sub, sup, aux), π, D_j(π), scdca, containers = containers)
solve!((sub, sup, aux)::NTuple{3, Any}, π::F, scdca::Bool) where F<:Function = solve!((sub, sup, aux), π, D_j(π), scdca)


"""
	solve(C::Integer, π, D_j_π, scdca::Bool; containers)
	solve(C::Integer, π, scdca::Bool; containers)
Solve a combinatorial discrete choice problem over `C` choices with SCD-C from above if `scdca` is `true` (otherwise, from below). The solver uses the objective function `π(J)`. The objective function must accept as argument a Boolean vector with length corresponding to the number of items in the problem.

The solver can optionally take `D_j_π(j, J)`, a user-supplied marginal value function; otherwise it will construct one automatically given `π`. It may also optionally take preallocated `containers = (working, converged)`, where `working` and `converged` are both `Vectors` with element type matching `(sub, sup, aux)`. These are used for the branching step and will be automatically allocated if not supplied.
"""
function solve(C::Integer, π::F, D_j_π::G, scdca::Bool; containers) where {F<:Function, G<:Function}
	sub = falses(C)
	sup = trues(C)
	aux = falses(C)
	
	solve!((sub, sup, aux), π, D_j_π, scdca, containers = containers)
end
function solve(C::Integer, π::F, D_j_π::G, scdca::Bool) where {F<:Function, G<:Function}
	sub = falses(C)
	sup = trues(C)
	aux = falses(C)
	
	solve!((sub, sup, aux), π, D_j_π, scdca)
end
solve(C::Integer, π::F, scdca::Bool; containers) where F<:Function = solve(C::Integer, π, D_j(π), scdca; containers = containers)
solve(C::Integer, π::F, scdca::Bool) where F<:Function = solve(C::Integer, π, D_j(π), scdca)
