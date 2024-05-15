mutable struct LambdaTracker
    lambda::Vector{Float64}
    marked::Vector{Bool}  # Track whether each lambda is marked
end

function update_lambda_with_marks!(tracker::LambdaTracker, x_values::Matrix{Float64}, df::DataFrame, 
                                   w::Float64, Z_u::Float64, Z_l::Float64, U::Vector{Int})

    norm_violations = sqrt(sum((sum(df.demand[j] * x_values[i, j] for j=1:size(x_values, 2)) - df.capacity[i])^2 for i in U))

    # Processing each lambda based on its marking status
    for i in U
        violation_i = sum(df.demand[j] * x_values[i, j] for j=1:size(x_values, 2)) - df.capacity[i]
        lambda_update = (w * (Z_u - Z_l) * violation_i) / norm_violations

        # Determine the new potential value of lambda
        new_lambda = tracker.lambda[i] + lambda_update

        # Apply marking logic to handle increases and decreases
        if tracker.marked[i] && lambda_update < 0
            # Prevent decrease if previously marked
            new_lambda = tracker.lambda[i]
        else
            # Allow increase and mark this lambda
            tracker.marked[i] = lambda_update > 0
        end

        # Ensure lambda is non-negative
        tracker.lambda[i] = max(new_lambda, 0)
    end

end

function unmark_all!(tracker::LambdaTracker)
    fill!(tracker.marked, false)  # Unmark all multipliers to allow decreasing again
end
