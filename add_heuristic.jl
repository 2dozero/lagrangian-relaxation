using DataFrames

# 초기 데이터 로드 함수 (make_data.jl에서 제공된 함수 사용)
include("make_data.jl")

function calculate_savings(i, K, df, c_ij)
    if isempty(K)
        return -df.fixed_cost[i]
    end

    # 모든 선택된 시설과의 비용 차이 계산
    w_ij = [maximum([c_ij[k, j] - c_ij[i, j] for k in K]; init=0) for j in 1:size(c_ij, 2)]
    Ω_i = sum(w_ij)
    total_demand = sum(df.demand)
    # 비용 절감 계산
    potential_savings = Ω_i * min(df.capacity[i] / total_demand, 1) - df.fixed_cost[i]
    return potential_savings
end

function add_heuristic(df::DataFrame, c_ij::Matrix{Float64})
    K = Set{Int}()
    Z_u = Inf  # 최적 비용을 무한대로 초기화

    while true
        R = Dict{Int, Float64}()

        for i in 1:size(df, 1)
            if !(i in K)
                R[i] = calculate_savings(i, K, df, c_ij)
            end
        end

        if isempty(R)
            println("더 이상 고려할 시설이 없습니다.")
            break
        end

        # 최적의 시설과 R 값 추출
        max_value, best_facility = findmax(R)
        if best_facility < 1 || best_facility > size(df, 1)
            println("잘못된 시설 번호입니다: $(best_facility)")
            break
        end

        push!(K, best_facility)
        current_cost = sum(df.fixed_cost[f] for f in K)
        Z_u = min(Z_u, current_cost)

        if sum(df.capacity[f] for f in K) >= sum(df.demand)
            println("수요를 충족하는데 필요한 용량이 확보되었습니다.")
            break
        end
    end

    # Step 4: 각 고객 j에 대해, K 내에서 최상의 할당과 두 번째 할당 간의 비용 차이를 계산
    cost_differential = Dict{Int, Float64}()
    for j in 1:size(df, 1)
        best_cost = Inf
        second_best_cost = Inf
        for i in K
            if c_ij[i, j] < best_cost
                second_best_cost = best_cost
                best_cost = c_ij[i, j]
            elseif c_ij[i, j] < second_best_cost
                second_best_cost = c_ij[i, j]
            end
        end
        cost_differential[j] = second_best_cost - best_cost
    end

    # Step 5: 각 고객을 비용 차이가 가장 큰 순서대로 정렬하고, 최소 비용 할당을 가진 열린 시설에 할당
    sorted_customers = sort(collect(keys(cost_differential)), by=x->cost_differential[x], rev=true)
    for j in sorted_customers
        for i in K
            if df.capacity[i] >= df.demand[j]
                df.capacity[i] -= df.demand[j]
                break
            end
        end
    end

    # Step 6: 고객이 할당되지 않은 시설을 제거
    assigned_facilities = Set{Int}()
    for j in 1:size(df, 1)
        best_i = argmin([c_ij[i, j] for i in K])
        push!(assigned_facilities, best_i)
    end
    K = intersect(K, assigned_facilities)

    return K, Z_u
end

df, c_ij = load_data("usa.txt")
K, Z_u = add_heuristic(df, c_ij)
println("Opened facilities: ", K)
println("Minimal cost Z_u: ", Z_u)
