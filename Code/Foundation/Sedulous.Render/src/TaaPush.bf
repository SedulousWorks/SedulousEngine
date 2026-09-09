using System;
using Sedulous.Core;

namespace Sedulous.Render;

/// What the temporal resolve pushes to its shader.
[CRepr]
struct TaaPush
{
	public Float2 TexelSize = .(0, 0);
	/// How much of the history survives each frame. Near one accumulates many samples and so
	/// resolves the most detail; lower reacts faster to change.
	public float BlendFactor = 0.97f;
	/// Nought on the first frame, or after a resize, when there is nothing to blend with.
	public float HistoryValid = 0.0f;
	/// How wide the neighbourhood clamp is, in standard deviations: what stops a reprojected
	/// sample from a different surface bleeding in as a ghost.
	public float VarianceGamma = 1.25f;
	public float MotionScale = 32.0f;
	public float NearPlane = 0.1f;
	public float FarPlane = 1000.0f;

	public this() {}
}
