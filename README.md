# Try to be smaller.
We are finally there!

# Build it.
## Prequisites
Download and install the following software and add it to your system PATH:
* Git <https://git-scm.com/>
* CMake <https://cmake.org/>
* Ninja Build <https://ninja-build.org/>

## Build
* Navigate to the source root.
* Initialize the git submodules: `git submodule update --init --recursive`
* Create an out of source build directory: `mkdir build`
* Navigate to the build directory
* Run CMake: `cmake [SOURCE_ROOT] -G"Ninja" -DCMAKE_TOOLCHAIN_FILE="[SOURCE_ROOT]/toolchain.cmake"`
* Run Ninja: `ninja`
* Profit
* If you need the executable faster, run `ninja debug` instead.

# License
This project is licensed under GPLv3 and copyright (c) 2023 Alexander Kraus <nr4@z10.info>. See LICENSE for details.
