.DEFAULT_GOAL = help
.PHONY: help

ENV ?= prod
CLUSTER ?= maia
INFRA_DIR= "./infra/$(CLUSTER)"
ANSIBLE_DIR= ansible
INVENTORIES= $(ANSIBLE_DIR)/inventories/$(ENV)
ANSIBLE_DEFAULT_VARS= $(ANSIBLE_DIR)/inventories/all
ANSIBLE_EXTRA_VARS= --extra-var "env=$(ENV) CLUSTER=$(CLUSTER)"
TerraformWS=$(ENV)_$(CLUSTER)

ANSIBLE_PLAYBOOK :=  pipenv run  ansible-playbook -i $(ANSIBLE_DEFAULT_VARS) -i $(INVENTORIES)  $(ANSIBLE_EXTRA_VARS)

get-vars: ## debug vars
	 echo INFRA_DIR: $(INFRA_DIR)
	 echo CLUSTER: $(CLUSTER)
	 echo ENV: $(ENV)
	 echo ws : $(TerraformWS)
	 echo ci : ci_$(TerraformWS)


init-terraform:  ## Setup Terraform and validate
	 terraform -chdir=$(INFRA_DIR) init

tf-ns-create:  ##  Terraform create namespace
	 terraform workspace new $(ENV)

tf-ns-delete:  ##  Terraform  delete ns
	 terraform workspace select default
	 terraform workspace delete  $(ENV)

tf-validate:  ##  Terraform and validate
	 terraform -chdir=$(INFRA_DIR) validate

tf-plan:init-terraform tf-validate ## Generate Plan
	 terraform -chdir=$(INFRA_DIR) plan  -input=false -compact-warnings

setup-eks-cluster:  init-terraform tf-plan ## Setup eks cluster
	 terraform -chdir=$(INFRA_DIR) apply -auto-approve -input=false -compact-warnings

destroy-eks-cluster:  init-terraform  ## destroy eks cluster
	terraform -chdir=$(INFRA_DIR) destroy -auto-approve

ci-terraform-configs:  ## update Terraform Workspace and cluster_name with CI-configurations
	 sed -i -e  's/Terraform_CLUSTER_Workspace/$(TerraformWS)/g' $(INFRA_DIR)/main.tf && rm -rf $(INFRA_DIR)/main.tf-e
	 sed -i -e  's/CLUSTER_NAME/ci-$(CLUSTER)/g' $(INFRA_DIR)/main.tf && rm -rf $(INFRA_DIR)/main.tf-e
	 sed -i -e  's/vpc_1/$(TerraformWS)/g' $(INFRA_DIR)/vpc.tf && rm -rf $(INFRA_DIR)/vpc.tf-e

terraform-configs:  ## update Terraform Workspace and cluster_name configurations
	 sed -i -e  's/Terraform_CLUSTER_Workspace/$(TerraformWS)/g' $(INFRA_DIR)/main.tf && rm -rf $(INFRA_DIR)/main.tf-e
	 sed -i -e  's/CLUSTER_NAME/$(CLUSTER)/g' $(INFRA_DIR)/main.tf && rm -rf $(INFRA_DIR)/main.tf-e
	 sed -i -e  's/vpc_1/$(TerraformWS)/g' $(INFRA_DIR)/vpc.tf && rm -rf $(INFRA_DIR)/vpc.tf-e

cleanup: destroy-eks-cluster tf-ns-delete ## cleanup

install-ansible-collections: ## install ansible collections
	ansible-galaxy collection install --collections-path $(ANSIBLE_DIR)/collections --requirements-file $(ANSIBLE_DIR)/collections/requirements.yml --force


install-components:  ## components installation
	$(ANSIBLE_PLAYBOOK) $(ANSIBLE_DIR)/components_install.yml --tags setup_components

install-pre-components:  ## pre packages installation
	$(ANSIBLE_PLAYBOOK) $(ANSIBLE_DIR)/components_install.yml --tags setup_pre

install-grafana:  ## grafana installation
	$(ANSIBLE_PLAYBOOK) $(ANSIBLE_DIR)/components_install.yml --tags setup_grafana_operator

install-prometheus:  ## setup_prometheus_operator
	$(ANSIBLE_PLAYBOOK) $(ANSIBLE_DIR)/components_install.yml --tags setup_prometheus_operator

install-argo-cd:  ## setup argo-cd
	$(ANSIBLE_PLAYBOOK) $(ANSIBLE_DIR)/components_install.yml --tags setup_argocd

install-setup_consul:  ## setup consul
	$(ANSIBLE_PLAYBOOK) $(ANSIBLE_DIR)/components_install.yml --tags setup_consul

get-kubeconfig:  ## get-kubeconfig
	aws eks --region $(terraform output -raw region) update-kubeconfig --name $(terraform output -raw cluster_name)

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
