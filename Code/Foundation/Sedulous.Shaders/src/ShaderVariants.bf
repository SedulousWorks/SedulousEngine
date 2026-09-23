using System;
using System.Collections;

namespace Sedulous.Shaders;

/// The variant model: what a stage declares, and what a request collapses to.
///
/// A shipped build has NO compiler, so every variant the runtime can ask for must exist in
/// the cooked pack BY CONSTRUCTION. That works because:
///
///   Authoring    one line per stage, `// variants: SKINNED INSTANCED`, names the flags the
///                stage actually branches on. Absent means single variant, which is most
///                shaders.
///   Canonical    a request is intersected with the declared mask, in development AND in a
///                shipped build identically, so asking for a flag the stage ignores lands on
///                a variant that exists.
///   Cook         the POWER SET of the declared mask is built, so every canonical request
///                has somewhere to land. A miss in a shipped build is impossible rather than
///                merely loud.
///   Drift lint   a stage that `#ifdef`s a flag it did not declare is a bug, because
///                canonicalization would silently strip it and the visuals would be wrong.
///                The cook fails on used-but-undeclared.
static class ShaderVariants
{
	private const String cTag = "variants:";

	/// Reads the `// variants: A B C` directive out of a stage's HLSL.
	///
	/// The tag may sit anywhere on a line after the `//`; tokens are whitespace separated
	/// define names. An unknown token is IGNORED rather than an error, so a shader may name
	/// a flag that does not exist yet without breaking the cook.
	public static VariantDirective ParseVariantDirective(StringView source)
	{
		VariantDirective result = .();

		let length = source.Length;
		let data = source.Ptr;
		for (int i = 0; i < length; ++i)
		{
			if ((i + cTag.Length > length) || (source.Substring(i, cTag.Length) != cTag))
				continue;

			result.Present = true;
			int at = i + cTag.Length;
			while ((at < length) && (data[at] != '\n'))
			{
				while ((at < length) && ((data[at] == ' ') || (data[at] == '\t')
					|| (data[at] == '\r')))
					at++;

				let start = at;
				while ((at < length) && (data[at] != ' ') && (data[at] != '\t')
					&& (data[at] != '\r') && (data[at] != '\n'))
					at++;

				if (at > start)
					result.Mask |= ShaderFlagNames.FlagFromName(source.Substring(start, at - start));
			}
			return result;
		}
		return result;
	}

	/// Whether a stage carries the `// preserve-interface` directive.
	///
	/// It keeps EVERY declared stage input and output in the SPIR-V interface even where the
	/// body never reads one, which optimisation otherwise strips. A fragment stage declaring
	/// another family's whole output struct to read one member of it needs this, the interface
	/// being matched by LOCATION: a shorter input list is a mismatch, not a subset.
	public static bool ParsePreserveInterfaceDirective(StringView source)
	{
		const String cPreserveTag = "preserve-interface";

		let length = source.Length;
		for (int i = 0; i + cPreserveTag.Length <= length; ++i)
		{
			if (source.Substring(i, cPreserveTag.Length) == cPreserveTag)
				return true;
		}
		return false;
	}

	/// The variant a request actually resolves to: only the bits the stage declared survive.
	///
	/// Applied in development and in a shipped build identically, which is what makes the two
	/// behave the same and what dedupes variants: a pixel shader that ignores SKINNED stops
	/// recompiling once per skinned mesh.
	public static ShaderFlags CanonicalizeFlags(ShaderFlags requested, ShaderFlags declared)
		=> requested & declared;

	/// Every variant the cook must build for a declared mask, which is its power set.
	///
	/// Always includes None. A mask with k bits yields 2^k entries, and k is at most 8, so
	/// at most 256.
	public static void EnumerateVariants(ShaderFlags declared, List<ShaderFlags> outVariants)
	{
		uint32[8] bits = default;
		uint32 count = 0;
		for (let entry in ShaderFlagNames.Table)
		{
			if (declared.HasFlag(entry.Flag) && (count < 8))
			{
				bits[count] = (uint32)entry.Flag;
				count++;
			}
		}

		let total = 1u << count;
		for (uint32 subset = 0; subset < total; ++subset)
		{
			uint32 flags = 0;
			for (uint32 b = 0; b < count; ++b)
			{
				if ((subset & (1u << b)) != 0)
					flags |= bits[b];
			}
			outVariants.Add((ShaderFlags)flags);
		}
	}

	/// Flag names the source branches on but did not declare.
	///
	/// These are the drift bugs canonicalization would silently strip. Only lines that BEGIN
	/// with a `#if` family directive are scanned, because a bare search for the name would
	/// fail the cook on a comment that merely mentions a flag. Matching is whole word, which
	/// also covers a `defined(FLAG)` operand on such a line.
	///
	/// An empty result is clean.
	public static void FindUndeclaredFlagUses(StringView source, ShaderFlags declared,
		List<StringView> outUses)
	{
		let length = source.Length;
		let data = source.Ptr;

		int lineStart = 0;
		while (lineStart <= length)
		{
			int lineEnd = lineStart;
			while ((lineEnd < length) && (data[lineEnd] != '\n'))
				lineEnd++;

			let line = source.Substring(lineStart, lineEnd - lineStart);
			if (IsConditionalLine(line))
				CollectUndeclaredOnLine(line, declared, outUses);

			if (lineEnd >= length)
				break;
			lineStart = lineEnd + 1;
		}
	}

	/// Whether the line is a preprocessor conditional.
	///
	/// Whitespace between the `#` and the keyword is legal preprocessor syntax and accepted.
	private static bool IsConditionalLine(StringView line)
	{
		int at = 0;
		while ((at < line.Length) && ((line[at] == ' ') || (line[at] == '\t')))
			at++;
		if ((at >= line.Length) || (line[at] != '#'))
			return false;

		int keyword = at + 1;
		while ((keyword < line.Length) && ((line[keyword] == ' ') || (line[keyword] == '\t')))
			keyword++;

		let rest = line.Substring(keyword);
		return rest.StartsWith("if") || rest.StartsWith("elif");
	}

	private static void CollectUndeclaredOnLine(StringView line, ShaderFlags declared,
		List<StringView> outUses)
	{
		for (let entry in ShaderFlagNames.Table)
		{
			if (declared.HasFlag(entry.Flag))
				continue;

			for (int p = 0; p + entry.Define.Length <= line.Length; ++p)
			{
				if (line.Substring(p, entry.Define.Length) != entry.Define)
					continue;

				let leftOk = (p == 0) || !IsWordChar(line[p - 1]);
				let after = p + entry.Define.Length;
				let rightOk = (after == line.Length) || !IsWordChar(line[after]);
				if (leftOk && rightOk)
				{
					// Reported once per line: a flag named twice on one `#if` is one bug.
					outUses.Add(entry.Define);
					break;
				}
			}
		}
	}

	private static bool IsWordChar(char8 c)
		=> ((c >= 'A') && (c <= 'Z')) || ((c >= 'a') && (c <= 'z'))
			|| ((c >= '0') && (c <= '9')) || (c == '_');
}
