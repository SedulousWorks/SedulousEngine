using Sedulous.Core.Mathematics;

namespace Sedulous.VG;

/// A solid color fill
public struct VGSolidFill : IVGFill
{
	private Color mColor;

	public this(Color color)
	{
		mColor = color;
	}

	public Color GetColorAt(Vector2 position, RectangleF bounds)
	{
		return mColor;
	}

	public Color BaseColor => mColor;

	public bool RequiresInterpolation => false;

	/// Preset solid fills
	public static VGSolidFill White => .(Color.White);
	public static VGSolidFill Black => .(Color.Black);
	public static VGSolidFill Red => .(Color.Red);
	public static VGSolidFill Green => .(Color.Green);
	public static VGSolidFill Blue => .(Color.Blue);
	public static VGSolidFill Transparent => .(Color.Transparent);
}
