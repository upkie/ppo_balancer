Configure the training path environment variable so that new policies are automatically saved in this directory. For instance, adapt the following path and save it to your `.bashrc`:

```bash
export UPKIE_TRAINING_PATH="${HOME}/src/ppo_balancer/ppo_balancer/training"
```

You can then use the Makefile in this directory to start TensorBoard automatically:

```console
make tensorboard
```
