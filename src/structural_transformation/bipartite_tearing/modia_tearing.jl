# This code is from the Modia project and is licensed as follows:
# https://github.com/ModiaSim/Modia.jl/blob/b61daad643ef7edd0c1ccce6bf462c6acfb4ad1a/LICENSE

################################################
#
# Functions to tear systems of equations
#
# Author: Martin Otter, DLR-SR (first version: Jan. 14, 2017)
#
# Details are described in the paper:
#   Otter, Elmqvist (2017): Transformation of Differential Algebraic Array Equations to
#                           Index One Form. Modelica'2017 Conference.
#
################################################

"""
    (eSolved, vSolved, eResidue, vTear) = tearEquations!(td, Gsolvable, es, vs; eSolvedFixed=Int[], vSolvedFixed=Int[], vTearFixed=Int[])

Equations es shall be solved with respect to variables vs. The function returns
the teared equation so that if vTear is given, vSolved can be computed from eSolved
in a forward sequence (so solving eSolved[1] for vSolved[1], eSolved[2] for vSolved[2],
and so on). vTear must be selected, so that the equations eResidues are fulfilled.
Equations es are the union of eSolved and eResidue.
Variables vs are the union of vSolved and vTear.

Gsolvable defines the variables that can be explicitly solved in every equation without influencing the solution space
(= rank preserving operation).

eSolvedFixed/vSolvedFixed must be a DAG starting at eSolvedFixed/SolvedFixed[1]
"""
function tearEquations!(ict::IncrementalCycleTracker, Gsolvable, es::Vector{Int}, vs::Vector{Int};
                        eSolvedFixed::Vector{Int}=Int[], vSolvedFixed::Vector{Int}=Int[], vTearFixed::Vector{Int}=Int[])
    G = ict.graph
    vActive = BitSet(vs)
    vMatched = BitSet()

    esReduced = setdiff(es, eSolvedFixed)
    # println("    es = ", es, ", eSolvedFixed = ", eSolvedFixed, ", esReduced = ", esReduced)
    # println("    vs = ", vs, ", vSolvedFixed = ", vSolvedFixed)
    for eq in esReduced  # iterate only over equations that are not in eSolvedFixed
        for vj in Gsolvable[eq]
            if !(vj in vMatched) && (vj in vActive)
                r = add_edge_checked!(ict, Iterators.filter(!=(vj), G.graph.fadjlist[eq]), vj) do G
                    G.matching[vj] = eq
                    push!(vMatched, vj)
                end
                r && break
            end
        end
    end

    vSolved = filter(in(vMatched), topological_sort(ict))
    inv_matching = Union{Missing, Int}[missing for _ = 1:nv(G)]
    for (v, eq) in pairs(G.matching)
        eq === unassigned && continue
        inv_matching[v] = eq
    end
    eSolved = getindex.(Ref(inv_matching), vSolved)
    vTear = setdiff(vs, vSolved)
    eResidue = setdiff(es, eSolved)
    return (eSolved, vSolved, eResidue, vTear)
end
