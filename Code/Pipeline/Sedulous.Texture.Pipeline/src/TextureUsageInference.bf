using System;
using Sedulous.Texture.Compression;

namespace Sedulous.Texture.Pipeline;

/// Guessing what a texture is FOR from the name conventions texture packs share.
static class TextureUsageInference
{
	private static readonly StringView[6] cNormalTokens =
		.("_normal", "_norm", "_nrm", "_nor", "_ddn", "normalmap");

	private static readonly StringView[8] cMaskTokens =
		.("_disp", "_height", "_mask", "_rough", "_ao", "_orm", "_arm", "_metal");

	/// Case insensitive, matched anywhere in the stem, and only where what FOLLOWS the token is
	/// the end, an underscore or a digit.
	///
	/// That boundary rule is what keeps ordinary words out: "foo_nor_gl_4k" is a normal map and
	/// "my_armor" is not a mask. A name matching nothing infers colour, which is the default
	/// and the least destructive guess.
	public static SourceUsage Infer(StringView stem)
	{
		let lower = scope String();
		lower.Reserve(stem.Length);
		for (int i < stem.Length)
		{
			let c = stem[i];
			lower.Append(((c >= 'A') && (c <= 'Z')) ? (char8)(c + 32) : c);
		}

		for (let token in cNormalTokens)
		{
			if (HasToken(lower, token))
				return .Normal;
		}
		for (let token in cMaskTokens)
		{
			if (HasToken(lower, token))
				return .Mask;
		}
		return .Color;
	}

	private static bool HasToken(StringView haystack, StringView token)
	{
		if (haystack.Length < token.Length)
			return false;

		for (int at = 0; (at + token.Length) <= haystack.Length; ++at)
		{
			var match = true;
			for (int i < token.Length)
			{
				if (haystack[at + i] != token[i])
				{
					match = false;
					break;
				}
			}
			if (!match)
				continue;

			let next = at + token.Length;
			if ((next >= haystack.Length) || (haystack[next] == '_')
				|| ((haystack[next] >= '0') && (haystack[next] <= '9')))
			{
				return true;
			}
		}
		return false;
	}
}
