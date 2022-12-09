using JuMP
using CPLEX
include("read_data.jl")

# Définition de constantes pour le statut de résolution du problème
const OPTIMAL = JuMP.MathOptInterface.OPTIMAL
const INFEASIBLE = JuMP.MathOptInterface.INFEASIBLE
const UNBOUNDED = JuMP.MathOptInterface.DUAL_INFEASIBLE;


function PDI_resolution_heuristique(filename)
    file_type, nb_clients, general_info, clients_info, demand_info = Read_instance(filename)

    nb_t=general_info[3] #nombre de periodes
    u=general_info[4] #cout unitaire de production
    f=general_info[5] #cout de setup de production
    C=general_info[6] #capacite de production
    Q=general_info[7] #capacite d'un vehicule
    k=general_info[8] #nombre de vehicules


    h0=clients_info[0][3] #cout de stockage
    L0=clients_info[0][4] #capacite de stockage pour le producteur
    #L00=clients_info[1,5] #le stock intial pour le producteur
    d=demand_info
    M=[]

    for t in 1:nb_t
        #push!(M,400000)
        push!(M,min(C, sum((sum(d[i][j] for j = t:nb_t) for i = 1:nb_clients))))
    end

    vec_xNode=[]
    vec_yNode=[]
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

    function build_matrix(nb_clients, nb_t)
        xijt=zeros((nb_clients+1,nb_clients+1,nb_t))
        pre=-1
        actual=-1
        somme_sc_new=0
        for t in 1:nb_t
            tsp_partition=VRP_heurisitque_Binpacking(t)

            for i = 1:length(tsp_partition)
                for index in tsp_partition[i]
                    if index==1
                        pre=1
                        continue
                    end
                    actual=index
                    somme_sc_new+=cij[pre,actual]
                    xijt[pre,actual,t]=1
                    pre=index
                end
                somme_sc_new+=cij[actual,1]
                xijt[actual,1,t]=1
            end
        end
        return xijt,somme_sc_new
    end
    function PLNE_LSP()#filename)
        #=
        file_type, nb_clients, general_info, clients_info, demand_info = Read_instance(filename)

        nb_t=general_info[3] #nombre de periodes
        u=general_info[4] #cout unitaire de production
        f=general_info[5] #cout de setup de production
        C=general_info[6] #capacite de production
        Q=general_info[7] #capacite d'un vehicule
        k=general_info[8] #nombre de vehicules
        if file_type=='B'
            mc=general_info[9]
        end=#

        #h0=clients_info[0][3] #cout de stockage
        #L0=clients_info[0][4] #capacite de stockage pour le producteur
        #L00=clients_info[1,5] #le stock intial pour le producteur
        #d=demand_info

    	m = Model(CPLEX.Optimizer)

        # L'ajout de variables
        @variable(m, p[1:nb_t],lower_bound = 0 ) # variable de production R+
        @variable(m, y[1:nb_t], Bin) # variable de lancement
        @variable(m, i[1:nb_clients+1, 1:nb_t],lower_bound = 0 )#lower_bound = 0) #variable de stockage
        @variable(m, q[1:nb_clients, 1:nb_t],lower_bound = 0 )#lower_bound = 0) #variable d'approvisionnement
        @variable(m, z[1:nb_clients+1, 1:nb_t],Bin) # variable de visite

        # Fonction objective
        @objective(m, Min, sum(u*p[t] + f*y[t] + sum(clients_info[ind-1][3]*i[ind,t]  for ind = 1:nb_clients+1 ) +  sum(2*ci0[ind]*z[ind,t] for ind = 1:nb_clients+1 ) for t = 1:nb_t) )

        # contraintes (1) pour dire "en stock à t-1 + production à t = produite pour tous les revendeurs + en stock à t
        @constraint(m, clients_info[0][5]+p[1]==sum(q[ind-1,1] for ind = 2:nb_clients+1) +i[1,1])
        for t in 2:nb_t
            @constraint(m, i[1,t-1]+p[t]==sum(q[ind-1,t] for ind = 2:nb_clients+1) +i[1,t])
        end

        # contraintes (2) pour dire “L'equivalence : stock à t-1 +approvisionnement à t = demande+stock a l'instant t”
        for ind in 2:nb_clients+1
            @constraint(m, clients_info[ind-1][5] + q[ind-1,1]==d[ind-1][1]+i[ind,1])
        end
        for t in 2:nb_t
            for ind in 2:nb_clients+1
                @constraint(m, i[ind,t-1] + q[ind-1,t]==d[ind-1][t-1]+i[ind,t])
            end
        end

        #contraintes (3) pour dire que la variable de production est à 0 si la variable de lancement est à 0
        for t in 1:nb_t
            @constraint(m,p[t]<=M[t]*y[t])
        end

        # contraintes (4) pour dire le stock du producteur est inferieur à son capacoté de stockage
        @constraint(m,clients_info[0][5]<=L0)
        for t in 1:nb_t
            @constraint(m,i[1,t]<=L0)
        end

        # contraintes (5) pour dire le stock du revendeurs est inferieur à son capacoté de stockage
        for t in 1:nb_t
            for ind in 2:nb_clients+1
                Li=clients_info[ind-1][4]
                if t==1
                    @constraint(m,clients_info[ind-1][5]+q[ind-1,t]<=Li)
                else
                    @constraint(m,i[ind,t-1]+q[ind-1,t]<=Li)
                end
            end
        end
        # contraintes (6) La contrainte ajouté: la variable de visite est à 0 si quantité d'approvisionnement est à 0
        for t in 1:nb_t
            for ind in 2:nb_clients+1
                @constraint(m,z[ind,t]<=M[t]*q[ind-1,t])
            end
        end


    	println("Résolution du PLNE par le solveur")
    	optimize!(m)
       	println("Fin de la résolution du PLNE par le solveur")

    	status = termination_status(m)
        println(status)
    	# un petit affichage sympathique
    	if status == JuMP.MathOptInterface.OPTIMAL
            q_vals = value.(q)
            z_vals = value.(z)
    		println("Temps de résolution :", solve_time(m))
            return objective_value(m),q_vals,z_vals
    	else
    		println("Problème lors de la résolution")
    	end
    end

    function VRP_heurisitque_Binpacking(t)

        #= Principe :
            1) remplir les vehicules de facons gluton
            2) Forme un circuit de mainiere gloutonne
        =#
        #Q=general_info[7] #capacite d'un vehicule
        #k=general_info[8] #nombre de vehicules
        cpt_vehi=0 # compteur de vehicule
        bool_end=false # boolean pour detercter si on a bien traité tous les villes
        charge_actuel=0
        # Creation d'une dictionnaire de partition donc chaque indice corresponde a une tournee d'un vehicule
        partition,cpt_vehi=create_partition(nb_clients, Q, q_vals,t)
        #dictionnaire contenant pour chaque tournee l'ordre de tournage

        tsp_partition=tsp_create_partition(nb_clients,cpt_vehi,partition,clients_info)
        return tsp_partition
    end

    # Corp du code

    val_objective,q_vals,z_vals=PLNE_LSP()
    somme_sc_new=0
    somme_sc_old=0
    for ind = 1:nb_clients+1
        for t = 1:nb_t
            somme_sc_old+=2*ci0[ind]*z_vals[ind,t]
        end
    end
    xijt,somme_sc_new=build_matrix(nb_clients,nb_t)
    println("Avant mise a jour: ",val_objective)
    val_objective=val_objective+somme_sc_new-somme_sc_old
    println("Apres mise a jour: ",val_objective)
    return val_objective,vec_xNode,vec_yNode,xijt
end

#println(PLNE_LSP("PRP_instances/A_014_ABS75_15_2.prp"))
#PLNE_LSP("PRP_instances/B_200_instance1.prp")
#PLNE_LSP("PRP_instances/B_200_instance3.prp")
#Resolution_heuristique("PRP_instances/A_014_ABS75_15_2.prp")
#Resolution_heuristique("PRP_instances/A_005_#ABS1_15_z.prp")
#Resolution_heuristique("PRP_instances/B_200_instance18.prp")

#Resolution_heuristique("PRP_instances/A_005_#ABS1_15_z.prp")
