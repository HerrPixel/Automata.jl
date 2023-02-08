# A single state in an automaton.
# To reduce memory usage, this does not have any reference to the automaton it belongs to.
mutable struct state
    name::AbstractString
    neighbours::Dict{Char,state}

    # constructor for a state.
    # You need to supply a name and can optionally also supply a dictionary of neighbours reachable by symbols
    function state(Name::AbstractString, Neighbours::Dict{Char,state}=Dict{Char,state}())
        return new(Name, Neighbours)
    end
end

# A finite deterministic automaton 
mutable struct automaton
    states::Dict{AbstractString,state} # Maybe a better datastructure to store nodes
    alphabet::Set{Char}
    initialState::state
    acceptingStates::Set{state}

    # Constructor for an empty automaton
    function automaton()
        s = state("epsilon")
        return new([s], Dict{Char,Int}(), s, Set{state}())
    end

    # Constructor for an automaton based on states supplied by strings
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

# adding a new state to the automaton
addState!(A::automaton, State::AbstractString) = addState(A, state(State))

# adding a new state to the automaton
function addState!(A::automaton, State::state)

    # What if the state already exists?
    # We might need to complete this state before the next operation
    A.states[State.name] = State
end

# adding a new terminal state to the automaton
addTerminalState!(A::automaton, TerminalState::AbstractString) = addTerminalState(A, state(TerminalState))

# adding a new terminal state to the automaton
function addTerminalState!(A::automaton, TerminalState::state)
    if !haskey(A.states, TerminalState.name)
        addState!(A, TerminalState)
    end
    push!(A.acceptingStates, TerminalState)
end

removeTerminalState!(A::automaton, TerminalState::AbstractString) = removeTerminalState!(A, A.states[TerminalState])


function removeTerminalState!(A::automaton, TerminalState::state)
    delete!(A.acceptingStates, TerminalState)
end

# adding a new edge to the automaton
function addEdge!(A::automaton, StartingState::AbstractString, Symbol::Char, TargetState::AbstractString)
    start = get(A.states, StartingState, state(StartingState))
    target = get(A.states, TargetState, state(TargetState))
    addEdge!(A, start, Symbol, target)
end

# adding a new edge to the automaton
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

# adding a new symbol to the alphabet of the automaton
function addSymbol!(A::automaton, Symbol::Char)

    # What if the symbol already exists?
    # We might need to complete the automaton before the next operation
    push!(A.alphabet, Symbol)
end

# returns the state reached by walking the edge labeled by Symbol from the supplied state
function walkEdge(state::State, Symbol::Char)
    # If the state does not have an entry for that symbol, this will fail.
    # We need to fix this or change it in the future somehow
    return state.neighbours[Symbol]
end

# returns true if the supplied state is terminal in the given automaton
function isTerminal(A::automaton, s::state)
    return s ∈ A.acceptingStates
end

# removes a state from an automaton
function removeState!(A::automaton, s::state)
    delete!(A.acceptingStates, s)
    delete!(A.states, s)
end