@testset "Shorthand constructors are equivalent" begin
    a = Automata.automaton()
    b = Automata.automaton(["epsilon"], Vector{Char}(), "epsilon", Vector{String}(), Vector{Tuple{String,Char,String}}())

    @test a == b
end

@testset "building automata is correct" begin
    a = Automata.automaton()
    s = Automata.state("a")

    Automata.addState!(a, s)

    b = Automata.automaton(["epsilon", "a"], Vector{Char}(), "epsilon", Vector{String}(), Vector{Tuple{String,Char,String}}())

    @test a == b

    Automata.addTerminalState!(a, s)
    b = Automata.automaton(["epsilon", "a"], Vector{Char}(), "epsilon", ["a"], Vector{Tuple{String,Char,String}}())

    @test a == b

    Automata.addSymbol!(a, 'a')
    b = Automata.automaton(["epsilon", "a"], ['a'], "epsilon", ["a"], Vector{Tuple{String,Char,String}}())

    @test a == b

    Automata.addEdge!(a, a.initialState, 'a', s)
    b = Automata.automaton(["epsilon", "a"], ['a'], "epsilon", ["a"], [("epsilon", 'a', "a")])

    @test a == b
end

@testset "terminal behaviour is correct" begin
    a = Automata.automaton()
    s = Automata.state("a")

    Automata.addState!(a, s)
    Automata.addTerminalState!(a, s)

    @test Automata.isTerminal(a, s)
    @test !Automata.isTerminal(a, a.initialState)
end

#= tests to add:
- semantic equals true and false tests
- adding terminal states not already contained in the automata
- string and state functions are equal
- adding edge for states not already in the automata
- walkedge true and false test
- removing state with existing and non-exisiting state
- removing terminal state
=#