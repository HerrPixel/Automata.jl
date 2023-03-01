# completes the automaton, such that each state has an edge for each symbol in the alphabet.
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

# removes all unreachable states of an automaton
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

# returns true if the automaton A accepts the word w, false otherwise
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

# returns true if the automaton has a reachable loop, false otherwise
# currently this does not return the states of the loop
function hasLoop(A::automaton)

    # this is faulty! only nodes in the current stack should be checked!
    #

    # Implementation of recursive DFS via function call stack
    function DFS(currentState::state, currentStack::Stack{state}, visitedStates::Set{state})
        # for each neighbour, we traverse deeper
        for nextState in values(currentState.neighbours)

            # if we found that neighbour in the current branch already, we found a cycle
            if nextState ∈ visitedStates
                return true
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

# Possible ideas to implement:
# - NFA
# - Powerset construction
# - union of two languages
# - kleene star
# - other operations on languages