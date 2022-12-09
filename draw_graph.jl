using Compose
using Cairo
using Graphs,LightGraphs, GraphPlot, MetaGraphs, GraphRecipes, Plots
using Dates
include("PDI_resolution_exacte_BnC.jl")
include("PDI_resolution_heuristique.jl")
#include("re.jl")

function draw_all_graph(f,filename)
    objective_value(m),vec_xNode, vec_yNode,matrix_x=f(filename)
    t=size(matrix_x)[3]
    #println(matrix_x,t)
    now=Dates.format(Dates.now(),"yyyy-mm-dd HH:MM:SS")
    now=DateTime(now[1:16], dateformat"yyyy-mm-dd HH:MM")
    now_newformat=Dates.format(now,"yyyy-mm-dd HH:MM")
    now=replace(now_newformat,"-"=>"_"," "=>"_",":"=>"_")
    dir=string("./data/",now)
    mkdir(dir)
    for i in 1:t
        savename=string(dir,"/",now,"_t$i")
        #println(savename)
        draw_graph(matrix_x[:,:,i], vec_xNode, vec_yNode,savename)
    end
    return string(dir,"/",now,"_t")
end
function draw_graph(mat_arcTwoNodes, vec_xNode, vec_yNode ,savename)

    #=mat_arcTwoNodes =
   [0    1    0    0    0    0    0    0    0    0;
    0    0    0    0    0    1    0    0    0    0;
    0    0    0    0    0    0    0    0    0    1;
    1    0    0    0    1    0    0    0    0    0;
    0    0    0    0    0    1    0    0    0    0;
    1    0    0    1    0    0    0    1    0    0;
    0    1    1    0    0    0    0    0    0    0;
    0    0    0    0    0    0    0    0    1    0;
    0    0    0    0    1    0    0    0    0    0;
    0    0    0    0    0    1    1    0    1    0]=#

    # Load the packages
    # Create a generic graph
    #println(mat_arcTwoNodes)
    gr = Graphs.SimpleGraphs.SimpleDiGraph()#SimpleDiGraph()
    Graphs.SimpleGraphs.add_vertices!(gr, size(mat_arcTwoNodes, 1))
    # Add edges based on the adjacency matrix
    for i in 1:size(mat_arcTwoNodes, 1), j in 1:size(mat_arcTwoNodes, 2)
        #println("here",mat_arcTwoNodes[i,j])
        if isapprox(mat_arcTwoNodes[i,j], 1; atol = 1e-8) #&& i==1
            Graphs.SimpleGraphs.add_edge!(gr, i, j)
        elseif (i==j)
            Graphs.SimpleGraphs.add_edge!(gr, i, j)
        #    Graphs.SimpleGraphs.add_edge!(gr, i, 0)
        else
            nothing
        end
    end
    #println(gr)
    #=
    mgr = MetaDiGraph(gr)
    # Add the attribute of nodes
    for i in 1:size(mat_arcTwoNodes,1)
        set_props!(mgr, i, Dict(
            Symbol("vec_xNode") => vec_xNode[i],
            Symbol("vec_yNode") => vec_yNode[i]
            ))
    end=#
    # Attach the metagraph to the original graph
    #=mgr = MetaDiGraph(gr)
    # Add the attribute of nodes
    for i in 1:size(mat_arcTwoNodes,1)
        set_props!(mgr, i, Dict(
            Symbol("vec_xNode") => vec_xNode[i],
            Symbol("vec_yNode") => vec_yNode[i]
            ))
    end=#
    # Plot the graph
    #draw(PNG("karate.png", 16cm, 16cm),graphplot(gr, x=vec_xNode, y=vec_yNode))
    #draw(PNG("karate.png", 16cm, 16cm), graphplot(gr, x=vec_xNode, y=vec_yNode))
    savefig(graphplot(gr, x=vec_xNode, y=vec_yNode,nodeshape=:circle,nodesize=0.7,edgecolor = :blue,names = [string(i) for i in 1:size(mat_arcTwoNodes, 1)],fontsize = 18,linewidth=2),savename)
end


#=
@time begin
    #draw_all_graph(PDI_resolution_heuristique,"PRP_instances/A_014_ABS1_15_1.prp")
    #draw_all_graph(PDI_resolution_heuristique,"PRP_instances/A_020_ABS1_50_1.prp")
    #draw_all_graph(PDI_resolution_heuristique,"PRP_instances/A_025_ABS1_50_1.prp")
    #draw_all_graph(PDI_resolution_heuristique,"PRP_instances/A_030_ABS1_50_1.prp")
    #draw_all_graph(PDI_resolution_heuristique,"PRP_instances/A_050_ABS1_50_1.prp")
    #draw_all_graph(PDI_resolution_heuristique,"PRP_instances/B_200_instance1.prp")
end
=#


#draw_all_graph(PDI_resolution_exacte,"PRP_instances/A_005_#ABS1_15_z.prp")
#draw_all_graph(PDI_branch_and_cut,"PRP_instances/A_005_#ABS1_15_z.prp")
#draw_all_graph(PDI_resolution_exacte,"PRP_instances/A_006_ABS1_15_1.prp")
#draw_all_graph(PDI_branch_and_cut,"PRP_instances/A_006_ABS1_15_1.prp")
#draw_all_graph(PDI_resolution_exacte,"PRP_instances/A_014_ABS1_15_2.prp")

#draw_all_graph(PDI_resolution_exacte,"PRP_instances/A_005_#ABS1_15_z.prp")
#draw_all_graph(PDI_resolution_exacte,"PRP_instances/A_006_ABS1_15_1.prp")
#draw_all_graph(PDI_resolution_exacte,"PRP_instances/A_007_ABS2_15_4.prp")



#draw_all_graph(PDI_branch_and_cut,"PRP_instances/A_007_ABS2_15_4.prp")

#draw_all_graph(PDI_resolution_exacte,"PRP_instances/A_007_ABS2_15_4.prp")


#draw_all_graph(PDI_branch_and_cut,"PRP_instances/A_014_ABS1_15_1.prp")
#draw_all_graph(PDI_branch_and_cut,"PRP_instances/A_014_ABS1_15_2.prp")
#draw_all_graph(PDI_branch_and_cut,"PRP_instances/A_014_ABS1_15_3.prp")
#draw_all_graph(PDI_branch_and_cut,"PRP_instances/A_014_ABS1_15_4.prp")
#draw_all_graph(PDI_branch_and_cut,"PRP_instances/A_050_ABS1_50_1.prp")

#draw_all_graph(PDI_branch_and_cut,"PRP_instances/A_020_ABS1_50_1.prp")
#draw_all_graph(PDI_branch_and_cut,"PRP_instances/A_025_ABS1_50_1.prp")
#draw_all_graph(PDI_branch_and_cut,"PRP_instances/A_030_ABS1_50_1.prp")


#draw_all_graph(PDI_resolution_exacte,"PRP_instances/A_005_#ABS1_15_z.prp")
#draw_all_graph(PDI_branch_and_cut,"PRP_instances/A_014_ABS1_15_1.prp")
