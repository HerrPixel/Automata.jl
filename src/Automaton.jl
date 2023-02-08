mutable struct state
    name::AbstractString
    neighbours::Dict{Char,state}

    function state(Name::AbstractString, Neighbours::Dict{Char,state}=Dict{Char,state}())
        return new(Name, Neighbours)
    end
end

mutable struct automaton
    states::Dict{AbstractString,state} # Maybe a better datastructure to store nodes
    alphabet::Set{Char}
    initialState::state
    acceptingStates::Set{state}

    function automaton()
        s = state("epsilon")
        return new([s], Dict{Char,Int}(), s, Set{state}())
    end

    function automaton(States::Vector{AbstractString}, Alphabet::Vector{Char}, InitialState::AbstractString, AcceptingStates::Vector{AbstractString}, Edges::Vector{Tuple{AbstractString,Char,AbstractString}}=[])

        @assert InitialState ∈ States "Initial state $InitialState is not a state"
        for s in AcceptingStates
            @assert s ∈ States "Accepting state $s is not a state"
        end

        for (a, x, b) in Edges
            @assert a ∈ States "State $a from edge ($a,$x,$b) is not a state"
            @assert x ∈ Alphabet "Character $x from edge ($a,$x,$b) is not in the alphabet"
            @assert b ∈ States "State $b from edge ($a,$x,$b) is not a state"
        end

        states = Dict{AbstractString,state}()

        for stateName in States
            s = state(stateName)
            states[stateName] = s
        end

        acceptingStates = Set{state}()

        for stateName in AcceptingStates
            push!(acceptingStates, states[stateName])
        end

        for (startName, x, targetName) in Edges
            start = states[startName]
            target = states[targetName]
            start.neighbours[x] = target
        end

        return new(states, Set{Char}(Alphabet), state[InitialState], acceptingStates)
    end
end

addState(A::automaton, State::AbstractString) = addState(A, state(State))

function addState(A::automaton, State::state)
    push!(A.states, State)
end


