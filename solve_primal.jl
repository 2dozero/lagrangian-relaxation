function compute_UB(df::DataFrame, c_ij::Matrix{Float64})
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

    optimize!(model)

    return objective_value(model)
end