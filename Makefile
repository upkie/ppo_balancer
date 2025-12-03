# Makefile for the PPO balancer
#
# SPDX-License-Identifier: Apache-2.0

PROJECT_NAME = ppo_balancer

# Programs
BAZEL = $(CURDIR)/tools/bazelisk
PYTHON = python3

CURDATE = $(shell date -Iseconds)
CURDIR_NAME = $(shell basename $(CURDIR))

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

pack_env:  ## pack Python environment to be deployed to your Upkie
	@pixi run pack || { \
		echo "Error: pixi not found"; \
		echo "See https://pixi.sh/latest/#installation"; \
		exit 1; \
	}

run_real:  ### run saved policy on the real robot
	echo ". $(CURDIR)/activate.sh && $(PYTHON) ppo_balancer/run.py"; \
	. $(CURDIR)/activate.sh && $(PYTHON) ppo_balancer/run.py; \

unpack_env:  ### unpack Python environment
	@pixi-unpack environment.tar || { \
		echo "Error: pixi-unpack not found"; \
		echo "See https://github.com/Quantco/pixi-pack?tab=readme-ov-file#-installation"; \
		exit 1; \
	}

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
