using JuMP, AmplNLWriter, Ipopt, MathOptInterface
const MOI = MathOptInterface


include("physical_substrate.jl")
include("slice_instantiation.jl")
include("utils.jl")

function network_slicing(number_slices, number_VNFs, total_number_centers, total_available_cpus, required_cpus)   
    
    model = Model(Ipopt.Optimizer)

    VNFs_placements = Array{VariableRef, 3}(undef, number_slices, number_VNFs, total_number_centers)
    for s in 1: number_slices
        for c in 1: total_number_centers
            for k in 1: number_VNFs
                VNFs_placements[s, k, c] = @variable(model, base_name="slice_$(s)_center_$(c)_VNF_$(k)", lower_bound=0, upper_bound=1)
            end
        end
    end
    assigned_cpus = Array{VariableRef, 2}(undef, number_slices, number_VNFs)
    for s in 1: number_slices
        for k in 1: number_VNFs
            assigned_cpus[s, k] = @variable(model, base_name="assigned_cpus_slice_$(s)_VNF_$(k)", lower_bound=0, upper_bound=required_cpus[s, k])
        end
    end
    @objective(model, Max, sum(log(1 + (assigned_cpus[s, k] * VNFs_placements[s, k, c]) / required_cpus[s, k]) - (sin(VNFs_placements[s, k, c] * pi) * (number_slices * number_VNFs)) for s in 1: number_slices for k in 1: number_VNFs for c in 1: total_number_centers))
    
    # Constraints

    # Node Embedding Constraints
    # Constraint 1: Each VNF is assigned only once to a center.
    for s in 1: number_slices
        for k in 1: number_VNFs
            @constraint(model, sum(VNFs_placements[s, k, c] for c in 1:total_number_centers) == 1)
        end
    end
    
    # Constraint 2: Each VNF is assigned to an exactly one center.
    for s in 1: number_slices
        for c in 1: total_number_centers
            @constraint(model, sum(VNFs_placements[s, k, c] for k in 1: number_VNFs) <= 1)
        end
    end
    # Constraint 3: Guarantee that allocated VNF resources do not exceed physical servers' processing capacity.
    for c in 1: total_number_centers
        @constraint(model, sum(VNFs_placements[s, k, c] * assigned_cpus[s, k] for s in 1: number_slices, k in 1: number_VNFs) <= total_available_cpus[c])
    end

    # Solve the problem
    optimize!(model)
    status = termination_status(model)
    if status == MOI.OPTIMAL
        println("An optimal solution has been found!")
    elseif status == MOI.INFEASIBLE
        println("The problem is infeasible.")
    else
        println("The solver stopped with status: $status")
    end

    # Extract Results Values
    vnf_placement_values = Array{Int, 3}(undef, number_slices, number_VNFs, total_number_centers)
    for s in 1: number_slices
        for k in 1: number_VNFs
            for c in 1: total_number_centers
                if value(VNFs_placements[s, k, c]) > 0.5
                    vnf_placement_values[s, k, c] = 1
                else
                    vnf_placement_values[s, k, c] = 0
                end 
            end
        end
    end

    assigned_cpus_values = Array{Float32, 2}(undef, number_slices, number_VNFs)
    for s in 1: number_slices
        for k in 1: number_VNFs
            assigned_cpus_values[s, k] = value(assigned_cpus[s, k])
        end
    end
    return vnf_placement_values, assigned_cpus_values
end

number_node = 10
total_number_centers, total_available_cpus, _, _, _, _, _ = physical_substrate(number_node)


number_slices = 7
number_VNFs = 8

required_cpus, _, _ = slice_instantiation(number_slices, number_VNFs)



vnf_placement_values, assigned_cpus_values = network_slicing(number_slices, number_VNFs, total_number_centers, total_available_cpus, required_cpus)

println(required_cpus)
println(assigned_cpus_values)
display_solution(vnf_placement_values)
