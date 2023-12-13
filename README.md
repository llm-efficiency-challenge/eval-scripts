# Eval Scripts

## TL;DR

These are the _very basic_ scripts are for running submissions of the competition. Scripts herein are very dumb, intentionally so. PRs welcome for better scripts!

## Setup

The following tools need to be setup on an evaluation machine.

* `docker` and `nvidia-docker` for running the helm suite and the submissions
* `git` for cloning repos
* `curl` for running the healthchecks to ensure containers are running

With these installed run the `setup.sh` script with the number of GPUs in the evaluation machine.

```sh
./setup.sh $NUM_GPUS
```

... for example to use 8 gpus in an eval machine

```sh
./setup.sh 8
```

### What this does
This script will ensure a few tools are present and functional, as well as setting up a degree of isolation on the machine.
This takes the form of docker networks and port exposures for each individual GPU.

We also checkout the helm evaluation version used in the competition, into the `./private-helm` folder.

## Running a submission
Make sure the submissions are in `./submissions` folder relative to this script.

To run a single submission do:

```sh
./eval-repo.sh         \
    '$gpu_device'      \
    '$isolation'       \
    '$hardware_track'  \
    '$helm_config'     \
    '$submission'
```

What this does:

* `'$gpu_device'` Specifies the GPU string to pass to docker for the GPU(s) to run the submission on
* `'$isolation'` An isolation factor used to divide submissions between multiple GPUs on a single server. We recommend to keep this number the same as the `$gpu_device` string.
* `'$helm_config'` The config used for helm, must be in a path visibile to the helm container. Private-helm contains configs within the container for the 111 competition.
* `'$hardware_track'` The hardware track to build for in the submissions folder. Essentially a top level folder in `./submissions` that differentiates between different hardware tracks/
* `'$submission'` The submission folder to build

The `$submission` is the folder that contains the submission to evaluate. A bare `Dockerfile` is expected at this location to build the submissions container.

### Layout of the submissions folder
Submissions are laid out in `./submissions` folder in the following fashion:

```
./submissions
├── 4090
│   └── $user
│       └── $repo
│           ├── README.md
│           ├── submission_1
│           │   ├── Dockerfile
│           │   └── ...
│           └── submission_2
│               ├── Dockerfile
│               └── ...
└── A100
    └── $user
        └── $repo
            ├── README.md
            ├── submission_1
            │   ├── Dockerfile
            │   └── ...
            └── submission_2
                ├── Dockerfile
                └── ...
```

### Putting this together for a simple run

Using the above layout to run a submission for A100 `$user` `$repo/submission_2` on the second GPU you would do the following:

```sh
./eval-repo.sh                           \
    'device=1'                           \
    '1'                                  \
    'A100'                               \
    '/helm/config/some_helm_config.conf' \
    '$user/$repo/submission_2'
```

## Changing locations
Should you want to change the locations of the `./private-helm`, `./submissions` or `./results` folders you will need to edit `utils.sh`

* For `./submissions` change `$BASE_SUB_DIR` in [`utils.sh`](utils.sh)
* For `./results` change `$OUT_DIR` in [`utils.sh`](utils.sh)
* For `./private-helm` change [`build-eval-container.sh`](build-eval-container.sh)