# Automata module in Julia

This module models a deterministic finite automata in Julia.

All common operations on automata are supported, like adding states/edges, making states terminal or removing them from the terminal set as well as making complements, completing missing edges and finding loops, i.e. the represented language is infinite.

Current implemented features:
- adding and removing states
- adding and removing symbols from the alphabet
- adding edges
- checking words for acceptabilty
- completing missing edges
- deleting non-accesible states and edges
- building a complement automata
- detecting reachable loops in the automata 

