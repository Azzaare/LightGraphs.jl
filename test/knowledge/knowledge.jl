# using TikzGraphs, TikzPictures

@testset "Knowledge and decycling" begin
    g3 = DiGraph(3)
    add_edge!(g3, 1, 2)
    add_edge!(g3, 2, 3)
    add_edge!(g3, 3, 1)
    g4 = DiGraph(6)
    add_edge!(g4, 3, 6)
    add_edge!(g4, 4, 6)
    add_edge!(g4, 5, 1)
    add_edge!(g4, 1, 2)
    add_edge!(g4, 2, 1)
    add_edge!(g4, 2, 3)
    add_edge!(g4, 3, 4)
    add_edge!(g4, 4, 3)
    for g in [CompleteDiGraph(8), g3, g4]
        println(g)
        println("The maximum size of decycling is $(size_decycling(g, algorithm = PathDecyclingAlgorithm())).")
        V = flow_knowledge(g; decycling = PathDecyclingAlgorithm())
        println(V)
        # savegraph("/home/azzaare/size.jgz", g, compress=false)
        # t = plot(g)
        # TikzGraphs.save(PDF("/home/azzaare/size.pdf"), t)
    end

    # Tests for version-decycling
    h3 = CompleteDiGraph(3)
    add_vertices!(h3, 2)
    add_edge!(h3, 4, 1)
    add_edge!(h3, 4, 2)
    add_edge!(h3, 5, 3)

    vers = [
        [DateTime(2011), DateTime(2015)],
        [DateTime(2013)],
        [DateTime(2012), DateTime(2014), DateTime(2016)]
    ]
    println(h3)
    println("The maximum size of decycling is $(size_decycling(h3, algorithm = VersionDecyclingAlgorithm(), versions = vers)).")
    V = flow_knowledge(h3; decycling = VersionDecyclingAlgorithm(), versions = vers)
    println(V)
    # savegraph("/home/azzaare/size.jgz", h3, compress=false)
    # t = plot(h3)
    # TikzGraphs.save(PDF("/home/azzaare/size.pdf"), t)
end
