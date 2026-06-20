using System;
using Sedulous.Core.Mathematics;

namespace Sedulous.Drawing;

/// A brush that fills with a solid color
public class SolidBrush : IBrush
{
	private Color32 mColor;

	public Color32 BaseColor => mColor;
	public bool RequiresInterpolation => false;
	public Object Texture => null;

	public this(Color32 color)
	{
		mColor = color;
	}

	public Color32 GetColorAt(Vector2 position, RectangleF bounds)
	{
		return mColor;
	}

	/// Set the brush color
	public void SetColor(Color32 color)
	{
		mColor = color;
	}

	// Common predefined brushes (static instances)
	public static readonly SolidBrush White = new .(Color32.White) ~ delete _;
	public static readonly SolidBrush Black = new .(Color32.Black) ~ delete _;
	public static readonly SolidBrush Red = new .(Color32.Red) ~ delete _;
	public static readonly SolidBrush Green = new .(Color32.Green) ~ delete _;
	public static readonly SolidBrush Blue = new .(Color32.Blue) ~ delete _;
	public static readonly SolidBrush Transparent = new .(Color32(0, 0, 0, 0)) ~ delete _;
}
