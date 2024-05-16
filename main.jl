using Gurobi
using JuMP
using DataFrames
include("make_data.jl")
# include("add_heuristic.jl")
include("solve_lagrangian.jl")
include("update_lambda.jl")

# 전체 Step 0 함수
function step0(file_path::String)
    df, c_ij = load_data(file_path)
    # open_facilities, Z_u = add_heuristic(df, c_ij)
    Z_u = 500000.0
    UB = Z_u

    # Z_l = solve_facility_location(df, c_ij, open_facilities)
    Z_l, is_feasible, f_inf_index, x_values = compute_Z_l(df, zeros(nrow(df)), c_ij)
    LB = Z_l
    inf_indicies = findall(x -> x == 0, f_inf_index)
    lambda = zeros(nrow(df))
    U = inf_indicies
    @show lambda
    @show typeof(lambda)
    @show inf_indicies
    @show typeof(inf_indicies)
    ### Step0 ###
    println("Initial Z^u: ", Z_u)
    println("Optimal Z^l: ", Z_l)
    if !is_feasible
        lambda = update_lambda(inf_indicies, lambda, x_values, df, 0.00000025, Z_u, Z_l, U)
    end

    max_iterations = 200
    iteration = 0
    while iteration < max_iterations
        iteration += 1
        Z_l_, is_feasible, f_inf_index, x_values = compute_Z_l(df, lambda, c_ij)
        
        if Z_l < Z_l_
            LB = Z_l_
        end

        if is_feasible
            UB_candidate = compute_UB(df, c_ij)
            if Z_u > UB_candidate
                UB = UB_candidate
            end
            if Z_u / Z_l <= 1.001
                break
            end
        end

        if iteration >= max_iterations
            println("max iteration")
            break
        end

        lambda = update_lambda(inf_indicies, lambda, x_values, df, 0.00000025, Z_u, Z_l, U)

    end
end

# usa.txt 파일 경로
file_path = "usa.txt"

# Step 0 실행
step0(file_path)


# struct Parameters
#     df::DataFrame
#     U::Vector{Int}
#     w::Float64
#     c_ij::Matrix{Float64}
#     Z_u::Float64
#     Z_l::Float64
#     λ::Vector{Float64}
#     # x_values::Matrix{Float64}
# end
