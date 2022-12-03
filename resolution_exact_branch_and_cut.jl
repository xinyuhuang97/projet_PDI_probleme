#using JuMP
#using CPLEX
#include("read_data.jl")
include("resolution_exacte.jl")

# Définition de constantes pour le statut de résolution du problème
const OPTIMAL = JuMP.MathOptInterface.OPTIMAL
const INFEASIBLE = JuMP.MathOptInterface.INFEASIBLE
const UNBOUNDED = JuMP.MathOptInterface.DUAL_INFEASIBLE;


function model_branch_and_cut(filename)
    m=model_Bard_Nananukul(filename,false)
    function lazycut(cb_data)
        file_type, nb_clients, general_info, clients_info, demand_info = Read_instance(filename)

        nb_t=general_info[3] #nombre de periodes
        Q=general_info[7] #capacite d'un vehicule
        # nb_clients represent bien le nombre de clients

        for t in 1:nb_t
            his_total=Set{Int64}()
            sous_tours=Set{Int64}[]
            for i in 2:nb_clients+1
                println("hi")
                bool_trouve_veudeur=0
                #println(i)
                his=Set{Int64}(i)
                if (!(i in his_total) && round(callback_value(cb_data, variable_by_name(m, "zit[$(i-1),$t]"))) == 1)

                    noeud_actuel=i
                    tete=i
                    while true
                        for j in 1:nb_clients+1
                            #println(j)
                            connection=round( callback_value(cb_data, variable_by_name(m, "x[$j,$noeud_actuel,$t]")) )
                            if connection!=1
                                continue
                            end
                            push!(his, noeud_actuel)
                            noeud_actuel=j
                        end
                        if noeud_actuel==1
                            break
                        end
                        if noeud_actuel in his
                            break
                        end
                        println(his, noeud_actuel)
                        if noeud_actuel==tete
                            set_dehors_sous_tours=set_diff(Set{Int64}(i for i in 2:nb_clients+1),his)
                            con = @build_constraint(sum(variable_by_name(m, "x[$x,$y,$t]") for x in S for y in set_dehors_sous_tours)>=sum(variable_by_name(m, "q[$x,$t]") for i in S))
                            MOI.submit(cvrp, MOI.LazyConstraint(cb_data), con)
                            #MOI.submit(cvrp, MOI.UsConstraint(cb_data), con)
                            break
                        end
                    end
                end
                his_total = union(his_total, his)
            end
        end                        # sous-tours trouves
    end
    MOI.set(m, MOI.LazyConstraintCallback(), lazycut)
    optimize!(m)
    println("Fin de la résolution du PLNE par le solveur")

    status = termination_status(m)
    println(status)
    # un petit affichage sympathique
    if status == JuMP.MathOptInterface.OPTIMAL
        #"x[$j,$noeud_actuel,$t]")
        q_vals = value(variable_by_name(m,"q[1,1]"))
        println(q_vals)
        z_vals = variable_by_name(m,"zit")#value.(zit)
        println("valeur objective:",objective_value(m))
        println("Temps de résolution :", solve_time(m))
        return objective_value(m),q_vals,z_vals
    else
        println("Problème lors de la résolution")
    end
end

#model_branch_and_cut("PRP_instances/A_014_ABS75_15_1.prp")
Resolution_exacte("PRP_instances/B_200_instance18.prp")
