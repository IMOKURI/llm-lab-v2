.DEFAULT_GOAL := help

.PHONY: help
help: ## Show this help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z0-9_-]+:.*?## / \
		{printf "\033[38;2;98;209;150m%-15s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

export
NOW = $(shell date '+%Y%m%d-%H%M%S')

#######################################################################################################################
# jupyter
#######################################################################################################################
IMAGE_NAME = quay.io/jupyter/datascience-notebook
IMAGE_TAG = 2025-03-14

up-jupyter: ## Start jupyter.
	docker run -d --name jupyter -p 8888:8888 \
		--shm-size=16g \
		--gpus '"device=0"' \
		--dns 1.1.1.1 \
		-v $(shell pwd)/cache:/home/jovyan/.cache \
		-v $(shell pwd)/work:/home/jovyan/work \
		$(IMAGE_NAME):$(IMAGE_TAG)

down-jupyter: ## Stop jupyter.
	docker stop jupyter || :
	docker rm jupyter || :

ps-jupyter: ## Status jupyter.
	docker ps -a -f name=jupyter || :

log-jupyter: ## Log jupyter.
	docker logs -f jupyter || :

#######################################################################################################################
# vllm
#######################################################################################################################
VLLM_IMAGE_NAME = vllm/vllm-openai
VLLM_IMAGE_TAG = v0.10.1

up-vllm: ## Start vllm.
	docker run -d --name vllm -p 8000:8000 \
		--shm-size=16g \
		--gpus '"device=0"' \
		-v $(shell pwd)/work:/work \
		-e HF_HUB_OFFLINE=1 \
		-e TRANSFORMERS_OFFLINE=1 \
		$(VLLM_IMAGE_NAME):$(VLLM_IMAGE_TAG) \
		--model /work/gemma-3-finance-finetune \
		--served-model-name gemma-3-finance \
		--gpu-memory-utilization 0.5 \
		--quantization fp8 \
		--max-model-len 2048 \
		--host 0.0.0.0 --port 8000

down-vllm: ## Stop vllm.
	docker stop vllm || :
	docker rm vllm || :

ps-vllm: ## Status vllm.
	docker ps -a -f name=vllm || :

log-vllm: ## Log vllm.
	docker logs -f vllm || :


test-vllm-models: ## test-vllm-models
	curl --request GET \
		--header "Content-Type: application/json" \
		--header "Authorization: Bearer no-key" \
		--url http://localhost:8000/v1/models | jq .

test-vllm-chat: ## test-vllm-chat
	curl --request POST \
		--header "Content-Type: application/json" \
		--header "Authorization: Bearer no-key" \
		--url http://localhost:8000/v1/chat/completions \
		--data @./prompt.json | jq .

