using Gurobi
using JuMP
using DataFrames
using Plots
include("make_data.jl")
include("solve_primal.jl")
# include("add_heuristic.jl")
include("solve_lagrangian.jl")
include("update_lambda.jl")

function lagrangian_relaxation_heuristic(file_path::String)
    df, c_ij = load_data(file_path)
    # open_facilities, Z_u = add_heuristic(df, c_ij)
    Z_u = 145500.0
    UB = Z_u
    
    LB_list = Float64[]
    UB_list = Float64[]
    lambda_list = Float64[]

    push!(UB_list, UB)

    # Z_l = solve_facility_location(df, c_ij, open_facilities)
    Z_l, is_feasible, f_inf_index, x_values, y_values = compute_Z_l(df, zeros(nrow(df)), c_ij)
    LB = Z_l
    inf_indices = findall(x -> x == 0, f_inf_index)
    lambda = zeros(nrow(df))
    U = [i for i in 1:nrow(df)]

    if !is_feasible
        lambda = update_lambda(inf_indices, lambda, x_values, df, 0.0000000025, UB, LB, U)
        push!(lambda_list, sum(lambda))
    end

    i = 1
    max_iteration = 200
    old_LB = LB

    while true
        new_Z_l, is_feasible, f_inf_index, x_values, y_values = compute_Z_l(df, lambda, c_ij)
        inf_indices = findall(x -> x == 0, f_inf_index)
        if Z_l < new_Z_l
            LB = new_Z_l
        end
        if LB < old_LB
            LB = old_LB
        else
            old_LB = LB
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
            lambda = update_lambda(inf_indices, lambda, x_values, df, 0.0000000025, UB, LB, U)
            push!(lambda_list, sum(lambda))
            new_Z_l, is_feasible, f_inf_index, x_values, y_values = compute_Z_l(df, lambda, c_ij)
            
            if i == max_iteration && !is_feasible
                break
            else
                continue
            end
        end
    end

    while length(UB_list) < length(LB_list)
        push!(UB_list, UB_list[end])
    end

    # Adjust y-axis limits to a more narrow range

    p = plot(1:length(LB_list), LB_list, label="LB_list", xlab="Iteration", ylab="Value", title="Progress of LB_list and UB_list")

    # Add UB_list to the existing plot
    plot!(1:length(UB_list), UB_list, label="UB_list")
    
    # Display the plot
    display(p)

    @show UB_list
    @show LB_list

    # Step 5
    if !is_feasible
        return "Stop (no feasible solution found)"
    else
        return "Find feasible solution"
    end
end

file_path = "usa.txt"
result = lagrangian_relaxation_heuristic(file_path)
println("Result: $result")
