using System;
using Sedulous.Core;

namespace Sedulous.Render;

/// What the tonemap pass pushes, mirroring tonemap.ps.hlsl's TonemapPush: exposure, bloom, the
/// coordinate transform, occlusion, the two mode flags, the auto exposure window, the grading,
/// whether the target stores the display encoding as written, and the screen's turn. The pads are
/// scalars, as a float3 there breaks WGSL's uniform alignment.
[CRepr]
struct TonemapPush
{
	public float Exposure = 1.0f;
	public float BloomIntensity = 0.0f;
	public Float2 UvScale = .(1, 1);
	public Float2 UvOffset = .(0, 0);
	public float AoStrength = 0.0f;
	/// 1 shows the occlusion alone.
	public float DebugShowAo = 0.0f;
	/// 0 the clamp, 1 AgX, 2 a plain copy.
	public float Operator = 0.0f;
	public float FlipSceneY = 0.0f;
	public float AutoExposure = 0.0f;
	public float AutoKey = 0.0f;
	public float AutoMin = 0.0f;
	public float AutoMax = 0.0f;
	public float GradeIntensity = 0.0f;
	public float LutSize = 0.0f;
	/// 1 when the target stores what is written as it is (a plain UNORM one).
	public float EncodeOutput = 0.0f;
	/// The screen's quarter turns.
	public float Rotation = 0.0f;
	public float Pad0 = 0.0f;
	public float Pad1 = 0.0f;

	public this() {}
}
