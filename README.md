# PPO balancer

<a href="https://youtube.com/shorts/bvWgYso1dzI">
    <img src="https://github.com/upkie/ppo_balancer/assets/1189580/3c4bac9b-02bf-429b-8b81-f931e4ce542f" align="right" height=200>
</a>

[![upkie](https://img.shields.io/badge/upkie-8.0.0-bbaacc)](https://github.com/upkie/upkie/tree/v8.0.0)

The PPO balancer is a feedforward neural network policy trained by reinforcement learning with a sim-to-real pipeline. Like the [MPC balancer](https://github.com/upkie/mpc_balancer) and [PID balancer](https://upkie.github.io/upkie/pid-balancer.html), it balances Upkie with straight legs. Training uses the <code><a href="https://upkie.github.io/upkie/classupkie_1_1envs_1_1upkie__ground__velocity_1_1UpkieGroundVelocity.html">UpkieGroundVelocity</a></code> gym environment and the PPO implementation from [Stable Baselines3](https://stable-baselines3.readthedocs.io/en/master/modules/ppo.html).

An overview video of the training pipeline is given in this video: [Sim-to-real RL pipeline for Upkie wheeled bipeds](https://www.youtube.com/shorts/bvWgYso1dzI).

## Installation

### On your machine

```console
conda env create -f environment.yaml
conda activate ppo_balancer
```

### On your Upkie

The PPO balancer uses [pixi](https://pixi.sh/latest/#installation) and [pixi-pack](https://github.com/Quantco/pixi-pack/releases) to pack a standalone Python environment to run policies on your Upkie. First, create `environment.tar` and upload it by:

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

To run the default policy:

```console
make run_agent
```

Here we assumed the spine is already up and running, for instance by running `./start_simulation.sh` on your machine, or by starting a pi3hat spine on the robot.

### Training a new policy

First, check that training progresses one rollout at a time:

```console
make train_and_show
```

Once this works, train for real with more environments and no GUI:

```console
make train
```

Adjust the number of parallel environments based on the `time/fps` series. The series is reported to the command line, as well as to TensorBoard which you can start by:

```console
make tensorboard
```

Increase the number of environments from the default value (``NB_TRAINING_ENVS`` in the Makefile) to "as much as you can as long as FPS keeps going up".

### Advanced usage

To run a policy saved to a custom path, use for instance:

```console
python ppo_balancer/run.py --policy ppo_balancer/training/2023-11-15/final.zip
```

## See also

- [Why aren't simulations deterministic when the policy is deterministic?](https://github.com/orgs/upkie/discussions/471)
- [Error: Shared object file not found](https://github.com/upkie/ppo_balancer/issues/8)
- [Packing pixi environments for the Raspberry Pi](https://github.com/orgs/upkie/discussions/467)
