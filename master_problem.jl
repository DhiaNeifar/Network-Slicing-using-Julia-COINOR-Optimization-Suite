using JuMP, AmplNLWriter, HiGHS, MathOptInterface


function master_problem(number_slices, number_nodes, total_cpus_clocks, adjacency_matrix, total_throughput, number_VNFs, number_cycles, traffic, delay_tolerance, Cycles, Throughputs, lambdas)
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
                end
            end
        end
    end

    @objective(model, Min, mu)
    
    # Constraints
    alpha = 0.5
    for (index, cycles) in enumerate(Cycles)
        throughput = Throughputs[index]
        λ = lambdas[index]
        @constraint(model, sum(alpha * (sum(cycles[s, k] * VNFs_placements[s, k, c] for k in 1: number_VNFs for c in 1: number_nodes) + 
        sum(throughput[s, k] * Virtual_links[s, k, i, j] for k in 1: number_VNFs - 1 for i in 1: number_nodes for j in 1: number_nodes)) + 
        (1 - alpha) * (sum(number_cycles[s, k] / cycles[s, k] * VNFs_placements[s, k, c] for k in 1: number_VNFs for c in 1: number_nodes) + 
        sum(traffic[s, k] / throughput[s, k] * Virtual_links[s, k, i, j] for k in 1: number_VNFs - 1 for i in 1: number_nodes for j in 1: number_nodes)) for s in 1: number_slices) + 
        sum(-λ[c] * (sum(VNFs_placements[s, k, c] * cycles[s, k] for s in 1: number_slices, k in 1: number_VNFs) - total_cpus_clocks[c]) for c in 1: number_nodes) + 
        sum(-λ[number_nodes * i + j] * (sum(Virtual_links[s, k, i, j] * throughput[s, k] for s in 1: number_slices, k in 1: number_VNFs - 1) - total_throughput[i, j]) for i in 1: number_nodes for j in 1: number_nodes) + 
        sum(-λ[number_nodes * (number_nodes + 1) + s] * ((sum(number_cycles[s, k] / cycles[s, k] * VNFs_placements[s, k, c] for k in 1: number_VNFs for c in 1: number_nodes) + 
        sum(traffic[s, k] / throughput[s, k] * Virtual_links[s, k, i, j] for k in 1: number_VNFs - 1 for i in 1: number_nodes for j in 1: number_nodes)) - delay_tolerance[s]) for s in 1: number_slices) <= mu)
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
                @constraint(model, sum(Virtual_links[s, k, i, j] * adjacency_matrix[i, j] for j in 1: number_nodes) - 
                sum(Virtual_links[s, k, j, i] * adjacency_matrix[j ,i] for j in 1: number_nodes) == VNFs_placements[s, k, i] - VNFs_placements[s, k + 1, i])
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