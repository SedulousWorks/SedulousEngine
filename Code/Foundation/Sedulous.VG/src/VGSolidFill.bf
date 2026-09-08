using Sedulous.Core;

namespace Sedulous.VG;

/// One colour everywhere.
class VGSolidFill : IVGFill
{
	private Color mColor = .White;

	public this() {}

	public this(Color color)
	{
		mColor = color;
	}

	public Color GetColorAt(Float2 position, Rectangle bounds) => mColor;
	public Color BaseColor => mColor;
	/// Nothing varies, so the tessellator writes one colour rather than evaluating per
	/// vertex.
	public bool RequiresInterpolation => false;

	public static VGSolidFill White() => new .(.White);
	public static VGSolidFill Black() => new .(.Black);
	public static VGSolidFill Red() => new .(.Red);
	public static VGSolidFill Green() => new .(.Green);
	public static VGSolidFill Blue() => new .(.Blue);
	public static VGSolidFill Transparent() => new .(.Transparent);
}
