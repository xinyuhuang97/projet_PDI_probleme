using DelimitedFiles

function Read_instance(filename, render = 0)
    lastfilename = split(filename,"/")
    filename_splitted = split(last(lastfilename),"_")
    file_type, nb_clients=filename_splitted[1], parse(Int64, filename_splitted[2])
    if render == 1
        println(file_type," ",nb_clients)
    end
    general_info, clients_info, demand_info = dict_type_read[file_type](filename,nb_clients, render)
    return file_type, nb_clients, general_info, clients_info, demand_info
end

function Read_A_type_instance(filename, nb_clients, render=1)
    general_info=Any[]
    clients_info=Dict()
    demand_info=Dict()
    open(filename) do f
        for (i,line) in enumerate(eachline(f))
            data =  split(line," ")
            if i<=8
                push!(general_info,data[2])
            elseif i<=8+nb_clients+1
                index=parse(Int, data[1])
                ix_drop=[1,4,5,7,9]
                deleteat!(data,ix_drop)
                data=[if tryparse(Int,x) != nothing tryparse(Int,x)  else Int(parse(Float64, x))  end for x in data  ]
                clients_info[index]=data
            elseif i==8+nb_clients+2
                continue
            else
                data =  split(line," ",limit=7)
                index=parse(Int, data[1])
                ix_drop=[1]
                deleteat!(data,ix_drop)
                data=[if tryparse(Int,x) != nothing tryparse(Int,x)  else Int(parse(Float64, x))  end for x in data  ]
                demand_info[index]=data
            end
        end
    general_info=[if tryparse(Int,x) != nothing tryparse(Int,x)  else Int(parse(Float64, x))  end for x in general_info  ]
    end
    if render == 1
        println(general_info)
        println(clients_info)
        println(demand_info)
    end
    return general_info, clients_info, demand_info
end

function Read_B_type_instance(filename, nb_clients, render=0)
    general_info=Any[]
    clients_info=Dict()
    demand_info=Dict()
    open(filename) do f
        for (i,line) in enumerate(eachline(f))
            data =  split(line," ")
            if i<=9
                push!(general_info,data[2])
            elseif i<=9+nb_clients+1
                index=parse(Int, data[1])
                ix_drop=[1,4,5,7,9]
                deleteat!(data,ix_drop)
                data=[if tryparse(Int,x) != nothing tryparse(Int,x)  else Int(parse(Float64, x))  end for x in data  ]
                clients_info[index]=data
            elseif i==9+nb_clients+2
                continue
            else
                data =  split(line," ",limit=21)
                index=parse(Int, data[1])
                ix_drop=[1]
                deleteat!(data,ix_drop)
                data=[if tryparse(Int,x) != nothing tryparse(Int,x)  else Int(parse(Float64, x))  end for x in data  ]
                demand_info[index]=data
            end
        end
    general_info=[if tryparse(Int,x) != nothing tryparse(Int,x)  else Int(parse(Float64, x))  end for x in general_info  ]
    end
    #print("hi")
    #print(render)
    if render == 1
        println(general_info)
        println(clients_info)
        println(demand_info)
    end
    return general_info, clients_info, demand_info
end

dict_type_read=Dict("A"=> Read_A_type_instance, "B"=>Read_B_type_instance)
#Read_instance("PRP_instances/A_014_ABS75_15_2.prp")
#Read_instance("PRP_instances/B_200_instance18.prp")
