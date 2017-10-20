function find_leaves(
    g::AbstractGraph
    )
    leaves = Vector{Int}()
    for v in vertices(g)
        if indegree(g, v) <= 1
            push!(leaves, v)
        end
    end
    return leaves
end

function ascending_flow(
    g::AbstractGraph,
    vfk::AbstractVector{TF},
    efk::Dict{<:Any,TF},
    decycling::NoDecyclingAlgorithm
    ) where TF <: AbstractFloat
    marks = Dict((src(e), dst(e)) => false for e in edges(g)) # Mark if an edge has been already visited
    dequeue = find_leaves(g)
    while !isempty(dequeue)
        v = splice!(dequeue, 1) # TODO: check alternative for pop_first
        for w in out_neighbors(g, v)
            if !marks[(v, w)]
                marks[(v, w)] = true
                knowledge = vfk[v] / TF(outdegree(g, v))
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
    vfk::AbstractVector{TF},
    efk::Dict{<:Any,TF},
    decycling::AbstractFullDecyclingAlgorithm
    ) where TF <: AbstractFloat
    old_nv = nv(g)
    decycling!(g; knowledges = vfk, algorithm = decycling)
    return ascending_flow(g, vfk, efk, NoDecyclingAlgorithm())[1:old_nv]
end
