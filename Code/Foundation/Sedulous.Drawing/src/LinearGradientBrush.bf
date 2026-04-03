using System;
using Sedulous.Core.Mathematics;

namespace Sedulous.Drawing;

/// A brush that fills with a linear gradient between two points
public class LinearGradientBrush : IBrush
{
	private Vector2 mStartPoint;
	private Vector2 mEndPoint;
	private Color mStartColor;
	private Color mEndColor;

	public Color BaseColor => mStartColor;
	public bool RequiresInterpolation => true;
	public Object Texture => null;

	public this(Vector2 startPoint, Vector2 endPoint, Color startColor, Color endColor)
	{
		mStartPoint = startPoint;
		mEndPoint = endPoint;
		mStartColor = startColor;
		mEndColor = endColor;
	}

	public Color GetColorAt(Vector2 position, RectangleF bounds)
	{
		// Project position onto the gradient line
		let gradientDir = mEndPoint - mStartPoint;
		let gradientLenSq = gradientDir.X * gradientDir.X + gradientDir.Y * gradientDir.Y;

		if (gradientLenSq < 0.0001f)
			return mStartColor;

		let toPos = position - mStartPoint;
		var t = (toPos.X * gradientDir.X + toPos.Y * gradientDir.Y) / gradientLenSq;
		t = Math.Clamp(t, 0.0f, 1.0f);

		return LerpColor(mStartColor, mEndColor, t);
	}

	/// Set gradient start point
	public void SetStartPoint(Vector2 point)
	{
		mStartPoint = point;
	}

	/// Set gradient end point
	public void SetEndPoint(Vector2 point)
	{
		mEndPoint = point;
	}

	/// Set gradient colors
	public void SetColors(Color startColor, Color endColor)
	{
		mStartColor = startColor;
		mEndColor = endColor;
	}

	/// Get the start point
	public Vector2 StartPoint => mStartPoint;

	/// Get the end point
	public Vector2 EndPoint => mEndPoint;

	/// Get the start color
	public Color StartColor => mStartColor;

	/// Get the end color
	public Color EndColor => mEndColor;

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
