@testset "Constructors" begin
  #=
      Both automata should be:
        ┌─┐
      ->│ε│
        └─┘
  =#
  a = Automata.automaton()
  b = Automata.automaton(["epsilon"], Vector{Char}(), "epsilon", Vector{String}(), Vector{Tuple{String,Char,String}}())

  @test a == b
end

@testset "Equality Tests" begin
  #=
      Both automata should be:
        ┌─┐
      ->│ε│
        └─┘
  =#
  a = Automata.automaton(["epsilon"], Vector{Char}(), "epsilon", Vector{String}(), Vector{Tuple{String,Char,String}}())
  b = Automata.automaton(["epsilon"], Vector{Char}(), "epsilon", Vector{String}(), Vector{Tuple{String,Char,String}}())

  @test a == b

  #=
      Now a is:
        ┌───┐
      ->│foo│
        └───┘
  =#
  a = Automata.automaton(["foo"], Vector{Char}(), "foo", Vector{String}(), Vector{Tuple{String,Char,String}}())

  @test a != b
  @test semanticEquals(a, b)

  #=
      Now a is:
        ┌───┐        ┌───┐
      ->│foo│--(a)-->│bar│
        └───┘        └───┘
  =#

  a = Automata.automaton(["foo", "bar"], ['a'], "foo", Vector{String}(), [("foo", 'a', "bar")])

  @test a != b
  @test !semanticEquals(a, b)
end

@testset "Building automata" begin
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

@testset "Terminal behaviour is correct" begin
  a = Automata.automaton()
  s = Automata.state("a")

  Automata.addState!(a, s)
  Automata.addTerminalState!(a, s)

  @test Automata.isTerminal(a, s)
  @test !Automata.isTerminal(a, a.initialState)
end

@testset "terminal states not already in the automaton" begin
  a = Automata.automaton()
  Automata.addTerminalState!(a, "end")
  # "end" is not a state in the automata
  # but should be added, alongside making it terminal

  b = Automata.automaton(["epsilon", "end"], Vector{Char}(), "epsilon", ["end"], Vector{Tuple{String,Char,String}}())

  @test a == b
end

@testset "edges with states not already in the automaton" begin
  a = Automata.automaton()

end


#= tests to add:
- equality test for states
- string and state functions are equal
- adding edge for states not already in the automata
- walkedge true and false test
- removing state with existing and non-exisiting state
- removing terminal state
=#