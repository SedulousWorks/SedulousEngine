using System;
using System.Collections;
using Sedulous.Shaders;

namespace Sedulous.Shaders.Tests;

/// The variant model: what a stage declares, what a request collapses to, and what the cook
/// must build.
class ShaderVariantTests
{
	/// The directive names flags; anything it did not name stays out of the mask.
	[Test]
	public static void TheDirectiveMapsNamesToAMask()
	{
		let directive = ShaderVariants.ParseVariantDirective("""
			// variants: SKINNED INSTANCED
			float4 main(){}
			""");

		Test.Assert(directive.Present, "the directive was found");
		Test.Assert(directive.Mask.HasFlag(.Skinned));
		Test.Assert(directive.Mask.HasFlag(.Instanced));
		Test.Assert(!directive.Mask.HasFlag(.GBuffer), "and named nothing else");

		let absent = ShaderVariants.ParseVariantDirective("float4 main(){ return 0; }\n");
		Test.Assert(!absent.Present, "a shader without one declares nothing");
		Test.Assert(absent.Mask == .None);
	}

	/// A token that is not a known flag is ignored rather than failing, so a shader may name
	/// a flag that does not exist yet.
	[Test]
	public static void AnUnknownTokenIsIgnored()
	{
		let directive = ShaderVariants.ParseVariantDirective(
			"// variants: SKINNED NOT_A_REAL_FLAG GBUFFER\n");

		Test.Assert(directive.Present);
		Test.Assert(directive.Mask.HasFlag(.Skinned));
		Test.Assert(directive.Mask.HasFlag(.GBuffer));
		Test.Assert(directive.Mask == (ShaderFlags.Skinned | ShaderFlags.GBuffer),
			"and contributed nothing of its own");
	}

	/// Canonicalization keeps only the declared bits, which is what makes a request for a
	/// flag the stage ignores land on a variant that exists.
	[Test]
	public static void CanonicalizeKeepsOnlyDeclaredBits()
	{
		let requested = ShaderFlags.Skinned | ShaderFlags.GBuffer;
		// A vertex shader that branches only on SKINNED.
		Test.Assert(ShaderVariants.CanonicalizeFlags(requested, .Skinned) == .Skinned);
		Test.Assert(ShaderVariants.CanonicalizeFlags(requested, .None) == .None);
	}

	/// The power set: a mask with k bits yields 2^k variants, and None is always among them.
	[Test]
	public static void ThePowerSetEnumeratesEveryVariant()
	{
		let variants = scope List<ShaderFlags>();
		ShaderVariants.EnumerateVariants(.Skinned | .Instanced, variants);
		Test.Assert(variants.Count == 4, "two declared bits give four variants");

		bool sawNone = false;
		bool sawBoth = false;
		for (let variant in variants)
		{
			if (variant == .None)
				sawNone = true;
			if (variant == (ShaderFlags.Skinned | ShaderFlags.Instanced))
				sawBoth = true;
		}
		Test.Assert(sawNone, "the empty variant is built");
		Test.Assert(sawBoth, "and so is the full one");

		let single = scope List<ShaderFlags>();
		ShaderVariants.EnumerateVariants(.None, single);
		Test.Assert(single.Count == 1, "a shader that declares nothing has one variant");
		Test.Assert(single[0] == .None);
	}

	/// The drift lint catches a stage branching on a flag it did not declare, which
	/// canonicalization would otherwise strip in silence.
	[Test]
	public static void TheDriftLintCatchesAnUndeclaredBranch()
	{
		let source = "#ifdef GBUFFER\nfloat x;\n#endif\n";

		let undeclared = scope List<StringView>();
		ShaderVariants.FindUndeclaredFlagUses(source, .None, undeclared);
		Test.Assert(undeclared.Count == 1, "the undeclared branch is reported");
		Test.Assert(undeclared[0] == "GBUFFER");

		let clean = scope List<StringView>();
		ShaderVariants.FindUndeclaredFlagUses(source, .GBuffer, clean);
		Test.Assert(clean.IsEmpty, "and a declared one is not");
	}

	/// A comment that merely mentions a flag must NOT fail the cook. Only a real
	/// preprocessor conditional counts, and whitespace after the hash is legal.
	[Test]
	public static void TheDriftLintIgnoresComments()
	{
		let source = """
			// GBUFFER is a user-defined marker, see docs
			/* undefined behavior when SKINNED */
			#  ifdef ALPHA_TEST
			#endif
			float4 main() : SV_Target0 { return 0; }
			""";

		let undeclared = scope List<StringView>();
		ShaderVariants.FindUndeclaredFlagUses(source, .None, undeclared);
		Test.Assert(undeclared.Count == 1, "only the real conditional is reported");
		Test.Assert(undeclared[0] == "ALPHA_TEST");
	}

	/// A flag name embedded in a longer identifier is not a use of that flag: the match is
	/// whole word, so MY_GBUFFER_THING does not trip the lint.
	[Test]
	public static void TheDriftLintMatchesWholeWords()
	{
		let undeclared = scope List<StringView>();
		ShaderVariants.FindUndeclaredFlagUses("#if defined(MY_GBUFFER_THING)\n#endif\n", .None,
			undeclared);
		Test.Assert(undeclared.IsEmpty, "a longer identifier is not the flag");

		let real = scope List<StringView>();
		ShaderVariants.FindUndeclaredFlagUses("#if defined(GBUFFER)\n#endif\n", .None, real);
		Test.Assert(real.Count == 1, "but the flag inside defined() is");
		Test.Assert(real[0] == "GBUFFER");
	}

	/// Every flag in the table emits its define, and only the set ones do.
	[Test]
	public static void SetFlagsBecomeDefines()
	{
		let defines = scope List<ShaderDefine>();
		ShaderFlagNames.AppendDefines(.Skinned | .AlphaTest, defines);

		Test.Assert(defines.Count == 2, "two flags give two defines");
		bool sawSkinned = false;
		bool sawAlphaTest = false;
		for (let define in defines)
		{
			if (define.Name == "SKINNED")
				sawSkinned = true;
			if (define.Name == "ALPHA_TEST")
				sawAlphaTest = true;
			Test.Assert(define.Value == "1", "a flag define is always 1");
		}
		Test.Assert(sawSkinned && sawAlphaTest);

		let none = scope List<ShaderDefine>();
		ShaderFlagNames.AppendDefines(.None, none);
		Test.Assert(none.IsEmpty);
	}

	/// The table round trips: every flag's name maps back to the flag it came from.
	[Test]
	public static void EveryFlagNameMapsBackToItsFlag()
	{
		for (let entry in ShaderFlagNames.Table)
			Test.Assert(ShaderFlagNames.FlagFromName(entry.Define) == entry.Flag);

		Test.Assert(ShaderFlagNames.FlagFromName("NOT_A_FLAG") == .None);
		// Case sensitive, matching the preprocessor.
		Test.Assert(ShaderFlagNames.FlagFromName("skinned") == .None);
	}
}
