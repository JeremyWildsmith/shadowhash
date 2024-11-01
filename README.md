# ShadowHash

## Introduction

ShadowHash is an Elixir application which implements distributed hash cracking against a linux [shadow file](https://man7.org/linux/man-pages/man5/shadow.5.html), as well as GPU Accelerated password cracking for select algorithms.

The project is largely an exercise in distributed programming in Elixir and programming using CUDA and NX, and less about creating a robust or competative password cracker.

## Usage

ShadowHash can operate on a single node, or work distributively on multiple nodes / machines.

### Installation and Configuration

1. Ensure you have Erlang OTP installed and Elixir installed (version Elixir 1.17.3 on Erlang 27) Follow the official installation instrucitons [here](https://elixir-lang.org/install.html)
2. Install and configure your environment for CUDA if you plan to use GPU Accelerated password hashers included in ShadowHash. 
    - These steps vary depending on your hardware configuration. For Nvidia you can follow the guide here: https://docs.nvidia.com/cuda/cuda-installation-guide-linux/
3. Clone this repository onto your local machine
4. Run the following commands to acquire the project dependencies with CUDA enabled:
   ```
   > export XLA_TARGET=cuda12
   > mix deps.get
   > mix deps.compile
   ```
   (depending on your environment, you may need to manually build XLA for GPU accelerated hashing.)

5. Run the test-cases to ensure all is working as expected
   ```
   > mix test --trace
   ```

6. For GPU-based hashing generation, ShadowHash relies on it's own Nx based hashing algorithm. For CPU-based hashing, ShadowHash relies on mkpasswd. It can be installed via your package managers:
    ```
    > sudo apt install mkpasswd
    > mkpasswod --version
    mkpasswd 5.5.22
    ``` 

7. Optional, for generating benchmark plots (generated by using benchmark.sh script), you will need to have gnuplot installed, which can also be acquire via your package manager.
    ```
    > sudo apt-get install gnuplot
    > gnuplot --version
      gnuplot 6.0 patchlevel 0

### Single Node

Using ShadowHash on a single node is straight-forward. Use the `--help` switch on the `shadow_hash` task to learn about the available options and usage instructions.

**ShadowHash is implemented as a MIX task.**

```
> mix shadow_hash --help

Shadow file parser and password cracker.
Usage is: shadow_hash <shadow_path> [--user <username>]
 <shadow_path> : The path to the linux shadow file containing hashed user passwords.
 --user <user>  : Supply a username, the passwords for which will be cracked.
                  Otherwise, attempts to crack all passwords in the shadow file.
 --all-chars    : Will also bruteforce with non-printable characters
 --dictionary <dictionary>  : Supply a dictionary of passwords that are attempted initially
 --gpu           : Supported for md5crypt, will execute the hash algorithm
                   on the GPU. There is initial overhead to JIT compile to CUDA
                   but after JIT compiling, significantly faster.
 --gpu-warmup    : Warm-up GPU bruteforce algorithm. Useful when capturing
                   timing metrics and you don't want to include start-up overhead
 --workers <num> : Number of workers to process bruteforce requests. Defaults
                   to number of available CPU cores. Be mindful of the memory constraint 
                   of GPU if using GPU acceleration
 --verbose       : Print verbose logging
```

### Multi-Node
In a multi-node configuration, `shadow_hash` will distribute the password cracking work horizontally accross multiple machines and optionally multiple GPUs. Currently this feature is pending implementation.

## Benchmarking

For generating benchmark metrics, please refer to the `benchmark.sh` shell script.

Below is a sample benchmark file produced by `benchmark.sh` which benchmarks the hashing performance accross all supported algorithms for different thread counts.
![benchmark stats for 2 character password](/docs/output.png)