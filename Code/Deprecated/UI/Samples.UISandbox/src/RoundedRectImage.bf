using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Image;

namespace Samples.UISandbox;

/// Generates the rounded rectangles the textured theme is skinned from.
///
/// They are made HERE rather than loaded, so the textured theme demonstrates image skinning
/// without the sandbox needing an art pack: the shapes are exactly what a nine-slice needs and
/// nothing else.
static class RoundedRectImage
{
	/// A byte colour, which is how the skin below is written.
	public struct Px
	{
		public uint8 R;
		public uint8 G;
		public uint8 B;
		public uint8 A;

		public this(uint8 r, uint8 g, uint8 b, uint8 a = 255)
		{
			R = r; G = g; B = b; A = a;
		}

		public static Px Clear => .(0, 0, 0, 0);
	}

	/// The same radius on all four corners.
	public static OwnedImageData Make(uint32 width, uint32 height, Px fill, Px border,
		int32 radius) => Make(width, height, fill, border, radius, radius, radius, radius);

	/// Per corner radii, which is what the spin buttons need: each rounds on ONE outer corner
	/// so the pair reads as a single control.
	///
	/// A pixel outside its corner's arc is transparent, the ring just inside it is the border,
	/// and a square corner borders on the outer edge instead.
	public static OwnedImageData Make(uint32 width, uint32 height, Px fill, Px border,
		int32 topLeft, int32 topRight, int32 bottomRight, int32 bottomLeft)
	{
		let pixels = new List<uint8>();
		pixels.Resize((int)width * (int)height * 4);

		for (uint32 y < height)
		{
			for (uint32 x < width)
			{
				int32 centerX = -1;
				int32 centerY = -1;
				int32 radius = 0;

				if ((x < (uint32)topLeft) && (y < (uint32)topLeft))
				{
					centerX = topLeft; centerY = topLeft; radius = topLeft;
				}
				else if ((x >= (width - (uint32)topRight)) && (y < (uint32)topRight))
				{
					centerX = (int32)width - topRight - 1; centerY = topRight; radius = topRight;
				}
				else if ((x < (uint32)bottomLeft) && (y >= (height - (uint32)bottomLeft)))
				{
					centerX = bottomLeft; centerY = (int32)height - bottomLeft - 1;
					radius = bottomLeft;
				}
				else if ((x >= (width - (uint32)bottomRight)) &&
					(y >= (height - (uint32)bottomRight)))
				{
					centerX = (int32)width - bottomRight - 1;
					centerY = (int32)height - bottomRight - 1;
					radius = bottomRight;
				}

				var inside = true;
				var isBorder = false;

				if (centerX >= 0)
				{
					let dx = (int32)x - centerX;
					let dy = (int32)y - centerY;
					let distance = Sqrt((float)((dx * dx) + (dy * dy)));
					if (distance > (float)radius)
						inside = false;
					else if (distance > (float)(radius - 1))
						isBorder = true;
				}
				else if ((x == 0) || (x == (width - 1)) || (y == 0) || (y == (height - 1)))
				{
					isBorder = true;
				}

				let color = inside ? (isBorder ? border : fill) : Px.Clear;
				let offset = (int)((y * width) + x) * 4;
				pixels[offset + 0] = color.R;
				pixels[offset + 1] = color.G;
				pixels[offset + 2] = color.B;
				pixels[offset + 3] = color.A;
			}
		}

		return new OwnedImageData(width, height, .RGBA8, pixels);
	}
}
