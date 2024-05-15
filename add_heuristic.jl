using DataFrames

# 초기 데이터 로드 함수 (make_data.jl에서 제공된 함수 사용)
include("make_data.jl")

function calculate_savings(i, K, df, c_ij)
    if isempty(K)
        return -df.fixed_cost[i]  # 시설이 하나도 열리지 않았다면, 음의 고정 비용 반환
    end

    # w_ij 계산: 선택된 시설들과의 비용 차이를 기반으로
    w_ij = [maximum([c_ij[k, j] - c_ij[i, j] for k in K]; init=0) for j in 1:size(c_ij, 2)]
    Ω_i = sum(w_ij)
    # 비용 절감 계산: 시설 용량을 고려하여 수정
    total_demand = sum(df.demand; init=0)
    potential_savings = Ω_i * min(df.capacity[i] / total_demand, 1) - df.fixed_cost[i]
    return potential_savings
end

function add_heuristic(df::DataFrame, c_ij::Matrix{Float64})
    K = Set{Int}()
    Z_u = Inf  # 최적 비용을 무한대로 초기화
    # @show size(df, 1)
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
        current_cost = sum(df.fixed_cost[f] for f in K; init=0)
        Z_u = min(Z_u, current_cost)

        if sum(df.capacity[f] for f in K; init=0) >= sum(df.demand; init=0)
            println("수요를 충족하는데 필요한 용량이 확보되었습니다.")
            break
        end
    end

    return K, Z_u
end

df, c_ij = load_data("usa.txt")
K, Z_u = add_heuristic(df, c_ij)
println("Opened facilities: ", K)
println("Minimal cost Z_u : ", Z_u)
