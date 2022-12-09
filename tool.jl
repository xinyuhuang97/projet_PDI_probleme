function detect_soustours(n,xsep,zsep)
	"""
	n: nb de revendeurs
	xsep : matrice x[:,:,k,t], contient peut etre plusieurs tournees
	detecter un sous tour d une voiture k, a l instant t
	"""
	sousTours=Set()
	his_visite=Set()
	trouveDepartDepot=true # =false si trouver au moins un sous tour
	for i =2:n+1
		if(!(i in his_visite) ) #si deja visite, appartient deja a un sous tours
			for j =2:n+1
				if(xsep[i,j]>=1)
					passeDepot,tournee=chercher_tournee(n,xsep,j,i)
					if(!passeDepot && !(1 in tournee)) #detection d un sous tours
						trouveDepartDepot=false
						push!(sousTours, Set(tournee))
						union!(his_visite,tournee)

					end
				end
			end
		end

	end
    #for i =1:n
    #    if (zsep[i]==1) && !(zsep[i]+1 in his_visite)
    #        push!(sousTours, Set([i+1]))
    #        trouveDepartDepot=false
    #    end
    #end
	#print(sousTours)
	return trouveDepartDepot,sousTours
end

function chercher_tournee(n,xsep,i,circuit)
	"""
	circuit: un chiffre, le point de depart du circuit
	n : nb de revendeur
	i : le point de depart suivant
	xsep : matrice x de la voiture k, a l instant t
	donne le circuit de la voirture k a l instant t
	"""
	depart=i
	tournee=[circuit]
	findDepot=false
	dejaPasse=Set() #stock les noeuds deja passes
	push!(dejaPasse,circuit)
	#println(xsep)
    c=0
    record=0
    b=false
	while(!findDepot && !(depart in dejaPasse)&& !b)#c!=n+1)
		push!(tournee,depart)
		push!(dejaPasse,depart)
        record=depart
		for j =1:n+1
            c=j
			if(xsep[depart,j]>0) && !(j in tournee)
				depart=j
				break
			end
		end
        if record==depart &&c==n+1
            b=true
        end
		if(depart==1)
			if(!(1 in tournee))
				push!(tournee,depart)
			end
			findDepot=true
		end
	end
	#println(tournee)
	return findDepot,tournee
end

function create_partition(nb_clients,Q,q_vals,t)
    cpt_vehi=1 # compteur de vehicule
    bool_end=false # boolean pour detercter si on a bien traité tous les villes
    charge_actuel=0
    partition=Dict()
    for i in 1:nb_clients
        qi=q_vals[i,t]
        if isapprox(qi, 0.0; atol = 1e-8)
            continue
        end
        if charge_actuel==0
            charge_actuel=qi
            partition[cpt_vehi]=[1]
            push!(partition[cpt_vehi],i+1)
        elseif charge_actuel+qi>Q
            cpt_vehi+=1
            charge_actuel=qi
            partition[cpt_vehi]=[1]
            push!(partition[cpt_vehi],i+1)
        else
            charge_actuel+=qi
            #println(partition[cpt_vehi],i)
            push!(partition[cpt_vehi],i+1)
        end
    end
    return partition,cpt_vehi
end



function tsp_create_partition(nb_clients,cpt_vehi ,partition,clients_info)
    tsp_partition=Dict()
    if length(partition)==0
        return tsp_partition
    end
    cij=Array{Float64, 2}(undef, nb_clients+1, nb_clients+1)
    for i in 1:nb_clients+1
        for j in 1:nb_clients+1
            cij[i,j]=floor(hypot(clients_info[i-1][1]-clients_info[j-1][1],  clients_info[i-1][2]-clients_info[j-1][2]) +1/2)
        end
    end
    for i = 1:cpt_vehi
        ordre=[1]
        filter!(e->e≠1,partition[i])
        pred=1
        while length(partition[i])!=0
            dis_min=Inf
            index_min=-1
            for j in partition[i]
                dist=cij[pred,j]
                if (dis_min>dist) && (j!=index_min)
                    dis_min=dist
                    index_min=j
                end
            end
            push!(ordre,index_min)
            filter!(e->e≠index_min,partition[i])
            pred=index_min
        end
        tsp_partition[i]=ordre
    end
    return tsp_partition
end
