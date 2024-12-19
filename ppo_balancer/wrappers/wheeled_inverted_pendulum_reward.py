#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#
# SPDX-License-Identifier: Apache-2.0
# Copyright 2024 Inria

import gymnasium as gym
import numpy as np
from gymnasium.core import ActType, ObsType

from upkie.envs.wrappers import ObservationBasedReward


class WheeledInvertedPendulumReward(ObservationBasedReward):
    """Redefine the environment reward with a function suited to the WIP model.

    Attributes:
        position_weight: Weight of the position term.
        velocity_weight: Weight of the velocity term.
        tip_height: Height of the "tip" reference point, in meters.
        std_position: Standard deviation (in meters) of tip position
            displacements used in the position reward term.
    """

    position_weight: float
    std_position: float
    tip_height: float
    velocity_weight: float

    def __init__(
        self,
        env: gym.Env[ObsType, ActType],
        position_weight: float = 1.0,
        std_position: float = 0.05,
        tip_height: float = 0.58,
        velocity_weight: float = 1.0,
    ):
        """Initialize with reward weights.

        Args:
            env: The environment to wrap.
            position_weight: Weight of the position term.
            velocity_weight: Weight of the velocity term.
            tip_height: Height of the "tip" reference point, in meters.
            std_position: Standard deviation (in meters) of tip position
                displacements used in the position reward term.
        """
        super().__init__(env)
        self.tip_height = tip_height
        self.position_weight = position_weight
        self.velocity_weight = velocity_weight

    def reward(self, observation: np.ndarray) -> float:
        """Get reward for a given state.

        Args:
            observation: Observation from the ground-velocity environment.

        Returns:
            Reward.
        """
        pitch: float = observation[0]
        ground_position: float = observation[1]
        angular_velocity: float = observation[2]
        ground_velocity: float = observation[3]
        tip_position = ground_position + self.tip_height * np.sin(pitch)
        tip_velocity = (
            ground_velocity
            + self.tip_height * angular_velocity * np.cos(pitch)
        )
        position_reward = np.exp(-((tip_position / self.std_position) ** 2))
        velocity_penalty = -abs(tip_velocity)
        return (
            self.position_weight * position_reward
            + self.velocity_weight * velocity_penalty
        )
