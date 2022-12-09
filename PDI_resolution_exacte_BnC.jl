#using JuMP
#using CPLEX
#include("read_data.jl")
include("PDI_resolution_exacte.jl")
include("tool.jl")

# Définition de constantes pour le statut de résolution du problème
const OPTIMAL = JuMP.MathOptInterface.OPTIMAL
const INFEASIBLE = JuMP.MathOptInterface.INFEASIBLE
const UNBOUNDED = JuMP.MathOptInterface.DUAL_INFEASIBLE;






function PDI_branch_and_cut(filename)
    m,vec_xNode, vec_yNode=model_Bard_Nananukul(filename;mtz=false)
    function lazycut(cb_data)
        file_type, nb_clients, general_info, clients_info, demand_info = Read_instance(filename)

        nb_t=general_info[3] #nombre de periodes
        Q=general_info[7] #capacite d'un vehicule
        # nb_clients represent bien le nombre de clients
        for t = 1:nb_t
            xsep=zeros((nb_clients+1,nb_clients+1))
            zsep=zeros((nb_clients))
            for i = 1:nb_clients+1
                for j = 1:nb_clients+1
                    if( round(callback_value(cb_data,variable_by_name(m,"x[$i,$j,$t]")))==1)
                        xsep[i,j]=1
                    end
                end
            end
            for i = 1:nb_clients
                if (round(callback_value(cb_data,variable_by_name(m,"zit[$i,$t]")))==1)
                    zsep[i]=1
                end
            end
            trouveDepartDepot,sousTours=detect_soustours(nb_clients,xsep,zsep)
            if(!trouveDepartDepot) # trouver au moins un sous tours
				for s in sousTours
                    if(length(s)>=1)
                        set_dehors_sous_tours=setdiff(Set(1:nb_clients+1),s)
                        con1 = @build_constraint(sum(variable_by_name(m, "x[$i,$j,$t]") for i in set_dehors_sous_tours for j in s)>=sum(variable_by_name(m, "q[$i,$t]") for i in s)/Q)
                        MOI.submit(m, MOI.LazyConstraint(cb_data), con1)
                    end
					if(length(s)>=2)
                        #set_dehors_sous_tours=setdiff(Set(1:nb_clients+1),s)
                        #con1 = @build_constraint(sum(variable_by_name(m, "x[$i,$j,$t]") for i in set_dehors_sous_tours for j in s)>=sum(variable_by_name(m, "q[$i,$t]") for i in s)/Q)
                        #MOI.submit(m, MOI.LazyConstraint(cb_data), con1)
                        #set_dehors_sous_tours=setdiff(Set(1:nb_clients+1),s)
                        #con1 = @build_constraint(sum(variable_by_name(m, "x[$i,$j,$t]") for i in set_dehors_sous_tours for j in s)>=sum(variable_by_name(m, "q[$i,$t]") for i in s)/Q)
                        #MOI.submit(m, MOI.LazyConstraint(cb_data), con1)
                        con2 = @build_constraint(sum(variable_by_name(m, "x[$i,$j,$t]") for i in s for j in s if i!=j )*Q <= sum( Q*variable_by_name(m,"zit[$(i-1),$t]") - variable_by_name(m,"q[$i,$t]") for i in s))
                        MOI.submit(m, MOI.LazyConstraint(cb_data), con2)
                    end
                end
            end
            #=sousTours=Set()
            for i in 2:nb_clients+1
                tournee=[i]
                push!(sousTours, Set(tournee))
            end
            for s in sousTours
                set_dehors_sous_tours=setdiff(Set(1:nb_clients+1),s)
                con1 = @build_constraint(sum(variable_by_name(m, "x[$i,$j,$t]") for i in set_dehors_sous_tours for j in s)>=sum(variable_by_name(m, "q[$i,$t]") for i in s)/Q)
                MOI.submit(m, MOI.LazyConstraint(cb_data), con1)
            end=#
        end
    end
        #=for t in 1:nb_t
            his_total=Set{Int64}()
            sous_tours=Set{Int64}[]
            for i in 2:nb_clients+1
                #println("hi")
                bool_trouve_veudeur=false
                #println(i)

                if (!(i in his_total) && round(callback_value(cb_data, variable_by_name(m, "zit[$(i-1),$t]"))) == 1)

                    noeud_actuel=i
                    tete=i
                    his=Set{Int64}(i)
                    while true
                        for j in 1:nb_clients+1
                            #println(j)
                            connection=round( callback_value(cb_data, variable_by_name(m, "x[$j,$noeud_actuel,$t]")) )
                            if connection==1
                                #continue
                                noeud_actuel=j
                            end
                            #push!(his, noeud_actuel)
                            #noeud_actuel=j
                        end
                        if noeud_actuel==1
                            bool_trouve_veudeur=true
                            break
                        end
                        if noeud_actuel in his
                            break
                        end
                        #println(his, noeud_actuel)
                        #=if noeud_actuel==tete
                            set_dehors_sous_tours=set_diff(Set{Int64}(i for i in 2:nb_clients+1),his)
                            con = @build_constraint(sum(variable_by_name(m, "x[$x,$y,$t]") for x in S for y in set_dehors_sous_tours)>=sum(variable_by_name(m, "q[$x,$t]") for x in S))
                            MOI.submit(cvrp, MOI.LazyConstraint(cb_data), con)
                            #MOI.submit(cvrp, MOI.UsConstraint(cb_data), con)
                            break
                        end=#

                        push!(his, noeud_actuel)
                    end
                    if !bool_trouve_veudeur
                        push!(sous_tours, his)
                        #=set_dehors_sous_tours=setdiff(Set{Int64}(i for i in 2:nb_clients+1),his)
                        if length(his)>=1
                            #println("here",set_dehors_sous_tours)
                            #println("hi",his)
                            #t1= @build_constraint(sum(variable_by_name(m, "x[$a,$b,$t]") for b in his for a in set_dehors_sous_tours)>=0)
                            #t2= @build_constraint(sum(variable_by_name(m, "q[$(i-1),$t]") for i in his)>=0)#@build_constraint(sum(variable_by_name(m, "q[$a,$t]") for a in his)<=0)
                            con = @build_constraint(sum(variable_by_name(m, "x[$a,$b,$t]") for b in his for a in set_dehors_sous_tours)>=sum(variable_by_name(m, "q[$(x-1),$t]") for x in his)/Q)
                            MOI.submit(m, MOI.LazyConstraint(cb_data), con)
                        end=#
                        #=if length(his)>=2
                            con= @build_constraint(sum(variable_by_name(m, "x[$a,$b,$t]") for b in his for a in set_dehors_sous_tours)<=length(his)-sum(variable_by_name(m, "q[$(x-1),$t]") for x in his)/Q)
                            MOI.submit(m, MOI.LazyConstraint(cb_data), con)
                        end=#
                        #MOI.submit(cvrp, MOI.UsConstraint(cb_data), con)

                    end
                    his_total = union(his_total, his)
                end

                #
            end
            for s in sous_tours
                set_dehors_sous_tours=setdiff(Set{Int64}(i for i in 1:nb_clients+1),s)
                #=if length(s)>=1
                    #println("here",set_dehors_sous_tours)
                    #println("hi",his)
                    #t1= @build_constraint(sum(variable_by_name(m, "x[$a,$b,$t]") for b in his for a in set_dehors_sous_tours)>=0)
                    #t2= @build_constraint(sum(variable_by_name(m, "q[$(i-1),$t]") for i in his)>=0)#@build_constraint(sum(variable_by_name(m, "q[$a,$t]") for a in his)<=0)
                    #println("s",s)
                    con = @build_constraint(sum(variable_by_name(m, "x[$a,$b,$t]") for b in s for a in set_dehors_sous_tours)>=sum(variable_by_name(m, "q[$(x),$t]") for x in s)/Q)
                    MOI.submit(m, MOI.LazyConstraint(cb_data), con)
                end=#
                if length(s)>=2
                    #con1=@build_constraint(sum(variable_by_name(m,"q[$i,$t]") for i in s)>=0)
                    #con2=@build_constraint(sum(variable_by_name(m, "x[$(i-1+1),$j,$t]") for i in s for j in s if i!=j )>=0)
                    #println(s)
                    #sp=
                    #con3=@build_constraint(sum(variable_by_name(m,"zit[$(i-1),$t]") for i in s )>=0)
                    con = @build_constraint(sum(variable_by_name(m, "x[$a,$b,$t]") for b in s for a in set_dehors_sous_tours)>=sum(variable_by_name(m, "q[$(x),$t]") for x in s)/Q)
                    MOI.submit(m, MOI.LazyConstraint(cb_data), con)
                    con = @build_constraint(sum(variable_by_name(m, "x[$i,$j,$t]") for i in s for j in s if i!=j )*Q <= sum( Q*variable_by_name(m,"zit[$(i-1),$t]") - variable_by_name(m,"q[$i,$t]") for i in s))
                    MOI.submit(m, MOI.LazyConstraint(cb_data), con)
                end
            end
        end                        # sous-tours trouves
    end=#
    MOI.set(m, MOI.LazyConstraintCallback(), lazycut)
    optimize!(m)
    println("Fin de la résolution du PLNE par le solveur")

    status = termination_status(m)
    println(status)
    # un petit affichage sympathique
    if status == JuMP.MathOptInterface.OPTIMAL
        #"x[$j,$noeud_actuel,$t]")
        #q_vals = value.(q[:x])
        #println(q_vals)
        #z_vals = value.(z[:x])#value.(zit)
        println("valeur objective:",objective_value(m))
        println("Temps de résolution :", solve_time(m))
        #println(value.(m[:x]))
        println(value.(m[:q]))
        println(value.(m[:x]))
        println("hi",value.(m[:I]))
        println(value.(m[:p]))
        #println(value.(m[:w]))
        return objective_value(m),vec_xNode, vec_yNode,value.(m[:x])
    else
        println("Problème lors de la résolution")
    end
end

#model_branch_and_cut("PRP_instances/A_014_ABS1_15_2.prp")
#model_branch_and_cut("PRP_instances/B_200_instance17.prp")
