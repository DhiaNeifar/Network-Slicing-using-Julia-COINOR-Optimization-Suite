using JuMP
using CPLEX

# Create a new model with CPLEX as the solver
model = Model(CPLEX.Optimizer)

# Define variables
@variable(model, x1 >= 0)
@variable(model, x2 >= 0)

# Define the objective function
@objective(model, Min, 1 / x1 + x2 ^2)

# Define the constraints
@constraint(model, x1 + x2 >= 1)

# Solve the model
optimize!(model)

x1_value = value(x1)
x2_value = value(x2)

println("Objective value: ", objective_value)
println("x1 value: ", x1_value)
println("x2 value: ", x2_value)
