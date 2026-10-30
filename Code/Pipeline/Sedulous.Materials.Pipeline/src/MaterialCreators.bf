using System;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Content;
using Sedulous.Materials;
using Sedulous.Materials.Resource;
using Sedulous.Pipeline.Core;

namespace Sedulous.Materials.Pipeline;

/// The materials domain's New Asset creators, from the runtime presets: a material on each built-in
/// ("PBR Material" on "forward", "Unlit Material", "Phong Material"). Under Materials/ unless a
/// group was picked.
static class MaterialCreators
{
	public static void Register(AssetCreatorRegistry registry)
	{
		for (let builtin in MaterialPresets.BuiltinShadings)
		{
			let shading = builtin.Shading;
			registry.Register(new AssetCreator(scope String()..AppendF("{} Material", builtin.Label), "Materials", typeof(MaterialAsset),
				new [=shading] (context) => CreateMaterial(context, shading)).Under("Materials"));
		}
	}

	private static Instance CreateMaterial(AssetCreationContext context, BuiltinShading shading)
	{
		let target = context.Target;
		if (target == null)
			return null;
		let name = target.UniqueInstanceName(context.NameOr("Material"), .. scope .());
		let instance = target.CreateInstance(name, typeof(MaterialAsset).GetFullName(.. scope .()));
		if (instance == null)
			return null;
		let built = MaterialPresets.CreateBuiltin(shading, name);
		defer delete built;
		let asset = scope MaterialAsset();
		MaterialSource.FromMaterial(built, .(), asset.Source);
		if (!(instance.WriteObject(asset) case .Ok))
			return null;
		GlobalLog(.Information, "Pipeline: created {} material '{}'", MaterialPresets.BuiltinShadingOf(shading).Label, instance.GetPath(.. scope .()));
		return instance;
	}
}
