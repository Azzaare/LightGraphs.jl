function size_decycling_vda(
    components::Vector{Vector{Int}},
    versions::Vector{Vector{DateTime}}
    )
    Σ = mapreduce(length, +, 0, components)
    return mapreduce(length, +, Σ, versions)
end

function add_edges_vda!(
    digraph::AbstractGraph,
    knowledges::AbstractVector{T},
    component::Vector{Int},
    comp_versions::Vector{Tuple{DateTime, Int}},
    old_nv::Int
    ) where T<:AbstractFloat
    last_input = Dict([(u, u) => u for u in component])
    for (dt, u) in comp_versions
        add_vertex!(digraph)
        push!(knowledges, zero(T))
        previous_u = last_input[(u, u)]
        last_input[(u, u)] = nv(digraph)
        add_edge!(digraph, last_input[(u, u)], previous_u)

        for v in component
            if has_edge(digraph, u, v) && last_input[(v, v)] > old_nv && !haskey(last_input, (u, v))
                last_input[(u, v)] = last_input[v, v]
            end
        end
    end
    for (u, v) in keys(last_input)
        if u != v && haskey(last_input, (u, v))
            add_edge!(digraph, last_input[(u, u)], last_input[(u, v)])
        end
    end
    for (id, u) in enumerate(component)
        add_edge!(digraph, old_nv + id, last_input[(u, u)])
    end
end

function exchange_knowledges_vda!(
    knowledges::AbstractVector{T},
    component::Vector{Int},
    old_nv::Int
    ) where T<:AbstractFloat
    append!(knowledges, zeros(T, length(component))) # Expand knowledges vector
    for (i, v) in enumerate(component)
        aux = knowledges[v]
        knowledges[v] = knowledges[old_nv + i]
        knowledges[old_nv + i] = aux
    end
end

@traitfn function move_edges_vda!(
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

# TODO: consider a variant for when DateTime are equal
function version_decycling!(
    digraph::AbstractGraph,
    knowledges::AbstractVector{T},
    components::Vector{Vector{Int}},
    colors::Vector{Int},
    versions::Vector{Vector{Tuple{DateTime, Int}}}
    ) where T<:AbstractFloat
    for (color, component) in enumerate(components)
        old_nv = nv(digraph)
        add_vertices!(digraph, length(component)) # v_in vertices
        exchange_knowledges_vda!(knowledges, component, old_nv) # Expand knowledges; in = 1, out = 0
        add_edges_vda!(digraph, knowledges, component, versions[color], old_nv) # inner pathes edges
        move_edges_vda!(digraph, colors, component, old_nv, color) # move old edges
    end
end
