function detect_sous_tour1(n,xkt,zsep)
	"""
	n: nb de revendeurs
	xkt : matrice x[:,:,k,t], contient peut etre plusieurs tournees
	detecter un sous tour d une voiture k, a l instant t
	"""
	sousTours=Set()
	dejaVisite=Set()
	trouveDepartDepot=true # =false si trouver au moins un sous tour
	for i =2:n+1
		if(!(i in dejaVisite) ) #si deja visite, appartient deja a un sous tours
			for j =2:n+1
				if(xkt[i,j]>=1)
					passeDepot,tournee=find_tournee(n,xkt,j,i)
					if(!passeDepot && !(1 in tournee)) #detection d un sous tours
						trouveDepartDepot=false
						push!(sousTours, Set(tournee))
						union!(dejaVisite,tournee)

					end
				end
			end
		end

	end
    for i =1:n
        if (zsep[i]==1 && !(zsep[i]+1 in dejaVisite))
            push!(sousTours, Set([i+1]))
        end
    end
	#print(sousTours)
	return trouveDepartDepot,sousTours
end

function find_tournee(n,xkt,i,circuit)
	"""
	circuit: un chiffre, le point de depart du circuit
	n : nb de revendeur
	i : le point de depart suivant
	xkt : matrice x de la voiture k, a l instant t
	donne le circuit de la voirture k a l instant t
	"""
	depart=i
	tournee=[circuit]
	findDepot=false
	dejaPasse=Set() #stock les noeuds deja passes
	push!(dejaPasse,circuit)
	#println(xkt)
    c=0
    record=0
    b=false
	while(!findDepot && !(depart in dejaPasse)&& !b)#c!=n+1)
		push!(tournee,depart)
		push!(dejaPasse,depart)
        record=depart
		for j =1:n+1
            c=j
			if(xkt[depart,j]>0) && !(j in tournee)
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
