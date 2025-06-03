#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#
# SPDX-License-Identifier: Apache-2.0
# Copyright 2022 Stéphane Caron
# Copyright 2023 Inria

import argparse
import logging
import os
from typing import Tuple

import gin
import gymnasium as gym
import numpy as np
import upkie.envs
from stable_baselines3 import PPO
from upkie.utils.raspi import configure_agent_process, on_raspi
from upkie.utils.robot_state import RobotState
from upkie.utils.robot_state_randomization import RobotStateRandomization

from settings import EnvSettings, PPOSettings, TrainingSettings
from wrap_velocity_env import wrap_velocity_env

upkie.envs.register()


def parse_command_line_arguments() -> argparse.Namespace:
    """Parse command line arguments.

    Returns:
        Command-line arguments.
    """
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "policy",
        nargs="?",
        help="path to the policy parameters file",
    )
    parser.add_argument(
        "--training",
        default=False,
        action="store_true",
        help="add noise and actuation lag, as in training",
    )
    return parser.parse_args()


def get_tip_state(
    observation, tip_height: float = 0.58
) -> Tuple[float, float]:
    """Compute the state of the virtual tip used in the agent's reward.

    This extra info is for logging only.

    Args:
        observation Observation vector.
        tip_height Height of the virtual tip.

    Returns:
        Pair of tip (position, velocity) in the sagittal plane.
    """
    pitch = observation[0]
    ground_position = observation[1]
    angular_velocity = observation[2]
    ground_velocity = observation[3]
    tip_position = ground_position + tip_height * np.sin(pitch)
    tip_velocity = ground_velocity + tip_height * angular_velocity * np.cos(
        pitch
    )
    return tip_position, tip_velocity


def run_policy(env: gym.Wrapper, policy) -> None:
    """Run the policy on a given environment.

    Args:
        env: Upkie environment, wrapped by the agent.
        policy: MLP policy to follow.
    """
    action = np.zeros(env.action_space.shape)
    observation, info = env.reset()
    reward = 0.0
    while True:
        action, _ = policy.predict(observation, deterministic=True)
        tip_position, tip_velocity = get_tip_state(observation[-1])
        env.unwrapped.log("action", action)
        env.unwrapped.log("observation", observation[-1])
        env.unwrapped.log("reward", reward)
        env.unwrapped.log("tip_position", tip_position)
        env.unwrapped.log("tip_velocity", tip_velocity)
        observation, reward, terminated, truncated, info = env.step(action)
        if terminated or truncated:
            observation, info = env.reset()


def main(policy_path: str, training: bool) -> None:
    """Load environment and policy, and run the latter on the former.

    Args:
        policy_path: Path to policy parameters.
        training: If True, add training noise and domain randomization.
    """
    env_settings = EnvSettings()
    init_state = None
    if training:
        training_settings = TrainingSettings()
        init_state = RobotState(
            randomization=RobotStateRandomization(
                **training_settings.init_rand
            ),
        )
    with gym.make(
        env_settings.env_id,
        frequency=env_settings.agent_frequency,
        init_state=init_state,
        max_ground_velocity=env_settings.max_ground_velocity,
        regulate_frequency=True,
        spine_config=env_settings.spine_config,
    ) as velocity_env:
        env = wrap_velocity_env(
            velocity_env,
            env_settings,
            training=training,
        )
        ppo_settings = PPOSettings()
        policy = PPO(
            "MlpPolicy",
            env,
            policy_kwargs={
                "net_arch": {
                    "pi": ppo_settings.net_arch_pi,
                    "vf": ppo_settings.net_arch_vf,
                },
            },
            verbose=0,
        )
        policy.set_parameters(policy_path)
        run_policy(env, policy)


if __name__ == "__main__":
    if on_raspi():
        configure_agent_process()

    args = parse_command_line_arguments()

    # Policy parameters
    policy_path = args.policy
    if policy_path is None:
        script_dir = os.path.abspath(os.path.dirname(__file__))
        policy_dir = os.path.join(os.path.dirname(script_dir), "policy")
        policy_path = f"{policy_dir}/params.zip"
    if policy_path.endswith(".zip"):
        policy_path = policy_path[:-4]
    logging.info("Loading policy from %s.zip", policy_path)

    # Configuration
    config_path = f"{os.path.dirname(policy_path)}/operative_config.gin"
    logging.info("Loading policy configuration from %s", config_path)
    gin.parse_config_file(config_path)

    try:
        main(policy_path, args.training)
    except KeyboardInterrupt:
        logging.info("Caught a keyboard interrupt")
