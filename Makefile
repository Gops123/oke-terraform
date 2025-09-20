# OKE Terraform Infrastructure Makefile

# Configuration
ENVIRONMENT ?= dev
TF_PLAN := tfplan
TF_STATE := terraform.tfstate

# Colors
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[1;33m
BLUE := \033[0;34m
NC := \033[0m

.PHONY: help
help: ## Show available commands
	@echo "$(BLUE)OKE Terraform Management$(NC)"
	@echo "=============================="
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# Prerequisites
.PHONY: check-prereqs
check-prereqs: ## Check prerequisites
	@command -v terraform >/dev/null 2>&1 || { echo "$(RED)Error: terraform not installed$(NC)"; exit 1; }
	@command -v oci >/dev/null 2>&1 || { echo "$(RED)Error: oci-cli not installed$(NC)"; exit 1; }
	@command -v kubectl >/dev/null 2>&1 || { echo "$(RED)Error: kubectl not installed$(NC)"; exit 1; }
	@echo "$(GREEN)✓ Prerequisites OK$(NC)"

.PHONY: check-env
check-env: ## Check environment config
	@if [ ! -f "environments/$(ENVIRONMENT)/terraform.tfvars" ]; then \
		echo "$(RED)Error: environments/$(ENVIRONMENT)/terraform.tfvars not found$(NC)"; \
		exit 1; \
	fi
	@echo "$(GREEN)✓ Environment config found$(NC)"

# Environment Management
.PHONY: env-dev env-staging env-prod
env-dev: ## Switch to dev environment
	@cp environments/dev/terraform.tfvars ./terraform.tfvars
	@echo "$(GREEN)✓ Dev environment loaded$(NC)"

env-staging: ## Switch to staging environment
	@cp environments/staging/terraform.tfvars ./terraform.tfvars
	@echo "$(GREEN)✓ Staging environment loaded$(NC)"

env-prod: ## Switch to prod environment
	@cp environments/prod/terraform.tfvars ./terraform.tfvars
	@echo "$(GREEN)✓ Prod environment loaded$(NC)"

# Terraform Operations
.PHONY: init
init: check-prereqs check-env ## Initialize Terraform
	@terraform init
	@echo "$(GREEN)✓ Terraform initialized$(NC)"

.PHONY: validate
validate: check-env ## Validate configuration
	@terraform validate
	@echo "$(GREEN)✓ Configuration valid$(NC)"

.PHONY: fmt
fmt: ## Format Terraform files
	@terraform fmt -recursive
	@echo "$(GREEN)✓ Files formatted$(NC)"

.PHONY: plan
plan: init ## Create plan
	@terraform plan -out=$(TF_PLAN)
	@echo "$(GREEN)✓ Plan created$(NC)"

.PHONY: apply
apply: plan ## Apply configuration
	@echo "$(YELLOW)⚠️  This will create/modify resources$(NC)"
	@read -p "Continue? [y/N]: " confirm; \
	if [[ $$confirm =~ ^[Yy]$$ ]]; then \
		terraform apply $(TF_PLAN); \
		echo "$(GREEN)✓ Applied successfully$(NC)"; \
	else \
		echo "$(YELLOW)Cancelled$(NC)"; \
	fi

.PHONY: apply-auto
apply-auto: plan ## Apply with auto-approve
	@terraform apply -auto-approve $(TF_PLAN)
	@echo "$(GREEN)✓ Applied successfully$(NC)"

.PHONY: destroy
destroy: ## Destroy infrastructure
	@echo "$(RED)⚠️  This will destroy ALL resources!$(NC)"
	@read -p "Type 'DESTROY' to confirm: " confirm; \
	if [[ $$confirm == "DESTROY" ]]; then \
		terraform destroy -auto-approve; \
		echo "$(GREEN)✓ Destroyed successfully$(NC)"; \
	else \
		echo "$(YELLOW)Cancelled$(NC)"; \
	fi

# Environment Deployments
.PHONY: dev staging prod
dev: ## Deploy dev environment
	@$(MAKE) env-dev
	@$(MAKE) apply-auto

staging: ## Deploy staging environment
	@$(MAKE) env-staging
	@$(MAKE) apply-auto

prod: ## Deploy prod environment
	@$(MAKE) env-prod
	@$(MAKE) plan
	@$(MAKE) apply

# Cluster Management
.PHONY: build-cluster
build-cluster: ## Build complete OKE cluster
	@$(MAKE) check-prereqs
	@$(MAKE) check-env
	@$(MAKE) init
	@$(MAKE) validate
	@$(MAKE) plan
	@echo "$(YELLOW)⚠️  Building complete OKE cluster$(NC)"
	@$(MAKE) apply
	@$(MAKE) kubeconfig
	@echo "$(GREEN)✓ Cluster built successfully$(NC)"

.PHONY: build-cluster-auto
build-cluster-auto: ## Build cluster with auto-approve
	@$(MAKE) check-prereqs
	@$(MAKE) check-env
	@$(MAKE) init
	@$(MAKE) validate
	@$(MAKE) plan
	@$(MAKE) apply-auto
	@$(MAKE) kubeconfig
	@echo "$(GREEN)✓ Cluster built successfully$(NC)"

.PHONY: update-cluster
update-cluster: ## Update cluster configuration
	@$(MAKE) check-prereqs
	@$(MAKE) check-env
	@$(MAKE) init
	@$(MAKE) validate
	@$(MAKE) plan
	@$(MAKE) apply
	@echo "$(GREEN)✓ Cluster updated$(NC)"

.PHONY: update-worker-tier
update-worker-tier: ## Update worker node pools
	@$(MAKE) check-prereqs
	@$(MAKE) check-env
	@$(MAKE) init
	@$(MAKE) validate
	@$(MAKE) plan
	@$(MAKE) apply
	@echo "$(GREEN)✓ Worker tier updated$(NC)"

# Node Pool Management
.PHONY: scale-nodepool
scale-nodepool: ## Scale node pool (POOL_NAME=name SIZE=count)
	@if [ -z "$(POOL_NAME)" ] || [ -z "$(SIZE)" ]; then \
		echo "$(RED)Error: POOL_NAME and SIZE required$(NC)"; \
		echo "Usage: make scale-nodepool POOL_NAME=general SIZE=5"; \
		exit 1; \
	fi
	@echo "Scaling $(POOL_NAME) to $(SIZE) nodes..."
	@terraform apply -var="node_pools.$(POOL_NAME).size=$(SIZE)" -auto-approve
	@echo "$(GREEN)✓ Node pool scaled$(NC)"

.PHONY: upgrade-kubernetes
upgrade-kubernetes: ## Upgrade Kubernetes (VERSION=v1.29.0)
	@if [ -z "$(VERSION)" ]; then \
		echo "$(RED)Error: VERSION required$(NC)"; \
		echo "Usage: make upgrade-kubernetes VERSION=v1.29.0"; \
		exit 1; \
	fi
	@echo "Upgrading to $(VERSION)..."
	@terraform apply -var="kubernetes_version=$(VERSION)" -auto-approve
	@echo "$(GREEN)✓ Kubernetes upgraded$(NC)"

.PHONY: nodepool-status
nodepool-status: ## Show node pool status
	@CLUSTER_ID=$$(terraform output -raw cluster_id 2>/dev/null || echo ""); \
	if [ -z "$$CLUSTER_ID" ]; then \
		echo "$(RED)Error: No cluster ID found$(NC)"; \
		exit 1; \
	fi; \
	oci ce node-pool list --cluster-id "$$CLUSTER_ID" --query "data[*].{Name:name,Status:lifecycle-state,Size:size,Shape:node-shape}" --output table 2>/dev/null || echo "$(YELLOW)Unable to retrieve status$(NC)"

# Kubernetes Operations
.PHONY: kubeconfig
kubeconfig: ## Generate kubeconfig
	@CLUSTER_ID=$$(terraform output -raw cluster_id 2>/dev/null || echo ""); \
	REGION=$$(terraform output -raw region 2>/dev/null || echo "us-ashburn-1"); \
	if [ -z "$$CLUSTER_ID" ]; then \
		echo "$(RED)Error: No cluster ID found$(NC)"; \
		exit 1; \
	fi; \
	oci ce cluster create-kubeconfig \
		--cluster-id "$$CLUSTER_ID" \
		--file ~/.kube/config \
		--region "$$REGION" \
		--token-version 2.0.0; \
	echo "$(GREEN)✓ kubeconfig generated$(NC)"

.PHONY: kubectl-test
kubectl-test: ## Test kubectl connection
	@if kubectl get nodes >/dev/null 2>&1; then \
		echo "$(GREEN)✓ Connected to cluster$(NC)"; \
		kubectl get nodes; \
	else \
		echo "$(YELLOW)⚠️  Cannot connect to cluster$(NC)"; \
	fi

# Utilities
.PHONY: status
status: ## Show current status
	@echo "$(BLUE)Status:$(NC)"
	@echo "  Environment: $(ENVIRONMENT)"
	@echo "  Config: $(shell if [ -f "terraform.tfvars" ]; then echo "$(GREEN)✓ Found$(NC)"; else echo "$(RED)✗ Missing$(NC)"; fi)"
	@echo "  State: $(shell if [ -f "$(TF_STATE)" ]; then echo "$(GREEN)✓ Found$(NC)"; else echo "$(YELLOW)✗ Missing$(NC)"; fi)"

.PHONY: output
output: ## Show Terraform outputs
	@terraform output

.PHONY: clean
clean: ## Clean temporary files
	@rm -f $(TF_PLAN)
	@rm -f .terraform.lock.hcl
	@rm -rf .terraform
	@echo "$(GREEN)✓ Cleaned$(NC)"

.PHONY: test
test: ## Run basic tests
	@$(MAKE) check-prereqs
	@$(MAKE) validate
	@echo "$(GREEN)✓ Tests passed$(NC)"

.DEFAULT_GOAL := help