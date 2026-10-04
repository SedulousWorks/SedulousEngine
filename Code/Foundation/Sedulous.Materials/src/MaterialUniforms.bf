using System;
using Sedulous.Core;

namespace Sedulous.Materials;

/// Where a material's colours meet the GPU.
static class MaterialUniforms
{
	/// The uniform bytes a shader receives: the authored bytes as they are, except each colour
	/// property, which is authored sRGB and decoded to linear here (a ColorHdr's rgb also
	/// scaled by its intensity, its w set to one). The one place a material's colours meet the
	/// GPU, like the hardware decode of an sRGB texture. `gpu` holds at least `authored.Length`
	/// bytes.
	public static void EncodeForGpu(Material material, Span<uint8> authored, uint8* gpu)
	{
		if (authored.Length > 0)
			Internal.MemCpy(gpu, authored.Ptr, authored.Length);
		for (let def in material.Properties)
		{
			if (!def.IsColor || ((int)def.Offset + sizeof(Float4) > authored.Length))
				continue;
			let c = *(Float4*)(authored.Ptr + def.Offset);
			let linear = ToLinear(Color(c.X, c.Y, c.Z, c.W));
			var result = Float4(linear.R, linear.G, linear.B, linear.A);
			if (def.Type == .ColorHdr)
				result = .(linear.R * c.W, linear.G * c.W, linear.B * c.W, 1.0f);
			*(Float4*)(gpu + def.Offset) = result;
		}
	}
}
