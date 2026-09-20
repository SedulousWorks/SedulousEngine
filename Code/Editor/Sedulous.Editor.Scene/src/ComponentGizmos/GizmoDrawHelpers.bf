using Sedulous.Core;
using Sedulous.Render;

namespace Sedulous.Editor.Scene;

static class GizmoDrawHelpers
{
	public static Float3 WorldPosition(Float4x4 world) => .(world.M[3][0], world.M[3][1], world.M[3][2]);

	/// The -Z basis row, normalised.
	public static Float3 WorldForward(Float4x4 world)
		=> Normalized(Float3(-world.M[2][0], -world.M[2][1], -world.M[2][2]));

	public static void DrawCenterCross(DebugDraw dd, Float3 p, float r, Color color)
	{
		dd.DrawLine(p - Float3(r, 0, 0), p + Float3(r, 0, 0), color);
		dd.DrawLine(p - Float3(0, r, 0), p + Float3(0, r, 0), color);
		dd.DrawLine(p - Float3(0, 0, r), p + Float3(0, 0, r), color);
	}
}
