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
PYTHON = python3

CURDATE = $(shell date -Iseconds)
CURDIR_NAME = $(shell basename $(CURDIR))
TRAINING_DATE = $(shell date +%Y-%m-%d)
TRAINING_PATH = ${UPKIE_TRAINING_PATH}

# Only used to avoid uploading the training directory to the robot
TRAINING_DIRNAME = $(shell basename ${UPKIE_TRAINING_PATH})

# Help snippet adapted from:
# http://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
help:
	@echo "Host targets:\n"
	@grep -P '^[a-zA-Z0-9_-]+:.*? ## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "    \033[36m%-24s\033[0m %s\n", $$1, $$2}'
	@echo "\nRobot targets:\n"
	@grep -P '^[a-zA-Z0-9_-]+:.*?### .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?### "}; {printf "    \033[36m%-24s\033[0m %s\n", $$1, $$2}'

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

clean_broken_links:
	find -L $(CURDIR) -type l ! -exec test -e {} \; -delete

clean:  ## clean build and environment files
	$(BAZEL) clean --expunge
	rm -f environment.tar

upload: check_upkie_name  ## upload balancer to the robot
	ssh ${UPKIE_NAME} sudo date -s "$(CURDATE)"
	ssh ${UPKIE_NAME} mkdir -p $(CURDIR_NAME)
	ssh ${UPKIE_NAME} sudo find $(CURDIR_NAME) -type d -name __pycache__ -user root -exec chmod go+wx {} "\;"
	rsync -Lrtu --delete-after \
		--exclude $(TRAINING_DIRNAME)/ \
		--exclude .pixi \
		--exclude activate.sh \
		--exclude bazel-$(CURDIR_NAME) \
		--exclude bazel-$(CURDIR_NAME)/ \
		--exclude bazel-bin/ \
		--exclude bazel-out/ \
		--exclude bazel-testlogs/ \
		--exclude env/ \
		--progress \
		$(CURDIR)/ ${UPKIE_NAME}:$(CURDIR_NAME)/

tensorboard:  ## Start TensorBoard on today's trainings
	xdg-open http://localhost:6006 &
	tensorboard --logdir $(TRAINING_PATH)/$(TRAINING_DATE)

pack_pixi_env:  ## pack Python environment to be deployed to your Upkie
	@pixi run pack-to-upkie || { \
		echo "Error: pixi not found"; \
		echo "See https://pixi.sh/latest/#installation"; \
		exit 1; \
	}

unpack_pixi_env:  ### unpack Python environment
	@pixi-pack unpack environment.tar || { \
		echo "Error: pixi-pack not found"; \
		echo "You can download `pixi-pack-aarch64-unknown-linux-musl` from https://github.com/Quantco/pixi-pack/releases"; \
		exit 1; \
	}

run_policy:  ### run saved policy
	@if [ -f $(CURDIR)/activate.sh ]; then \
		echo ". $(CURDIR)/activate.sh && $(PYTHON) ppo_balancer/run.py"; \
		. $(CURDIR)/activate.sh && $(PYTHON) ppo_balancer/run.py; \
	else \
		echo "$(PYTHON) ppo_balancer/run.py"; \
		$(PYTHON) ppo_balancer/run.py; \
	fi
