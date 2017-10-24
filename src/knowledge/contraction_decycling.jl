function size_decycling_cda(k::Int)
    return k + 1
end

function exchange_knowledges_cda!(
    knowledges::AbstractVector{T},
    component::Vector{Int},
    old_nv::Int
    ) where T<:AbstractFloat
    append!(knowledges, zeros(T, length(component) + 1)) # Expand knowledges vector
    for (i, v) in enumerate(component)
        aux = knowledges[v]
        knowledges[v] = knowledges[old_nv + i]
        knowledges[old_nv + i] = aux
    end
end

function add_inner_edges_cda!(
    g::AbstractGraph,
    knowledges::AbstractVector{T},
    component::Vector{Int},
    old_nv::Int
    ) where T<:AbstractFloat
    for (i, v) in enumerate(component)
        add_edge!(g, nv(g), v) # Arc from central vertex to v_out
        add_edge!(g, old_nv + i, nv(g)) # Arc from v_in to central vertex
    end
end

@traitfn function move_edges_cda!(
    g::::IsDirected,
    colors::Vector{Int},
    component::Vector{Int},
    old_nv::Int,
    color::Int
    )
    for (i, t) in enumerate(component)
        v_in = old_nv + i
        t_in_neighbors = in_neighbors(g, t)
        first_new = findfirst(x -> x > old_nv, t_in_neighbors)
        for s in t_in_neighbors[1:first_new-1]
            rem_edge!(g, s, t)
            if color != colors[s]
                add_edge!(g, s, v_in)
            end
        end
    end
end

function contraction_decycling!(
    digraph::AbstractGraph,
    knowledges::AbstractVector{T},
    components::Vector{Vector{Int}},
    colors::Vector{Int}
    ) where T<:AbstractFloat
    for (color, component) in enumerate(components)
        old_nv = nv(digraph)
        add_vertices!(digraph, length(component) + 1) # v_in vertices an central contracted vertex
        exchange_knowledges_cda!(knowledges, component, old_nv) # in = 1, out = 0
        add_inner_edges_cda!(digraph, knowledges, component, old_nv) # inner edges
        move_edges_cda!(digraph, colors, component, old_nv, color) # move old edges
    end
end
