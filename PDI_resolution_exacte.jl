using JuMP
using CPLEX
include("read_data.jl")

# Définition de constantes pour le statut de résolution du problème
const OPTIMAL = JuMP.MathOptInterface.OPTIMAL
const INFEASIBLE = JuMP.MathOptInterface.INFEASIBLE
const UNBOUNDED = JuMP.MathOptInterface.DUAL_INFEASIBLE;

function model_Bard_Nananukul(filename;mtz=true)
    file_type, nb_clients, general_info, clients_info, demand_info = Read_instance(filename)

    nb_t=general_info[3] #nombre de periodes
    u=general_info[4] #cout unitaire de production
    f=general_info[5] #cout de setup de production
    C=general_info[6] #capacite de production
    Q=general_info[7] #capacite d'un vehicule
    k=general_info[8] #nombre de vehicules
    #m=k # Notation de l'article -> K={1....m}

    h0=clients_info[0][3] #cout de stockage
    L0=clients_info[0][4] #capacite de stockage pour le producteur
    #L00=clients_info[1,5] #le stock intial pour le producteur
    d=demand_info
    M=[]
    Mp=[]
    vec_xNode=[]
    vec_yNode=[]
    for t in 1:nb_t
        #push!(M,400000)
        push!(M,min(C, sum((sum(d[i][j] for j = t:nb_t) for i = 1:nb_clients))))
    end
    for ind in 1:nb_clients
        for t in 1:nb_t
            if t==1
                push!(Mp,[min(clients_info[ind][4], Q, sum(d[ind][j] for j = 1:nb_t))])
            else
                push!(Mp[ind],min(clients_info[ind][4], Q, sum(d[ind][j] for j = t:nb_t)))
            end
        end
    end

    ci0=Array{Float64}(undef, nb_clients+1)
    cij=Array{Float64, 2}(undef, nb_clients+1, nb_clients+1)
    if file_type=="A"
        for i in 1:nb_clients+1
            push!(vec_xNode,clients_info[i-1][1])
            push!(vec_yNode,clients_info[i-1][2])
            ci0[i]=floor(hypot(clients_info[i-1][1]-clients_info[0][1], clients_info[i-1][2]-clients_info[0][2]) +1/2)
        end
        for i in 1:nb_clients+1
            for j in 1:nb_clients+1

                cij[i,j]=floor(hypot(clients_info[i-1][1]-clients_info[j-1][1],  clients_info[i-1][2]-clients_info[j-1][2]) +1/2)
            end
        end
    end

    if file_type=="B"
        mc=general_info[9]
        for i in 1:nb_clients+1
            push!(vec_xNode,clients_info[i-1][1])
            push!(vec_yNode,clients_info[i-1][2])
            ci0[i]=mc*hypot(clients_info[i-1][1]-clients_info[0][1], clients_info[i-1][2]-clients_info[0][2] )
        end
        for i in 1:nb_clients+1
            for j in 1:nb_clients+1
                cij[i,j]=mc*hypot(clients_info[i-1][1]-clients_info[j-1][1], clients_info[i-1][2]-clients_info[j-1][2] )
            end
        end
    end
    #println(ci0)
    m = Model(CPLEX.Optimizer)

    # L'ajout de variables

    # production quantity in period t
    @variable(m, p[1:nb_t]>=0)#,lower_bound = 0 ) # variable de production R+
    # inventory at node i at the end of period t
    @variable(m, I[1:nb_clients+1, 1:nb_t]>=0)#,lower_bound = 0 )#lower_bound = 0) #variable de stockage
    # equal to 1 if there is production at the plant in period t, 0 otherwise
    @variable(m, y[1:nb_t], Bin) # variable de lancement
    # the number of vehicles leaving the plant in period t;
    @variable(m, 0<=z0t[1:nb_t]<=k,Int) # variable de nb de vehicules partent a partir du producteur
    # equal to 1 if customer i is visited in period t, 0 otherwise,
    @variable(m, zit[1:nb_clients, 1:nb_t],Bin) # variable de visite
    # if a vehicle travels directly from node i to node j in period t, 0 otherwise
    @variable(m, x[1:nb_clients+1, 1:nb_clients+1, 1:nb_t], Bin) #variable binaire pour dire si un vehicule voyage de i a j a peride t.
    # quantity delivered to customer i in period t
    @variable(m, q[1:nb_clients+1, 1:nb_t]>=0)#,lower_bound = 0 )#lower_bound = 0) #variable d'approvisionnement
    # load of a vehicle before making a delivery to customer i in period t.
    if mtz==true
        @variable(m, w[1:nb_clients, 1:nb_t]>=0)#,lower_bound = 0)
    end
    # Fonction objective
    @objective(m, Min, sum(u*p[t] + f*y[t] + sum(clients_info[ind-1][3]*I[ind,t]  for ind = 1:nb_clients+1 ) +  sum((2*cij[ind,ind2]*x[ind,ind2,t] for ind2 = 1:nb_clients+1 if ind!=ind2) for ind = 1:nb_clients+1 ) for t=1:nb_t))
    #2100 + 18000 + 354 +
    # same as in Resolution_heuristique
    # contraintes (1) pour dire "en stock à t-1 + production à t = produite pour tous les revendeurs + en stock à t
    @constraint(m, clients_info[0][5]+p[1]==sum(q[ind,1] for ind = 1:nb_clients+1) +I[1,1])
    for t in 2:nb_t
        @constraint(m, I[1,t-1]+p[t]==sum(q[ind,t] for ind = 1:nb_clients+1) +I[1,t])
    end

    # same as in Resolution_heuristique
    println("clients_info stock",clients_info[0][5])
    println(d,d[1][1])
    # contraintes (2) pour dire “L'equivalence : stock à t-1 +approvisionnement à t = demande+stock a l'instant t”
    for ind in 2:nb_clients+1
        #println("clients_info stock",clients_info[ind-1][5],clients_info[ind-1][4])
        @constraint(m, clients_info[ind-1][5] + q[ind,1]==d[ind-1][1]+I[ind,1])
    end
    for t in 2:nb_t
        for ind in 2:nb_clients+1
            @constraint(m, I[ind,t-1] + q[ind,t]==d[ind-1][t]+I[ind,t])
        end
    end

    # same as in Resolution_heuristique
    #contraintes (3) pour dire que la variable de production est à 0 si la variable de lancement est à 0
    for t in 1:nb_t
        println("M",M[t])
        @constraint(m,p[t]<=M[t]*y[t])
    end

    # same as in Resolution_heuristique
    # contraintes (4) pour dire le stock du producteur est inferieur à son capacité de stockage
    @constraint(m,clients_info[0][5]<=L0)
    println("L0",L0)
    for t in 1:nb_t
        @constraint(m,I[1,t]<=L0)
    end

    # same as in Resolution_heuristique
    # contraintes (5)(6) pour dire le stock du revendeurs est inferieur à son capacité de stockage
    for t in 1:nb_t
        for ind in 2:nb_clients+1
            Li=clients_info[ind-1][4]
            println(ind-1,Li)
            if t==1
                @constraint(m,clients_info[ind-1][5]+q[ind,t]<=Li)
            else
                @constraint(m,I[ind,t-1]+q[ind,t]<=Li)
            end
        end
    end

    # contraintes (7) La contrainte ajouté: la variable de visite est à 0 si quantité d'approvisionnement est à 0
    for t in 1:nb_t
        for ind in 2:nb_clients+1
            @constraint(m,q[ind,t]<=Mp[ind-1][t]*zit[ind-1,t])
        end
    end

    # contraintes (8) pour dire une ville peut au plus être visité au plus par une voiture
    for t in 1:nb_t
        for ind in 2:nb_clients+1
            #if ind ==1
            #    @constraint(m,sum(x[ind,ind2,t] for ind2 = 1:(nb_clients+1))==z0t[t])
                #@constraint(m,sum(x[ind,ind2,t] +x[ind2,ind,t] for ind2 = 2:(nb_clients+1) )==2*z0t[t])
            #else
            nodesIndexWithoutI = filter(e -> e != ind, 1:nb_clients+1)
            @constraint(m,sum(x[ind,ind2,t] for ind2 in nodesIndexWithoutI)==zit[ind-1,t])
            #@constraint(m,sum(x[ind,ind2,t] for ind2 = filter(e -> e != i, 1:nb_clients+1))==zit[ind-1,t])
            #@constraint(m,sum(x[ind,ind2,t] for ind2 = 1:(nb_clients+1))==zit[ind-1,t])
            #end
        end
    end

    #contraintes (9) pour dire
    for t in 1:nb_t
        for ind in 1:nb_clients+1
            if ind ==1
                @constraint(m,sum(x[ind,ind2,t] +x[ind2,ind,t] for ind2 = 2:(nb_clients+1) )==2*z0t[t])
            else
                nodesIndexWithoutI = filter(e -> e != ind, 1:nb_clients+1)
                #@constraint(m,sum(x[ind,ind2,t] +x[ind2,ind,t] for ind2 = 1:(nb_clients+1) )==2*zit[ind-1,t])
                @constraint(m,sum(x[ind,ind2,t] +x[ind2,ind,t] for ind2 in nodesIndexWithoutI )==2*zit[ind-1,t])
            end
        end
    end

    #for t in 1:nb_t
    #    for k in 1:nb_clients+1
    #        for s in powerset([ind for ind=2:data["n"]+1],2,)
    #contraintes (10) pour dire
    #for t in 1:nb_t
    #    @constraint(m,z0t[t]<=k)
    #end


    if mtz==true
        #contraintes (11) pour dire
        println(Mp)
        #println(Mp[0])
        for t in 1:nb_t
            for i in 2:nb_clients+1
                for j in 2:nb_clients+1
                    #w 2:nb+1
                    #q 2:nb+1
                    #x 1:nb+1
                    if (i!=j)
                        @constraint(m,w[i-1,t]-w[j-1,t]>=q[i,t]-Mp[i-1][t]*(1-x[i,j,t]))
                    end
                end
            end
        end

        #contraintes (12) pour dire
        for t in 1:nb_t
            for i in 2:nb_clients+1
                #@constraint(m,0.0<=w[i-1,t])
                @constraint(m,w[i-1,t]<=Q*zit[i-1,t])
            end
        end
    end

    #end=
    #for t in 1:nb_t
    #    for i in 1:nb_clients+1
    #        @constraint(m,x[i,i,t]==0)
    #    end
    #end
    #contraintes (13-16) donnees dans la definition de variables
    return m, vec_xNode, vec_yNode
end

function PDI_resolution_exacte(filename)

    m,vec_xNode, vec_yNode= model_Bard_Nananukul(filename)
    optimize!(m)
    println("Fin de la résolution du PLNE par le solveur")

    status = termination_status(m)
    println(status)
    # un petit affichage sympathique
    if status == JuMP.MathOptInterface.OPTIMAL
        #"x[$j,$noeud_actuel,$t]")
        q_vals = value(variable_by_name(m,"q[1,1]"))
        #println(q_vals)
        z_vals = variable_by_name(m,"zit")#value.(zit)
        println("valeur objective:",objective_value(m))
        println("Temps de résolution :", solve_time(m))
        println(value.(m[:q]))
        println(value.(m[:x]))
        println(value.(m[:I]))
        println(value.(m[:p]))
        println(value.(m[:w]))
        return objective_value(m),vec_xNode, vec_yNode,value.(m[:x])
    else
        println("Problème lors de la résolution")
    end
end

#Resolution_exacte("PRP_instances/A_005_#ABS1_15_z.prp")

#Resolution_exacte("PRP_instances/A_014_ABS75_15_1.prp")
#Resolution_exacte("PRP_instances/B_200_instance18.prp")
