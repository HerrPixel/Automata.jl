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

addState!(A::automaton, State::AbstractString) = addState(A, state(State))

function addState!(A::automaton, State::state)
    A.states[State.name] = State
end

addTerminalState!(A::automaton, TerminalState::AbstractString) = addTerminalState(A, state(TerminalState))

function addTerminalState!(A::automaton, TerminalState::state)
    if !haskey(A.states, TerminalState.name)
        addState!(A, TerminalState)
    end
    push!(A.acceptingStates, TerminalState)
end

function addEdge!(A::automaton, StartingState::AbstractString, Symbol::Char, TargetState::AbstractString)
    start = get(A.states, StartingState, state(StartingState))
    target = get(A.states, TargetState, state(TargetState))
    addEdge!(A, start, Symbol, target)
end

function addEdge!(A::automaton, StartingState::state, Symbol::Char, TargetState::state)
    if !haskey(A.states, StartingState.name)
        addState!(A, StartingState)
    end
    if !haskey(A.states, TargetState.name)
        addState!(A, TargetState)
    end
    if Symbol ∉ A.alphabet
        addSymbol!(A, Symbol)
    end

    StartingState.neighbours[Symbol] = TargetState
end

function addSymbol!(A::automaton, Symbol::Char)
    push!(A.alphabet, Symbol)
end

function walkEdge(state::State, Symbol::Char)
    # If the state does not have an entry for that symbol, this will fail.
    # We need to fix this or change it in the future somehow
    return state.neighbours[Symbol]
end

function isTerminal(A::automaton, s::state)
    return s ∈ A.acceptingStates
end