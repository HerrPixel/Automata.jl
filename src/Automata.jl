module Automata

using DataStructures

include("Automaton.jl")
include("OperationsOnAutomata.jl")

export state, automaton
export addState!, addEdge!, addSymbol!, addTerminalState!
export semanticEquals, walkEdge, isTerminal
export removeState!, removeTerminalState!

export complete!, reduceNonAccessibleStates!, isAccepted, complement!, hasLoop

end # module Automata
