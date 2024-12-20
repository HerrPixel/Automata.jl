""" 
    complete!(A::automaton)
completes the automaton, such that each state has an edge for each symbol in the alphabet.
"""
function complete!(A::automaton)

    # we make a junkyard state if we do not already have one. 
    # This is a non-accepting state where all non-specified edges will lead to. 
    if !haskey(A.states, "junkyard")
        junkyard = state("junkyard")
        hasBeenDefined = false
    else
        junkyard = A.states["junkyard"]
        hasBeenDefined = true
    end

    for s in values(A.states)
        for c in A.alphabet
            if !haskey(s.neighbours, c)

                # we only add the junkyard state if we need it, 
                # therefore we track it if we have already added it. 
                if !hasBeenDefined
                    addState!(A, junkyard)
                    hasBeenDefined = true
                end

                addEdge!(A, s, c, junkyard)
            end
        end
    end

    # the junkyard states loops to itself, nothing can escape it
    if hasBeenDefined
        for c in A.alphabet
            addEdge!(A, "junkyard", c, "junkyard")
        end
    end
end

"""
    reduceNonAccessibleStates!(A::automaton)
removes all unreachable states of an automaton.
"""
function reduceNonAccessibleStates!(A::automaton)
    reachableStates = Set{state}()
    q = Queue{state}()

    push!(reachableStates, A.initialState)
    enqueue!(q, A.initialState)

    # we use BFS on the graph of the automaton 
    # and store all reached nodes
    while !isempty(q)
        s = dequeue!(q)
        for c in A.alphabet
            target = walkEdge(s, c)
            if !isnothing(target) && target ∉ reachableStates
                push!(reachableStates, target)
                enqueue!(q, target)
            end
        end
    end

    # finally, all unreached nodes are removed from the automaton.
    # if they are referenced elsewhere, they survive.
    # Otherwise the next Garbage Collection cycle catches them.
    for s in values(A.states)
        if s ∉ reachableStates
            removeState!(A, s)
        end
    end
end

"""
    isAccepted()
returns true if the automaton A accepts the word w, false otherwise
"""
function isAccepted(A::automaton, w::AbstractString)
    s = A.initialState

    for c in w
        if c ∉ A.alphabet
            return false
        end
        s = walkEdge(s, c)
        if isnothing(s)
            return false
        end
    end

    return s ∈ A.acceptingStates
end

"""
    complement!(A::automaton)
Change A such that it accepts the complement of its language L(A)^C
"""
function complement!(A::automaton)

    # maybe add reduceNonAccessibleStates(A) here

    newTerminalStates = Set(values(A.states))

    for s in A.acceptingStates
        delete!(newTerminalStates, s)
        removeTerminalState!(A, s)
    end

    for s in newTerminalStates
        addTerminalState!(A, s)
    end
end

"""
    hasLoop(A::automaton)
returns true if the automaton has a reachable loop that leads to an end state, false otherwise.
I.e. The language recognized by the automaton is infinite.
"""
function hasLoop(A::automaton)

    # BFS from the s to check if any state of the loop can reach a terminal state.
    function canReachTerminalState(A::automaton, s::state)
        q = Queue{state}()
        visited = Set{state}()

        if isTerminal(A, s)
            return true
        end

        enqueue!(q, s)
        push!(visited, s)

        while !isempty(q)
            t = dequeue!(q)
            for nextState in values(t.neighbours)
                if isTerminal(A, nextState)
                    return true
                end
                if nextState ∈ visited
                    continue
                end
                enqueue!(q, nextState)
                push!(visited, nextState)
            end
        end
        return false
    end

    # Implementation of recursive DFS via function call stack
    function DFS(currentState::state, currentStack::Stack{state}, visitedStates::Set{state})
        # for each neighbour, we traverse deeper
        for nextState in values(currentState.neighbours)

            # if we found that neighbour in the current branch already, we found a cycle
            if nextState ∈ currentStack && canReachTerminalState(A, nextState)
                return true
            end

            if nextState ∈ visitedStates
                continue
            end

            # otherwise we traverse deeper
            push!(currentStack, nextState)
            push!(visitedStates, nextState)

            # if we find a cycle deeper down, return that value 
            if DFS(nextState, currentStack, visitedStates)
                return true
            end
            pop!(currentStack)
            delete!(visitedStates, nextState)
        end

        # otherwise return this branch as cycleless
        return false
    end

    visitedStates = Set{state}()
    s = Stack{state}()

    push!(visitedStates, A.initialState)
    push!(s, A.initialState)

    return DFS(A.initialState, s, visitedStates)
end

"""
    minimalize(A::automaton)
Minimize automaton A to its canonical minimal automaton. Does not change A but returns a new automaton.
"""
function minimalize(A::automaton)
    complete!(A)
    reduceNonAccessibleStates!(A)

    hasChanged = true

    equivalenceClasses = Vector{Vector{state}}()

    # populating the equivalence equivalenceClasses
    terminalStates = collect(A.acceptingStates)
    nonTerminalStates = Vector{state}()
    for s in values(A.states)
        if s ∉ terminalStates
            push!(nonTerminalStates, s)
        end
    end

    if !isempty(terminalStates)
        push!(equivalenceClasses, terminalStates)
    end

    if !isempty(nonTerminalStates)
        push!(equivalenceClasses, nonTerminalStates)
    end

    # splitting equivalence classes until they exhibit the same behaviour for each state
    # in an equivalence classes
    while hasChanged

        hasChanged = false

        for classIndex in eachindex(equivalenceClasses)
            class = equivalenceClasses[classIndex]

            for c in A.alphabet

                # storing the indices of the classes that each edge of our class leads to.
                # For each symbol in the alphabet, all states in a class should lead to the same
                # equivalence class.
                targetIndices = Vector{Int}()

                # for each state, find the index of the class its neighbour belongs to.
                for s in class
                    for index in eachindex(equivalenceClasses)
                        result = findfirst(==(walkEdge(s, c)), equivalenceClasses[index])
                        if !isnothing(result)
                            push!(targetIndices, index)
                            break
                        end
                    end
                end

                # we translate from target indices to possible new sets to put those states into.
                indexDict = Dict{Int,Int}()
                i = 1
                for t in targetIndices
                    if !haskey(indexDict, t)
                        indexDict[t] = i
                        i += 1
                    end
                end

                # each states edge leads to the same equivalence class.
                if length(indexDict) == 1
                    continue
                end

                # otherwise, we need to split, i.e. something changed
                hasChanged = true

                newEquivalenceClasses = Vector{Vector{state}}()

                # populating the Vector
                for j in 1:length(indexDict)
                    push!(newEquivalenceClasses, Vector{state}())
                end

                # putting the states of the current class in their new splitted equivalence
                # class based on the class in which their neighbour lies
                for j in eachindex(class)
                    index = indexDict[targetIndices[j]]
                    push!(newEquivalenceClasses[index], class[j])
                end

                # removing the old class
                deleteat!(equivalenceClasses, classIndex)

                # and pushing the new ones
                for j in eachindex(newEquivalenceClasses)
                    push!(equivalenceClasses, newEquivalenceClasses[j])
                end

                break
            end

            # since the vector of classes has changed, we shouldn't iterate over the old vector
            # so we break and reenter the new loop in the next iteration
            if hasChanged
                break
            end
        end
    end

    # now we need to rebuild our automata with the new reduced classes
    indexOfInitialState = 0
    stateNames = Vector{String}()

    # finding out the index of the new initial state
    for classIndex in eachindex(equivalenceClasses)
        class = equivalenceClasses[classIndex]
        for s in class
            if s == A.initialState
                indexOfInitialState = classIndex
            end
        end

        push!(stateNames, "$classIndex")
    end

    B = automaton(stateNames, collect(A.alphabet), "$indexOfInitialState", Vector{String}())

    # adding new edges and making states terminal
    for classIndex in eachindex(equivalenceClasses)
        class = equivalenceClasses[classIndex]
        representative = class[1]

        # new state is terminal, if the old one was
        if isTerminal(A, representative)
            addTerminalState!(B, "$classIndex")
        end

        for c in B.alphabet

            # stores the index to which this edge leads to
            result = 0

            # finding that index by going through every class to find the neighbour
            for index in eachindex(equivalenceClasses)
                result = findfirst(==(walkEdge(representative, c)), equivalenceClasses[index])
                if !isnothing(result)
                    result = index
                    break
                end
            end

            addEdge!(B, "$classIndex", c, "$result")
        end
    end

    return B
end

#= 
zip up two automata, 
i.e. if any state in shouldBeZipped is reached, 
it is zipped up with toBeZipped and edges are walked in both automata 
to build a powerset automata. 
In the resulting automata, 
each state is represented by a set of states in A and B.
The function shouldBeTerminal(states::Vector{state}, A::automaton, B::automaton)
is then asked if that state is supposed to be Terminal.
=#
function zip(A::automaton, B::automaton, shouldBeZipped::Vector{state}, toBeZipped::state, shouldBeTerminal::Function)

    # we make a BFS over the powerset automata, therefore we need a queue
    q = Queue{Vector{state}}()

    # each new state gets a name, in this case a number.
    # to remember states, we store the represented set in a dictionary.
    NewNames = Dict{Vector{state},Int}()
    nextName = 1

    # building the alphabet as a union of both alphabets
    for c in B.alphabet
        if c ∉ A.alphabet
            addSymbol!(A, c)
        end
    end

    for c in A.alphabet
        if c ∉ B.alphabet
            addSymbol!(B, c)
        end
    end

    # completing both automata to avoid missing edges
    complete!(A)
    complete!(B)

    currState = [A.initialState]

    # edge case, if the initial state should already be zipped, our initial state is already a power-state
    if A.initialState ∈ shouldBeZipped
        push!(currState, toBeZipped)
    end

    NewNames[currState] = nextName

    # the skeleton for our new automaton.
    # contains the initial state and the bigger alphabet but nothing else for now.
    C = automaton(["$nextName"], collect(A.alphabet), "$nextName", Vector{String}())

    nextName += 1

    enqueue!(q, currState)

    while !isempty(q)
        currState = dequeue!(q)

        # for each state, explore all edges
        for c in C.alphabet

            # since we are possibly a power-state,
            # we need to collect neighbours from all our states
            neighbour = Vector{state}()

            for s in currState
                n = walkEdge(s, c)

                # we don't need to collect a neighbour twice
                if n ∉ neighbour
                    push!(neighbour, n)

                    # if we reached a state that should be zipped, add the zipped state to our neighbour list
                    if n ∈ shouldBeZipped && toBeZipped ∉ neighbour
                        push!(neighbour, toBeZipped)
                    end
                end
            end

            # if this particular power-state is not already in our automata,
            # create it and add it to the queue
            if !haskey(NewNames, neighbour)
                NewNames[neighbour] = nextName
                nextName += 1
                enqueue!(q, neighbour)
            end

            # and finally add the newly explored edge
            source = NewNames[currState]
            target = NewNames[neighbour]
            addEdge!(C, "$source", c, "$target")
        end
    end

    # check each of the new states for terminality based on the supplied function
    for (states, index) in NewNames
        if shouldBeTerminal(states, A, B)
            addTerminalState!(C, "$index")
        end
    end

    return C
end

"""
    Intersection(A::automaton, B::automaton)
Build Automata that accepts Intersection of Languages of A and B
"""
function Intersection(A::automaton, B::automaton)

    function intersectionTerminal(states::Vector{state}, A::automaton, B::automaton)
        for s in states
            if !isTerminal(A, s) && !isTerminal(B, s)
                return false
            end
        end
        return true
    end

    return zip(A, B, [A.initialState], B.initialState, intersectionTerminal)
end

"""
    Union(A::automaton, B::automaton)
Build Automata that accepts Union of Languages of A and B
"""
function Union(A::automaton, B::automaton)

    function unionTerminal(states::Vector{state}, A::automaton, B::automaton)
        for s in states
            if isTerminal(A, s) || isTerminal(B, s)
                return true
            end
        end
        return false
    end

    return zip(A, B, [A.initialState], B.initialState, unionTerminal)
end

"""
    Intersection(A::automaton, B::automaton)
Build Automata that accepts Concatenation of Languages of A and B
"""
function Concatenation(A::automaton, B::automaton)

    function concatenationTerminal(states::Vector{state}, A::automaton, B::automaton)
        for s in states
            if isTerminal(B, s)
                return true
            end
        end
        return false
    end

    return zip(A, B, collect(A.acceptingStates), B.initialState, concatenationTerminal)
end