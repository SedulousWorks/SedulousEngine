using System;
using Sedulous.Core;

namespace Sedulous.Editor.Scene;

/// The plane the scene grid lies on, through the world origin.
enum GridPlane : uint8
{
	/// The ground, the default.
	case XZ;
	/// Facing Z.
	case XY;
	/// Facing X.
	case YZ;
}

/// A plane's two in plane axes and its normal: unit, right handed (U cross V is the normal).
struct GridPlaneAxes
{
	public Float3 U = .Zero;
	public Float3 V = .Zero;
	public Float3 Normal = .Zero;

	public this() {}

	public this(Float3 u, Float3 v, Float3 normal)
	{
		U = u;
		V = v;
		Normal = normal;
	}
}

/// The finest line spacing for a camera's distance from the plane, a power of ten (10 m up
/// shows 1 m cells, 100 m up 10 m cells), and how far (nought to one) the camera is toward the
/// next decade, across which the finest lines fade out and the next decade's in.
struct GridSpacing
{
	public float Spacing = 1.0f;
	public float Blend = 0.0f;

	public this() {}
}

/// The scene grid's pure parts: its plane's axes, its spacing for the camera, and how far it
/// reaches. The page draws it (the shader grid, or debug lines to compare).
static class SceneGrid
{
	/// The finest cell is a tenth of the distance.
	private const float cCellsPerDistance = 0.1f;
	/// A centimetre: no finer, however close.
	private const float cFinest = 0.01f;

	public static GridPlaneAxes AxesOf(GridPlane plane)
	{
		switch (plane)
		{
		case .XY: return .(.(1, 0, 0), .(0, 1, 0), .(0, 0, 1));
		case .YZ: return .(.(0, 1, 0), .(0, 0, 1), .(1, 0, 0));
		default: return .(.(0, 0, 1), .(1, 0, 0), .(0, 1, 0));
		}
	}

	public static GridSpacing SpacingFor(float distance)
	{
		let target = Math.Max(cFinest, Math.Max(distance, 0.0f) * cCellsPerDistance);
		let decades = Math.Log10(target);
		let whole = Math.Floor(decades);
		var spacing = GridSpacing();
		spacing.Spacing = Math.Pow(10.0f, whole);
		spacing.Blend = Math.Clamp(decades - whole, 0.0f, 1.0f);
		return spacing;
	}

	/// How far from the camera the grid reaches before it has faded out: broad near the plane
	/// (a level seen from a person's height), growing as the camera climbs, inside the editor
	/// camera's far plane.
	public static float FadeDistance(float distance) =>
		Math.Clamp(60.0f + 25.0f * Math.Max(distance, 0.0f), 60.0f, 900.0f);
}
