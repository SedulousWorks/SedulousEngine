using Sedulous.Core.Mathematics;

namespace Sedulous.VG;

/// A solid color fill
public struct VGSolidFill : IVGFill
{
	private Color32 mColor;

	public this(Color32 color)
	{
		mColor = color;
	}

	public Color32 GetColorAt(Vector2 position, RectangleF bounds)
	{
		return mColor;
	}

	public Color32 BaseColor => mColor;

	public bool RequiresInterpolation => false;

	/// Preset solid fills
	public static VGSolidFill White => .(Color32.White);
	public static VGSolidFill Black => .(Color32.Black);
	public static VGSolidFill Red => .(Color32.Red);
	public static VGSolidFill Green => .(Color32.Green);
	public static VGSolidFill Blue => .(Color32.Blue);
	public static VGSolidFill Transparent => .(Color32.Transparent);
}
