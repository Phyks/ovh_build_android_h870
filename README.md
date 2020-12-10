Building Android (Lineage 17.1 or `/e/`) for LG G6 (h870)
========================================================

Building Android requires lots of RAM (at least 16GB) and a good CPU required.
Here are a set of helper scripts to build ROMs for the LG G6, leveraging the
OVH Public Cloud infrastructure.

Typical build time (from scratch) for a ROM is about 3 hours, which is about
1€ with the current hourly prices (2020).

## Details

This repository is made of three components:
* The main `build_android.sh` bash script which handles the actual build of
    the ROM (for the h870 device).
* A small Python module (`ovh_orchestrator`) responsible for spawning and
    purging instances in OVH Public Cloud.
* The main entrypoint `run.sh` which spawns an instance, runs the build on it
    copy back the built files and clean everything afterwards.

## Installation

```
cp ovh_orchestrator/config.example.py ovh_orchestrator/config.py
$EDITOR ovh_orchestrator/config.py  # Edit according to your own credentials / needs
```

## Usage

```
./run.sh
```


## License

Code is published under an MIT license.

```
Copyright 2020 Phyks

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
```

## Thanks

Many thanks to BernardoBas for his initial [unofficial
build](https://forum.xda-developers.com/t/rom-a10-h870-h870ds-h872-us997-lineageos-17-1-for-lg-g6-unofficial.4137809/)
and his help reproducing.
