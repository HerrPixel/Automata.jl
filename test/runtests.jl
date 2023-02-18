#include("../src/Automata.jl")

using Automata
using Test

include("Automaton.jl")
include("OperationsOnAutomata.jl")

@testset "apfel" begin
    a = automaton()

    println(a)

    @test a == a
end


# https://discourse.julialang.org/t/writing-tests-in-vs-code-workflow-autocomplete-and-tooltips/57488/8