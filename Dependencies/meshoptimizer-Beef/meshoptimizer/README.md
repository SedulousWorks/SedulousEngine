# meshoptimizer (vendored)

Source: https://github.com/zeux/meshoptimizer
Commit: b5b2c4391cb62d434d44e7f6ffb96194605fae2f (2026-08-21, v1.2 / MESHOPTIMIZER_VERSION 1020)
License: MIT (LICENSE.md)

Trimmed vendoring (the bc7enc precedent): only the core the mesh pipeline
uses - index/vertex optimization (vcache/overdraw/vfetch + generateVertexRemap),
simplification (meshopt_simplify family), and the cache/overdraw analyzers the
cook tests log (rasterizer.cpp backs analyzeOverdraw). No codecs, clusterizer,
meshlets, stripifier, demo, or tools. Cook/import-time only (Geometry.Pipeline);
never linked by the runtime.
