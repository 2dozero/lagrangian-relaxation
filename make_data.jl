using DataFrames

# Haversine 공식을 사용하여 두 지점 사이의 거리를 계산하는 함수
function haversine(lat1, lon1, lat2, lon2)
    r = 6371  # 지구의 반지름 (킬로미터)
    dlat = deg2rad(lat2 - lat1)
    dlon = deg2rad(lat2 - lon1)
    a = sin(dlat / 2)^2 + cos(deg2rad(lat1)) * cos(deg2rad(lat2)) * sin(dlon / 2)^2
    c = 2 * atan(sqrt(a), sqrt(1 - a))
    return r * c
end

# 데이터를 파일에서 읽고, c_ij 값을 계산하는 함수
function load_data(file_path::String)
    file = open(file_path, "r")
    data = []

    # 정규 표현식을 사용하여 데이터 추출
    regex = r"(\d+)\s+(\d+\.\d+)\s+(\d+\.\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+<(.+)>"

    for line in eachline(file)
        match = Base.match(regex, line)
        if match !== nothing
            push!(data, (parse(Int, match[1]), parse(Float64, match[2]), parse(Float64, match[3]), parse(Int, match[4]), parse(Int, match[5]), parse(Int, match[6]), match[7]))
        end
    end

    close(file)

    # 데이터프레임으로 변환
    df = DataFrame(data, [:index, :longitude, :latitude, :demand, :fixed_cost, :capacity, :location])

    # c_ij 값을 계산
    c_ij = [haversine(df.latitude[i], df.longitude[i], df.latitude[j], df.longitude[j]) for i in 1:nrow(df), j in 1:nrow(df)]

    return df, c_ij
end
