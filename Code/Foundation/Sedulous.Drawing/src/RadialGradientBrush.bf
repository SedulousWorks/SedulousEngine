using System;
using Sedulous.Core.Mathematics;

namespace Sedulous.Drawing;

/// A brush that fills with a radial gradient from center to edge
public class RadialGradientBrush : IBrush
{
	private Vector2 mCenter;
	private float mRadius;
	private Color mCenterColor;
	private Color mEdgeColor;

	public Color BaseColor => mCenterColor;
	public bool RequiresInterpolation => true;
	public Object Texture => null;

	public this(Vector2 center, float radius, Color centerColor, Color edgeColor)
	{
		mCenter = center;
		mRadius = radius;
		mCenterColor = centerColor;
		mEdgeColor = edgeColor;
	}

	public Color GetColorAt(Vector2 position, RectangleF bounds)
	{
		if (mRadius < 0.0001f)
			return mCenterColor;

		let distance = Vector2.Distance(position, mCenter);
		var t = distance / mRadius;
		t = Math.Clamp(t, 0.0f, 1.0f);

		return LerpColor(mCenterColor, mEdgeColor, t);
	}

	/// Set the center point
	public void SetCenter(Vector2 center)
	{
		mCenter = center;
	}

	/// Set the radius
	public void SetRadius(float radius)
	{
		mRadius = radius;
	}

	/// Set gradient colors
	public void SetColors(Color centerColor, Color edgeColor)
	{
		mCenterColor = centerColor;
		mEdgeColor = edgeColor;
	}

	/// Get the center point
	public Vector2 Center => mCenter;

	/// Get the radius
	public float Radius => mRadius;

	/// Get the center color
	public Color CenterColor => mCenterColor;

	/// Get the edge color
	public Color EdgeColor => mEdgeColor;

	private static Color LerpColor(Color a, Color b, float t)
	{
		// Cast to float to handle negative differences properly
		let r = (float)a.R + ((float)b.R - (float)a.R) * t;
		let g = (float)a.G + ((float)b.G - (float)a.G) * t;
		let bl = (float)a.B + ((float)b.B - (float)a.B) * t;
		let al = (float)a.A + ((float)b.A - (float)a.A) * t;

		return Color(
			(uint8)Math.Clamp(r, 0, 255),
			(uint8)Math.Clamp(g, 0, 255),
			(uint8)Math.Clamp(bl, 0, 255),
			(uint8)Math.Clamp(al, 0, 255)
		);
	}
}
