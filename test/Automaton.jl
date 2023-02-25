@testset "Constructors" begin
    @testset "Automata constructors are equivalent" begin
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

    @testset "Constructor throws error on wrong arguments" begin

        # Initial state is not part of the state list
        @test_throws ArgumentError automaton(["a"], Vector{Char}(), "b", Vector{String}())

        # accepting state is not part of the state list
        @test_throws ArgumentError automaton(["a"], Vector{Char}(), "a", ["b"])

        # edge has non-existing source
        @test_throws ArgumentError automaton(["a"], ['a'], "a", ["a"], [("b", 'a', "a")])

        # edge has non-exisiting target
        @test_throws ArgumentError automaton(["a"], ['a'], "a", ["a"], [("a", 'a', "b")])

        # edge uses non-existing symbol
        @test_throws ArgumentError automaton(["a"], ['a'], "a", ["a"], [("a", 'b', "a")])
    end
end

@testset "Equality Tests" begin

    @testset "States" begin
        s = state("s")
        t = state("t")
        u = state("u")

        #=
            Both states should be:
            ┌─┐      ┌─┐      ┌─┐
            │s│<-(a)-│a│-(b)->│t│
            └─┘      └─┘      └─┘
        =#

        a = state("a", Dict('a' => s, 'b' => t))
        b = state("a", Dict('a' => s, 'b' => t))

        @test a == b
        @test semanticEquals(a, b)

        #=
            Now b should be: (different named state)
            ┌─┐      ┌─┐      ┌─┐
            │s│<-(a)-│b│-(b)->│t│
            └─┘      └─┘      └─┘
        =#

        b = state("b", Dict('a' => s, 'b' => t))

        @test a != b
        @test semanticEquals(a, b)

        #=
            Now b should be: (different left neighbour)
            ┌─┐      ┌─┐      ┌─┐
            │u│<-(a)-│b│-(b)->│t│
            └─┘      └─┘      └─┘
        =#

        b = state("b", Dict('a' => u, 'b' => t))

        @test a != b
        @test semanticEquals(a, b)

        #=
            Now b should be: 
            ┌─┐-(a)->┌─┐
            │b│      │t│
            └─┘-(b)->└─┘
        =#

        b = state("b", Dict('a' => t, 'b' => t))

        @test a != b
        @test !semanticEquals(a, b)
    end

    @testset "Automata" begin
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
end

@testset "Building automata" begin

    @testset "adding states" begin
        #=
            Both automata should be:
              ┌─┐
            ->│ε│
              └─┘
        =#
        a = automaton()
        b = automaton()

        #=
            Now a is 
              ┌─┐  ┌─┐
            ->│ε│  │c│
              └─┘  └─┘
        =#
        addState!(a, "c")

        @test a != b

        c = state("c")

        #=
            Now b is also: 
              ┌─┐  ┌─┐
            ->│ε│  │c│
              └─┘  └─┘
        =#

        addState!(b, c)

        # this also tests the equality of the two addState! functions
        @test a == b
    end

    @testset "adding terminal states" begin
        #=
            Both automata should be:
              ┌─┐
            ->│ε│
              └─┘
        =#
        a = automaton()
        b = automaton()

        #=
            Now a is 
              ┌─┐  ╔═╗
            ->│ε│  ║c║
              └─┘  ╚═╝
        =#
        addTerminalState!(a, "c")

        @test a != b

        c = state("c")

        #=
            Now b is also:
              ┌─┐  ╔═╗
            ->│ε│  ║c║
              └─┘  ╚═╝
        =#
        addTerminalState!(b, c) # this also tests the equality of the two functions

        @test a == b

        #=
            Now a is:
              ╔═╗  ╔═╗
            ->║ε║  ║c║
              ╚═╝  ╚═╝
        =#
        addTerminalState!(a, "epsilon") # this is already a state in a

        @test a != b

        #=
            Now b is also:
              ╔═╗  ╔═╗
            ->║ε║  ║c║
              ╚═╝  ╚═╝
        =#
        epsilon = b.initialState
        addTerminalState!(b, epsilon) # this is already a state in b
        # this also tests the equality of the two functions

        @test a == b
    end

    @testset "adding Edges" begin
        #=
            Both automata should be:
              ┌─┐
            ->│ε│
              └─┘
        =#
        a = automaton()
        b = automaton()

        #=
            Now a is:
              ┌─┐ ─┐
            ->│ε│ (a)
              └─┘ <┘
        =#
        addSymbol!(a, 'a')
        addSymbol!(b, 'a')
        addEdge!(a, "epsilon", 'a', "epsilon")

        @test a != b

        #=
            Now b is:
              ┌─┐ ─┐
            ->│ε│ (a)
              └─┘ <┘
        =#
        epsilon = b.initialState
        addEdge!(b, epsilon, 'a', epsilon)

        @test a == b # this also tests the equality of both functions

        addSymbol!(a, 'b')
        addSymbol!(b, 'b')

        #=
            Now a is:
              ┌─┐ ─┬─(b)─> ┌─┐
            ->│ε│ (a)      │b│
              └─┘ <┘       └─┘
        =#
        addEdge!(a, "epsilon", 'b', "b") # b does not exist in the automata

        @test a != b

        #=
            Now b is also:
              ┌─┐ ─┬─(b)─> ┌─┐
            ->│ε│ (a)      │b│
              └─┘ <┘       └─┘
        =#
        b_state = state("b")
        addEdge!(b, epsilon, 'b', b_state) # this also tests the equality of both functions

        @test a == b

        #=
            Now a is:
              ┌─┐ ─┬─(b)─> ┌─┐        ┌─┐
            ->│ε│ (a)      │b│ <─(a)─ │c│
              └─┘ <┘       └─┘        └─┘
        =#
        addEdge!(a, "c", 'a', "b") # c is not a state in the automata

        @test a != b

        #=
            Now b is also:
              ┌─┐ ─┬─(b)─> ┌─┐        ┌─┐
            ->│ε│ (a)      │b│ <─(a)─ │c│
              └─┘ <┘       └─┘        └─┘
        =#
        c = state("c")
        addEdge!(b, c, 'a', b_state)

        @test a == b # tests the equality of both function signatures

        #=
            Now a is:
              ┌─┐ ─┬─(b)─> ┌─┐ <─(a)─ ┌─┐
            ->│ε│ (a)      │b│        │c│
              └─┘ <┘       └─┘ <─(c)─ └─┘
        =#
        addEdge!(a, "c", 'c', "b") # c is not a symbol of the automata

        @test a != b

        #=
            Now b is also:
              ┌─┐ ─┬─(b)─> ┌─┐ <─(a)─ ┌─┐
            ->│ε│ (a)      │b│        │c│
              └─┘ <┘       └─┘ <─(c)─ └─┘
        =#
        addEdge!(b, c, 'c', b_state)

        @test a == b # tests the equality of both function signatures
    end

    @testset "adding Symbols" begin
        a = automaton()
        b = automaton()

        @test a == b

        addSymbol!(a, 'a')

        @test a != b
    end
end

@testset "Deconstructing automata" begin
    @testset "Removing states" begin
        a = automaton()
        b = automaton()

        addState!(a, "a")
        addSymbol!(a, 'a')
        addEdge!(a, "epsilon", 'a', "a")

        a_state = state("a")
        addState!(b, a_state)
        addSymbol!(b, 'a')
        addEdge!(b, b.initialState, 'a', a_state)

        #=
            Both automata are:
              ┌─┐       ┌─┐
            ->│ε│ ─(a)─>│a│
              └─┘       └─┘
        =#

        @test_throws ArgumentError removeState!(a, "epsilon")     # we shouldn't be able to
        @test_throws ArgumentError removeState!(b, b.initialState) # remove initial states

        removeState!(a, "a")

        #=
            Now a is:
              ┌─┐
            ->│ε│
              └─┘
        =#

        @test a != b

        removeState!(b, a_state)

        #=
            Now both automata are:
              ┌─┐
            ->│ε│
              └─┘
        =#

        @test a == b
    end

    @testset "removing terminal states" begin
        a = automaton()
        b = automaton()

        a_state = state("a")

        addTerminalState!(a, "a")
        addTerminalState!(b, a_state)

        #=
            Now both automata are:
              ┌─┐  ╔═╗
            ->│ε│  ║a║
              └─┘  ╚═╝
        =#

        removeTerminalState!(a, "epsilon") # removing non-terminal states from the terminal 
        # states doesn't change anything

        @test a == b

        removeTerminalState!(b, b.initialState) # same as above but now with state argument

        @test a == b

        removeTerminalState!(a, "a")

        #=
            Now a is 
              ┌─┐  ┌─┐
            ->│ε│  │a│
              └─┘  └─┘
        =#

        @test a != b

        removeTerminalState!(b, a_state)

        #=
            Now b is also: 
              ┌─┐  ┌─┐
            ->│ε│  │a│
              └─┘  └─┘
        =#

        @test a == b

        c = automaton()
        addState!(c, "a")

        #=
            Now c is: 
              ┌─┐  ┌─┐
            ->│ε│  │a│
              └─┘  └─┘
        =#

        @test a == c # only terminal behaviour is changed,
        @test b == c # the state still exists
    end

    @testset "Removing edges" begin
        a = automaton()
        b = automaton()

        a_state = state("a")

        addState!(a, "a")
        addState!(b, a_state)

        addSymbol!(a, 'a')
        addSymbol!(b, 'a')

        addEdge!(a, "epsilon", 'a', "a")
        addEdge!(b, b.initialState, 'a', a_state)

        #=
            Both automata are:
              ┌─┐       ┌─┐
            ->│ε│ ─(a)─>│a│
              └─┘       └─┘
        =#

        @test a == b

        removeEdge!(a.states["a"], 'a') # removing non-exisiting edges does not do anything

        @test a == b

        removeEdge!(a_state, 'a') # same as above

        @test a == b

        removeEdge!(a.initialState, 'a')
        println(a.initialState)

        #=
            Now a is:
              ┌─┐       ┌─┐
            ->│ε│       │a│
              └─┘       └─┘
        =#

        @test a != b

        c = automaton()

        addSymbol!(c, 'a')
        addState!(c, "a")

        #=
            Now c is:
              ┌─┐       ┌─┐
            ->│ε│       │a│
              └─┘       └─┘
        =#

        @test a == c
    end
end

@testset "Getter functions" begin
    a = automaton()

    a_state = state("a")
    addTerminalState!(a, a_state)

    #=
         a is:
          ┌─┐  ╔═╗
        ->│ε│  ║a║
          └─┘  ╚═╝
    =#

    @test isTerminal(a, "a")
    @test isTerminal(a, a_state)
    @test !isTerminal(a, a.initialState)
    @test !isTerminal(a, "epsilon")
end

@testset "walkEdge" begin
    a = automaton()

    addSymbol!(a, 'a')
    addEdge!(a, "epsilon", 'a', "a")

    #=
        a is:
          ┌─┐       ┌─┐
        ->│ε│ ─(a)─>│a│
          └─┘       └─┘
    =#

    @test isnothing(walkEdge(a.initialState, 'b')) #non-existing edge
    @test walkEdge(a.initialState, 'a') == a.states["a"]
end