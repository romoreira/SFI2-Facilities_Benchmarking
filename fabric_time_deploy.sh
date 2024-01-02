#!/bin/bash

#!/bin/bash

# Nome do arquivo CSV para armazenar os tempos
csv_file="results/fabric_deployment.csv"

# Cabeçalhos do arquivo CSV
echo "#experiment, deployment_time" > "$csv_file"

# Número de vezes que deseja executar o experimento
num_execucoes=10

# Loop para executar o experimento 10 vezes
for ((i=1; i<=$num_execucoes; i++)); do

    # Armazena o tempo de início
    #start_time=$(date +%s)

    # Aplica o arquivo YAML do StatefulSet
    kubectl apply -f svc-cassandra.yaml
    kubectl apply -f pv-cassandra.yaml
    kubectl apply -f pvc-cassandra.yaml

    # Armazena o tempo de início
    start_time=$(date +%s)

    kubectl apply -f sts-cassandra.yaml.bkp

    # Define o número total de nós no cluster
    n_total_nos=3

    # Aguarda até que todos os nós estejam no estado "UN"
    while true; do
        status=$(kubectl exec cassandra-0 -- nodetool status | grep -c "UN")
        if [ "$status" -eq "$n_total_nos" ]; then
            end_time=$(date +%s)
            echo "Todos os nós estão no estado UN."
            break
        else
            echo "Aguardando todos os nós estarem no estado UN..."
            sleep 1
        fi
    done

    # Calcula o tempo decorrido em segundos
    elapsed_time=$((end_time - start_time))
    echo "Tempo decorrido para todos os nós ficarem no estado UN: $elapsed_time segundos"
    # Imprime o tempo decorrido no formato CSV
    echo "$i, $elapsed_time" >> "$csv_file"

    sleep 30

    # Exclui o StatefulSet
    kubectl delete sts cassandra

    # Espera alguns segundos para garantir que o StatefulSet foi removido antes de excluir os PVCs
    sleep 10

    # Exclui os PersistentVolumeClaims associados ao StatefulSet
    kubectl delete pvc cassandra-pvc --force

    # Espera mais alguns segundos antes de excluir os PersistentVolumes
    sleep 10

    kubectl delete svc cassandra --force
    sleep 10

    # Exclui os PersistentVolumes associados aos PVCs
    kubectl delete pv cassandra-pv --force

    echo "Exclusão completa do StatefulSet, PersistentVolumeClaims e PersistentVolumes do Cassandra."
done
