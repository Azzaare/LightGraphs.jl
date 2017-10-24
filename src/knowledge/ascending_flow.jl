# In the sense of ascending flow of knowledge, this function returns the leaves.
# However, it corresponds to roots in the graph.
function find_leaves_af(
    g::AbstractGraph
    )
    leaves = Vector{Int}()
    for v in vertices(g)
        if indegree(g, v) < 1
            push!(leaves, v)
        end
    end
    return leaves
end

function ascending_flow(
    g::AbstractGraph,
    vfk::AbstractVector{T},
    efk::Dict{<:Any,T},
    decycling::NoDecyclingAlgorithm
    ) where T <: AbstractFloat
    marks = Dict((src(e), dst(e)) => false for e in edges(g)) # Mark if an edge has been already visited
    dequeue = find_leaves_af(g)
    while !isempty(dequeue)
        v = splice!(dequeue, 1) # TODO: check alternative for pop_first
        for w in out_neighbors(g, v)
            if !marks[(v, w)]
                marks[(v, w)] = true
                knowledge = vfk[v] / T(outdegree(g, v))
                aux = vfk[w]
                vfk[w] += knowledge
                efk[(v, w)] = get!(efk, (v, w), 0.) + knowledge
                # TODO: rearrange for short-circuit evaluation
                if mapreduce(x -> marks[(x, w)], &, true, in_neighbors(g, w))
                    push!(dequeue, w)
                end
            end
        end
    end
    return vfk
end

function ascending_flow(
    g::AbstractGraph,
    vfk::AbstractVector{T},
    efk::Dict{<:Any,T},
    decycling::AbstractFullDecyclingAlgorithm,
    versions::Vector{Vector{DateTime}}
    ) where T <: AbstractFloat
    old_nv = nv(g)
    decycling!(g; knowledges = vfk, algorithm = decycling, versions = versions)
    return ascending_flow(g, vfk, efk, NoDecyclingAlgorithm())[1:old_nv]
end
