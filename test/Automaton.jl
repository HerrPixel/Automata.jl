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

    Automata.addEdge!(a, "epsilon", 'a', "a")
    b = Automata.automaton(["epsilon", "a"], ['a'], "epsilon", ["a"], [("epsilon", 'a', "a")])

    @test a == b
end

