using Random

function slice_instantiation(number_slices)
    number_uRLLC = rand(1: (number_slices - 2))
    number_eMBB = rand(1: (number_slices - number_uRLLC - 1))
    number_mMTC = number_slices - number_uRLLC - number_eMBB
    number_cycles = vcat([rand(250: 500) for _ in 1: number_uRLLC], [rand(1000: 5000) for _ in 1: number_eMBB], [rand(250: 500) for _ in 1: number_mMTC])

    traffic = vcat([rand(5: 20) for _ in 1: number_uRLLC], [rand(100: 300) for _ in 1: number_eMBB], [rand(70: 150) for _ in 1: number_mMTC])
    delay_tolerance = vcat([1 for _ in 1: number_uRLLC], [10 for _ in 1: number_eMBB + number_mMTC])

    return number_uRLLC, number_eMBB, number_mMTC, number_cycles, traffic, delay_tolerance
end
