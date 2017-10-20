# using TikzGraphs, TikzPictures

@testset "Knowledge and decycling" begin
    g3 = DiGraph(3)
    add_edge!(g3, 1, 2)
    add_edge!(g3, 2, 3)
    add_edge!(g3, 3, 1)
    g4 = DiGraph(4)
    add_edge!(g4, 1, 2)
    add_edge!(g4, 2, 1)
    add_edge!(g4, 2, 3)
    add_edge!(g4, 3, 4)
    add_edge!(g4, 4, 3)
    for g in [CompleteDiGraph(2), g3, g4]
        println(g)
        V = flow_knowledge(g)
        println(V)
    end
end
