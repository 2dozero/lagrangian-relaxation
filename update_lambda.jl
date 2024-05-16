# include("main.jl")

# step0 #
function update_lambda(inf_indicies::Vector{Int64}, lambda::Vector{Float64}, x_values::Matrix{Float64}, df::DataFrame, 
    w::Float64, Z_u::Float64, Z_l::Float64, U::Vector{Int})
    norm_violations = sqrt(sum((sum(df.demand[j] * x_values[i, j] for j=1:size(x_values, 2)) - df.capacity[i])^2 for i in U))

    new_lambda = zeros(size(lambda))

    # Processing each lambda based on its marking status
    for i in U
        violation_i = sum(df.demand[j] * x_values[i, j] for j=1:size(x_values, 2)) - df.capacity[i]
        lambda_update = (w * (Z_u - Z_l) * violation_i) / norm_violations
        lambda_update += lambda[i]

        new_lambda[i] = max(0, lambda_update)
    end

    return new_lambda

end