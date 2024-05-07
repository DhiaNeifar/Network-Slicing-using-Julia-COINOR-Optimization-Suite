using JuMP, AmplNLWriter, HiGHS, Couenne_jll, Bonmin_jll, MathOptInterface
const MOI = MathOptInterface


include("physical_substrate.jl")
include("slice_instantiation.jl")


function network_slicing(number_slices, total_number_centers, total_available_cpus, total_available_bandwidth, edges_delay, number_VNFs, required_cpus, required_bandwidth, delay_tolerance)
    
    model = Model(HiGHS.Optimizer)

    VNFs_placements = Array{VariableRef, 3}(undef, number_slices, number_VNFs, total_number_centers)
    for s in 1: number_slices
        for c in 1: total_number_centers
            for k in 1: number_VNFs
                VNFs_placements[s, k, c] = @variable(model, base_name="slice_$(s)_center_$(c)_VNF_$(k)", binary=true)
            end
        end
    end
    Virtual_links = Array{VariableRef, 4}(undef, number_slices, number_VNFs - 1, total_number_centers, total_number_centers)
    for s in 1: number_slices
        for k in 1: number_VNFs - 1
            for i in 1: total_number_centers
                for j in 1: total_number_centers
                    Virtual_links[s, k, i, j] = @variable(model, base_name="slice_$(s)_VL$(k)_to_VL$(k + 1)_PN$(i)_to_PN$(j)", binary=true)
                end
            end
        end
    end

    @objective(model, Min, sum(Virtual_links[s, k, i, j] * (edges_delay[i, j] + required_bandwidth[s, k]) for s in 1: number_slices for k in 1: number_VNFs - 1 for i in 1: total_number_centers for j in 1: total_number_centers))
    
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
            @constraint(model, sum(VNFs_placements[s, k, c] for k in 1: number_VNFs) <= ceil(div(number_VNFs, max(1, (total_number_centers - 1)))) + 1)
        end
    end
    # Constraint 3: Guarantee that allocated VNF resources do not exceed physical servers' processing capacity.
    for c in 1: total_number_centers
        @constraint(model, sum(VNFs_placements[s, k, c] * required_cpus[s, k] for s in 1: number_slices, k in 1: number_VNFs) <= total_available_cpus[c])
    end

    # Link Embedding Constraints
    # Constraint 1: Virtual links can only be mapped to existing physical Virtual_links
    for s in 1: number_slices
        for i in 1: total_number_centers
            for k in 1: number_VNFs - 1
                @constraint(model, sum(Virtual_links[s, k, i, j] - Virtual_links[s, k, j, i] for j in 1: total_number_centers) == 
                VNFs_placements[s, k, i] - VNFs_placements[s, k + 1, i])
            end
        end
    end

    # Constraint 2: Flow Conservation Constraint
    for i in 1: total_number_centers
        for j in 1: total_number_centers
            @constraint(model, sum(Virtual_links[s, k, i, j] * required_bandwidth[s, k] for s in 1: number_slices for k in 1: number_VNFs - 1) <= total_available_bandwidth[i, j])
        end
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

end

number_node = 8
total_number_centers, total_available_cpus, longitude, latitude, edges_adjacency_matrix, total_available_bandwidth, edges_delay = physical_substrate(number_node)


number_slices = 5
number_VNFs = 6

required_cpus, required_bandwidth, delay_tolerance = slice_instantiation(number_slices, number_VNFs)


network_slicing(number_slices, total_number_centers, total_available_cpus, total_available_bandwidth, edges_delay, number_VNFs, required_cpus, required_bandwidth, delay_tolerance)   

