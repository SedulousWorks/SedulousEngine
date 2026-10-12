using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Shaders;

namespace Sedulous.Shaders.Pipeline.Tests;

/// A custom shader checked without cooking it: DXC's messages read into file, line and column; a
/// properties error and an undeclared flag reported with their lines; a compile error at the
/// author's line after the block; an error under a flag only the full check finds, named with
/// its flag; a caller's compiler reused.
class ShaderCheckTests
{
	/// Wrong only under ALPHA_TEST (line 7): the plain variant compiles.
	private const String cBrokenUnderFlag = """
		// variants(fragment): ALPHA_TEST
		float4 VSMain(uint id : SV_VertexID) : SV_Position { return float4(0, 0, 0, 1); }
		float4 PSMain() : SV_Target0
		{
		    float4 c = float4(1, 1, 1, 1);
		#ifdef ALPHA_TEST
		    if (c.a < Cutof) discard;
		#endif
		    return c;
		}
		""";

	private static bool HaveCompiler()
	{
		let compiler = scope ShaderCompiler();
		return compiler.Initialize() case .Ok;
	}

	[Test]
	public static void DxcsMessageTextIsReadIntoFileLineColumnAndMessage()
	{
		let messages = "Lava.hlsl:12:21: error: use of undeclared identifier 'Sped'\n    float2 uv = input.uv * Sped;\n                    ^\nLava.hlsl:14:5: warning: implicit truncation of vector type\nC:\\Game\\Shaders\\lighting.hlsli:30:1: fatal error: 'missing.hlsli' file not found\r\nLava.hlsl:3:1: note: in file included from here\n";
		let errors = scope List<ShaderDiagnostic>();
		defer { ClearAndDeleteItems!(errors); }
		Test.Assert(ShaderCheck.ParseCompilerDiagnostics(messages, errors));
		Test.Assert(errors.Count == 2, "the warning, the note and the excerpt are not errors");
		Test.Assert((errors[0].File == "Lava.hlsl") && (errors[0].Line == 12) && (errors[0].Column == 21));
		Test.Assert(errors[0].Message == "use of undeclared identifier 'Sped'");
		Test.Assert(errors[1].File == "C:\\Game\\Shaders\\lighting.hlsli", "the drive letter stays");
		Test.Assert((errors[1].Line == 30) && (errors[1].Message == "'missing.hlsli' file not found"));

		let none = scope List<ShaderDiagnostic>();
		Test.Assert(!ShaderCheck.ParseCompilerDiagnostics("nothing to see\n", none));
		Test.Assert(none.IsEmpty);
	}

	[Test]
	public static void ADiagnosticPrintsAsFileLineColumnFileLineOrFile()
	{
		let diagnostic = scope ShaderDiagnostic();
		diagnostic.File.Set("Lava.hlsl");
		diagnostic.Line = 12;
		diagnostic.Column = 21;
		diagnostic.Message.Set("oops");
		Test.Assert(diagnostic.Format(.. scope .()) == "Lava.hlsl:12:21: oops");
		diagnostic.Column = 0;
		Test.Assert(diagnostic.Format(.. scope .()) == "Lava.hlsl:12: oops");
		diagnostic.Line = 0;
		Test.Assert(diagnostic.Format(.. scope .()) == "Lava.hlsl: oops");
	}

	[Test]
	public static void ACompileErrorIsFoundAtTheAuthorsLineAfterTheBlock()
	{
		if (!HaveCompiler()) { Console.WriteLine("SKIP: no DXC runtime"); return; }
		// The block's four lines are replaced by generated declarations; the error stays on line 6.
		let text = """
			properties
			{
			    float Strength = 2;
			}
			float4 VSMain(uint id : SV_VertexID) : SV_Position { return float4(0, 0, 0, 1); }
			float4 PSMain() : SV_Target0 { return float4(1, 1, 1, 1) * Strenght; }
			""";
		var options = ShaderCheckOptions();
		options.Depth = .BaseVariants;
		let check = scope ShaderCheck();
		check.Run(text, "Lava.hlsl", options);
		Test.Assert(check.Errors.Count == 1);
		Test.Assert((check.Errors[0].File == "Lava.hlsl") && (check.Errors[0].Line == 6) && (check.Errors[0].Column > 0));
		Test.Assert(check.Errors[0].Message.Contains("Strenght"));
		Test.Assert(!check.Errors[0].Message.Contains("(under"), "the plain variant");
		Test.Assert(check.Block.Properties.Count == 1, "the table parsed even though the code failed");
	}

	[Test]
	public static void APropertiesErrorAndAnUndeclaredFlagAreErrorsWithLines()
	{
		let bad = scope ShaderCheck();
		bad.Run("properties\n{\n    Colour Tint;\n}\n", "a.hlsl");
		Test.Assert((bad.Errors.Count == 1) && (bad.Errors[0].Line == 3));
		Test.Assert(bad.Errors[0].Message.Contains("unknown property type 'Colour'"));

		let undeclared = scope ShaderCheck();
		undeclared.Run("float4 PSMain() : SV_Target0 {\n#ifdef GBUFFER\n#endif\n return 1; }\n", "b.hlsl");
		Test.Assert(undeclared.Errors.Count == 1);
		Test.Assert(undeclared.Errors[0].Line == 0, "about the file's directives, not a line");
		Test.Assert(undeclared.Errors[0].Message.Contains("tests GBUFFER but no stage declares it"));
	}

	[Test]
	public static void AnErrorUnderAFlagIsTheFullChecksNamedWithItsFlag()
	{
		if (!HaveCompiler()) { Console.WriteLine("SKIP: no DXC runtime"); return; }
		var live = ShaderCheckOptions();
		live.Depth = .BaseVariants;
		let quick = scope ShaderCheck();
		quick.Run(cBrokenUnderFlag, "cut.hlsl", live);
		Test.Assert(quick.IsOk);
		Test.Assert(quick.FragmentMask == .AlphaTest);

		let full = scope ShaderCheck();
		full.Run(cBrokenUnderFlag, "cut.hlsl"); // every variant
		Test.Assert((full.Errors.Count == 1) && (full.Errors[0].Line == 7));
		Test.Assert(full.Errors[0].Message.Contains("Cutof"));
		Test.Assert(full.Errors[0].Message.Contains("(under ALPHA_TEST)"));
	}

	[Test]
	public static void ACallersCompilerIsReusedAndLeftAlive()
	{
		let compiler = scope ShaderCompiler();
		if (compiler.Initialize() case .Err) { Console.WriteLine("SKIP: no DXC runtime"); return; }
		var options = ShaderCheckOptions();
		options.Compiler = compiler;
		options.Depth = .BaseVariants;
		Test.Assert(scope ShaderCheck()..Run(cBrokenUnderFlag, "cut.hlsl", options).IsOk);
		Test.Assert(scope ShaderCheck()..Run(cBrokenUnderFlag, "cut.hlsl", options).IsOk, "still usable");
	}
}
