"""
    mutable struct Network<:AbstractNetwork

Contains constituent `Layer`s, orchestrates the movement of signals between `Layer`s, and handles first-layer input.

# Fields
- `layers::Array{AbstractLayer,1}`: Array of `Layer`s ordered from 1 to N for N layers
- `N_in::Int`: Number of input dimensions to the first `Layer`
- `prev_outputs::Vector`: Vector of vectors sized to hold the output from each `Layer` 
"""
mutable struct Network<:AbstractNetwork
    layers::Array{AbstractLayer, 1}

    prev_outputs
    prev_events::Array{Bool, 1}

    function Network(layers, N_in, prev_outputs)
        neurons_per_layer = [num_neurons(l) for l in layers]
        output_sizes = vcat([N_in], neurons_per_layer) # number of signals passed out of each layer incl. input

        N_layers = length(layers)
        N_neurons = sum(neurons_per_layer)

        net_layers = Array{AbstractLayer,1}()
        for (i,l) in enumerate(layers)
            if isa(l, Layer)
                conns = Array{Int,1}()
                if isempty(l.conns)
                    push!(conns, i-1)
                    new_layer = Layer(l.neurons, l.W, conns, l.N_neurons, l.state_size, l.input, l.output)
                else
                    conns = copy(l.conns)
                    new_layer = deepcopy(l)
                end
                push!(net_layers, new_layer)
            else
                push!(net_layers, deepcopy(l))
            end
        end

        return new(net_layers, N_in, prev_outputs, zeros(Bool, N_layers))
    end
end

"""
    function Network(layers, N_in::Int) 

Given an array of `Layer`s and the dimensionality of the input to the network, make a new `Network` which is a copy of each `Layer` with weights converted to `BlockArray` format.

The output dimensionality is in 
""" 
function Network(layers) 
    neurons_per_layer = [num_neurons(l) for l in layers]
    prev_outputs = [zeros(j) for j in neurons_per_layer]

    return Network(layers, N_in, prev_outputs)
end

"""
    function Network(layers::Array{L, 1}) where L <: AbstractLayer

Given an array of `Layer`s, constructs the `Network` resulting from connecting the `Layer`s with their specified `conn`s. 

The input dimensionality is inferred from the size of the weight matrices for the first `Layer` in the `layers` array.
"""
function Network(layers::Array{L, 1}) where L <: AbstractLayer
    in_layer = layers[1]
    N_in = 0
    if isa(in_layer.W, AbstractBlockArray)
        N_in = size(in_layer.W[Block(1,1)])[2]
    elseif isa(in_layer.W, AbstractArray{<:Number,2})
        N_in = size(in_layer.W)[2]
    else
        error("Layer weights should be a subtype of AbstractArray{<:Number,2}, given a $(typeof(in_layer.W))")
    end

    return Network(layers, N_in)
end

function update!(net::Network, du, u, t)
    @inbounds for (j,l) in enumerate(net.layers)
        update!(l, du.x[j], u.x[j], t)
    end
end

function event(net::Network, u, t)
    @inbounds for (j,l) in enumerate(net.layers)
        net.prev_events[j] = event(l, u.x[j], t)
    end
    return any(net.prev_events)
end

function aff_element!(net::Network, u, input, t)
    @inbounds for (j,l) in enumerate(net.layers)
        aff_element!(l, u.x[j], net.prev_outputs, t)
    end
    fill!(net.prev_events, false)
end