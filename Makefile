VAULT := algoVPN
FORCE:

## docker-build: Build and tag a docker image
.PHONY: docker-build

IMAGE          := trailofbits/algo
TAG	  	       := latest
DOCKERFILE     := Dockerfile
CONFIGURATIONS := $(shell pwd)

docker-build:
	docker build \
	-t $(IMAGE):$(TAG) \
	-f $(DOCKERFILE) \
	.

## docker-deploy: Mount config directory and deploy Algo
.PHONY: docker-deploy

# '--rm' flag removes the container when finished.
docker-deploy:
	docker run \
	--cap-drop=all \
	--rm \
	-it \
	-v $(CONFIGURATIONS):/data \
	$(IMAGE):$(TAG)

## docker-clean: Remove images and containers.
.PHONY: docker-prune

docker-prune:
	docker images \
	$(IMAGE) |\
	awk '{if (NR>1) print $$3}' |\
	xargs docker rmi

## docker-all: Build, Deploy, Prune
.PHONY: docker-all

docker-all: docker-build docker-deploy docker-prune

configs: FORCE
	op get document configs.tgz --vault $(VAULT) > configs.tgz
	tar -xzvf configs.tgz
	rm configs.tgz

config.cfg:
	op get document config.cfg --vault $(VAULT) > config.cfg
	# you can do a `git diff` to see the changes

configs.tgz:
	tar -czvf configs.tgz configs

config.cfg.back:
	mv config.cfg config.cfg.back

.PHONY: push_config
push_config: configs.tgz config.cfg
	op edit document config.cfg config.cfg --vault $(VAULT)
	op edit document configs.tgz configs.tgz --vault $(VAULT)

.PHONY: get_config
get_config: config.cfg.back config.cfg configs

.PHONY: clean_config
clean_config:
	rm -rf configs && mkdir configs && touch configs/.gitinit
	rm -f config.cfg.back configs.tgz
	git restore config.cfg
