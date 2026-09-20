using System;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Content;
using Sedulous.Materials;
using Sedulous.Materials.Resource;
using Sedulous.Materials.Pipeline;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Scene;

/// New material assets from the runtime presets: the lit PBR set on the "forward" shader,
/// or BaseColor plus an albedo map on "unlit". Both land under Materials/ unless a browser
/// group was given, uniquely named. Answers the instance, borrowed.
static class MaterialAssetCreators
{
	public static Instance CreateMaterialInstance(EditorContext context, Group group, bool unlit)
	{
		let project = context.Project;
		if (project == null)
			return null;
		var target = group;
		if (target == null)
		{
			let root = project.SourceDb.RootGroup;
			target = root.GetGroup("Materials");
			if (target == null)
				target = root.CreateGroup("Materials");
		}
		if (target == null)
			return null;

		let name = target.UniqueInstanceName("Material", .. scope .());
		let instance = target.CreateInstance(name, typeof(MaterialAsset).GetFullName(.. scope .()));
		if (instance == null)
			return null;

		let built = unlit ? MaterialPresets.CreateUnlit(name) : MaterialPresets.CreatePbr(name);
		defer delete built;
		let asset = scope MaterialAsset();
		MaterialSource.FromMaterial(built, .(), asset.Source);
		if (!(instance.WriteObject(asset) case .Ok))
			return null;
		GlobalLog(.Information, "Editor: created {} material '{}'", unlit ? "unlit" : "PBR", instance.GetPath(.. scope .()));
		context.RequestCook(false); // pickable as soon as the product lands
		return instance;
	}
}
