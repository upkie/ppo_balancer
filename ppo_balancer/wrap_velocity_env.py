#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#
# SPDX-License-Identifier: Apache-2.0
# Copyright 2023 Inria

import gymnasium
import numpy as np
from gymnasium import spaces
from gymnasium.wrappers import FrameStackObservation, RescaleAction
from upkie.envs import UpkieGroundVelocity
from upkie.envs.wrappers import (
    AddActionToObservation,
    AddLagToAction,
    DifferentiateAction,
    NoisifyAction,
    NoisifyObservation,
)

from settings import EnvSettings


def wrap_velocity_env(
    velocity_env: UpkieGroundVelocity,
    env_settings: EnvSettings,
    training: bool,
) -> gymnasium.Wrapper:
    env = velocity_env

    if training:  # training-specific wrappers
        env = NoisifyObservation(
            env,
            noise=np.array(env_settings.observation_noise),
        )
        env = NoisifyAction(
            env,
            noise=np.array(env_settings.action_noise),
        )
        env = AddLagToAction(
            env,
            time_constant=spaces.Box(*env_settings.action_lpf),
        )

    env = AddActionToObservation(env)
    env = FrameStackObservation( env, env_settings.history_size)
    env = DifferentiateAction(
        env,
        min_derivative=-env_settings.max_ground_accel,
        max_derivative=+env_settings.max_ground_accel,
    )
    env = RescaleAction(
        env,
        min_action=-1.0,
        max_action=+1.0,
    )
    return env
