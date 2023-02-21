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

    function automaton(States::Vector{<:AbstractString}, Alphabet::Vector{Char}, InitialState::AbstractString, AcceptingStates::Vector{<:AbstractString}, Edges::Vector{<:Tuple{<:AbstractString,Char,<:AbstractString}}=Vector{Tuple{AbstractString,Char,AbstractString}}())

        if InitialState ∉ States
            throw(ArgumentError("Initial State $InitialState is not a state"))
        end
        for s in AcceptingStates
            if s ∉ States
                throw(ArgumentError("Accepting state $s is not a state"))
            end
        end

        for (a, x, b) in Edges
            if a ∉ States
                throw(ArgumentError("State $a from edge ($a,$x,$b) is not a state"))
            elseif x ∉ Alphabet
                throw(ArgumentError("Character $x from edge ($a,$x,$b) is not in the alphabet"))
            elseif b ∉ States
                throw(ArgumentError("State $b from edge ($a,$x,$b) is not a state"))
            end
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

    # We need to check that a and b have edges labelled the same to the same named states.
    # Since a and b have the same number of neighbours, we only need to check 
    # that b has the same edges as a, as it can't have more.
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

    for (s_name, s_state) in a.states
        if !haskey(b.states, s_name)
            return false
        else
            t_state = b.states[s_name]
        end

        # tests for the same edges
        for (c, x) in s_state.neighbours
            if !haskey(t_state.neighbours, c)
                return false
            elseif t_state.neighbours[c].name != x.name
                return false
            end
        end
    end

    if length(a.acceptingStates) != length(b.acceptingStates)
        return false
    end

    # We need to check that a and b have the same named accepting states.
    # Since a and b have the same number of accepting states, we only need to check 
    # that b has at least the same named ones as a, since it cannot have more.
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

    # We canonically sort the edges and neighbours in a and b by the label of their edge.
    # We can then go through them simultaniously and check if both states have the same neighbourhood.
    # Note that we can't just count the number of neighbours, since `a` might have two edges 
    # going to the same neighbour and `b` only has one, so we need to check the neighbourhood connection
    # more thoroughly. 

    edgesFromA = sort(collect(keys(a.neighbours)))
    edgesFromB = sort(collect(keys(b.neighbours)))

    # a and b have a different set of edge labels.
    if edgesFromA != edgesFromB
        return false
    end

    # for keeping track of neighbours that might be reachable with more than one edge.
    SeenBeforeInA = Set{state}()
    SeenBeforeInB = Set{state}()

    for c in edgesFromA
        s = a.neighbours[c]
        t = b.neighbours[c]

        if (s ∈ SeenBeforeInA) != (t ∈ SeenBeforeInB)
            # one state has multiple edges going to this neighbour, while the other does not,
            # therefore they are not equal.

            return false
        elseif s ∈ SeenBeforeInA && t ∈ SeenBeforeInB
            continue
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

    # this helper function gives each reachable state in the automata a canonical name.
    # i.e. the shortest lexicographically sorted word you can use to reach this state.
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

    # We label states canonically. Then both automata should be completely equal with the new naming.
    # To not destroy any smart labelling by users, we do not change the labels in the automata however
    # and only keep this canonical labeling for ourselves.
    canonicalNamesInA = getCanonicalNames(a.initialState, sort(collect(a.alphabet)))
    canonicalNamesInB = getCanonicalNames(b.initialState, sort(collect(b.alphabet)))

    # helper function to sort Pairs by the second entry.
    function sortBySecond(first::Pair{state,String}, second::Pair{state,String})
        return first.second < second.second
    end

    # even though a dictionary might have multiple keys for the same value, in this usage, 
    # it is a 1:1 map, so we can sort by the second entry and get unique entries no problem.
    statesInA = sort(collect(canonicalNamesInA), lt=sortBySecond)
    statesInB = sort(collect(canonicalNamesInB), lt=sortBySecond)

    # we then compare each state of both automata.
    # since our label is canonical, independent of former naming.
    # we can go through our sorted list of labels and both entries should be the same.
    for i in eachindex(statesInA)
        (s, Sname) = statesInA[i]
        (t, Tname) = statesInB[i]

        # the states have different terminal behaviour
        if (s ∈ a.acceptingStates) != (t ∈ b.acceptingStates)
            return false
        end

        # our labels are canonical and should therefore be the same.
        if Sname != Tname
            return false
        end

        # the neighbourhood should also be the same.
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

"""
    addState!(A::automaton, State::AbstractString)
    addState!(A::automaton, State::state)
Add a state to the given automaton.
"""
function addState!(A::automaton, State::AbstractString)
    if haskey(A.states, State)
        return
    else
        addState!(A, state(State))
    end
end

function addState!(A::automaton, State::state)
    A.states[State.name] = State
end

"""
    addTerminalState!(A::automaton, TerminalState::AbstractString)
    addTerminalState!(A::automaton, TerminalState::state)
Add a terminal state to the given automaton. If the state already exists, it is made terminal.
"""
function addTerminalState!(A::automaton, TerminalState::AbstractString)
    addTerminalState!(A, get(A.states, TerminalState, state(TerminalState)))
end

function addTerminalState!(A::automaton, TerminalState::state)
    if !haskey(A.states, TerminalState.name)
        addState!(A, TerminalState)
    end
    push!(A.acceptingStates, TerminalState)
end

"""
    addEdge!(A::automaton, StartingState::AbstractString, Symbol::Char, TargetState::AbstractString)
    addEdge!(A::automaton, StartingState::state, Symbol::Char, TargetState::state)
Add a new edge to the automaton, creates new symbols and states if they do not already exist.
"""
function addEdge!(A::automaton, StartingState::AbstractString, Symbol::Char, TargetState::AbstractString)
    # create new states if the automaton does not already have them
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

"""
    addSymbol!(A::automaton, Symbol::Char)
Add a symbol to the automatons alphabet.
"""
function addSymbol!(A::automaton, Symbol::Char)

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
=#