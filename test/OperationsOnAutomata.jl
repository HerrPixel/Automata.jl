@testset "completing Automata" begin
    a = automaton()
    b = automaton()

    addSymbol!(a, 'a')
    addEdge!(a, "epsilon", 'a', "a")

    addSymbol!(b, 'a')
    addEdge!(b, "epsilon", 'a', "a")

    #=
        Both automata are:
          ┌─┐       ┌─┐
        ->│ε│ ─(a)─>│a│
          └─┘       └─┘
    =#

    @test a == b
    @test isnothing(walkEdge(a.states["a"], 'a')) # edge does not exist

    complete!(a)

    #=
        Now a is:
          ┌─┐       ┌─┐       ┌────────┐─┐
        ->│ε│ ─(a)─>│a│ ─(a)─>│junkyard│(a)
          └─┘       └─┘       └────────┘<┘
    =#

    @test a != b
    @test !isnothing(walkEdge(a.states["a"], 'a')) # edge exists now

    complete!(b)
    complete!(a)

    #=
        Both should still be:
          ┌─┐       ┌─┐       ┌────────┐─┐
        ->│ε│ ─(a)─>│a│ ─(a)─>│junkyard│(a)
          └─┘       └─┘       └────────┘<┘
    =#

    @test a == b # completing an already completed automata changes nothing
end

@testset "reduce non accessible states" begin
    a = automaton()
    b = automaton()

    addSymbol!(a, 'a')
    addEdge!(a, "a", 'a', "epsilon")

    addSymbol!(b, 'a')
    addEdge!(b, "a", 'a', "epsilon")

    #=
        Both automata are:
          ┌─┐       ┌─┐
        ->│ε│<─(a)─ │a│
          └─┘       └─┘
    =#

    @test a == b
    @test semanticEquals(a, b)

    reduceNonAccessibleStates!(a)

    #=
        Now a is:
          ┌─┐
        ->│ε│
          └─┘
    =#

    @test a != b                # a has lost a state
    @test semanticEquals(a, b)  # but semantically, a is still the same

    reduceNonAccessibleStates!(b)
    reduceNonAccessibleStates!(a)

    @test a == b # reducing twice, changes nothing
end

@testset "accepting behaviour" begin
    a = automaton()

    addSymbol!(a, 'a')
    addEdge!(a, "epsilon", 'a', "a")
    addTerminalState!(a, "a")

    #=
        a is:
          ┌─┐      ╔═╗
        ->│ε│─(a)─>║a║
          └─┘      ╚═╝
    =#

    @test !isAccepted(a, "")
    @test isAccepted(a, "a")
    @test !isAccepted(a, "b") # words with symbols not in the alphabet

    addTerminalState!(a, "epsilon")

    #=
        a is:
          ╔═╗      ╔═╗
        ->║ε║─(a)─>║a║
          ╚═╝      ╚═╝
    =#

    @test isAccepted(a, "") # correctly recognizes empty words
end

@testset "complement automata" begin
    a = automaton()

    addSymbol!(a, 'a')
    addEdge!(a, "epsilon", 'a', "a")
    addTerminalState!(a, "a")

    #=
        a is:
          ┌─┐      ╔═╗
        ->│ε│─(a)─>║a║
          └─┘      ╚═╝
    =#

    @test isTerminal(a, "a")
    @test !isTerminal(a, "epsilon")

    complement!(a)

    #=
        a is:
          ╔═╗      ┌─┐
        ->║ε║─(a)─>│a│
          ╚═╝      └─┘
    =#

    @test !isTerminal(a, "a")
    @test isTerminal(a, "epsilon")
end

@testset "finding loops" begin
    a = automaton()

    addSymbol!(a, 'a')
    addEdge!(a, "epsilon", 'a', "a")
    addTerminalState!(a, "a")

    #=
        a is:
          ┌─┐      ╔═╗
        ->│ε│─(a)─>║a║
          └─┘      ╚═╝
    =#

    @test !hasLoop(a)

    addEdge!(a, "a", 'a', "a")

    @test hasLoop(a)

    removeEdge!(a.states["a"], 'a')
    addEdge!(a, "a", 'a', "aa")
    addEdge!(a, "aa", 'a', "a")

    #=
        Now a is:
          ┌─┐       ╔═╗<─(a)─ ┌──┐
        ->│ε│ ─(a)─>║a║       │aa│
          └─┘       ╚═╝ ─(a)─>└──┘
    =#

    @test hasLoop(a)

    removeTerminalState!(a, "a")

    #=
        Now a is:
          ┌─┐       ┌─┐<─(a)─ ┌──┐
        ->│ε│ ─(a)─>│a│       │aa│
          └─┘       └─┘ ─(a)─>└──┘
    =#

    @test !hasLoop(a) # we only want to detect loops that lead to
    # a reacheable terminal state, therefore this is not a loop we
    # want to detect
end

@testset "minmalizing automata" begin
    a = automaton()

    addSymbol!(a, 'a')
    addEdge!(a, "epsilon", 'a', "a")
    addTerminalState!(a, "a")
    addEdge!(a, "a", 'a', "a")

    b = automaton()

    addSymbol!(b, 'a')
    addEdge!(b, "epsilon", 'a', "a")
    addTerminalState!(b, "a")
    addEdge!(b, "a", 'a', "a")

    #=
        both automata are:
          ┌─┐       ╔═╗─┐
        ->│ε│ ─(a)─>║a║(a)
          └─┘       ╚═╝<┘
    =#

    a = minimalize(a)

    @test semanticEquals(a, b) # minimalizing an already minimized automata changes nothing

    addTerminalState!(a, a.initialState)

    #=
        Now a is:
          ╔═╗       ╔═╗─┐
        ->║ε║ ─(a)─>║a║(a)
          ╚═╝       ╚═╝<┘
    =#

    a = minimalize(a)

    @test !semanticEquals(a, b) # a should be reduced to a single state now
end

@testset "Intersection of automata" begin
    a = automaton()
    b = automaton()

    addEdge!(a, "epsilon", 'a', "a")
    addEdge!(a, "a", 'a', "aa")
    addEdge!(a, "aa", 'a', "aa")
    addTerminalState!(a, "aa")
    #= a is the automata that accepts words over {a} that have atleast 2 a's
          ┌─┐      ┌─┐       ╔═╗─┐
        ->│ε│─(a)─>│a│─(a)─> ║a║(a)
          └─┘      └─┘       ╚═╝<┘
    =#

    addEdge!(b, "epsilon", 'a', "a")
    addEdge!(b, "a", 'a', "epsilon")
    addTerminalState!(b, "a")
    #= b is the automata that accepts words that have an odd number of a's
      ┌─┐─(a)─>╔═╗
      │ε│      ║a║
      └─┘<─(a)─╚═╝
    =#
    c = Automata.Intersection(a, b)
    c = minimalize(c)

    d = automaton()

    addEdge!(d, "epsilon", 'a', "a")
    addEdge!(d, "a", 'a', "aa")
    addEdge!(d, "aa", 'a', "aaa")
    addEdge!(d, "aaa", 'a', "aa")
    addTerminalState!(d, "aaa")
    #= d is now the intersection of those two, the language with odd a's and words with length >= 3
          ┌─┐      ┌─┐       ┌─┐─(a)─>╔═╗
        ->│ε│─(a)─>│a│─(a)─> │a│      ║a║
          └─┘      └─┘       └─┘<─(a)─╚═╝
    =#

    @test semanticEquals(c, d)
end

@testset "Union of automata" begin
    a = automaton()
    b = automaton()

    addEdge!(a, "epsilon", 'a', "a")
    addEdge!(a, "a", 'a', "epsilon")
    addTerminalState!(a, "epsilon")
    #= a is the automata that accepts words that have an even number of a's
      ╔═╗─(a)─>┌─┐
      ║ε║      │a│
      ╚═╝<─(a)─└─┘
    =#

    addEdge!(b, "epsilon", 'a', "a")
    addEdge!(b, "a", 'a', "epsilon")
    addTerminalState!(b, "a")
    #= b is the automata that accepts words that have an odd number of a's
      ┌─┐─(a)─>╔═╗
      │ε│      ║a║
      └─┘<─(a)─╚═╝
    =#

    c = Automata.Union(a, b)
    c = minimalize(c)

    d = automaton()
    addEdge!(d, "epsilon", 'a', "epsilon")
    addTerminalState!(d, "epsilon")
    #=
    d should now be the union of those two, i.e. the automaton which
    accepts everything
        ╔═╗─┐
        ║ε║(a)
        ╚═╝<┘
    =#

    @test semanticEquals(c, d)
end

@testset "concatenating automata" begin
    a = automaton()

    addEdge!(a, "epsilon", 'a', "a")
    addEdge!(a, "a", 'a', "a")
    addTerminalState!(a, "a")

    #=
        a is:
          ┌─┐       ╔═╗─┐
        ->│ε│ ─(a)─>║a║(a)
          └─┘       ╚═╝<┘
          i.e. the automata that accepts words in {a}* with atleast one a
    =#

    b = automaton()
    addEdge!(b, "epsilon", 'b', "b")
    addEdge!(b, "b", 'b', "b")
    addTerminalState!(b, "b")

    #=
        b is:
          ┌─┐       ╔═╗─┐
        ->│ε│ ─(b)─>║b║(b)
          └─┘       ╚═╝<┘
          i.e. the automata that accepts words in {b}* with atleast one b
    =#

    @test isAccepted(a, "a")
    @test !isAccepted(a, "b")

    @test isAccepted(b, "b")
    @test !isAccepted(b, "a")

    c = Concatenation(a, b)

    # now c should accept words of the form {a}+{b}+ i.e. words with atleast one a first and then atleast one b

    @test isAccepted(c, "ab")
    @test !isAccepted(c, "a")
    @test !isAccepted(c, "b")
end