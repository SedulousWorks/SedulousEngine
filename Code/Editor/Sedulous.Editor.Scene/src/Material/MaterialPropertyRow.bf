using System;
using Sedulous.Materials;

namespace Sedulous.Editor.Scene;

/// The row a material property gets on the material page, by its declared type: a colour
/// picker only for a declared colour (which shows the sRGB value as entered), a picker plus an
/// intensity for a colour that may pass white, and plain numbers for any other Float4.
enum MaterialPropertyRow
{
	/// Not shown (samplers, matrices).
	case None;
	case Number;
	case Numbers2;
	case Numbers3;
	case Numbers4;
	case Integer;
	case Color;
	case ColorWithIntensity;
	case Texture;

	/// Pure, so the choice is testable without a live page.
	public static MaterialPropertyRow For(MaterialPropertyType type)
	{
		switch (type)
		{
		case .Float: return .Number;
		case .Float2: return .Numbers2;
		case .Float3: return .Numbers3;
		case .Float4: return .Numbers4;
		case .Int: return .Integer;
		case .Color: return .Color;
		case .ColorHdr: return .ColorWithIntensity;
		case .Texture2D, .TextureCube: return .Texture;
		default: return .None;
		}
	}
}
