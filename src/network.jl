
# A Network comprises layers and handles passing inputs between layers. Furthemore,
#   it also tracks the states of all of the neurons at each time step. 
mutable struct Network<:AbstractNetwork
    layers::Array{<:AbstractLayer, 1}  # Array of layers in order from input to output
    N_in::Int                          # Number of input dimensions
    N_out::Int                         # Number of output dimensions
    neur_states::Matrix                # The states of each neuron for each time step
    neur_outputs::Matrix               # The outputs of each neuron for each time step
    state_size::Int
    t                                  # Internal time parameter
end

# Constructor for the Network which simply takes as input the layers in order from 
#   first to last.
function Network(layers::Array{<:AbstractLayer, 1})
    N_in = size(layers[1].W)[2] # Number of dimensions in the input space
    N_out = size(layers[end].W)[1] # Number of output dimensions
    N_neurons = sum(map(l -> l.N_neurons, layers))

    state_size = sum([length(l.neurons[1].state)*length(l.neurons) for l in layers])

    return Network(layers, N_in, N_out, zeros(state_size, 1), zeros(state_size, 1), state_size, 0.0)
end

# Evolve the entire Network a duration `dt` starting from time `t` according to the
#   input `input`
function update!(network::Network, input, dt, t)
    # in_vec = input
    # out_vec = zeros(get_neuron_count(network))
    # start = 1
    # for l in network.layers
    #     in_vec = update!(l, in_vec, dt, t)
    #     out_vec[start:start+l.N_neurons-1] .= in_vec
    #     start += l.N_neurons
    # end
    # retval = out_vec[ (end-network.layers[end].N_neurons+1) : end]
    # out_vec = foldl(
        # (prev,layer)-> update!(layer, prev, dt, t), network.layers, init=input
        # )
    # return retval, out_vec
    return foldl(
        (prev,layer)-> update!(layer, prev, dt, t), network.layers, init=input
        )
end

# Reset the Network to its initial state.
function reset!(network::Network)
    network_neur_states = Array{Any, 2}(undef, network.state_size, 1) 
    network.t = 0.
    reset!.(network.layers)
    return nothing
end

# Simulate the network from `t0` to `tf` with a time step of `dt` with an input to
#   the first layer of `input`
function simulate!(network::Network, input, dt, tf, t0 = 0; track_flag = false)
    t_steps = t0:dt:tf
    N_steps = length(t_steps)

    network.neur_outputs = Array{Any, 2}(undef, get_neuron_count(network), length(t_steps))
    if track_flag
        network.neur_states = Array{Any, 2}(undef, network.state_size, length(t_steps) + 1) 
        network.neur_states[:,1] .= get_neuron_states(network)
    end

    for (i,t) in zip(1:N_steps,t_steps)
        update!(network, input, dt, t)
        network.neur_outputs[:, i] = get_neuron_outputs(network)
        # network.neur_outputs[:, i] .= neurons_out
        if track_flag
            network.neur_states[:,i+1] .= get_neuron_states(network)
        end
        network.t += dt
    end

    if track_flag
        return network.neur_outputs, network.neur_states
    else
        return network.neur_outputs
    end
end

# Count the number of neurons in the `Network`.
function get_neuron_count(network::Network)
    return sum(map((x)->x.N_neurons, network.layers))
end

# Get the state of each `Neuron` in the `Network` in a single array at the
#   current internal time step.
function get_neuron_states(network::Network)
    return vcat([get_neuron_states(l) for l in network.layers]...)
end

function get_neuron_outputs(network::Network)
    return vcat([get_neuron_outputs(l) for l in network.layers]...)
end