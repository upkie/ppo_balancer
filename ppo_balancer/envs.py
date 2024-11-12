#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#
# SPDX-License-Identifier: Apache-2.0
# Copyright 2023 Inria

import gymnasium
import numpy as np
from gymnasium import spaces
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


def make_training_env(
    velocity_env: UpkieGroundVelocity,
    env_settings: EnvSettings,
) -> gymnasium.Wrapper:
    action_noise = np.array(env_settings.action_noise)
    observation_noise = np.array(env_settings.observation_noise)
    noisy_obs_env = NoisifyObservation(velocity_env, noise=observation_noise)
    noisy_env = NoisifyAction(noisy_obs_env, noise=action_noise)
    filtered_env = AddLagToAction(
        noisy_env,
        time_constant=spaces.Box(*env_settings.action_lpf),
    )
    return filtered_env


def make_accel_env(
    velocity_env: UpkieGroundVelocity,
    env_settings: EnvSettings,
    training: bool,
) -> gymnasium.Wrapper:
    inner_env = (
        make_training_env(velocity_env, env_settings)
        if training
        else velocity_env
    )
    history_env = FrameStack(
        AddActionToObservation(inner_env),
        env_settings.history_size,
    )
    accel_env = DifferentiateAction(
        history_env,
        min_derivative=-env_settings.max_ground_accel,
        max_derivative=+env_settings.max_ground_accel,
    )
    rescaled_accel_env = RescaleAction(
        accel_env,
        min_action=-1.0,
        max_action=+1.0,
    )
    return rescaled_accel_env


def make_ppo_balancer_env(
    velocity_env: UpkieGroundVelocity,
    env_settings: EnvSettings,
    training: bool,
) -> gymnasium.Wrapper:
    return make_accel_env(velocity_env, env_settings, training=training)
