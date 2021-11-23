.PHONY: list clean provision-dev-cluster

CURRENT_DIR = $(shell pwd)

list:
	@$(MAKE) -pRrq -f $(lastword $(MAKEFILE_LIST)) : 2>/dev/null | awk -v RS= -F: '/^# File/,/^# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' | sort | egrep -v -e '^[^[:alnum:]]' -e '^$@$$'

clean:
	@echo "Cleaning up..."
	k3d cluster delete dev-ld

provision-dev-cluster:
	@echo "Creating a k3d cluster..."
	k3d cluster create dev-ld \
		--api-port 6550 -p "8081:80@loadbalancer" \
		--port "8443:443@loadbalancer" \
		--k3s-arg '--flannel-backend=none@server:*' \
		--volume "$(CURRENT_DIR)/k3d/calico.yaml:/var/lib/rancher/k3s/server/manifests/calico.yaml" \
		--k3s-arg '--no-deploy=traefik@server:*' \
		--volume "$(CURRENT_DIR)/k3d/helm-ingress-nginx.yaml:/var/lib/rancher/k3s/server/manifests/helm-ingress-nginx.yaml"

install-argo-cd:
	helm install argo-cd charts/argo-cd/ --namespace=argocd --create-namespace

install-application:
	helm template applications/argo-cd/ | kubectl apply -f -

delete-argocd-helm:
	kubectl delete secret -l owner=helm,name=argo-cd -n argocd

get-argocd-admin-cerd:
	kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
