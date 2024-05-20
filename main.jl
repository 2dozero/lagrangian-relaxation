using Gurobi
using JuMP
using DataFrames
include("make_data.jl")
include("solve_primal.jl")
# include("add_heuristic.jl")
include("solve_lagrangian.jl")
include("update_lambda.jl")



function lagrangian_relaxation_heuristic(file_path::String)
    df, c_ij = load_data(file_path)
    # open_facilities, Z_u = add_heuristic(df, c_ij)
    Z_u = 800000.0
    UB = Z_u
    LB_list = Float64[]
    UB_list = Float64[]
    lambda_list = Float64[]

    # Z_l = solve_facility_location(df, c_ij, open_facilities)
    Z_l, is_feasible, f_inf_index, x_values, y_values = compute_Z_l(df, zeros(nrow(df)), c_ij)
    # @show f_inf_index
    LB = Z_l
    inf_indicies = findall(x -> x == 0, f_inf_index)
    lambda = zeros(nrow(df))
    # U = inf_indicies
    U = [i for i in 1:nrow(df)]
    # @show U
    # @show inf_indicies
    # @show typeof(inf_indicies)
    # @show UB, LB
    if !is_feasible
        lambda = update_lambda(inf_indicies, lambda, x_values, df, 0.000000025, UB, LB, U)
        push!(lambda_list, sum(lambda))
    end
    # @show lambda
    # if is_feasible
    #     break
    # end

    i = 1
    max_iteration = 200

    while true
        new_Z_l, is_feasible, f_inf_index, x_values, y_values = compute_Z_l(df, lambda, c_ij)
        inf_indicies = findall(x -> x == 0, f_inf_index)
        if Z_l < new_Z_l
            LB = new_Z_l
        end
        push!(LB_list, LB)

        if is_feasible
            UB_candidate = compute_UB(df, c_ij, x_values, y_values)
            if UB > UB_candidate
                UB = UB_candidate
                push!(UB_list, UB)
            end
            if UB / LB <= 1.001 # Step 4
                break
            end

        else 
            goto_step_2 = true
        end


        if goto_step_2
            i += 1

            lambda = update_lambda(inf_indicies, lambda, x_values, df, 0.000000025, UB, LB, U)
            push!(lambda_list, sum(lambda))
            new_Z_l, is_feasible, f_inf_index, x_values, y_values = compute_Z_l(df, lambda, c_ij)
            
            if i == max_iteration && !is_feasible
                break
            else
                continue
            end
        end
        # break
    end

    @show UB_list
    @show LB_list
    # @show lambda_list

    # Step 5
    if !is_feasible
        return "Stop"
    else
        return "Find"
    end

end

file_path = "usa.txt"

lagrangian_relaxation_heuristic(file_path)


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
