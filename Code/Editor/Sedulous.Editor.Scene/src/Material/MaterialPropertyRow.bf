using System;
using Sedulous.Materials;

namespace Sedulous.Editor.Scene;

/// The row a material property gets on the material page, by its declared type: a colour
/// picker only for a declared colour (which shows the sRGB value as entered), a picker plus an
/// intensity for a colour that may pass white, and plain numbers for any other Float4.
enum MaterialPropertyRow
{
	/// Not shown (samplers, ints, matrices until a preset needs them).
	case None;
	case Number;
	case Numbers4;
	case Color;
	case ColorWithIntensity;
	case Texture;

	/// Pure, so the choice is testable without a live page.
	public static MaterialPropertyRow For(MaterialPropertyType type)
	{
		switch (type)
		{
		case .Float: return .Number;
		case .Float4: return .Numbers4;
		case .Color: return .Color;
		case .ColorHdr: return .ColorWithIntensity;
		case .Texture2D, .TextureCube: return .Texture;
		default: return .None;
		}
	}
}
