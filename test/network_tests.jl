@testset "Networks" begin
    N = 32
    N_in = 16

    @testset "Homogeneous Networks FF" begin
        neurons1 = [nnsim.identity() for _ in 1:N]
        W1 = randn(N, N_in)
        neurons2 = [nnsim.identity() for _ in 1:N]
        W2 = randn(N, N)
        L1 = Layer(neurons1, W1)
        L2 = Layer(neurons2, W2)
        net_hom = Network([L1, L2], N_in)
        
        # Network should change Layer `conns`
        @test begin                         
            ( all(net_hom.layers[1].conns .== [0]) &&
                all(net_hom.layers[2].conns .== [1]) )
        end

        # Layers should now have BlockArrays
        @test begin                         
            isa(net_hom.layers[1].W, AbstractBlockArray) &&
                isa(net_hom.layers[2].W, AbstractBlockArray)
        end

        # Layer block arrays should have correct size
        @test begin                         
            ( all(size(net_hom.layers[1].W) .== [N, N_in + N + N]) &&
                all(size(net_hom.layers[2].W) .== [N, N_in + N + N]) )
        end

        state0 = L1.neurons[1].state[1]

        # All neurons initialized correctly
        @test begin                         
            all(nnsim.get_neuron_states(net_hom) .== 0.)
        end

        # Layers are changed to have correct `conns` given the feed-forward network
        @test begin                         
            ( all(net_hom.layers[1].conns .== [0]) 
                && all(net_hom.layers[2].conns .== [1]) )
        end

        # Neuron Outputs function works
        @test begin                         
            all(nnsim.get_neuron_outputs(net_hom) .== 0.)
        end

        # Update works, not evolving system/state unchanged
        @test begin                         
            update!(net_hom, zeros(Float64, N_in), 0, 0)
            all(nnsim.get_neuron_states(net_hom) .== 0.)
        end

        # Update passes the correct values to layer inputs
        @test begin
            update!(net_hom, ones(Float64, N_in), 0, 0)                         
            all( nnsim.get_neuron_outputs(net_hom) .≈ vcat(
                    sum.(eachrow(W1)), zeros(N)
                    )
                )
                
        end
        # It currently takes two updates to stimulate the second layer
        @test begin
            update!(net_hom, ones(Float64, N_in), 0, 0)                         
            all( nnsim.get_neuron_outputs(net_hom) .≈ vcat(
                    sum.(eachrow(W1)), sum.(eachrow(W2*W1))
                    )
                )
        end

        #######################################################
        # Test simulate! with Matrix inputs
        #######################################################
        reset!(net_hom)
        outputs, states = simulate!(net_hom, zeros(N_in, 1000), 0.001, track_flag = true)
        @test begin                         # Check neuron output matrix size
            all(size(outputs) .== [2*N, 1001])
        end

        # Check neuron output matrix size
        @test begin                         
            all(size(states) .== [2*N, 1001])
        end

        ######################################################
        # Test simulate! with a function input
        ######################################################
        input_fun(t) = zeros(Float64, N_in)
        outputs, states = simulate!(net_hom, input_fun, 0.001, 1., track_flag = true)
        # Check neuron output matrix size
        @test begin                         
            all(size(outputs) .== [2*N, 1001])
        end

        # Check neuron output matrix size
        @test begin                         
            all(size(states) .== [2*N, 1001])
        end

        # Reset the full network
        @test begin                         
            reset!(net_hom)
            all(nnsim.get_neuron_states(net_hom) .== 0.)
        end

    end

end