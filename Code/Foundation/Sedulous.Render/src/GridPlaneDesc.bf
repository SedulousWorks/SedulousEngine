using System;
using Sedulous.Core;

namespace Sedulous.Render;

/// A grid drawn on a plane by a shader (the editor's ground grid): a square `Extent` metres
/// across each way from `Origin`, on the plane spanned by the unit axes `AxisU` and `AxisV`.
///
/// Lines fall at whole multiples of `Spacing` along each axis in WORLD coordinates, so the
/// square can follow the camera without the lines swimming, every tenth one heavier; `Blend`
/// (nought to one) fades the finest lines out and the next decade's in as the camera climbs.
/// It fades out toward `FadeDistance` from `CameraPosition`, and is depth tested against the
/// scene. The two lines through the world origin take their axis's colour.
struct GridPlaneDesc
{
	public Float3 Origin = .Zero;
	public float Extent = 100.0f;
	public Float3 AxisU = .(1.0f, 0.0f, 0.0f);
	public float Spacing = 1.0f;
	public Float3 AxisV = .(0.0f, 0.0f, 1.0f);
	public float Blend = 0.0f;
	public Float3 CameraPosition = .Zero;
	public float FadeDistance = 100.0f;

	public this() {}
}
