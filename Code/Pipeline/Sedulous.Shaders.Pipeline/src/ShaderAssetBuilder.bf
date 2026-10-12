using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Logging;
using Sedulous.Pipeline.Core;
using Sedulous.Shaders;
using Sedulous.Shaders.Resource;

namespace Sedulous.Shaders.Pipeline;

/// Cooks a shader asset: reads its one file, replaces its properties block with the generated
/// set-2 declarations, and COMPILES every variant both stages declare, with the engine's shader
/// library on the include path. A failure fails the cook with `File.hlsl:line: message` (the
/// cook keeps the last good product), so a broken shader is caught here rather than at draw
/// time, every frame. Success writes a ShaderSource carrying the expanded source, both entries,
/// both lattices and the property table every material on the shader is laid out by.
class ShaderAssetBuilder : IAssetBuilder
{
	/// <data root>/Shaders, the include path; empty when no data root was given.
	private String mShaderLibrary = new .() ~ delete _;

	public Type AssetType => typeof(ShaderAsset);
	public Type ProductType => typeof(ShaderSource);
	/// 2: the product names each stage's entry point. 3: one file, compiled at cook time; the
	/// product carries the expanded source, the lattices and the property table.
	public int32 Version => 3;

	/// `dataRoot`: the engine's data root, whose shader library (`Shaders/`) is on every custom
	/// shader's include path. Empty: includes resolve nowhere.
	public this(StringView dataRoot = default)
	{
		if (!dataRoot.IsEmpty)
			PathJoin(dataRoot, ShaderSystemHost.cShaderFolder, mShaderLibrary);
	}

	public Result<void, ErrorCode> Build(Asset asset, AssetBuildContext context)
	{
		if (context.Output == null)
			return .Err(.InvalidArgument);

		let shader = (ShaderAsset)asset;
		let file = shader.FileName.Value;
		let text = scope String();
		if (AssetSource.ReadText(context, file, text) case .Err(let readError))
			return .Err(readError);

		// The properties block becomes the set-2 declarations; `#line` keeps the author's line
		// numbers for everything after it.
		let expanded = scope String();
		let block = scope ShaderPropertiesBlock();
		ShaderProperties.Expand(text, file, expanded, block);
		for (let error in block.Errors)
			GlobalLog(.Error, "Shaders: {}:{}: {} - cook failed", file, error.Line, error.Message);
		if (!block.IsOk)
			return .Err(.InvalidArgument);

		// Each stage's lattice; a flag the file tests but no stage declares would never be
		// compiled, so it fails the cook (the corpus's drift lint, over both stages).
		let vertexMask = ShaderVariants.ParseStageVariantDirective(text, .Vertex).Mask;
		let fragmentMask = ShaderVariants.ParseStageVariantDirective(text, .Fragment).Mask;
		let undeclared = scope List<StringView>();
		ShaderVariants.FindUndeclaredFlagUses(text, vertexMask | fragmentMask, undeclared);
		for (let flag in undeclared)
			GlobalLog(.Error, "Shaders: {}: tests {} but no stage declares it (add it to a // variants(vertex): or // variants(fragment): line) - cook failed", file, flag);
		if (!undeclared.IsEmpty)
			return .Err(.InvalidArgument);

		if (!CompileEveryVariant(file, expanded, shader, vertexMask, fragmentMask))
			return .Err(.InvalidArgument);

		let cooked = scope ShaderSource();
		cooked.Name.Set(shader.Name);
		cooked.VertexSource.Set(expanded);
		cooked.FragmentSource.Set(expanded);
		cooked.VertexEntryPoint.Set(shader.VertexEntryPoint);
		cooked.FragmentEntryPoint.Set(shader.FragmentEntryPoint);
		cooked.VertexVariantMask = (uint32)vertexMask;
		cooked.FragmentVariantMask = (uint32)fragmentMask;
		cooked.SetProperties(block);
		return context.Output.WriteObject(cooked);
	}

	/// Compiles both stages' every declared variant to SPIR-V, logging a failure as DXC reports
	/// it (`File.hlsl:line:col: error: ...`). True when all compile.
	private bool CompileEveryVariant(StringView file, StringView expanded, ShaderAsset shader, ShaderFlags vertexMask,
		ShaderFlags fragmentMask)
	{
		let compiler = scope ShaderCompiler();
		if (compiler.Initialize() case .Err)
		{
			GlobalLog(.Error, "Shaders: {}: the DXC compiler is unavailable - cook failed", file);
			return false;
		}
		StringView[1] includePaths = .(mShaderLibrary);
		(ShaderStage stage, StringView entryPoint, ShaderFlags mask)[2] stages = .(
			(.Vertex, shader.VertexEntryPoint, vertexMask),
			(.Fragment, shader.FragmentEntryPoint, fragmentMask));

		let variants = scope List<ShaderFlags>();
		let defines = scope List<ShaderDefine>();
		for (let stage in stages)
		{
			variants.Clear();
			ShaderVariants.EnumerateVariants(stage.mask, variants);
			for (let flags in variants)
			{
				defines.Clear();
				ShaderFlagNames.AppendDefines(flags, defines);
				var options = CompileOptions();
				options.Defines = defines;
				if (!mShaderLibrary.IsEmpty)
					options.IncludePaths = includePaths;
				options.BindingShifts = BindingShifts.Standard;
				options.BindingShiftSets = 4;
				options.SourceName = file;
				var result = compiler.Compile(.((uint8*)expanded.Ptr, expanded.Length), stage.stage, stage.entryPoint,
					.SPIRV, options);
				defer result.Dispose();
				if (!result.Success)
				{
					// One stage's first failure says what is wrong; the rest repeat it.
					GlobalLog(.Error, "Shaders: {} ({}, variant flags {}) - cook failed: {}", file, stage.entryPoint,
						(uint32)flags, result.Messages);
					return false;
				}
			}
		}
		return true;
	}
}
