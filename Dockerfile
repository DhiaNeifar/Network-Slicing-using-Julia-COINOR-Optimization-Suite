# Start from the COIN-OR Optimization Suite base image
FROM coinor/coin-or-optimization-suite

# Install wget to download Julia
RUN apt-get update && apt-get install -y wget

# Download and install Julia
RUN wget https://julialang-s3.julialang.org/bin/linux/x64/1.6/julia-1.6.1-linux-x86_64.tar.gz \
    && tar -xvzf julia-1.6.1-linux-x86_64.tar.gz -C /usr/local --strip-components=1 \
    && rm julia-1.6.1-linux-x86_64.tar.gz

# Download and install Julia
RUN apt-get install -y vim

# Verify Julia installation
RUN julia --version

# Install Julia packages
RUN julia -e 'using Pkg; Pkg.add("JuMP"); Pkg.add("AmplNLWriter"); Pkg.add("MathOptInterface"); Pkg.add("FilePathsBase"); Pkg.add("Serialization"); Pkg.add("LinearAlgebra");'

 
