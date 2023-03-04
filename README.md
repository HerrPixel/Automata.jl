# Automata module in Julia

This module models a deterministic finite automata in Julia.

Below is a list of implemented features and a list of examples on how to use them.

Implemented features:
- adding and removing states
- adding symbols to the alphabet
- adding and removing edges
- adding and removing terminalilty of states
- checking states and automata for syntactic and semantic equality
- completing missing edges
- deleting non-accesible states and edges
- building a complement automata
- detecting reachable loops in the automata
- minimize automata
- get the automata for the union of the languages of two automata
- get the automata for the intersection of the languages of two automata
- get the automata for the concatenation of the languages of two automata

## Examples

### Building automata:

```julia
A = automaton()

addState!(A,"banana") # adds a new state named "banana"

addSymbol!(A,'a') # adds 'a' to the alphabet

addEdge!(A,"banana",'a',"apple") # adds an edge between "banana" and "apple" labeled by 'a'

addTerminalState!(A,"apple") # state "apple" is now a terminal state

```

### Deconstructing automata:

```julia
removeState!(A,"banana") # removes the state "banana" from A with every edge pointing to it. Can't remove initial states.

removeTerminalState!(A,"apple") # removes "apple" from the list of terminal states. It still exists in the automata but is not terminal anymore.

banana = A.states["banana"]

removeEdge!(banana,'a') # removes the outgoing edge from state "banana" labelled by 'a'
```

### Operations on Automata

```julia
complete!(A) # adds all non-existing edge, such that for each symbol 'c' in the alphabet of A, every state has an edge labelled by 'c'

reduceNonAccessibleStates!(A) # removes unreachable states and edges from A

complement!(A) # changes A such that it accepts its complement Language L^c

hasLoop(A) # returns true if A has a reachable loop, false otherwise

B = minimalize(A) # returns a new minimal automata B, such that L(A) = L(B) and B is minimal with this property.

C = Intersection(A,B) # returns an automaton C, such that L(C) = L(A) <intersected> L(B)

C = Union(A,B) # returns an automaton C, such that L(C) = L(A) <union> L(B)

C = Concatenation(A,B) # returns an automaton C, such that L(C) = L(A)L(B)
```

### Miscellaneous

```julia
A = automaton()
B = automaton()

A == B # checks whether A and B are completely the same, with same named states, edges, alphabets, etc.

semanticEquals(A,B) # checks whether A and B are the same up to renaming the states, i.e. there is an isomorphism f: states(A( -> states(B) between the states, such that if there is an edge between "c" and "d in A using symbol 'x', then there is an edge f(c) to f(d) using 'x' in B.

isTerminal(A,"apple") # returns true if "apple" is a terminal state in A, false otherwise
```