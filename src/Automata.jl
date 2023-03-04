module Automata

using DataStructures

include("Automaton.jl")
include("OperationsOnAutomata.jl")

export state, automaton
export addState!, addEdge!, addSymbol!, addTerminalState!
export semanticEquals, walkEdge, isTerminal
export removeState!, removeTerminalState!, removeEdge!

export complete!, reduceNonAccessibleStates!, isAccepted, complement!, hasLoop, minimalize, Intersection, Union, Concatenation

end # module Automata