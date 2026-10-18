# GPUI (adapted, not vendored)

The engine carries no GPUI code as a library. Parts of GPUI's quad shader (Zed,
`crates/gpui_wgpu/src/shaders.wgsl`, https://github.com/zed-industries/zed) were adapted into:

- `Data/Shaders/vg_box.ps.hlsl`: the analytic box's coverage and border (`fs_quad`,
  `quad_sdf_impl`, `quarter_ellipse_sdf`, `pick_corner_radius`), ported to HLSL and changed as its
  header says.

GPUI is Copyright 2022 - 2025 Zed Industries, Inc., licensed under the Apache License, Version 2.0
(`LICENSE-APACHE` beside this file, as Zed ships it).
