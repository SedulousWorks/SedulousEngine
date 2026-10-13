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
	/// product carries the expanded source, the lattices and the property table. 4: the product
	/// carries programs beside the main one (a surface shader's depth and pick).
	public int32 Version => 4;

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
		let taken = EngineShaderFile(shader.Name, .. scope String());
		if (!taken.IsEmpty)
		{
			GlobalLog(.Error, "Shaders: {}: the name '{}' is the engine's shader ({}): one name keys a shader in the shader system and a shipped build's pack, so rename it - cook failed", file, shader.Name, taken);
			return .Err(.InvalidArgument);
		}
		let text = scope String();
		if (AssetSource.ReadText(context, file, text) case .Err(let readError))
			return .Err(readError);

		// What the cook proves: the block expands, every flag tested is declared, and every
		// variant of both stages compiles. Each error is logged where it is, and fails it.
		var options = ShaderCheckOptions();
		options.VertexEntryPoint = shader.VertexEntryPoint;
		options.FragmentEntryPoint = shader.FragmentEntryPoint;
		options.ShaderLibrary = mShaderLibrary;
		options.Depth = .EveryVariant;
		let check = scope ShaderCheck();
		check.Run(text, file, options);
		for (let error in check.Errors)
			GlobalLog(.Error, "Shaders: {} - cook failed", error.Format(.. scope .()));
		if (!check.IsOk)
			return .Err(.InvalidArgument);

		let cooked = scope ShaderSource();
		cooked.Name.Set(shader.Name);
		cooked.VertexSource.Set(check.Expanded);
		cooked.FragmentSource.Set(check.Expanded);
		cooked.VertexEntryPoint.Set(shader.VertexEntryPoint);
		cooked.FragmentEntryPoint.Set(shader.FragmentEntryPoint);
		cooked.VertexVariantMask = (uint32)check.VertexMask;
		cooked.FragmentVariantMask = (uint32)check.FragmentMask;
		cooked.SetProperties(check.Block);
		return context.Output.WriteObject(cooked);
	}

	/// The engine library's file for a shader of this name (`forward` is forward.ps.hlsl), or
	/// empty when the name is free. A project shader with an engine shader's name would replace
	/// it everywhere the name is looked up.
	private void EngineShaderFile(StringView name, String outFile)
	{
		if (mShaderLibrary.IsEmpty || name.IsEmpty)
			return;
		StringView[3] suffixes = .(".vs.hlsl", ".ps.hlsl", ".cs.hlsl");
		for (let suffix in suffixes)
		{
			outFile.Set(name);
			outFile.Append(suffix);
			if (FileExists(PathJoin(mShaderLibrary, outFile, .. scope String())))
				return;
		}
		outFile.Clear();
	}
}
