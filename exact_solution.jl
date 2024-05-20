using JuMP
using Gurobi
using DataFrames


function compute_exact(df::DataFrame, c_ij::Matrix{Float64})
    model = Model(Gurobi.Optimizer)
    N = nrow(df)
    M = nrow(df)

    model = Model(Gurobi.Optimizer)
    @variable(model, x[i=1:N, j=1:M], Bin)
    @variable(model, y[i=1:N], Bin)

    @objective(model, Min,
        sum(df.fixed_cost[i] * y[i] for i in 1:N) +
        sum(c_ij[i, j] * x[i, j] for i in 1:N, j in 1:M)
    )

    @constraint(model, [i=1:N], sum(df.demand[j] * x[i, j] for j in 1:M) <= df.capacity[i])
    @constraint(model, [j=1:M], sum(x[i, j] for i in 1:N) == 1)
    @constraint(model, [i=1:N, j=1:M], x[i, j] <= y[i])

    optimize!(model)

    if termination_status(model) != MOI.OPTIMAL
        println("The model is infeasible or unbounded.")
        return Inf
    end

    return objective_value(model)
end


file_path = "usa.txt"
df, c_ij = load_data(file_path)
compute_exact(df, c_ij)