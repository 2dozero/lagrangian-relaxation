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
    TC = 0

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
        TC = current_cost
        Z_u = min(Z_u, current_cost)

        # Step 3: 수요 조건 확인
        if sum(df.capacity[f] for f in K) < sum(df.demand)
            println("현재 선택된 시설의 용량이 충분하지 않습니다. 다시 Step 1로 돌아갑니다.")
            continue
        else
            break
        end
    end

    # 고객 할당 및 비용 계산 (Step 4 - Step 5)
    assignments = Dict{Int, Int}()
    for j in 1:size(df, 1)
        best_i = argmin([c_ij[i, j] for i in K])
        assignments[j] = best_i
        df.capacity[best_i] -= df.demand[j]
    end

    # 할당되지 않은 시설 제거 (Step 6)
    for i in K
        if !any(assignments[j] == i for j in keys(assignments))
            delete!(K, i)
        end
    end

    if TC < Z_u
        Z_u = TC
    else
        # 마지막으로 가능한 최적 비용 계산
        TC = Z_u
    end

    return K, Z_u
end

df, c_ij = load_data("usa.txt")
K, Z_u = add_heuristic(df, c_ij)
println("Opened facilities: ", K)
println("Minimal cost Z_u: ", Z_u)
