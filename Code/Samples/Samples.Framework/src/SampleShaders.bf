using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.RHI;
using Sedulous.Shaders;

namespace Samples.Framework;

/// Where an RHI sample's shaders come from: their files under Data/Samples/RHI, each naming its
/// entry points in its own comments (`// entry: vertex VSMain`), compiled with DXC as the sample
/// starts; or, where there is no shader compiler (Android), the pack
/// `Sedulous.Tools.ShaderPack --entries` cooks from the same files (Data/Samples/RHI/shaders.dpak).
///
/// Opened by SampleApp before the sample's OnInit, closed after its OnShutdown.
class SampleShaders
{
	/// The pack's name in the folder.
	public const String cPackFileName = "shaders.dpak";

	private String mFolder = new .() ~ delete _;
	private ShaderCompiler mCompiler = null;
	private CookedShaderPack mPack = null;

	public ~this()
	{
		Close();
	}

	public bool HasCompiler => mCompiler != null;
	public bool HasPack => mPack != null;

	/// `folder` holds the samples' shader files (Data/Samples/RHI). Its shaders.dpak, if there is
	/// one, is read too, for when no compiler is: a cooked pack never wins over the files.
	public void Open(StringView folder)
	{
		Close();
		mFolder.Set(folder);

		mCompiler = new ShaderCompiler();
		if (mCompiler.Initialize() case .Err)
			DeleteAndNullify!(mCompiler);

		let packPath = PathJoin(folder, cPackFileName, .. scope String());
		if (!FileExists(packPath))
			return;
		let stream = scope FileStream(packPath, .Read);
		mPack = new CookedShaderPack();
		if (!stream.IsValid || (mPack.Read(stream) case .Err))
		{
			Console.Error.WriteLine(scope $"SampleShaders: '{packPath}' could not be read");
			DeleteAndNullify!(mPack);
		}
	}

	public void Close()
	{
		DeleteAndNullify!(mCompiler);
		DeleteAndNullify!(mPack);
	}

	/// The module for one entry of `file` (relative to the folder, "Sample001_Triangle/Shader.hlsl").
	public Result<IShaderModule> Load(IDevice device, StringView file,
		// QUALIFIED: Sedulous.RHI has its own ShaderStage, a set of stages.
		Sedulous.Shaders.ShaderStage stage, StringView entryPoint, StringView label, StringView shaderModel)
	{
		if (mCompiler != null)
		{
			let path = PathJoin(mFolder, file, .. scope String());
			let bytes = scope List<uint8>();
			if (ReadFile(path, bytes) case .Err)
			{
				Console.Error.WriteLine(scope $"SampleShaders: no shader file '{path}'");
				return .Err;
			}
			return ShaderHelpers.CompileToModule(mCompiler, device, .((char8*)bytes.Ptr, bytes.Count), stage, entryPoint,
				label, shaderModel);
		}

		let name = ShaderPackCooker.EntryShaderName(file, entryPoint, .. scope String());
		if (mPack == null)
		{
			Console.Error.WriteLine(scope $"SampleShaders: no shader compiler and no cooked pack for '{name}'");
			return .Err;
		}
		let format = (device.Type == .DX12) ? CookedShaderFormat.Dxil : CookedShaderFormat.SpirV;
		if (!(mPack.Find(name, stage, .None, format) case .Ok(let blob)))
		{
			Console.Error.WriteLine(
				scope $"SampleShaders: '{name}' is not in the cooked pack (Sedulous.Tools.ShaderPack --entries)");
			return .Err;
		}
		var desc = ShaderModuleDesc();
		desc.Code = blob;
		desc.Label = label;
		desc.EntryPoint = entryPoint;
		return device.CreateShaderModule(desc);
	}
}
