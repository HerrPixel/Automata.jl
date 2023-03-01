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