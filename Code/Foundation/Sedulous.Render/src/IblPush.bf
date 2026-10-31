using System;
using Sedulous.Core;

namespace Sedulous.Render;

/// The environment builds' constants, laid out exactly as the shaders read them. One struct
/// serves every stage of the chain, each reading the fields it needs.
[CRepr]
struct IblPush
{
	/// Which of the cube's six faces is being written.
	public int32 FaceIndex = 0;
	/// The sky mode, for the source stage.
	public int32 Mode = 0;
	/// The prefilter's roughness for this mip.
	public float Roughness = 0.0f;
	public float SkyIntensity = 1.0f;
	public Float3 SunDirection = .(0, -1, 0);
	/// In degrees.
	public float SunAngularSize = 0.5f;
	public Float3 Horizon = .(0, 0, 0);
	public float SunIntensity = 1.0f;
	public Float3 Zenith = .(0, 0, 0);
	/// In radians, a yaw about +Y.
	public float SkyRotation = 0.0f;
	public Float3 Ground = .(0, 0, 0);
	/// The analytic sky's haze.
	public float Turbidity = 3.0f;

	public this() {}
}
