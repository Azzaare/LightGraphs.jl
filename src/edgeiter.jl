type EdgeIterState
    s::Int  # src vertex
    di::Int # index into adj of dest vertex
    fin::Bool
end

type EdgeIter
    m::Int
    adj::Vector{Vector{Int}}
    directed::Bool
end

eltype(::Type{EdgeIter}) = Edge

EdgeIter(g::Graph) = EdgeIter(ne(g), g.fadjlist, false)
EdgeIter(g::DiGraph) = EdgeIter(ne(g), g.fadjlist, true)

function _next(eit::EdgeIter, state::EdgeIterState = EdgeIterState(1,1,false))
    while state.s <= length(eit.adj)
        arr = eit.adj[state.s]
        while state.di <= length(arr)
            if eit.directed || state.s <= arr[state.di]
                return state
            end
            state.di += 1
        end
        state.s += 1
        state.di = 1
    end
    state.fin = true
    return state
end

start(eit::EdgeIter) = _next(eit)
done(eit::EdgeIter, state::EdgeIterState) = state.fin
length(eit::EdgeIter) = eit.m

function next(eit::EdgeIter, state)
    edge = Edge(state.s, eit.adj[state.s][state.di])
    state.di += 1
    return(edge, _next(eit, state))
end

function _isequal(e1::EdgeIter, e2)
    for e in e2
        s, d = e
        found = length(searchsorted(e1.adj[s], d)) > 0
        if !e1.directed
            found = found || length(searchsorted(e1.adj[d],s)) > 0
        end
        !found && return false
    end
    return true
end
==(e1::EdgeIter, e2::AbstractArray{Edge,1}) = _isequal(e1, e2)
==(e1::AbstractArray{Edge,1}, e2::EdgeIter) = _isequal(e2, e1)
==(e1::EdgeIter, e2::Set{Edge}) = _isequal(e1, e2)
==(e1::Set{Edge}, e2::EdgeIter) = _isequal(e2, e1)


function ==(e1::EdgeIter, e2::EdgeIter)
    length(e1.adj) == length(e2.adj) || return false
    e1.directed == e2.directed || return false
    for i in 1:length(e1.adj)
        e1.adj[i] == e2.adj[i] || return false
    end
    return true
end

show(io::IO, eit::EdgeIter) = write(io, "EdgeIter $(eit.m)")
show(io::IO, s::EdgeIterState) = write(io, "EdgeIterState [$(s.s), $(s.di), $(s.fin)]")
