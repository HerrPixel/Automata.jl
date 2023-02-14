#=
@testset "Shorthand constructors are equivalent" begin
    a = Automata.automaton()

    b = Automata.automaton(["epsilon"], Vector{Char}(), "epsilon", Vector{String}(), Vector{Tuple{String,Char,String}}())

    println(a)
    println(b)
    @test a == b
end

# add Base.(==) for state and automata

=#
