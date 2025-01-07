# Makefile for the PPO balancer
#
# SPDX-License-Identifier: Apache-2.0

PROJECT_NAME = ppo_balancer

# You can adjust the number of training environments for best performance on
# your machine, either by editing this file or by passing it to the `make`
# command, e.g. `make <your_target> NB_TRAINING_ENVS=<new_value>`.
NB_TRAINING_ENVS = 6

# Programs
BAZEL = $(CURDIR)/tools/bazelisk
BROWSER = firefox
PYTHON = python3

CURDATE = $(shell date -Iseconds)
CURDIR_NAME = $(shell basename $(CURDIR))
TRAINING_DATE = $(shell date +%Y-%m-%d)
TRAINING_PATH = ${UPKIE_TRAINING_PATH}

# Only used to avoid uploading the training directory to the robot
TRAINING_DIRNAME = $(shell basename ${UPKIE_TRAINING_PATH})

# Help snippet adapted from:
# http://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
.PHONY: help
help:
	@echo "Host targets:\n"
	@grep -P '^[a-zA-Z0-9_-]+:.*? ## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "    \033[36m%-24s\033[0m %s\n", $$1, $$2}'
	@echo "\nRobot targets:\n"
	@grep -P '^[a-zA-Z0-9_-]+:.*?### .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?### "}; {printf "    \033[36m%-24s\033[0m %s\n", $$1, $$2}'
.DEFAULT_GOAL := help

.PHONY: check_upkie_name
check_upkie_name:
	@ if [ -z "${UPKIE_NAME}" ]; then \
		echo "ERROR: Environment variable UPKIE_NAME is not set.\n"; \
		echo "This variable should contain the robot's hostname or IP address for SSH. "; \
		echo "You can define it inline for a one-time use:\n"; \
		echo "    make some_target UPKIE_NAME=your_robot_hostname\n"; \
		echo "Or add the following line to your shell configuration:\n"; \
		echo "    export UPKIE_NAME=your_robot_hostname\n"; \
		exit 1; \
	fi

.PHONY: clean_broken_links
clean_broken_links:
	find -L $(CURDIR) -type l ! -exec test -e {} \; -delete

.PHONY: build
build: clean_broken_links
	$(BAZEL) build --config=pi64 //ppo_balancer:run

.PHONY: clean
clean:  ## clean intermediate build files
	$(BAZEL) clean --expunge

.PHONY: upload
upload: check_upkie_name  ## upload agent to the robot
	ssh ${UPKIE_NAME} sudo date -s "$(CURDATE)"
	ssh ${UPKIE_NAME} mkdir -p $(CURDIR_NAME)
	ssh ${UPKIE_NAME} sudo find $(CURDIR_NAME) -type d -name __pycache__ -user root -exec chmod go+wx {} "\;"
	rsync -Lrtu --delete-after --exclude bazel-bin/ --exclude bazel-out/ --exclude bazel-testlogs/ --exclude bazel-$(CURDIR_NAME) --exclude bazel-$(CURDIR_NAME)/ --exclude cache/ --exclude .pixi --exclude env/ --exclude activate.sh --exclude $(TRAINING_DIRNAME)/ --progress $(CURDIR)/ ${UPKIE_NAME}:$(CURDIR_NAME)/

tensorboard:  ## Start tensorboard on today's trainings
	rm -f $(TRAINING_PATH)/today
	ln -sf $(TRAINING_PATH)/$(TRAINING_DATE) $(TRAINING_PATH)/today
	$(BROWSER) http://localhost:6006 &
	tensorboard --logdir $(TRAINING_PATH)/$(TRAINING_DATE)

train:  ## train a new policy
	$(BAZEL) run //ppo_balancer:train -- --nb-envs $(NB_TRAINING_ENVS)

train_and_show:  ## train a new policy with simulations shown (slower)
	$(BAZEL) run //ppo_balancer:train -- --nb-envs $(NB_TRAINING_ENVS) --show

environment.tar:
	@pixi run pack-to-upkie || { \
		echo "Error: pixi not found"; \
		echo "See https://pixi.sh/latest/#installation"; \
		exit 1; \
	}

$(CURDIR)/activate.sh:
	@pixi-pack unpack environment.tar || { \
		echo "Error: pixi-pack not found"; \
		echo "You can download `pixi-pack-aarch64-unknown-linux-gnu` from https://github.com/Quantco/pixi-pack/releases"; \
		exit 1; \
	}

pack_pixi_env: environment.tar  ## pack Python environment to be deployed to your Upkie

unpack_pixi_env: $(CURDIR)/activate.sh  ### unpack Python environment

run_agent:  ### run saved policy
	@if [ -f $(CURDIR)/activate.sh ]; then \
		echo ". $(CURDIR)/activate.sh && $(PYTHON) ppo_balancer/run.py"; \
		. $(CURDIR)/activate.sh && $(PYTHON) ppo_balancer/run.py; \
	else \
		echo "$(PYTHON) ppo_balancer/run.py"; \
		$(PYTHON) ppo_balancer/run.py; \
	fi
