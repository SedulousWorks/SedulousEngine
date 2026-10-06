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

namespace Sedulous.Editor.Project;

/// The starter content a new project is seeded with: the one function both the editor's New
/// Project and the MCP project_create run. A project made over MCP had none, so its exported
/// game showed no text: the engine's built-in font is not in a dist.
static class ProjectSeed
{
	/// Seeds `project` from the engine data root's Assets/: Roboto as a distance-field font set
	/// as the default UI font, the BlueSky sky, and the cube, sphere and plane (every primitive
	/// with `allPrimitives`). The settings are the caller's to save.
	public static void SeedStarterContent(EditorProject project, StringView dataRoot, bool allPrimitives = false)
	{
		let root = project.SourceDb.RootGroup;
		let importContext = scope ImportContext(project.SourcesRoot(.. scope .()));

		// The UI font, the one a shipped game binds. A distance-field font, so a 72 px title and
		// a 14 px caption both draw clean from its one bake.
		{
			let source = DataPath(dataRoot, "Assets/fonts/roboto/Roboto-Regular.ttf", .. scope .());
			let copied = scope String();
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

		// The default sky: BlueSky.hdr as an equirectangular skybox texture.
		{
			let source = DataPath(dataRoot, "Assets/environment/BlueSky.hdr", .. scope .());
			let copied = scope String();
			if (ImportPaths.CopyIntoSources(importContext, source, copied) case .Ok)
			{
				if (let instance = GroupNamed(root, "Environment").CreateInstance("BlueSky", typeof(TextureAsset).GetFullName(.. scope .())))
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
		if (allPrimitives)
		{
			GeometryCreators.CreatePrimitive(meshes, "Cylinder", Primitives.Cylinder());
			GeometryCreators.CreatePrimitive(meshes, "Cone", Primitives.Cone());
			GeometryCreators.CreatePrimitive(meshes, "Torus", Primitives.Torus());
		}
		GlobalLog(.Information, "Editor: starter content seeded (font/sky/primitives{})", allPrimitives ? ", all primitives" : "");
	}

	/// The group `name` under `root`, made if absent.
	private static Group GroupNamed(Group root, StringView name)
	{
		let group = root.GetGroup(name);
		return (group != null) ? group : root.CreateGroup(name);
	}
}
