"""
    AbstractDecyclingAlgorithm

Abstract type that allows users to pass in their preferred decycling algorithm
"""
abstract type AbstractDecyclingAlgorithm end

"""
    AbstractFullDecyclingAlgorithm

Abstract type that allows users to pass in their preferred full graph decycling algorithm (usually before computing the flow of knowledge)
"""
abstract type AbstractFullDecyclingAlgorithm <: AbstractDecyclingAlgorithm end

"""
    AbstractPartialDecyclingAlgorithm

Abstract type that allows users to pass in their preferred full graph decycling algorithm (usually before computing the flow of knowledge)
"""
abstract type AbstractPartialDecyclingAlgorithm <: AbstractDecyclingAlgorithm end

"""
    PathDecyclingAlgorithm <: AbstractDecyclingAlgorithm

Forces the decycling function to use the path-decycling algorithm.
"""
struct PathDecyclingAlgorithm <: AbstractFullDecyclingAlgorithm end

"""
    VersionDecyclingAlgorithm <: AbstractFullDecyclingAlgorithm

Forces the decycling function to use the version-decycling algorithm.
"""
struct VersionDecyclingAlgorithm <: AbstractFullDecyclingAlgorithm end

"""
    ContractionDecyclingAlgorithm <: AbstractFullDecyclingAlgorithm

Forces the decycling function to use the contraction-decycling algorithm.
"""
struct ContractionDecyclingAlgorithm <: AbstractFullDecyclingAlgorithm end

"""
    StorageDecyclingAlgorithm <: AbstractPartialDecyclingAlgorithm

Forces the decycling function to use the storage-decycling algorithm.
"""
struct StorageDecyclingAlgorithm <: AbstractPartialDecyclingAlgorithm end

"""
    NoDecyclingAlgorithm <: AbstractPartialDecyclingAlgorithm

Forces the decycling function to not be used (for efficiency in flow_knowledge)
"""
struct NoDecyclingAlgorithm <: AbstractDecyclingAlgorithm end

# Method for contraction-decycling algorithm
function decycling!(
    g::AbstractGraph,
    knowledges::AbstractVector{T},
    algorithm::ContractionDecyclingAlgorithm,
    components::Vector{Vector{Int}},
    colors::Vector{Int},
    versions::Vector{Vector{DateTime}}
    ) where T<:AbstractFloat
    contraction_decycling!(g, knowledges, components, colors)
end

# Method for path-decycling algorithm
function decycling!(
    g::AbstractGraph,
    knowledges::AbstractVector{T},
    algorithm::VersionDecyclingAlgorithm,
    components::Vector{Vector{Int}},
    colors::Vector{Int},
    versions::Vector{Vector{DateTime}}
    ) where T<:AbstractFloat
    if isempty(versions)
        warn("Empty versions information: switch to contraction-decycling algorithm.")
        contraction_decycling!(g, knowledges, components, colors)
    else
        versions_by_component = fill(Vector{Tuple{DateTime, Int}}(), length(components))
        for (node_id, node_version) in enumerate(versions)
            for dt in node_version
                id_insert = findfirst(x -> x[1] > dt, versions_by_component[colors[node_id]])
                if id_insert == 0
                    id_insert = length(versions_by_component[colors[node_id]]) + 1
                end
                insert!(versions_by_component[colors[node_id]], id_insert, (dt, node_id))
            end
        end
        version_decycling!(g, knowledges, components, colors, versions_by_component)
    end
end

# Method for path-decycling algorithm
function decycling!(
    g::AbstractGraph,
    knowledges::AbstractVector{T},
    algorithm::PathDecyclingAlgorithm,
    components::Vector{Vector{Int}},
    colors::Vector{Int},
    versions::Vector{Vector{DateTime}}
    ) where T<:AbstractFloat
    path_decycling!(g, knowledges, components, colors)
end

@traitfn function notsingle_strongly_connected_components(g::::IsDirected)
    components = sort!(strongly_connected_components(g); by = length)
    first_notsimple = findfirst(x -> length(x) > 1, components)
    if first_notsimple > 0
        return components[first_notsimple:end]
    else
        return []
    end
end

"""
    decycling(g[, algorithm][, knowledges])

Generic decycling function for `g`. Uses decycling algorithm `algorithm`.

- If `algorithm` is not specified, it will default to [`MergeDecyclingAlgorithm`](@ref).
- If `knowledges` is not specified, it will default to `1`.

Return a tuple of (acyclic_g, knowledge_vector).

### Usage Example:

```jldoctest
julia> flow_graph = g(8) # Create a flow-graph
julia> flow_edges = [
(1,2,10),(1,3,5),(1,4,15),(2,3,4),(2,5,9),
(2,6,15),(3,4,4),(3,6,8),(4,7,16),(5,6,15),
(5,8,10),(6,7,15),(6,8,10),(7,3,6),(7,8,10)
]

julia> capacity_matrix = zeros(Int, 8, 8)  # Create a capacity matrix

julia> for e in flow_edges
    u, v, f = e
    add_edge!(flow_graph, u, v)
    capacity_matrix[u,v] = f
end

julia> f, F = maximum_flow(flow_graph, 1, 8) # Run default maximum_flow without the capacity_matrix

julia> f, F = maximum_flow(flow_graph, 1, 8) # Run default maximum_flow with the capacity_matrix

julia> f, F = maximum_flow(flow_graph,1,8,capacity_matrix,algorithm=EdmondsKarpAlgorithm()) # Run Edmonds-Karp algorithm

julia> f, F = maximum_flow(flow_graph,1,8,capacity_matrix,algorithm=DinicAlgorithm()) # Run Dinic's algorithm

julia> f, F, labels = maximum_flow(flow_graph,1,8,capacity_matrix,algorithm=BoykovKolmogorovAlgorithm()) # Run Boykov-Kolmogorov algorithm

```
"""

function decycling!(
    g::AbstractGraph;                           # the input graph
    knowledges::AbstractVector{T} =        # knowledge generated at each node
    ones(Float64, nv(g)),
    algorithm::AbstractDecyclingAlgorithm  =    # keyword argument for algorithm
    PathDecyclingAlgorithm(),
    versions::Vector{Vector{DateTime}} = Vector{Vector{DateTime}}()
    ) where T<:AbstractFloat

    components = notsingle_strongly_connected_components(g)
    colors = zeros(Int, nv(g))

    # Color the each node with its component id. Single-sized components are uncolored (0)
    for (color, component) in enumerate(components)
        for node in component
            colors[node] = color
        end
    end
    decycling!(g, knowledges, algorithm, components, colors, versions)
end

function size_decycling(
    k::Int,
    algorithm::PathDecyclingAlgorithm
    )
    return size_decycling_pda(k)
end

function size_decycling(
    k::Int,
    algorithm::ContractionDecyclingAlgorithm
    )
    return size_decycling_cda(k)
end

function size_decycling(
    g::AbstractGraph;
    algorithm::AbstractDecyclingAlgorithm =
    PathDecyclingAlgorithm(),
    versions::Vector{Vector{DateTime}} = Vector{Vector{DateTime}}()
    )
    if algorithm == VersionDecyclingAlgorithm()
        if isempty(versions)
            return size_decycling(g; algorithm = ContractionDecyclingAlgorithm())
        else
            return size_decycling_vda(notsingle_strongly_connected_components(g), versions)
        end
    end
    return mapreduce(x -> size_decycling(length(x),
        algorithm), +, 0, notsingle_strongly_connected_components(g))
end
