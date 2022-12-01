using JuMP
using CPLEX
include("read_data.jl")

# Définition de constantes pour le statut de résolution du problème
const OPTIMAL = JuMP.MathOptInterface.OPTIMAL
const INFEASIBLE = JuMP.MathOptInterface.INFEASIBLE
const UNBOUNDED = JuMP.MathOptInterface.DUAL_INFEASIBLE;


function model_branch_and_cut(filename)
    m=model_Bard_Nananukul(filename, mtz=false)

    function lazycut(cb_data)
        file_type, nb_clients, general_info, clients_info, demand_info = Read_instance(filename)

        nb_t=general_info[3] #nombre de periodes
        Q=general_info[7] #capacite d'un vehicule
        # nb_clients represent bien le nombre de clients
