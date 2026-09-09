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
	/// The direction in the first three, and the sun's angular size in degrees in the fourth.
	public Float4 Sun = .(0, -1, 0, 0.5f);
	/// The colour in the first three, and the sun's intensity in the fourth.
	public Float4 Horizon = .(0, 0, 0, 1);
	/// The colour in the first three, and the rotation in radians in the fourth.
	public Float4 Zenith = .(0, 0, 0, 0);
	/// The colour in the first three, and the turbidity in the fourth.
	public Float4 Ground = .(0, 0, 0, 3);

	public this() {}
}
