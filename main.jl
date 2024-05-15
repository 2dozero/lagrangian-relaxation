using Gurobi
using JuMP
using DataFrames
include("make_data.jl")
include("add_heuristic.jl")
include("solve_lagrangian.jl")

# 전체 Step 0 함수
function step0(file_path::String)
    df, c_ij = load_data(file_path)
    open_facilities, Z_u = add_heuristic(df, c_ij)
    if isempty(open_facilities)
        println("No facilities could be opened.")
        return
    end
    # Z_l = solve_facility_location(df, c_ij, open_facilities)
    Z_l, is_feasible, f_inf_index = compute_Z_l(df, zeros(nrow(df)), c_ij)
    inf_indicies = findall(x -> x == 0, f_inf_index)
    @show inf_indicies
    
    

    # println("Open facilities: ", open_facilities)
    println("Initial Z^u: ", Z_u)
    println("Optimal Z^l: ", Z_l)
    println("feasibility check : ", is_feasible)
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
