# PPO balancer

<a href="https://youtube.com/shorts/bvWgYso1dzI">
    <img src="https://github.com/upkie/ppo_balancer/assets/1189580/3c4bac9b-02bf-429b-8b81-f931e4ce542f" align="right" height=200>
</a>

[![upkie](https://img.shields.io/badge/upkie-6.0.0-salmon)](https://github.com/upkie/upkie/tree/v6.0.0)

The PPO balancer is a feedforward neural network policy trained by reinforcement learning with a sim-to-real pipeline. Like the [MPC balancer](https://github.com/upkie/mpc_balancer) and [PID balancer](https://upkie.github.io/upkie/pid-balancer.html), it balances Upkie with straight legs. Training uses the <code><a href="https://upkie.github.io/upkie/classupkie_1_1envs_1_1upkie__ground__velocity_1_1UpkieGroundVelocity.html">UpkieGroundVelocity</a></code> gym environment and the PPO implementation from [Stable Baselines3](https://stable-baselines3.readthedocs.io/en/master/modules/ppo.html).

An overview video of the training pipeline is given in this video: [Sim-to-real RL pipeline for Upkie wheeled bipeds](https://www.youtube.com/shorts/bvWgYso1dzI).

## Installation

```console
conda env create -f environment.yaml
conda activate ppo_balancer
```

## Running a policy

### On your machine

To run the default policy:

```console
make test_policy
```

Here we assumed the spine is already up and running, for instance by running `./start_simulation.sh` on your machine, or by starting a pi3hat spine on the robot.

To run a policy saved to a custom path, use for instance:

```console
python ppo_balancer/run.py --policy ppo_balancer/training/2023-11-15/final.zip
```

## On a real robot

Upload the agent repository to the robot:

```console
make upload
```

Then, SSH into the robot and run the following target:

```console
$ ssh your-upkie
user@your-upkie:~$ python ppo_balancer/run.py
```

This will run the policy saved at the default path. To run a custom policy, save its ZIP file to the robot (save its operative config as well for your future reference) and pass it path as argument to `run.py`.

## Training a new policy

First, check that training progresses one rollout at a time:

```console
make train_and_show
```

Once this works you can train for real, with more environments and no GUI:

```console
make train
```

Check out the `time/fps` plots in the command line or in TensorBoard to adjust the number of parallel environments:

```console
make tensorboard
```

You should increase the number of environments from the default value (``NB_TRAINING_ENVS`` in the Makefile) to "as much as you can as long as FPS keeps going up".

## Export dependencies to your Upkie

PPO balancer uses `pixi-pack` to export a pixi environment to your Upkie. If you don't have it yet, you can install pixi from [here](https://pixi.sh/latest/#installation).

First, create an `environment.tar` file with the following command:

```bash
pixi run pack-to-upkie
```

Then, upload it to your Upkie and unpack it by:

```bash
pixi-pack unpack environment.tar
```

If `pixi-pack` is not installed on your Upkie, you can get a `pixi-pack-aarch64-unknown-linux-gnu` binary from the [pixi-pack release page](https://github.com/Quantco/pixi-pack/releases). Finally, activate the environment and run the agent:

```bash
source ./activate.sh
python ppo_balancer/run.py
```

## Troubleshooting

### Shared object file not found

**Symptom:** you are getting errors related to PyTorch not finding shared object files, with a call to ``_preload_cuda_deps()`` somewhere in the traceback:

```
  File ".../torch/__init__.py", line 178, in _load_global_deps
    _preload_cuda_deps()
  File ".../torch/__init__.py", line 158, in _preload_cuda_deps
    ctypes.CDLL(cublas_path)
  File "/usr/lib/python3.10/ctypes/__init__.py", line 374, in __init__
    self._handle = _dlopen(self._name, mode)
OSError: .../nvidia/cublas/lib/libcublas.so.11: cannot open shared object file: No such file or directory
```

**Workaround:** ``pip install torch`` in your local pip environment. This will override Bazel's and allow you to train and run normally.
