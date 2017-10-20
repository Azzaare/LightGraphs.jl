function permutation(n::Int, k::Int)
    return reduce(*, 1, (n - k + 1):n)
end

function sum_partial_permutation(k::Int)
    return mapreduce(x -> permutation(k, x), +, 0, 1:k)
end

function size_decycling(k::Int)
    return k + sum_partial_permutation(k)
end

function add_pathes_pda!(
    g::AbstractGraph,
    knowledges::AbstractVector{T},
    old_nv::Int,
    comp_dict::Dict{Int, Int},
    i::Int
    ) where T<:AbstractFloat
    v_out = pop!(comp_dict, i)
    v_in = old_nv + i
    cv = nv(g) # current vertex
    add_edge!(g, v_in, cv)
    add_edge!(g, cv, v_out)
    for j in keys(comp_dict)
        if has_edge(g, comp_dict[j], v_out)
            add_vertex!(g) # Add next vertex in current path
            push!(knowledges, zero(T))
            add_edge!(g, cv, nv(g))
            add_pathes_pda!(g, knowledges, old_nv, deepcopy(comp_dict), j)
        end
    end
end

function add_pathes_pda!(
    digraph::AbstractGraph,
    knowledges::AbstractVector{T},
    component::Vector{Int},
    old_nv::Int
    ) where T<:AbstractFloat
    for i in 1:length(component)
        comp_dict = Dict{Int, Int}(enumerate(component))
        add_vertex!(digraph) # Add first vertex of path starting from i
        push!(knowledges, zero(T))
        add_pathes_pda!(digraph, knowledges, old_nv, comp_dict, i)
    end
end

@traitfn function move_edges_pda!(
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

function exchange_knowledges!(
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

function path_decycling!(
    digraph::AbstractGraph,
    knowledges::AbstractVector{T},
    components::Vector{Vector{Int}},
    colors::Vector{Int}
    ) where T<:AbstractFloat
    for (color, component) in enumerate(components)
        old_nv = nv(digraph)
        add_vertices!(digraph, length(component)) # v_in vertices
        exchange_knowledges!(knowledges, component, old_nv) # Expand knowledges; in = 1, out = 0
        add_pathes_pda!(digraph, knowledges, component, old_nv) # inner pathes edges
        move_edges_pda!(digraph, colors, component, old_nv, color) # move old edges
    end
end
