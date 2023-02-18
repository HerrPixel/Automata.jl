##############################
#                            #
#     Struct Definitions     #
#                            #
##############################

"""
    state(Name::AbstractString, Neighbours::Dict{Char,state}=())

A named state with optional neighbours.
"""
mutable struct state
    name::String
    neighbours::Dict{Char,state}

    function state(Name::AbstractString, Neighbours::Dict{Char,state}=Dict{Char,state}())
        return new(Name, Neighbours)
    end
end

"""
    automaton()
    automaton(States,Alphabet,InitialState,AcceptingStates,Edges=[])
    automaton(States::Vector{<:AbstractString},Alphabet::Vector{Char},InitialState::AbstractString, AcceptingStates::Vector{<:AbstractString}, Edges::Vector{<:Tuple{<:AbstractString,Char,<:AbstractString}}=[])

A finite deterministic automaton given by states, labelled edges, an initial state and accepting states. 
"""
mutable struct automaton
    states::Dict{String,state}
    alphabet::Set{Char}
    initialState::state
    acceptingStates::Set{state}

    # replace assertions by errors

    function automaton()
        s = state("epsilon")
        return new(Dict("epsilon" => s), Set{Char}(), s, Set{state}())
    end

    function automaton(States::Vector{<:AbstractString}, Alphabet::Vector{Char}, InitialState::AbstractString, AcceptingStates::Vector{<:AbstractString}, Edges::Vector{<:Tuple{<:AbstractString,Char,<:AbstractString}}=[])

        @assert InitialState ∈ States "Initial state $InitialState is not a state"
        for s in AcceptingStates
            @assert s ∈ States "Accepting state $s is not a state"
        end

        for (a, x, b) in Edges
            @assert a ∈ States "State $a from edge ($a,$x,$b) is not a state"
            @assert x ∈ Alphabet "Character $x from edge ($a,$x,$b) is not in the alphabet"
            @assert b ∈ States "State $b from edge ($a,$x,$b) is not a state"
        end

        states = Dict{String,state}()

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

        return new(states, Set{Char}(Alphabet), states[InitialState], acceptingStates)
    end
end

##############################
#                            #
#       Equality Tests       #
#                            #
##############################

"""
    ==(a::state,b::state)

`true` if `a` is equal to `b`, i.e. same name and neighbourhood, and `false` otherwise.
"""
function Base.:(==)(a::state, b::state)
    if a.name != b.name
        return false
    end
    if length(a.neighbours) != length(b.neighbours)
        return false
    end
    for (c, node) in a.neighbours
        if !haskey(b.neighbours, c)
            return false
        elseif node.name != b.neighbours[c].name
            return false
        end
    end

    return true
end

"""
    ==(a::automaton,b::automaton)

`true` if `a` is equal to `b`, i.e. same alphabet, states, initial states, terminal states and edges, and `false` otherwise.
"""
function Base.:(==)(a::automaton, b::automaton)
    if a.alphabet != b.alphabet
        return false
    end

    if a.initialState.name != b.initialState.name
        return false
    end

    if length(a.states) != length(b.states)
        return false
    end

    for (s, _) in a.states
        if !haskey(b.states, s)
            return false
        end
    end

    if length(a.acceptingStates) != length(b.acceptingStates)
        return false
    end

    for node in a.acceptingStates
        if !haskey(b.states, node.name)
            return false
        elseif b.states[node.name].name != node.name
            return false
        end
    end

    return true
end

"""
    semanticEquals(a::state, b::state)

`true` if `a` is equal to `b` up to renaming itself and its neighbourhood, `false` otherwise.
"""
function semanticEquals(a::state, b::state)
    if length(a.neighbours) != length(b.neighbours)
        return false
    end

    edgesFromA = sort(collect(keys(a.neighbours)))
    edgesFromB = sort(collect(keys(b.neighbours)))

    if edgesFromA != edgesFromB
        return false
    end

    SeenBeforeInA = Set{state}()
    SeenBeforeInB = Set{state}()

    for c in edgesFromA
        s = a.neighbours[c]
        t = b.neighbours[c]
        if s ∈ SeenBeforeInA && t ∈ SeenBeforeInB
            continue
        elseif (s ∈ SeenBeforeInA && t ∉ SeenBeforeInB) || (s ∉ SeenBeforeInA && t ∈ SeenBeforeInB)
            return false
        else
            push!(SeenBeforeInA, s)
            push!(SeenBeforeInB, t)
        end
    end

    return true
end

"""
    semanticEquals(a::state, b::state)

`true` if `a` is equal to `b` up to renaming states, `false` otherwise.
"""
function semanticEquals(a::automaton, b::automaton)

    function getCanonicalNames(initialState::state, alphabet::Vector{Char})
        q = Queue{state}()
        canonicalNames = Dict{state,String}()

        enqueue!(q, initialState)
        canonicalNames[initialState] = ""

        while !isempty(q)
            s = dequeue!(q)

            for c in alphabet
                if haskey(s.neighbours, c)
                    t = s.neighbours[c]
                    enqueue!(q, t)

                    if !haskey(canonicalNames, t)
                        canonicalNames[t] = canonicalNames[s] * c
                    end
                end
            end
        end
        return canonicalNames
    end

    if a.alphabet != b.alphabet
        return false
    end

    canonicalNamesInA = getCanonicalNames(a.initialState, sort(collect(a.alphabet)))
    canonicalNamesInB = getCanonicalNames(b.initialState, sort(collect(b.alphabet)))

    function sortBySecond(first::Pair{state,String}, second::Pair{state,String})
        return first.second < second.second
    end

    statesInA = sort(collect(canonicalNamesInA), lt=sortBySecond)
    statesInB = sort(collect(canonicalNamesInB), lt=sortBySecond)

    for i in eachindex(statesInA)
        (s, Sname) = statesInA[i]
        (t, Tname) = statesInB[i]

        if (s ∈ a.acceptingStates) != (t ∈ b.acceptingStates)
            return false
        end

        if Sname != Tname
            return false
        end
        for (c, x) in s.neighbours
            if !haskey(t, c)
                return false
            end

            if canonicalNamesInA[x] != canonicalNames[t.neighbours[c]]
                return false
            end
        end
    end

    return true
end

##############################
#                            #
#        Adding Things       #
#                            #
##############################

# adding a new state to the automaton
function addState!(A::automaton, State::AbstractString)
    if haskey(A.states, State)
        return
    else
        addState!(A, state(State))
    end
end

# adding a new state to the automaton
function addState!(A::automaton, State::state)
    A.states[State.name] = State
end

# adding a new terminal state to the automaton
# careful if this node is already present with that name
addTerminalState!(A::automaton, TerminalState::AbstractString) = addTerminalState!(A, state(TerminalState))

# adding a new terminal state to the automaton
function addTerminalState!(A::automaton, TerminalState::state)
    if !haskey(A.states, TerminalState.name)
        addState!(A, TerminalState)
    end
    push!(A.acceptingStates, TerminalState)
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

##############################
#                            #
#       Removing Things      #
#                            #
##############################

# removes a state from an automaton
function removeState!(A::automaton, s::state)
    delete!(A.acceptingStates, s)
    delete!(A.states, s)
end

removeTerminalState!(A::automaton, TerminalState::AbstractString) = removeTerminalState!(A, A.states[TerminalState])

function removeTerminalState!(A::automaton, TerminalState::state)
    delete!(A.acceptingStates, TerminalState)
end

##############################
#                            #
#           Getter           #
#                            #
##############################

# returns true if the supplied state is terminal in the given automaton
function isTerminal(A::automaton, s::state)
    return s ∈ A.acceptingStates
end

##############################
#                            #
#        Miscellaneous       #
#                            #
##############################

# returns the state reached by walking the edge labeled by Symbol from the supplied state
function walkEdge(State::state, Symbol::Char)
    # If the state does not have an entry for that symbol, this will fail.
    # We need to fix this or change it in the future somehow
    return State.neighbours[Symbol]
end

#= methods to add
- removing Edges
- show function
- throw errors in constructor
=#