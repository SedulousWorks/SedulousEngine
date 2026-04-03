using System;
using Sedulous.Core.Mathematics;

namespace Sedulous.Drawing;

/// A brush that fills with a solid color
public class SolidBrush : IBrush
{
	private Color mColor;

	public Color BaseColor => mColor;
	public bool RequiresInterpolation => false;
	public Object Texture => null;

	public this(Color color)
	{
		mColor = color;
	}

	public Color GetColorAt(Vector2 position, RectangleF bounds)
	{
		return mColor;
	}

	/// Set the brush color
	public void SetColor(Color color)
	{
		mColor = color;
	}

	// Common predefined brushes (static instances)
	public static readonly SolidBrush White = new .(Color.White) ~ delete _;
	public static readonly SolidBrush Black = new .(Color.Black) ~ delete _;
	public static readonly SolidBrush Red = new .(Color.Red) ~ delete _;
	public static readonly SolidBrush Green = new .(Color.Green) ~ delete _;
	public static readonly SolidBrush Blue = new .(Color.Blue) ~ delete _;
	public static readonly SolidBrush Transparent = new .(Color(0, 0, 0, 0)) ~ delete _;
}
