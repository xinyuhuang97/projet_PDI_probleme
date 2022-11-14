using JuMP
using CPLEX
include("read_data.jl")

# Définition de constantes pour le statut de résolution du problème
const OPTIMAL = JuMP.MathOptInterface.OPTIMAL
const INFEASIBLE = JuMP.MathOptInterface.INFEASIBLE
const UNBOUNDED = JuMP.MathOptInterface.DUAL_INFEASIBLE;








function Resolution_heuristique(filename)
    file_type, nb_clients, general_info, clients_info, demand_info = Read_instance(filename)

    nb_t=general_info[3] #nombre de periodes
    u=general_info[4] #cout unitaire de production
    f=general_info[5] #cout de setup de production
    C=general_info[6] #capacite de production
    Q=general_info[7] #capacite d'un vehicule
    k=general_info[8] #nombre de vehicules
    if file_type=='B'
        mc=general_info[9]
    end

    h0=clients_info[0][3] #cout de stockage
    L0=clients_info[0][4] #capacite de stockage pour le producteur
    #L00=clients_info[1,5] #le stock intial pour le producteur
    d=demand_info
    M=[]
    for j in 1:nb_clients
        push!(M,500000)
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
        #print(nb_clients,nb_t)
        #println(nb_clients, general_info, clients_info, demand_info)
        @variable(m, p[1:nb_t],lower_bound = 0 )#lower_bound = 0 )  # variable de production R+
        @variable(m, y[1:nb_t], Bin) # variable de lancement
        @variable(m, i[1:nb_clients+1, 1:nb_t],lower_bound = 0 )#lower_bound = 0) #variable de stockage
        @variable(m, q[1:nb_clients, 1:nb_t],lower_bound = 0 )#lower_bound = 0) #variable d'approvisionnement

        #sum(u*p[t] + f*y[t] + sum(h[i]*i[ind][t] for ind = 2:nb_clients+1) for t = 1:nb_t )
        # h[i]=clients_info[ind][3] sum(clients_info[ind][3]*i[ind][t] for ind = 2:nb_clients+1)
        #
        #print(clients_info[0])
        @objective(m, Min, sum(u*p[t] + f*y[t] + sum(clients_info[ind-1][3]*i[ind,t] for ind = 2:nb_clients+1 ) for t = 1:nb_t) )


        # contraintes (1) pour dire " en stock à t-1 + production à t = produite pour tous les revendeurs + en stock à t
        @constraint(m, clients_info[0][5]+p[1]==sum(q[ind-1,1] for ind = 2:nb_clients+1) +i[1,1])
        for t in 2:nb_t
            @constraint(m, i[1,t-1]+p[t]==sum(q[ind-1,t] for ind = 2:nb_clients+1) +i[1,t])
        end

        # contraintes (2) pour dire
        for ind in 2:nb_clients+1
            @constraint(m, clients_info[ind-1][5] + q[ind-1,1]==d[ind-1][1]+i[ind,1])
        end
        for t in 2:nb_t
            for ind in 2:nb_clients+1
                @constraint(m, i[ind,t-1] + q[ind-1,t]==d[ind-1][t-1]+i[ind,t])
            end
        end
        #contraintes (3) pour dire
        for t in 1:nb_t
            @constraint(m,p[t]<=M[t]*y[t])
        end
        # contraintes (4) pour dire
        @constraint(m,clients_info[0][5]<=L0)
        for t in 2:nb_t
            @constraint(m,i[1,t-1]<=L0)
        end
        # contraintes (5) pour dire
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
    	print(m)
    	println()

    	println("Résolution du PLNE par le solveur")
    	optimize!(m)
       	println("Fin de la résolution du PLNE par le solveur")

    	status = termination_status(m)
        println(status)
    	# un petit affichage sympathique
    	if status == JuMP.MathOptInterface.OPTIMAL
    		#println("Valeur optimale = ", objective_value(m))
    		#println("Solution primale optimale :")
            q_vals = value.(q)
            println(q_vals)
            println(size(q_vals))
            i_vals = value.(i)
            println(i_vals)
    		println("Temps de résolution :", solve_time(m))
            return q_vals
    	else
    		println("Problème lors de la résolution")
    	end
        #print("return",q_vals[1][1])
        #print("return",q_vals[1])


    end
    function VRP_heurisitque_Binpacking(t)
        #= Principe :
            1) remplir les vehicules de facons gluton
            2) Forme un circuit de mainiere gloutonne
        =#

        #Q=general_info[7] #capacite d'un vehicule
        #k=general_info[8] #nombre de vehicules
        cpt_vehi=1 #compteur de vehicule
        bool_end=false #boolean pour detercter si on a bien traité tous les villes
        charge_actuel=0
        # quantite d'approvisionnement
        q=q_vals
        partition=Dict()
        for i in 1:nb_clients
            #println(i,"_",t,q_vals)
            #print(q_vals,q_vals[i][t])
            qi=q_vals[i,t]
            if isapprox(qi, 0.0; atol = 1e-8)
                continue
            end
            if charge_actuel==0
                charge_actuel=qi
                partition[cpt_vehi]=Any[]
                push!(partition[cpt_vehi],i)
            elseif charge_actuel+qi>Q
                cpt_vehi+=1
                # if cpt_vehi>k ? si depasse le nombre de vehicules qu'on possede
                charge_actuel=qi
                partition[cpt_vehi]=[i]
            else
                charge_actuel+=qi
                push!(partition[cpt_vehi],i)
            end
        end
        tsp_partition=Dict()
        for i in 1:cpt_vehi
            smallest_indice=-1 # l'indice plus proche du point de depart
            #cherche le plus proche ville
            #println(partition)
            lg=length(partition[i])
            ordre=Array{Int}(undef,lg)
            index=-1
            cpt=1
            index_ville=true
            index_min=-1
            while index_ville==true
                #println(index_ville, ordre)
                if index==-1
                    #println(partition[i])
                    index=partition[i][1]
                    #ordre[1]=index
                else
                    dis_min=0

                    for index2 in partition[i]# a modifier
                        if index !=index2
                            dist= (clients_info[index][1]-clients_info[index2][1])^2 + (clients_info[index][2]-clients_info[index2][2])^2
                            if dis_min==0
                                dis_min=-dist
                                index_min=index2
                            else
                                if dis_min<-dist
                                    dis_min=-dist
                                end
                            end
                        end
                    end
                end
                #println(index)
                #println(partition[i])
                filter!(e->e≠index,partition[i])
                #println(partition[i])
                if index_min!=-1
                    index=index_min
                end
                ordre[cpt]=index
                cpt+=1


                #println("ordre",ordre)
                #println(length(partition[i]))
                if length(partition[i])<=1
                    index_ville=false
                end
                #println(index_ville, ordre)
            end
            tsp_partition[i]=ordre
        end
        return tsp_partition
    end
    q_vals=PLNE_LSP()
    for t in 1:nb_t
        println(t)
        println(VRP_heurisitque_Binpacking(t))
    end
end

#println(PLNE_LSP("PRP_instances/A_014_ABS75_15_2.prp"))
#PLNE_LSP("PRP_instances/B_200_instance1.prp")
#PLNE_LSP("PRP_instances/B_200_instance3.prp")
#Resolution_heuristique("PRP_instances/A_014_ABS75_15_2.prp")
Resolution_heuristique("PRP_instances/B_200_instance3.prp")
