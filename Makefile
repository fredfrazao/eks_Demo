.DEFAULT_GOAL = help
.PHONY: help 
		

ENV ?= dev
PIPENV_SYNC ?= true
KUBECONFIG_FILE ?= ''
HW_INVENTORY_ARG ?= ''
ANSIBLE_PLAYBOOK := pipenv run ansible-playbook $(PRIVATE_KEY_OPTION) $(INVENTORIES) $(ANSIBLE_EXTRA_VARS)



ifneq ("$(wildcard .vault_$(ENV))","")
    ANSIBLE_VAULT_PASSWORD_FILE=.vaultfile_$(ENV)
else
    ANSIBLE_VAULT_PASSWORD_FILE=~/.vaultfile_$(ENV)
endif


ifneq ($(SSH_KEY),)
    PRIVATE_KEY_OPTION=--private-key $(SSH_KEY)
else
    PRIVATE_KEY_OPTION=
endif


env:
	@echo "ANSIBLE_VAULT_PASSWORD_FILE=${ANSIBLE_VAULT_PASSWORD_FILE}" > .env

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'


lint: install-pre-commit-hooks
	pipenv run pre-commit run --all-files --verbose

pipenv-sync: ## sync pipenv with Pipenv.lock
ifeq ($(PIPENV_SYNC), true)
	./scripts/check_tool.sh pipenv
ifeq ($(shell pipenv run pip3 list | grep ansible | grep -q 2.9; echo $$?), 0)
	pipenv --rm
endif
	pipenv sync
else
	@echo "Skipping pipenv sync"
endif

pipenv-install:
	pipenv install

play-dependencies: env pipenv-sync  ## dependencies when running ansible plays

# make print-pass ENV=dev PASS=somepass
print-pass:
	@pipenv run yq -r ".$(PASS)" $$(grep -ir "$(PASS): !vault" ansible/inventories/$(ENV) -l) | pipenv run ansible-vault decrypt --vault-password-file $(ANSIBLE_VAULT_PASSWORD_FILE) 2>/dev/null; echo

tf-validate:  ##  Terraform and validate
	 terraform validate


init-terraform:  ## Setup Terraform and validate 
	 terraform init 
	 terraform validate 

plan-terraform:  ## Setup Terraform and validate 
	 terraform plan -input=false 
	 
setup-eks-cluster:  init-terraform tf-validate plan-terraform ## Setup eks cluster
	 terraform apply  -auto-approve -input=false

destroy-eks-cluster: init-terraform ## destroy eks cluster
	terraform destroy -auto-approve 

get-kubeconfig:  ## get kubeconfig and update ./kube
	aws eks --region $(terraform output -raw region) update-kubeconfig --name $(terraform output -raw cluster_name) 
