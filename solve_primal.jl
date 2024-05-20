function compute_UB(df::DataFrame, c_ij::Matrix{Float64}, x_values::Matrix{Float64}, y_values::Vector{Float64}) 
    # model = Model(Gurobi.Optimizer)
    # N = nrow(df)
    # M = nrow(df)

    # model = Model(Gurobi.Optimizer)
    # @variable(model, x_values[i=1:N, j=1:M], Bin)
    # @variable(model, y_values[i=1:N], Bin)

    # @objective(model, Min,
    #     sum(df.fixed_cost[i] * y_values[i] for i in 1:N) +
    #     sum(c_ij[i, j] * x_values[i, j] for i in 1:N, j in 1:M)
    # )

    # optimize!(model)

    # return objective_value(model)

    N = nrow(df)
    M = nrow(df)
    objective_value = sum(df.fixed_cost[i] * y_values[i] for i in 1:N) + sum(c_ij[i, j] * x_values[i, j] for i in 1:N, j in 1:M)

    return objective_value
end


# file_path = "usa.txt"
# df, c_ij = load_data(file_path)
# compute_UB(df, c_ij)


