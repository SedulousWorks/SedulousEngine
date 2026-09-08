using System;

namespace Sedulous.Materials.Resource;

/// What a source targeting the built in forward shader has to declare.
///
/// The forward pass reads a fixed uniform block. A source missing part of it produces a
/// SHORT buffer, and the shader then reads past the end of it, which is a class of bug that
/// shows up as noise in whichever field happens to follow.
///
/// A stale source is REFUSED rather than upgraded in memory. Upgrading would need this
/// layer to know the offsets the shader expects, which is exactly the coupling the data
/// driven model exists to avoid; and a source that silently gains properties on load is a
/// source that never gets re-cooked.
static class ForwardMaterialContract
{
	public const String ShaderName = "forward";

	/// The properties added after the first version of the forward block. A source
	/// declaring the earlier set predates them.
	public const String[4] RequiredProperties = .(
		"EmissiveColor", "OcclusionStrength", "NormalScale", "AlphaCutoff");

	/// True when the source is usable. Anything not targeting the forward shader passes
	/// unexamined: a custom shader declares its own block and this knows nothing about it.
	public static bool IsComplete(MaterialSource source, String outMissing = null)
	{
		if (source.ShaderName != ShaderName)
			return true;

		for (let required in RequiredProperties)
		{
			var present = false;
			for (let declared in source.PropertyNames)
			{
				if (declared == required)
				{
					present = true;
					break;
				}
			}
			if (!present)
			{
				if (outMissing != null)
					outMissing.Set(required);
				return false;
			}
		}
		return true;
	}
}
