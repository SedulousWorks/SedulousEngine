using System;
using Sedulous.Core;

namespace Sedulous.Editor.Scene;

/// One of the orientation gizmo's six knobs: a world axis, where its knob sits on screen, and
/// how far it points away from the viewer (into the screen is positive).
struct ViewGizmoPole
{
	public Float3 Axis = .Zero;
	public bool Positive = true;
	public Float2 Screen = .(0, 0);
	public float Depth = 0.0f;

	public this() {}
}

/// The six knobs for one camera, around the gizmo's centre, ordered back to front: draw in
/// order, hit-test in reverse.
struct ViewGizmoLayout
{
	public Float2 Center = .(0, 0);
	public ViewGizmoPole[6] Poles = default;

	public this() {}
}

/// The scene view's orientation gizmo, top right: the axis tripod turning with the camera, a
/// click on a knob turning the camera about its pivot to look along that axis, and a click on
/// the centre switching the view between perspective and orthographic. The pure parts,
/// testable without a viewport; the page draws them and routes the click.
static class ViewGizmo
{
	/// Pixels from the centre to a knob.
	public const float cArm = 34.0f;
	/// A knob's side, in pixels.
	public const float cKnob = 18.0f;
	/// From the viewport's right edge.
	public const float cMargin = 12.0f;
	/// From the top edge, below the frame rate readout's line.
	public const float cTop = 28.0f;
	/// A top or bottom view looks straight down or up.
	public const float cStraightPitch = 1.5707963f;
	/// The centre's side, in pixels: the projection toggle.
	public const float cCentre = 10.0f;

	/// Where the knobs sit for a camera whose basis is `right`, `up`, `forward`, in a viewport
	/// `viewportWidth` pixels wide: each axis seen along the view, as the tripod shows it.
	public static ViewGizmoLayout LayoutFor(Float3 right, Float3 up, Float3 forward, float viewportWidth)
	{
		var layout = ViewGizmoLayout();
		layout.Center = .(viewportWidth - cMargin - cArm - 0.5f * cKnob, cTop + cArm + 0.5f * cKnob);
		Float3[6] axes = .(.(1, 0, 0), .(0, 1, 0), .(0, 0, 1), .(-1, 0, 0), .(0, -1, 0), .(0, 0, -1));
		for (int i < 6)
		{
			var pole = ViewGizmoPole();
			pole.Axis = axes[i];
			pole.Positive = i < 3;
			// Screen Y runs down.
			pole.Screen = .(layout.Center.X + Dot(axes[i], right) * cArm, layout.Center.Y - Dot(axes[i], up) * cArm);
			pole.Depth = Dot(axes[i], forward);
			layout.Poles[i] = pole;
		}
		// Back to front: the knob pointing furthest into the screen first.
		for (int i = 1; i < 6; i++)
		{
			for (int j = i; (j > 0) && (layout.Poles[j].Depth > layout.Poles[j - 1].Depth); j--)
				Swap!(layout.Poles[j], layout.Poles[j - 1]);
		}
		return layout;
	}

	/// The knob under pixel (x, y), the front-most where two overlap; -1 when none.
	public static int32 Hit(ViewGizmoLayout layout, float x, float y)
	{
		let half = 0.5f * cKnob;
		for (int32 i = 5; i >= 0; i--)
		{
			let c = layout.Poles[i].Screen;
			if ((x >= c.X - half) && (x <= c.X + half) && (y >= c.Y - half) && (y <= c.Y + half))
				return i;
		}
		return -1;
	}

	/// Whether pixel (x, y) is on the centre, and no knob covers it: a knob is hit first.
	public static bool HitCentre(ViewGizmoLayout layout, float x, float y)
	{
		let half = 0.5f * cCentre;
		return (Hit(layout, x, y) < 0) && (x >= layout.Center.X - half) && (x <= layout.Center.X + half)
			&& (y >= layout.Center.Y - half) && (y <= layout.Center.Y + half);
	}

	/// What the centre says the view is.
	public static StringView ProjectionLabel(bool orthographic) => orthographic ? "Ortho" : "Persp";

	/// The camera angles that look along `axis` from its side toward the centre: +X looks down
	/// -X (yaw 90 degrees), +Z down -Z (yaw 0). Y keeps `currentYaw` and looks straight down
	/// from +Y, up from -Y.
	public static void SnapAngles(Float3 axis, float currentYaw, out float yaw, out float pitch)
	{
		if ((axis.Y > 0.5f) || (axis.Y < -0.5f))
		{
			yaw = currentYaw;
			pitch = (axis.Y > 0.0f) ? -cStraightPitch : cStraightPitch;
			return;
		}
		// Forward is -axis: (-cos(p) sin(y), sin(p), -cos(p) cos(y)) at pitch nought.
		yaw = Math.Atan2(axis.X, axis.Z);
		pitch = 0.0f;
	}

	private static int AxisIndex(ViewGizmoPole pole) => (pole.Axis.X != 0.0f) ? 0 : ((pole.Axis.Y != 0.0f) ? 1 : 2);

	/// The knob's label: "X", "-Y" and so on.
	public static StringView Label(ViewGizmoPole pole)
	{
		StringView[3] positive = .("X", "Y", "Z");
		StringView[3] negative = .("-X", "-Y", "-Z");
		return pole.Positive ? positive[AxisIndex(pole)] : negative[AxisIndex(pole)];
	}

	/// The scene's origin axis colours (red X, green Y, blue Z), the negative knobs dimmer;
	/// `hovered` brightens a knob under the pointer.
	public static Color ColorOf(ViewGizmoPole pole, bool hovered)
	{
		Color[3] axes = .(.(0.9f, 0.2f, 0.2f, 1.0f), .(0.2f, 0.9f, 0.2f, 1.0f), .(0.2f, 0.4f, 0.95f, 1.0f));
		let c = axes[AxisIndex(pole)];
		let scale = (pole.Positive ? 1.0f : 0.45f) * (hovered ? 1.25f : 1.0f);
		return .(Math.Min(1.0f, c.R * scale), Math.Min(1.0f, c.G * scale), Math.Min(1.0f, c.B * scale), 1.0f);
	}
}
