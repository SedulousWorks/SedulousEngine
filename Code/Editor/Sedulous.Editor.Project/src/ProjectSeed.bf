using System;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Logging;
using Sedulous.Content;
using Sedulous.VFS;
using Sedulous.Geometry;
using Sedulous.Geometry.Pipeline;
using Sedulous.Fonts.Pipeline;
using Sedulous.Texture.Pipeline;
using Sedulous.Pipeline.Core;
using Sedulous.Pipeline.Importer;
using Sedulous.Render.Pipeline;

namespace Sedulous.Editor.Project;

/// The starter content a new project is seeded with: the one function both the editor's New
/// Project and the MCP project_create run. A project made over MCP had none, so its exported
/// game showed no text: the engine's built-in font is not in a dist. And the content an older
/// project gains on its upgrade: its first quality level.
static class ProjectSeed
{
	/// A project saved before the quality levels (manifest version 10 or before) carried its scene
	/// pass's MSAA count, a quality level's now. Writes the project's first level, Quality/Default,
	/// at that count with every effect at High, lists it as the default and saves the manifest.
	/// The antialiasing a scene or profile asked for is not carried over: their loads say which
	/// asked for one, for the level to take it.
	public static void UpgradeToQualityLevels(EditorProject project, uint32 msaaSamples)
	{
		let settings = project.Settings;
		let typeName = typeof(RenderQualityAsset).GetFullName(.. scope .());
		let group = GroupNamed(project.SourceDb.RootGroup, "Quality");
		var instance = (group != null) ? group.GetInstance("Default") : null;
		if ((instance == null) && (group != null))
			instance = group.CreateInstance("Default", typeName);
		let asset = scope RenderQualityAsset();
		asset.Values.Label.Set("Default");
		asset.Values.MsaaSamples = msaaSamples;
		if ((instance == null) || (instance.TypeName != typeName) || (instance.WriteObject(asset) case .Err))
		{
			GlobalLog(.Error, "Project: the upgrade to quality levels could not write Quality/Default: the project runs at the engine's own highest level until it lists one");
			return;
		}
		settings.QualityLevelIds.Add(instance.Id);
		settings.DefaultQualityId = instance.Id;
		if (project.SaveSettings() case .Err)
		{
			GlobalLog(.Error, "Project: the upgrade to quality levels wrote Quality/Default but not the manifest");
			return;
		}
		GlobalLog(.Information, "Project: upgraded to quality levels: Quality/Default at {}x MSAA is the game's level; antialiasing is the level's now, so give it the one the scenes asked for (their loads say which)", msaaSamples);
	}

	/// Seeds `project` from the engine data root's Assets/: Roboto as a distance-field font set
	/// as the default UI font, a 1K Poly Haven sky (CC0) as the default sky, and every primitive
	/// (the cube, sphere, plane, cylinder, cone and torus). The settings are the caller's to save.
	public static void SeedStarterContent(EditorProject project, StringView dataRoot)
	{
		let root = project.SourceDb.RootGroup;
		let importContext = scope ImportContext(project.SourcesRoot(.. scope .()));
		project.CodeRoot(importContext.CodeRoot);

		// The UI font, the one a shipped game binds. A distance-field font, so a 72 px title and
		// a 14 px caption both draw clean from its one bake.
		{
			let source = DataPath(dataRoot, "Engine/Fonts/roboto/Roboto-Regular.ttf", .. scope .());
			let copied = scope String();
			importContext.Folder.Set("Fonts"); // in the group it is added to
			if (ImportPaths.CopyIntoSources(importContext, source, copied) case .Ok)
			{
				if (let instance = GroupNamed(root, "Fonts").CreateInstance("Roboto", typeof(FontAsset).GetFullName(.. scope .())))
				{
					let asset = scope FontAsset();
					asset.FileName.Set(copied);
					asset.Family.Set("Roboto");
					asset.Mode = .DistanceField;
					if (instance.WriteObject(asset) case .Ok)
						project.Settings.DefaultUiFontId = instance.Id;
				}
			}
			else
				GlobalLog(.Warning, "Editor: starter font missing ({}), the new project has no default UI font", source);
		}

		// The default sky: Poly Haven's Kloofendal 48d Partly Cloudy (Pure Sky) at 1K, CC0 (its
		// licence beside it), an equirectangular skybox texture. A 1024 x 512 HDR of 1.4 MB: the
		// 4096 x 2048 BlueSky (10 MB, nearly 3 s to cook) was more than a starting sky needs.
		{
			let source = DataPath(dataRoot,
				"Templates/kloofendal_48d_partly_cloudy_puresky/kloofendal_48d_partly_cloudy_puresky_1k.hdr", .. scope .());
			let copied = scope String();
			importContext.Folder.Set("Environment"); // in the group it is added to
			if (ImportPaths.CopyIntoSources(importContext, source, copied) case .Ok)
			{
				if (let instance = GroupNamed(root, "Environment").CreateInstance("Sky", typeof(TextureAsset).GetFullName(.. scope .())))
				{
					let asset = scope TextureAsset();
					asset.FileName.Set(copied);
					asset.SetupForEquirectangularSkybox();
					instance.WriteObject(asset).IgnoreError();
				}
			}
		}

		let meshes = AssetCreationContext(null, root, "").TargetOr("Meshes");
		GeometryCreators.CreatePrimitive(meshes, "Cube", Primitives.Cube());
		GeometryCreators.CreatePrimitive(meshes, "Sphere", Primitives.Sphere());
		GeometryCreators.CreatePrimitive(meshes, "Plane", Primitives.Plane());
		GeometryCreators.CreatePrimitive(meshes, "Cylinder", Primitives.Cylinder());
		GeometryCreators.CreatePrimitive(meshes, "Cone", Primitives.Cone());
		GeometryCreators.CreatePrimitive(meshes, "Torus", Primitives.Torus());
		GlobalLog(.Information, "Editor: starter content seeded (font/sky/primitives)");
	}

	/// The group `name` under `root`, made if absent.
	private static Group GroupNamed(Group root, StringView name)
	{
		let group = root.GetGroup(name);
		return (group != null) ? group : root.CreateGroup(name);
	}
}
