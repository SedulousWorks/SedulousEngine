# meshoptimizer-Beef

Beef bindings for [meshoptimizer](https://github.com/zeux/meshoptimizer).

- **Version:** MESHOPTIMIZER_VERSION 1020 (v1.2)
- **License:** MIT (`meshoptimizer/LICENSE.md`)

meshoptimizer already exposes a C API, so `src/MeshOptimizer.bf` binds it directly with no
wrapper in between.

## Trimmed vendoring

`meshoptimizer/` carries a subset: index and vertex optimisation,
simplification, and the analyzers. No codecs, clusterizer, meshlets or stripifier.

The binding declares **only what those translation units define**. The upstream header
declares a good deal more; binding any of it would compile and then fail at link time on
the first call, which is a much worse place to find out. The set was taken with `nm` over
the built archive rather than read off the header — re-derive it the same way if the
vendored set ever changes:

```
nm --defined-only -g dist/Release-Linux64/libmeshoptimizer.a | awk '$2=="T"{print $3}' \
  | grep '^meshopt_' | grep -vE '[0-9]' | sort -u
```

## Building the native library

```
./build-native.sh make RELEASE      # configure
./build-native.sh build RELEASE     # build + copy into dist/Release-Linux64
```

Windows: `build-native.ps1 make` then `build-native.ps1 build ALL`, which fills
`dist/Debug-Win64` and `dist/Release-Win64`.

## Test

`meshoptimizer-Beef-Test` welds a mesh with duplicated vertices, optimises it, simplifies
it, and prints what the analyzers report. Open `BeefSpace.toml` and run it.
