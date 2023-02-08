# completes the automaton, such that each state has an edge for each symbol in the alphabet.
function complete!(A::automaton)

    # we make a junkyard state if we do not already have one. 
    # This is a non-accepting state where all non-specified edges will lead to. 
    junkyard::state
    if !haskey(A.states, "junkyard")
        junkyard = state("junkyard")
        addState!(A, junkyard)
    else
        junkyard = A.states["junkyard"]
    end

    for s in values(A.states)
        for c in A.alphabet
            if !haskey(s, c)
                addEdge!(A, s, c, junkyard)
            end
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
            if target ∉ reachableStates
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