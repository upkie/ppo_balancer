This template repository makes it easier to create new agents for [Upkie](https://github.com/upkie/upkie) wheeled bipeds.

## Getting started

4. Implement your agent in the ``agent`` directory.
5. Optional: adapt the spines in the ``spines`` directory, for instance with custom observers.

## Usage

The `Makefile` can be to build and upload your agent to the real robot. Run ``make help`` for a list of available rules.

You can also run your agent locally with Bazelisk:

```bash
$ ./tools/bazelisk run //agent
```
