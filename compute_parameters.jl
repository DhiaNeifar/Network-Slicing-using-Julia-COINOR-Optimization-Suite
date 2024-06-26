function compute_parameters(system_performance_dict, number_slices, number_nodes, number_VNFs, VNFs_placements, Virtual_links, clocks, throughput, number_uRLLC, number_eMBB, number_mMTC, number_cycles, traffic, delay_tolerance, β, nodes_recovery_resources, node_recovery_requirements, recovery_states, theta)
    θ = theta
    uRLLC_slices_deployed = 0
    uRLLC_slices_delay = 0
    uRLLC_slices_resources = 0
    eMBB_slices_deployed = 0
    eMBB_slices_delay = 0
    eMBB_slices_resources = 0
    mMTC_slices_deployed = 0
    mMTC_slices_delay = 0
    mMTC_slices_resources = 0
    for s in 1: number_slices
        delay = 10 ^ -6 * sum(number_cycles[s, k] / clocks[s, k] * VNFs_placements[s, k, c] for k in 1: number_VNFs for c in 1: number_nodes) + 
        10 ^ -3 * sum(traffic[s, k] / throughput[s, k] * Virtual_links[s, k, i, j] for k in 1: number_VNFs - 1 for i in 1: number_nodes for j in 1: number_nodes)
        resources_consumed = sum(clocks[s, k] * VNFs_placements[s, k, c] for k in 1: number_VNFs for c in 1: number_nodes) + 
        sum(throughput[s, k] * Virtual_links[s, k, i, j] for k in 1: number_VNFs - 1 for i in 1: number_nodes for j in 1: number_nodes)
        if s <= number_uRLLC
            uRLLC_slices_delay += delay
            uRLLC_slices_resources += resources_consumed
            if delay < delay_tolerance[s]
                uRLLC_slices_deployed += 1
            end
        end
        if number_uRLLC < s <= number_uRLLC + number_eMBB
            eMBB_slices_delay += delay
            eMBB_slices_resources += resources_consumed
            if delay < delay_tolerance[s]
                eMBB_slices_deployed += 1
            end
        end
        if number_uRLLC + number_eMBB < s
            mMTC_slices_delay += delay
            mMTC_slices_resources += resources_consumed
            if delay < delay_tolerance[s]
                mMTC_slices_deployed += 1
            end
        end
    end
    β_uRLLC, β_eMBB, β_mMTC = β[number_uRLLC], β[number_uRLLC + number_eMBB], β[number_uRLLC + number_eMBB + number_mMTC]
    average_delay = uRLLC_slices_delay + eMBB_slices_delay + mMTC_slices_delay
    average_resources_consumed = uRLLC_slices_resources + eMBB_slices_resources + mMTC_slices_resources
    average_deployed = uRLLC_slices_deployed + eMBB_slices_deployed + mMTC_slices_deployed
    
    recovery_resources_consumed = sum(recovery_states .* node_recovery_requirements)
    objective_values = θ * recovery_resources_consumed + (1 - θ) * (β_uRLLC * uRLLC_slices_resources + (1 - β_uRLLC) * uRLLC_slices_delay + 
    β_eMBB * eMBB_slices_resources + (1 - β_eMBB) * eMBB_slices_delay + 
    β_mMTC * mMTC_slices_resources + (1 - β_mMTC) * mMTC_slices_delay)

    if isempty(system_performance_dict) == true
        system_performance_dict["uRLLC_slices_deployed"] = [uRLLC_slices_deployed]
        system_performance_dict["uRLLC_slices_delay"] = [uRLLC_slices_delay]
        system_performance_dict["uRLLC_slices_resources"] = [uRLLC_slices_resources]
        system_performance_dict["eMBB_slices_deployed"] = [eMBB_slices_deployed]
        system_performance_dict["eMBB_slices_delay"] = [eMBB_slices_delay]
        system_performance_dict["eMBB_slices_resources"] = [eMBB_slices_resources]
        system_performance_dict["mMTC_slices_deployed"] = [mMTC_slices_deployed]
        system_performance_dict["mMTC_slices_delay"] = [mMTC_slices_delay]
        system_performance_dict["mMTC_slices_resources"] = [mMTC_slices_resources]
        system_performance_dict["nodes_recovery_resources"] = [nodes_recovery_resources]
        system_performance_dict["average_delay"] = [average_delay]
        system_performance_dict["average_resources_consumed"] = [average_resources_consumed]
        system_performance_dict["average_deployed"] = [average_deployed]
        system_performance_dict["recovery_resources_consumed"] = [recovery_resources_consumed]
        system_performance_dict["objective_values"] = [objective_values]
    else
        push!(system_performance_dict["uRLLC_slices_deployed"], uRLLC_slices_deployed)
        push!(system_performance_dict["uRLLC_slices_delay"], uRLLC_slices_delay)
        push!(system_performance_dict["uRLLC_slices_resources"], uRLLC_slices_resources)
        push!(system_performance_dict["eMBB_slices_deployed"], eMBB_slices_deployed)
        push!(system_performance_dict["eMBB_slices_delay"], eMBB_slices_delay)
        push!(system_performance_dict["eMBB_slices_resources"], eMBB_slices_resources)
        push!(system_performance_dict["mMTC_slices_deployed"], mMTC_slices_deployed)
        push!(system_performance_dict["mMTC_slices_delay"], mMTC_slices_delay)
        push!(system_performance_dict["mMTC_slices_resources"], mMTC_slices_resources)
        push!(system_performance_dict["nodes_recovery_resources"], nodes_recovery_resources)
        push!(system_performance_dict["average_delay"], average_delay)
        push!(system_performance_dict["average_resources_consumed"], average_resources_consumed)
        push!(system_performance_dict["average_deployed"], average_deployed)
        push!(system_performance_dict["recovery_resources_consumed"], recovery_resources_consumed)
        push!(system_performance_dict["objective_values"], objective_values)
    end

    return system_performance_dict
end

