# PPO balancer

<a href="https://youtube.com/shorts/bvWgYso1dzI">
    <img src="https://github.com/upkie/ppo_balancer/assets/1189580/3c4bac9b-02bf-429b-8b81-f931e4ce542f" align="right" height=200>
</a>

[![upkie](https://img.shields.io/badge/upkie-8.1.1-bbaacc)](https://github.com/upkie/upkie/tree/v8.1.1)

The PPO balancer is a feedforward neural network policy trained by reinforcement learning with a sim-to-real pipeline. It balances Upkie using wheels only. Training uses the `UpkieGroundVelocity` environment and the PPO implementation from [Stable Baselines3](https://stable-baselines3.readthedocs.io/en/master/modules/ppo.html).

An overview video of the training pipeline is given in this video: [Sim-to-real RL pipeline for Upkie wheeled bipeds](https://www.youtube.com/shorts/bvWgYso1dzI).

## Getting started

First, install [pixi](https://pixi.sh/latest/#installation).

To test the last trained agent, first start a simulation process:

```console
./start_simulation.sh
```

Then run the agent with:

```
pixi run agent
```

## Training

To train a new policy, let's check first that training progresses properly one rollout at a time:

```console
pixi run show_training
```

Once this works, we can train for real with more environments and no GUI:

```console
pixi run train <nb_envs>
```

Adjust the number `nb_envs` of parallel environments based on the `time/fps` series. The series is reported to the command line (or to TensorBoard if you configure `UPKIE_TRAINING_PATH` as detailed below). Increase or decrease the number of environments until you find the sweet spot that maximizes FPS on your machine.

### TensorBoard

The repository comes with a training directory that will store logs each time a new policy is learned. Set the `UPKIE_TRAINING_PATH` environment variable to enable this:

```sh
export UPKIE_TRAINING_PATH="${HOME}/src/ppo_balancer/training"
```

Trainings will be grouped automatically by day. You can start TensorBoard for today by:

```console
pixi run tensorboard
```

## Real-robot execution

The PPO balancer uses [pixi-pack](https://github.com/Quantco/pixi-pack/releases) to pack a standalone Python environment to run policies on your Upkie. First, create `environment.tar` on your machine and upload it by:

```console
make pack_pixi_env
make upload
```

Then, unpack the remote environment:

```console
$ ssh user@your-upkie
user@your-upkie:~$ cd ppo_balancer
user@your-upkie:ppo_balancer$ make unpack_pixi_env
```

## Usage

To run the deployed policy on your Upkie:

```console
make run_agent
```

Here we assumed the pi3hat spine is already up and running.

### Advanced usage

To run a policy saved to a custom path, use for instance:

```console
python ppo_balancer/run.py --policy ppo_balancer/training/2023-11-15/final.zip
```

## See also

- [Why aren't simulations deterministic when the policy is deterministic?](https://github.com/orgs/upkie/discussions/471)
- [Error: Shared object file not found](https://github.com/upkie/ppo_balancer/issues/8)
- [Packing pixi environments for the Raspberry Pi](https://github.com/orgs/upkie/discussions/467)
