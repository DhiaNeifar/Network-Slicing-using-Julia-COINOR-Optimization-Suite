using JuMP, AmplNLWriter, Ipopt, MathOptInterface


function elastic_resource_management(number_slices, number_nodes, nodes_state, total_cpus_clocks, total_throughput, number_VNFs, number_cycles, traffic, VNFs_placements, Virtual_links, β)
    
    model = Model(Ipopt.Optimizer)
    set_silent(model)
    clocks = Array{VariableRef, 2}(undef, number_slices, number_VNFs)
    for s in 1: number_slices
        for k in 1: number_VNFs
            clocks[s, k] = @variable(model, base_name="clocks_slice_$(s)_VNF_$(k)", lower_bound=0)
        end
    end
    throughput = Array{VariableRef, 2}(undef, number_slices, number_VNFs - 1)
    for s in 1: number_slices
        for k in 1: number_VNFs - 1
            throughput[s, k] = @variable(model, base_name="throughput_slice_$(s)_VL$(k)_to_VL$(k + 1)", lower_bound=0)
        end
    end

    @objective(model, Min, sum(objective_function(s, number_nodes, number_VNFs, number_cycles, traffic, clocks, throughput, VNFs_placements, Virtual_links, β) for s in 1: number_slices)) 
    
    # Constraints
    constraints = Dict{String, ConstraintRef}()
    # Node Embedding Constraints
    # Constraint 1: Guarantee that allocated VNF resources do not exceed physical servers' processing capacity.
    for c in 1: number_nodes
        con_name = "Node$(c)_constraint"
        constraints[con_name] = @constraint(model, sum(VNFs_placements[s, k, c] * clocks[s, k] for s in 1: number_slices, k in 1: number_VNFs) <= total_cpus_clocks[c] * nodes_state[c])
    end

    # Link Embedding Constraints
    # Constraint 1: Guarantee that allocated throughput resources do not exceed physical links' throughput capacity.
    for i in 1: number_nodes
        for j in 1: number_nodes
            con_name = "Link($(i), $(j))_constraint"
            constraints[con_name] = @constraint(model, sum(Virtual_links[s, k, i, j] * throughput[s, k] for s in 1: number_slices, k in 1: number_VNFs - 1) <= total_throughput[i, j])
        end
    end

    # Solve the problem
    optimize!(model)


    # Extract Results Values
    clocks_values = Array{Float32, 2}(undef, number_slices, number_VNFs)
    for s in 1: number_slices
        for k in 1: number_VNFs
            if value(clocks[s, k]) < 0
                clocks_values[s, k] = 0
            else
                clocks_values[s, k] = value(clocks[s, k])
            end
        end
    end
    throughput_values = Array{Float32, 2}(undef, number_slices, number_VNFs - 1)
    for s in 1: number_slices
        for k in 1: number_VNFs - 1
            if value(throughput[s, k]) < 0
                throughput_values[s, k] = 0
            else
                throughput_values[s, k] = value(throughput[s, k])
            end
        end
    end
    return objective_value(model), clocks_values, throughput_values
end