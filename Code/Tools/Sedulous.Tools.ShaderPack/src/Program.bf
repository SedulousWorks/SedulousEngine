using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Shaders;

namespace Sedulous.Tools.ShaderPack;

/// Cooks the engine shader corpus into a shader pack.
///
/// The standalone shader half of what the exporter does: enumerate a shader directory,
/// compile every stage and variant to the requested backend blobs, and write the pack.
///
///     Sedulous.Tools.ShaderPack <shaderDir> <output.dpak> [wgsl] [spirv] [dxil]
///     Sedulous.Tools.ShaderPack --entries <dir> <output.dpak> [spirv] [dxil]
///
/// --entries cooks shaders that name their entry points in their own comments
/// (`// entry: vertex VSMain`, the RHI samples' under Data/Samples/RHI): every .hlsl under
/// <dir>, each entry under "<file>:<entry>". It defaults to spirv, the format a device without
/// a shader compiler (Android) reads.
///
/// A DESKTOP authoring tool by necessity. It needs DXC, and WGSL additionally needs naga
/// and tint, none of which exist in a browser - which is the point: the WGSL pack this
/// produces is what a web build ships and loads at run time, because it cannot compile
/// anything itself.
class Program
{
	/// Where the WGSL translator puts its intermediates. Must exist before the cook.
	private const String cScratchDirectory = ".shaderpackcook-scratch";

	public static int Main(String[] args)
	{
		let entries = (args.Count > 0) && (args[0] == "--entries");
		let first = entries ? 1 : 0;
		if (args.Count < first + 2)
		{
			PrintUsage();
			return 2;
		}

		let shaderDirectory = args[first];
		let outputPath = args[first + 1];

		let formats = scope List<CookedShaderFormat>();
		for (int i = first + 2; i < args.Count; i++)
		{
			switch (args[i])
			{
			case "wgsl": formats.Add(.Wgsl);
			case "spirv": formats.Add(.SpirV);
			case "dxil": formats.Add(.Dxil);
			default:
				Console.Error.WriteLine(scope $"Tools.ShaderPack: unknown format '{args[i]}'");
				PrintUsage();
				return 2;
			}
		}

		// WGSL by default, that being the one a browser cannot produce for itself; SPIR-V for
		// entry shaders, the one a device without a compiler reads.
		if (formats.IsEmpty)
			formats.Add(entries ? CookedShaderFormat.SpirV : CookedShaderFormat.Wgsl);

		let compiler = scope ShaderCompiler();
		if (compiler.Initialize() case .Err)
		{
			Console.Error.WriteLine("Tools.ShaderPack: DXC runtime unavailable");
			return 1;
		}

		let pack = scope CookedShaderPack();
		let report = scope ShaderCookReport();
		if (entries)
		{
			var entryOptions = ShaderEntryCookOptions();
			entryOptions.ShaderDirectory = shaderDirectory;
			entryOptions.Formats = formats;
			ShaderPackCooker.CookEntryShaders(compiler, entryOptions, pack, report);
		}
		else
		{
			CreateDirectory(cScratchDirectory);

			var options = ShaderCookOptions();
			options.ShaderDirectory = shaderDirectory;
			options.ScratchDirectory = cScratchDirectory;
			options.Formats = formats;
			ShaderPackCooker.CookEngineShaders(compiler, options, pack, report);
		}

		for (let error in report.Errors)
			Console.Error.WriteLine(scope $"cook error: {error}");

		Console.Error.WriteLine(
			scope $"Tools.ShaderPack: files={report.FilesCooked} variants={report.VariantsCooked} success={report.Success}");

		// A partially filled pack is NOT written. The cooker leaves one behind on purpose so
		// a caller can see what did cook, but a shipped build must refuse it.
		if (!report.Success)
			return 1;

		let output = scope FileStream(outputPath, .Write);
		if (!output.IsValid || (pack.Write(output) case .Err))
		{
			Console.Error.WriteLine(scope $"Tools.ShaderPack: could not write '{outputPath}'");
			return 1;
		}

		Console.Error.WriteLine(
			scope $"Tools.ShaderPack: wrote '{outputPath}' ({pack.Count} entries)");
		return 0;
	}

	private static void PrintUsage()
	{
		Console.Error.WriteLine(
			"usage: Sedulous.Tools.ShaderPack <shaderDir> <output.dpak> [wgsl] [spirv] [dxil]\n       Sedulous.Tools.ShaderPack --entries <dir> <output.dpak> [spirv] [dxil]");
	}
}
