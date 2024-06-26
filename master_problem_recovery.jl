using JuMP, AmplNLWriter, HiGHS, MathOptInterface


function master_problem_recovery(number_slices, number_nodes, nodes_state, total_cpus_clocks, adjacency_matrix, total_throughput, number_VNFs, number_cycles, traffic, Clocks, Throughputs, Recovery_states, lambdas, β, nodes_recovery_resources, node_recovery_requirements, θ)
    model = Model(HiGHS.Optimizer)
    set_silent(model)
    mu = @variable(model, base_name="auxiliary_variable")
    VNFs_placements = Array{VariableRef, 3}(undef, number_slices, number_VNFs, number_nodes)
    for s in 1: number_slices
        for k in 1: number_VNFs
            for c in 1: number_nodes
                VNFs_placements[s, k, c] = @variable(model, base_name="slice_$(s)_center_$(c)_VNF_$(k)", binary=true)
            end
        end
    end
    Virtual_links = Array{VariableRef, 4}(undef, number_slices, number_VNFs - 1, number_nodes, number_nodes)
    for s in 1: number_slices
        for k in 1: number_VNFs - 1
            for i in 1: number_nodes
                for j in 1: number_nodes
                    Virtual_links[s, k, i, j] = @variable(model, base_name="slice_$(s)_VL$(k)_to_VL$(k + 1)_PN$(i)_to_PN$(j)", binary=true)
                    if adjacency_matrix[i, j] == 0
                        fix(Virtual_links[s, k, i, j], 0.0)
                    end
                end
            end
        end
    end

    @objective(model, Min, mu)
    
    # Constraints
    for (index, clocks) in enumerate(Clocks)
        throughput = Throughputs[index]
        λ = lambdas[index]
        recovery_states = Recovery_states[index]
        @constraint(model, recovery_master_objective_function(number_slices, number_nodes, nodes_state, total_cpus_clocks, total_throughput, number_VNFs, number_cycles, traffic, clocks, throughput, VNFs_placements, Virtual_links, λ, β, recovery_states, nodes_recovery_resources, node_recovery_requirements, θ) <= mu)
    end

    # Node Embedding Constraints
    # Constraint 1: Each VNF is assigned only once to a center.
    for s in 1: number_slices
        for k in 1: number_VNFs
            @constraint(model, sum(VNFs_placements[s, k, c] for c in 1:number_nodes) == 1)
        end
    end
    
    # Constraint 2: Each VNF is assigned to an exactly one center.
    for s in 1: number_slices
        for c in 1: number_nodes
            @constraint(model, sum(VNFs_placements[s, k, c] for k in 1: number_VNFs) <= 1)
        end
    end

    # Link Embedding Constraints
    # Constraint 1: Flow Conservation Constraint
    for s in 1: number_slices
        for i in 1: number_nodes
            for k in 1: number_VNFs - 1
                @constraint(model, sum(Virtual_links[s, k, i, j] for j in 1: number_nodes if adjacency_matrix[i, j] == 1) - 
                sum(Virtual_links[s, k, j, i] for j in 1: number_nodes if adjacency_matrix[i, j] == 1) == VNFs_placements[s, k, i] - VNFs_placements[s, k + 1, i])
            end
        end
    end

    # Solve the problem
    optimize!(model)

    # Extract Results Values
    vnf_placement_values = Array{Int, 3}(undef, number_slices, number_VNFs, number_nodes)
    for s in 1: number_slices
        for k in 1: number_VNFs
            for c in 1: number_nodes
                if value(VNFs_placements[s, k, c]) > 0.5
                    vnf_placement_values[s, k, c] = 1
                else
                    vnf_placement_values[s, k, c] = 0
                end 
            end
        end
    end
    virtual_link_values = Array{Int, 4}(undef, number_slices, number_VNFs - 1, number_nodes, number_nodes)
    for s in 1: number_slices
        for k in 1: (number_VNFs - 1)
            for i in 1: number_nodes
                for j in 1: number_nodes
                    if value(Virtual_links[s, k, i, j]) > 0.5
                        virtual_link_values[s, k, i, j] = 1
                    else 
                        virtual_link_values[s, k, i, j] = 0
                    end
                end
            end
        end
    end
    return vnf_placement_values, virtual_link_values, objective_value(model)
end