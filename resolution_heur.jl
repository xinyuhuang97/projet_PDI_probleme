using JuMP
using CPLEX
include("read_data.jl")

# Définition de constantes pour le statut de résolution du problème
const OPTIMAL = JuMP.MathOptInterface.OPTIMAL
const INFEASIBLE = JuMP.MathOptInterface.INFEASIBLE
const UNBOUNDED = JuMP.MathOptInterface.DUAL_INFEASIBLE;

function PLNE_LSP(filename)

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

    h0=clients_info[1][3] #cout de stockage
    L0=clients_info[1][4] #capacite de stockage pour le producteur
    #L00=clients_info[1,5] #le stock intial pour le producteur
    d=demand_info
    M=[]
    for j in 1:nb_clients
        push!(M,5000)
    end
	m = Model(CPLEX.Optimizer)

    @variable(m, p[1:nb_t],lower_bound = 0 )  # variable de production R+
    @variable(m, y[1:nb_t], Bin) # variable de lancement
    @variable(m, i[1:nb_clients, 1:nb_t], lower_bound = 0) #variable de stockage
    @variable(m, q[1:nb_clients, 1:nb_t], lower_bound = 0) #variable d'approvisionnement

    #sum(u*p[t] + f*y[t] + sum(h[i]*i[ind][t] for ind = 2:nb_clients+1) for t = 1:nb_t )
    # h[i]=clients_info[ind][3] sum(clients_info[ind][3]*i[ind][t] for ind = 2:nb_clients+1)
    #
    @objective(m, Min, sum(u*p[t] + f*y[t] + sum(clients_info[ind][3]*i[ind,t] for ind = 1:nb_clients ) for t = 1:nb_t ) )


    # contraintes (1) pour dire " en stock à t-1 + production à t = produite pour tous les revendeurs + en stock à t
    for t in 2:nb_t
        @constraint(m, i[1,t-1]+p[t]==sum(q[ind,t] for ind = 1:nb_clients) +i[1,t])
    end
    # contraintes (2) pour dire
    for t in 2:nb_t
        for ind in 2:nb_clients
            @constraint(m, i[ind,t-1] + q[ind,t]==d[ind][t]+i[ind,t])
        end
    end
    # contraintes (3) pour dire
    for t in 2:nb_t
        @constraint(m,p[t]<=M[t]*y[t])
    end
    # contraintes (4) pour dire
    for t in 2:nb_t
        @constraint(m,i[1,t-1]<=L0)
    end
    # contraintes (5) pour dire
    for t in 2:nb_t
        for ind in 2:nb_clients
            Li=clients_info[ind][4]
            @constraint(m,i[ind,t-1]+q[ind,t]<=Li)
        end
    end
    for ind in 1:nb_clients
        @constraint(m,i[ind,1]==clients_info[ind][5])
    end
	print(m)
	println()

	println("Résolution du PLNE par le solveur")
	optimize!(m)
   	println("Fin de la résolution du PLNE par le solveur")

	status = termination_status(m)

	# un petit affichage sympathique
	if status == JuMP.MathOptInterface.OPTIMAL
		println("Valeur optimale = ", objective_value(m))
		println("Solution primale optimale :")
		println("Temps de résolution :", solve_time(m))
	else
		println("Problème lors de la résolution")
	end
end

PLNE_LSP("PRP_instances/A_014_ABS75_15_2.prp")
