# PPO balancer

The PPO balancer is a feedforward neural network policy trained by reinforcement learning with a sim-to-real pipeline. Like the [MPC balancer](https://github.com/upkie/mpc_balancer) and [PID balancer](https://upkie.github.io/upkie/pid-balancer.html), it balances Upkie with straight legs. Training uses the <code><a href="https://upkie.github.io/upkie/classupkie_1_1envs_1_1upkie__ground__velocity_1_1UpkieGroundVelocity.html">UpkieGroundVelocity</a></code> gym environment and the PPO implementation from [Stable Baselines3](https://stable-baselines3.readthedocs.io/en/master/modules/ppo.html).

An overview video of the training pipeline is given in this video: [Sim-to-real RL pipeline for Upkie wheeled bipeds](https://www.youtube.com/shorts/bvWgYso1dzI).

## Installation

### From Conda

```console
conda create -f environment.yaml
conda activate ppo_balancer
```

### From PyPI

```console
pip install upkie[ppo_balancer]
```

This instruction works on both your dev machine and the robot's Raspberry Pi.

## Running a policy

To run the default policy:

```console
python ppo_balancer/run.py
```

Here we assumed the spine is already up and running, for instance by running ``./start_simulation.sh`` on your dev machine, or by starting a pi3hat spine on the robot.

To run a policy saved to a custom path, use for instance:

```console
python ppo_balancer/run.py --policy ppo_balancer/training/2023-11-15/final.zip
```

## Real robot

On the real robot you can use the Makefile at the root of the repository as follows. This will run the policy saved at the default path:

```console
$ make build
$ make upload
$ ssh your-upkie
user@your-upkie:~$ make run_ppo_balancer
```

To run a custom policy, save its ZIP file to ``ppo_balancer/policy/params.zip`` (save its operative config as well) and follow the same steps.

## Training a new policy

First, check that training progresses one rollout at a time:

```
./tools/bazelisk run //ppo_balancer:train -- --show --nb-envs 2
```

Once this works you can remove the ``--show`` GUI toggle. Check out the `time/fps` plots in the command line or in TensorBoard to adjust the number of parallel environments from 2 (above) to "as much as you can as long as FPS keeps going up".

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
