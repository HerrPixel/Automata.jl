
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