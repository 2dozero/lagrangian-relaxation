using DataFrames

function add_heuristic(df::DataFrame, c_ij::Matrix{Float64})
    N = nrow(df)
    M = nrow(df)
    x = zeros(Int, N, M)
    y = zeros(Int, N)

    # Add heuristic to find an initial feasible solution
    K = []
    for i in 1:N
        push!(K, i)
        y[i] = 1
        if sum(df.capacity[i] for i in K) >= sum(df.demand)
            break
        end
    end

    for j in 1:M
        min_cost = Inf
        min_i = -1
        for i in K
            if df.capacity[i] >= df.demand[j] && c_ij[i, j] < min_cost
                min_cost = c_ij[i, j]
                min_i = i
            end
        end
        if min_i != -1
            x[min_i, j] = 1
            df.capacity[min_i] -= df.demand[j]
        else
            return false, x, y
        end
    end

    return true, x, y
end
