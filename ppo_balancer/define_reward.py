#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#
# SPDX-License-Identifier: Apache-2.0
# Copyright 2024 Inria

from typing import Any, Dict, SupportsFloat, Tuple

import gin
import gymnasium as gym
import numpy as np
from gymnasium.core import ActType, ObsType


@gin.configurable
class DefineReward(gym.Wrapper[ObsType, ActType, ObsType, ActType]):
    """Define the agent's reward function."""

    last_observation: ObsType
    position_weight: float
    smoothness_weight: float
    velocity_weight: float

    def __init__(
        self,
        env: gym.Env[ObsType, ActType],
        position_weight: float,
        velocity_weight: float,
        smoothness_weight: float,
        tip_height: float,
    ):
        """Initialize with reward weights.

        Args:
            env: Environment whose reward to redefine.
            position_weight: Weight of the position reward.
            velocity_weight: Weight of the velocity reward.
            smoothness_weight: Weight of the action-smoothness reward.
            tip_height: Height of the tip of the inverted pendulum model
                rewards are computed from, in meters.
        """
        super().__init__(env)
        self.last_action = None
        self.last_action_change_penalty = 0.0
        self.last_observation = None
        self.last_position_reward = 0.0
        self.last_velocity_penalty = 0.0
        self.position_weight = position_weight
        self.smoothness_weight = smoothness_weight
        self.tip_height = tip_height
        self.velocity_weight = velocity_weight

    def reset(self, **kwargs) -> Tuple[ObsType, Dict[str, Any]]:
        r"""!
        Reset the environment.

        \param kwargs Keyword arguments forwarded to the wrapped environment.
        """
        observation, info = self.env.reset(**kwargs)
        self.last_observation = observation
        return observation, info

    def step(
        self, action: ActType
    ) -> Tuple[ObsType, SupportsFloat, bool, bool, Dict[str, Any]]:
        r"""!
        Modifies the :attr:`env` reward using :meth:`self.reward`.
        """
        observation, _, terminated, truncated, info = self.env.step(action)
        reward = self.reward(self.last_observation, action, observation)
        self.last_observation = observation
        return (
            observation,
            reward,
            terminated,
            truncated,
            info,
        )

    def reward(
        self, obs: ObsType, action: ActType, new_obs: ObsType
    ) -> SupportsFloat:
        r"""!
        Returns the new environment reward.

        \param[in] obs Observation from which the action was computed.
        \param[in] action Action that was taken.
        \param[in] new_obs New observation after the action was taken.
        \return The modified reward.
        """
        pitch = new_obs[0]
        ground_position = new_obs[1]
        angular_velocity = new_obs[2]
        ground_velocity = new_obs[3]
        tip_height = self.tip_height

        tip_position = ground_position + tip_height * np.sin(pitch)
        tip_velocity = (
            ground_velocity + tip_height * angular_velocity * np.cos(pitch)
        )

        std_position = 0.05  # [m]
        position_reward = np.exp(-((tip_position / std_position) ** 2))
        velocity_penalty = -abs(tip_velocity)

        action_change_penalty = 0.0
        if self.last_action is None:
            self.last_action = action
        else:  # self.last_action is not None
            action_change = action - self.last_action
            action_change_penalty = -action_change.dot(action_change)
            self.last_action = 0.4 * action + 0.6 * self.last_action

        reward = (
            self.position_weight * position_reward
            + self.velocity_weight * velocity_penalty
            + self.smoothness_weight * action_change_penalty
        )

        self.last_position_reward = position_reward
        self.last_velocity_penalty = velocity_penalty
        self.last_action_change_penalty = action_change_penalty
        self.last_reward = reward
        return reward
