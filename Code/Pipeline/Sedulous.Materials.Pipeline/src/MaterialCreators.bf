using System;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Content;
using Sedulous.Materials;
using Sedulous.Materials.Resource;
using Sedulous.Pipeline.Core;

namespace Sedulous.Materials.Pipeline;

/// The materials domain's New Asset creators, from the runtime presets: the lit PBR set on the
/// "forward" shader, or BaseColor plus an albedo map on "unlit". Under Materials/ unless a
/// group was picked.
static class MaterialCreators
{
	public static void Register(AssetCreatorRegistry registry)
	{
		registry.Register(new AssetCreator("PBR Material", "Materials", typeof(MaterialAsset), new (context) => CreateMaterial(context, false)).Under("Materials"));
		registry.Register(new AssetCreator("Unlit Material", "Materials", typeof(MaterialAsset), new (context) => CreateMaterial(context, true)).Under("Materials"));
	}

	private static Instance CreateMaterial(AssetCreationContext context, bool unlit)
	{
		let target = context.Target;
		if (target == null)
			return null;
		let name = target.UniqueInstanceName(context.NameOr("Material"), .. scope .());
		let instance = target.CreateInstance(name, typeof(MaterialAsset).GetFullName(.. scope .()));
		if (instance == null)
			return null;
		let built = unlit ? MaterialPresets.CreateUnlit(name) : MaterialPresets.CreatePbr(name);
		defer delete built;
		let asset = scope MaterialAsset();
		MaterialSource.FromMaterial(built, .(), asset.Source);
		if (!(instance.WriteObject(asset) case .Ok))
			return null;
		GlobalLog(.Information, "Pipeline: created {} material '{}'", unlit ? "unlit" : "PBR", instance.GetPath(.. scope .()));
		return instance;
	}
}
