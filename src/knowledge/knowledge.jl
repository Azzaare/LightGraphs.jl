"""
    AbstractKnowledgeAlgorithm

Abstract type that allows users to pass in their preferred flow of knowledge algorithm
"""
abstract type AbstractKnowledgeAlgorithm end

"""
    AscendingFlowAlgorithm <: AbstractKnowledgeAlgorithm

Forces the decycling function to use the path-decycling algorithm.
"""
struct AscendingFlowAlgorithm <: AbstractKnowledgeAlgorithm end

function flow_knowledge(
    g::AbstractGraph,
    vfk::AbstractVector{TF},
    efk::Dict{<:Any,TF},
    knowledge_algorithm::AscendingFlowAlgorithm,
    decycling::AbstractDecyclingAlgorithm
    ) where TF <: AbstractFloat
    return ascending_flow(g, vfk, efk, decycling)
end

function flow_knowledge(
    g::AbstractGraph;
    vfk::AbstractVector{TF} = # vertices' flow of knowledge
    ones(Float64, nv(g)),
    efk::Dict{<:Any,TF} = # edges'    flow of knowledge
    Dict((src(e), dst(e)) => zero(Float64) for e in edges(g)),
    knowledge_algorithm::AbstractKnowledgeAlgorithm =
    AscendingFlowAlgorithm(),
    decycling::AbstractDecyclingAlgorithm =
    PathDecyclingAlgorithm()
    ) where TF <: AbstractFloat
    return flow_knowledge(g, vfk, efk, knowledge_algorithm, decycling)
end
