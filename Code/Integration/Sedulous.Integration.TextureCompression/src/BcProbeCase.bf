using System;
using Sedulous.RHI;

namespace Sedulous.Integration.TextureCompression;

/// One format to encode, the colour to put through it, and the channel it must come back
/// dominant in.
struct BcProbeCase
{
	public String Name;
	public TextureFormat Format;
	public uint8 R;
	public uint8 G;
	public uint8 B;
	/// Nought is red, one is green, two is blue.
	public int Dominant;

	public this(String name, TextureFormat format, uint8 r, uint8 g, uint8 b, int dominant)
	{
		Name = name;
		Format = format;
		R = r;
		G = g;
		B = b;
		Dominant = dominant;
	}
}
