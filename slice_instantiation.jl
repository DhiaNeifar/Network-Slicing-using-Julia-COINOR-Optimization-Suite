using Random

function slice_instantiation(num_slices, number_VNFs=6)
    required_cpus = [rand(10: 17) for _ in 1: num_slices, _ in 1: number_VNFs]
    required_bandwidth = [rand(10: 20) for _ in 1: num_slices, _ in 1: number_VNFs - 1]
    delay_tolerance = rand(1: 3, num_slices)

    return required_cpus, required_bandwidth, delay_tolerance
end
