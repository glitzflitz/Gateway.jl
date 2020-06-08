# Gateway.jl
[![Build Status](https://travis-ci.org/glitzflitz/Gateway.jl.svg?branch=master)](https://travis-ci.org/glitzflitz/Gateway.jl)

Julia library for obtaining IP address of the default gateway

Provides implementation for:
+ Linux
+ Windows
+ OS X
+ FreeBSD
+ Solaris

## Documentation

For most use cases, all you ever need is:
```julia
getgateway() => Sockets.IPv4
```
## Project Status
The package is tested against Julia `v1.2` release on Linux and Windows. If you have OS X and BSD variant/Solaris environment please feel free to submit test results.

