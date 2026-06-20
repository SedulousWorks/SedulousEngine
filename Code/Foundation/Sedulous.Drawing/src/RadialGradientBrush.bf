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

		return Color.Lerp(mCenterColor, mEdgeColor, t);
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
}
