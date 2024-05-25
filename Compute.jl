using JuMP
using HiGHS  # or any other solver you prefer

# Create a model
model = Model(HiGHS.Optimizer)

# Define variables
@variable(model, x >= 0)
@variable(model, y >= 0)

# Define constraints in a loop and store them in a dictionary
constraints = Dict{String, ConstraintRef}()
for i in 1:5
    con_name = "con_$i"
    constraints[con_name] = @constraint(model, 2 * i * x + i * y <= 10)
end

# Define the objective
@objective(model, Max, x + y)

# Solve the model
optimize!(model)

# Retrieve the Lagrangian multipliers (dual values) and save them in a list
λ = []
for i in 1:5
    con_name = "con_$i"
    push!(λ, dual(constraints[con_name]))
end

# Print the list of Lagrangian multipliers
println("Lagrangian multipliers: ", λ)
