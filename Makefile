# Makefile for the PPO balancer
#
# SPDX-License-Identifier: Apache-2.0

# Adjust the number of training env. for best performance on your machine:
NB_SHOW_TRAINING_ENVS = 2
NB_TRAINING_ENVS = 6

# Hostname or IP address of the robot's Raspberry Pi. Uses the value from the
# UPKIE_NAME environment variable, if defined.
REMOTE = ${UPKIE_NAME}

# Programs
BAZEL = $(CURDIR)/tools/bazelisk
BROWSER = firefox
PYTHON = python3
RASPUNZEL = $(CURDIR)/tools/raspunzel

CURDATE = $(shell date --iso=seconds)
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

run_policy:  ### run saved policy on the real robot
	$(RASPUNZEL) run -v -s //ppo_balancer:run
.PHONY: upload

upload: check_upkie_name build  ## upload agent to the robot
	ssh $(REMOTE) sudo date -s "$(CURDATE)"
	ssh $(REMOTE) mkdir -p $(CURDIR_NAME)
	ssh $(REMOTE) sudo find $(CURDIR_NAME) -type d -name __pycache__ -user root -exec chmod go+wx {} "\;"
	rsync -Lrtu --delete-after --delete-excluded --exclude bazel-out/ --exclude bazel-testlogs/ --exclude bazel-$(CURDIR_NAME) --exclude bazel-$(CURDIR_NAME)/ --exclude $(TRAINING_DIRNAME)/ --progress $(CURDIR)/ $(REMOTE):$(CURDIR_NAME)/

tensorboard:  ## Start tensorboard on today's trainings
	rm -f $(TRAINING_PATH)/today
	ln -sf $(TRAINING_PATH)/$(TRAINING_DATE) $(TRAINING_PATH)/today
	$(BROWSER) http://localhost:6006 &
	tensorboard --logdir $(TRAINING_PATH)/$(TRAINING_DATE)

test_policy:  ## test locally saved policy
	$(PYTHON) ppo_balancer/run.py

train:  ## train a new policy
	$(BAZEL) run //ppo_balancer:train -- --nb-envs $(NB_TRAINING_ENVS)

train_and_show:  ## train a new policy with simulations shown (slower)
	$(BAZEL) run //ppo_balancer:train -- --nb-envs $(NB_SHOW_TRAINING_ENVS) --show
