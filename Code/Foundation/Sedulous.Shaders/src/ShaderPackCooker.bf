using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;

namespace Sedulous.Shaders;

/// Precompiles a whole HLSL corpus into a CookedShaderPack.
///
/// The export step that removes the compiler from a shipped build. For each stage file it
/// parses the variant directive, drift lints, enumerates the power set of the declared mask,
/// and emits a blob for every variant and requested format.
///
/// Runs on a development or CI host only. A shipped build just reads the pack.
static class ShaderPackCooker
{
	/// How deep an `#include` chain is followed when expanding for the lint.
	private const uint32 cMaxIncludeDepth = 8;

	/// Fills `pack` from every stage file under the shader directory.
	///
	/// On any error the pack is left PARTIALLY filled and success is false. That is
	/// deliberate: the caller can inspect what did cook, and a shipped build must refuse a
	/// pack that did not cook clean.
	public static void CookEngineShaders(ShaderCompiler compiler, ShaderCookOptions options,
		CookedShaderPack pack, ShaderCookReport report)
	{
		let files = scope List<String>();
		defer { ClearAndDeleteItems!(files); }

		if (!ListDirectory(options.ShaderDirectory, scope (name, isDirectory) =>
			{
				if (!isDirectory)
					files.Add(new String(name));
			}))
		{
			report.AddError(options.ShaderDirectory, "could not list the shader directory");
			return;
		}

		// The directory yields filesystem order, so it is SORTED here: the pack's entry
		// order, and therefore its bytes, must be reproducible across hosts and runs.
		files.Sort(scope (a, b) => String.Compare(a, b, false));

		StringView[1] includePaths = .(options.ShaderDirectory);

		let translator = scope WgslTranslator(compiler, options.ScratchDirectory);
		translator.SetValidateWithTint(options.ValidateWgsl);
		ConfigureTools(translator);

		for (let fileName in files)
		{
			ShaderStage stage = .Vertex;
			let stem = scope String();
			if (!ParseStageFile(fileName, ref stage, stem))
				continue; // an .hlsli include, or something that is not a shader

			let source = scope String();
			if (!ReadStageSource(options.ShaderDirectory, fileName, source))
			{
				report.AddError(fileName, "could not read the source");
				continue;
			}

			// The directive comes from the STAGE FILE, but the lint runs over the include
			// expanded text: the flag conditionals live in the shared .hlsli bodies, and a
			// stage file is often just the directive plus one include.
			let directive = ShaderVariants.ParseVariantDirective(source);
			if (!LintIsClean(options.ShaderDirectory, source, directive.Mask, fileName, report))
				continue;

			// Recorded so a shipped runtime can canonicalize onto the cooked lattice, which
			// is what makes development and a shipped build behave the same.
			pack.AddDeclaredMask(stem, stage, directive.Mask);

			let variants = scope List<ShaderFlags>();
			ShaderVariants.EnumerateVariants(directive.Mask, variants);

			report.FilesCooked++;
			for (let flags in variants)
			{
				for (let format in options.Formats)
				{
					if (CookOne(compiler, translator, source, stage, flags, format, options,
						includePaths, stem, fileName, pack, report))
						report.VariantsCooked++;
				}
			}
		}

		report.Success = report.Errors.IsEmpty;
	}

	/// Points the translator at the vendored binaries beside the executable.
	///
	/// A host with no binary for its platform leaves the path empty, and the translator
	/// reports the tool missing rather than pretending to have translated.
	private static void ConfigureTools(WgslTranslator translator)
	{
		let root = scope String();
		GetExecutableDirectory(root);
		if (root.IsEmpty)
			return;

		let naga = scope String();
		PathJoin(root, ToolRelativePath("naga", .. scope String()), naga);
		if (FileExists(naga))
			translator.SetNagaPath(naga);

		let tint = scope String();
		PathJoin(root, ToolRelativePath("tint", .. scope String()), tint);
		if (FileExists(tint))
			translator.SetTintPath(tint);
	}

	private static void ToolRelativePath(StringView tool, String outPath)
	{
#if BF_PLATFORM_WINDOWS
		outPath.AppendF("{}.exe", tool);
#else
		outPath.Append(tool);
#endif
	}

	private static bool ReadStageSource(StringView shaderDirectory, StringView fileName,
		String outSource)
	{
		let path = scope String();
		PathJoin(shaderDirectory, fileName, path);

		let bytes = scope List<uint8>();
		if (ReadFile(path, bytes) case .Err)
			return false;
		outSource.Append(StringView((char8*)bytes.Ptr, bytes.Count));
		return true;
	}

	/// Runs the drift lint over the include expanded source, reporting every undeclared flag.
	private static bool LintIsClean(StringView shaderDirectory, StringView source,
		ShaderFlags declared, StringView fileName, ShaderCookReport report)
	{
		let expanded = scope String();
		let visited = scope List<String>();
		defer { ClearAndDeleteItems!(visited); }
		AppendExpandedSource(shaderDirectory, source, 0, visited, expanded);

		let undeclared = scope List<StringView>();
		ShaderVariants.FindUndeclaredFlagUses(expanded, declared, undeclared);
		if (undeclared.IsEmpty)
			return true;

		let message = scope String("uses undeclared variant flag(s):");
		for (let flag in undeclared)
		{
			message.Append(" ");
			message.Append(flag);
		}
		message.Append(" (add them to the // variants: directive)");
		report.AddError(fileName, message);
		return false;
	}

	/// Inlines `#include "file"` against the shader root so the lint sees the .hlsli bodies.
	///
	/// Linting only a stage file's own text would pass a cook that silently strips a used
	/// flag, because the conditionals usually live in the include. Quote includes only, since
	/// the corpus has no angle includes, depth limited and de-duplicated. An unreadable
	/// include is skipped rather than reported: DXC reports it properly during the real
	/// compile, and duplicating that here would report it once per variant.
	private static void AppendExpandedSource(StringView shaderDirectory, StringView source,
		uint32 depth, List<String> visited, String outExpanded)
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
			if (!TryExpandInclude(shaderDirectory, line, depth, visited, outExpanded))
			{
				outExpanded.Append(line);
				outExpanded.Append("\n");
			}

			if (lineEnd >= length)
				break;
			lineStart = lineEnd + 1;
		}
	}

	/// Whether the line was an include this consumed, expanded or already seen.
	private static bool TryExpandInclude(StringView shaderDirectory, StringView line,
		uint32 depth, List<String> visited, String outExpanded)
	{
		if (depth >= cMaxIncludeDepth)
			return false;

		int at = 0;
		while ((at < line.Length) && ((line[at] == ' ') || (line[at] == '\t')))
			at++;
		let trimmed = line.Substring(at);
		if (!trimmed.StartsWith("#include"))
			return false;

		let firstQuote = trimmed.IndexOf('"');
		if (firstQuote < 0)
			return false;
		let closeQuote = trimmed.IndexOf('"', firstQuote + 1);
		if (closeQuote < 0)
			return false;

		let includeName = trimmed.Substring(firstQuote + 1, closeQuote - firstQuote - 1);
		for (let seen in visited)
		{
			// Already inlined once: consume the line rather than re-scanning, so a diamond
			// include does not multiply the lint's work or report a flag twice.
			if (seen == includeName)
				return true;
		}
		visited.Add(new String(includeName));

		let path = scope String();
		PathJoin(shaderDirectory, includeName, path);
		let bytes = scope List<uint8>();
		if (ReadFile(path, bytes) case .Err)
			return false;

		AppendExpandedSource(shaderDirectory, StringView((char8*)bytes.Ptr, bytes.Count),
			depth + 1, visited, outExpanded);
		return true;
	}

	/// "<stem>.<vs|ps|cs>.hlsl" to a stage and a stem; false for anything else.
	///
	/// Matches the file provider's naming, so a cooked name and a development name agree.
	public static bool ParseStageFile(StringView fileName, ref ShaderStage outStage,
		String outStem)
	{
		StringView suffix;
		if (fileName.EndsWith(".vs.hlsl"))
		{
			outStage = .Vertex;
			suffix = ".vs.hlsl";
		}
		else if (fileName.EndsWith(".ps.hlsl"))
		{
			outStage = .Fragment;
			suffix = ".ps.hlsl";
		}
		else if (fileName.EndsWith(".cs.hlsl"))
		{
			outStage = .Compute;
			suffix = ".cs.hlsl";
		}
		else
		{
			return false;
		}

		let stem = fileName.Substring(0, fileName.Length - suffix.Length);
		if (stem.IsEmpty)
			return false;
		outStem.Set(stem);
		return true;
	}

	/// Compiles or translates one variant and format pair into the pack.
	private static bool CookOne(ShaderCompiler compiler, WgslTranslator translator,
		StringView source, ShaderStage stage, ShaderFlags flags, CookedShaderFormat format,
		ShaderCookOptions options, Span<StringView> includePaths, StringView stem,
		StringView fileName, CookedShaderPack pack, ShaderCookReport report)
	{
		if (format == .Wgsl)
		{
			let translated = scope WgslCookResult();
			translator.Translate(source, stage, flags, includePaths, translated);
			if (!translated.Success)
			{
				report.AddError(fileName, translated.Error);
				return false;
			}
			pack.Add(stem, stage, flags, format,
				.((uint8*)translated.Wgsl.Ptr, translated.Wgsl.Length));
			return true;
		}

		let defines = scope List<ShaderDefine>();
		ShaderFlagNames.AppendDefines(flags, defines);

		var compileOptions = CompileOptions();
		compileOptions.ShaderModel = "6_0";
		compileOptions.OptimizationLevel = 3;
		compileOptions.Defines = defines;
		compileOptions.IncludePaths = includePaths;
		compileOptions.PreserveInterface = ShaderVariants.ParsePreserveInterfaceDirective(source);

		ShaderTarget target = .SPIRV;
		if (format == .SpirV)
		{
			compileOptions.SpirvTargetEnvironment = options.SpirvTargetEnvironment;
			compileOptions.BindingShifts = BindingShifts.Standard;
			compileOptions.BindingShiftSets = 4;
		}
		else
		{
			target = .DXIL;
		}

		var compiled = compiler.Compile(.((uint8*)source.Ptr, source.Length), stage, "main",
			target, compileOptions);
		defer compiled.Dispose();

		if (!compiled.Success)
		{
			report.AddError(fileName, compiled.Messages.IsEmpty ? "the DXC compile failed"
				: compiled.Messages);
			return false;
		}

		pack.Add(stem, stage, flags, format, compiled.Bytecode);
		return true;
	}
}
