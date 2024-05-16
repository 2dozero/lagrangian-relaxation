using JuMP
using Gurobi
using DataFrames

# Lagrangian Heuristic을 사용하는 함수
function compute_Z_l(df::DataFrame, λ::Vector{Float64}, c_ij::Matrix{Float64})
    model = Model(Gurobi.Optimizer)
    N = nrow(df)
    M = nrow(df)

    model = Model(Gurobi.Optimizer)
    @variable(model, x[i=1:N, j=1:M], Bin)
    @variable(model, y[i=1:N], Bin)

    @objective(model, Min,
        sum(df.fixed_cost[i] * y[i] for i in 1:N) +
        sum((c_ij[i, j] + λ[i] * df.demand[j]) * x[i, j] for i in 1:N, j in 1:M) -
        sum(λ[i] * df.capacity[i] for i in 1:N)
    )

    # @constraint(model, [i=1:N], sum(df.demand[j] * x[i, j] for j in 1:M) <= df.capacity[i] * y[i])
    @constraint(model, [j=1:M], sum(x[i, j] for i in 1:N) == 1)
    @constraint(model, [i=1:N, j=1:M], x[i, j] <= y[i])

    optimize!(model)

    if termination_status(model) != MOI.OPTIMAL
        println("The model is infeasible or unbounded.")
        return Inf
    end

    feasible_for_1 = true
    f_inf_index = ones(Int, N)
    # @show f_inf_index
    for i in 1:N
        if sum(df.demand[j] * value(x[i, j]) for j in 1:M) > df.capacity[i] * value(y[i])
            f_inf_index[i] = 0
        end
    end
    if sum(f_inf_index) != N
        feasible_for_1 = false
    end
    # @show f_inf_index
    return objective_value(model), feasible_for_1, f_inf_index, value.(x)
end

# df, c_ij = load_data("usa.txt")
# Z_l, is_feasible, f_inf_index, x_values = compute_Z_l(df, zeros(nrow(df)), c_ij)