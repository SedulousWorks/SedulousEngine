using System;

namespace Sedulous.Render;

/// The built in depth like programs' cut-out (shadow_depth.ps, and pick_ids.ps under ALPHA_TEST):
/// the threshold the albedo's alpha is tested against, the material's AlphaCutoff over its base
/// colour's alpha, so a caster cuts out where its forward draw does. A push block in the space
/// after the pass's three sets (space3), padded to a row for the browser's uniform emulation.
[CRepr]
struct GpuCutoutPush
{
	public float AlphaThreshold = 0.5f;
	public float Pad0 = 0.0f;
	public float Pad1 = 0.0f;
	public float Pad2 = 0.0f;

	public this() {}
}
