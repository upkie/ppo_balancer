#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#
# SPDX-License-Identifier: Apache-2.0
# Copyright 2024 Inria

import gymnasium as gym
import numpy as np
from gymnasium.core import ActType, ObsType
from upkie.envs.wrappers import ObservationBasedReward


class DefineReward(ObservationBasedReward):
    """Define the agent's reward function."""

    position_weight: float
    velocity_weight: float

    def __init__(
        self,
        env: gym.Env[ObsType, ActType],
        position_weight: float = 1.0,
        velocity_weight: float = 1.0,
        tip_height: float = 0.58,
    ):
        """Initialize with reward weights.

        Args:
            env: Environment whose reward to redefine.
            position: Weight of the position term.
            velocity: Weight of the velocity term.
            tip_height: Height of the tip of the inverted pendulum model
                rewards are computed from, in meters.
        """
        super().__init__(env)
        self.position_weight = position_weight
        self.velocity_weight = velocity_weight
        self.tip_height = tip_height

    def reward(self, observation: ObsType, info: dict) -> float:
        """Returns the new environment reward.

        Args:
            observation: Latest observation from the environment.
            info: Latest info dictionary from the environment.

        Returns:
            Reward.
        """
        pitch = observation[0]
        ground_position = observation[1]
        angular_velocity = observation[2]
        ground_velocity = observation[3]
        tip_height = self.tip_height

        tip_position = ground_position + tip_height * np.sin(pitch)
        tip_velocity = (
            ground_velocity + tip_height * angular_velocity * np.cos(pitch)
        )

        std_position = 0.05  # [m]
        position_reward = np.exp(-((tip_position / std_position) ** 2))
        velocity_penalty = -abs(tip_velocity)

        wip_reward = (
            self.position_weight * position_reward
            + self.velocity_weight * velocity_penalty
        )
        return wip_reward
