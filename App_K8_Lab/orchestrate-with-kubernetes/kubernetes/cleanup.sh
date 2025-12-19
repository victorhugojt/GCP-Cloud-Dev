# Deletes the resources created in the lab

# Delete Pods
kubectl delete pods fortune-app secure-fortune --ignore-not-found

# Delete Services
kubectl delete services fortune-app auth frontend fortune --ignore-not-found

# Delete Deployments
kubectl delete deployments auth frontend fortune --ignore-not-found

# Delete Secrets and ConfigMaps
kubectl delete secrets tls-certs --ignore-not-found
kubectl delete configmaps nginx-proxy-conf nginx-frontend-conf --ignore-not-found