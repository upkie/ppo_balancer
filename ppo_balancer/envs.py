#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#
# SPDX-License-Identifier: Apache-2.0
# Copyright 2023 Inria

import gymnasium as gym
import numpy as np
from gymnasium.wrappers import FrameStack, RescaleAction
from settings import EnvSettings
from upkie.envs import UpkieGroundVelocity
from upkie.envs.wrappers import (
    AddActionToObservation,
    AddLagToAction,
    DifferentiateAction,
    NoisifyAction,
    NoisifyObservation,
)

from ppo_balancer.wrappers import WheeledInvertedPendulumReward


def add_training_wrappers(
    original_env: gym.Env,
    env_settings: EnvSettings,
) -> gym.Wrapper:
    action_noise = np.array(env_settings.action_noise)
    observation_noise = np.array(env_settings.observation_noise)
    noisy_obs_env = NoisifyObservation(original_env, noise=observation_noise)
    noisy_env = NoisifyAction(noisy_obs_env, noise=action_noise)
    filtered_env = AddLagToAction(
        noisy_env,
        time_constant=gym.spaces.Box(*env_settings.action_lpf),
    )
    return filtered_env


def make_ppo_balancer_env(
    env: UpkieGroundVelocity,
    env_settings: EnvSettings,
    training: bool,
) -> gym.Wrapper:
    env = WheeledInvertedPendulumReward(env)
    if training:
        env = add_training_wrappers(env, env_settings)
    env = FrameStack(AddActionToObservation(env), env_settings.history_size)
    env = DifferentiateAction(
        env,
        min_derivative=-env_settings.max_ground_accel,
        max_derivative=+env_settings.max_ground_accel,
    )
    env = RescaleAction(env, min_action=-1.0, max_action=1.0)
    return env
