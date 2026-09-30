using System;
using System.Collections;
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
using Sedulous.Editor.Core;
using Sedulous.Editor.Project;

namespace Sedulous.Tools.Editor;

/// The starter content a new project gets, and the primitive mesh creators: the Roboto
/// font as the project's default UI font, the BlueSky environment, and the primitives.
/// Composed here because only the executable links every asset type.
static class EditorSeed
{
	/// --seed-primitives: every primitive rather than the three a new project starts with.
	public static bool SeedAllPrimitives = false;

	/// The engine data root the baseline assets come from.
	public static String DataRoot = new .() ~ delete _;

	private static void BaselineAssetPath(StringView relative, String outPath)
	{
		DataPath(DataRoot, PathJoin("Assets", relative, .. scope .()), outPath);
	}

	/// Seeds a project the manager just created: the font, the sky and the primitives.
	public static void SeedNewProject(EditorContext ctx, EditorProject project)
	{
		let root = project.SourceDb.RootGroup;
		let importContext = scope ImportContext(project.SourcesRoot(.. scope .()));
		{
			let source = BaselineAssetPath("fonts/roboto/Roboto-Regular.ttf", .. scope .());
			let copied = scope String();
			if (ImportPaths.CopyIntoSources(importContext, source, copied) case .Ok)
			{
				var fonts = root.GetGroup("Fonts");
				if (fonts == null)
					fonts = root.CreateGroup("Fonts");
				if (let instance = fonts.CreateInstance("Roboto", typeof(FontAsset).GetFullName(.. scope .())))
				{
					let asset = scope FontAsset();
					asset.FileName.Set(copied);
					asset.Family.Set("Roboto");
					if (instance.WriteObject(asset) case .Ok)
						project.Settings.DefaultUiFontId = instance.Id;
				}
			}
			else
				GlobalLog(.Warning, "Editor: starter font missing ({}), the new project has no default UI font", source);
		}
		{
			let source = BaselineAssetPath("environment/BlueSky.hdr", .. scope .());
			let copied = scope String();
			if (ImportPaths.CopyIntoSources(importContext, source, copied) case .Ok)
			{
				var env = root.GetGroup("Environment");
				if (env == null)
					env = root.CreateGroup("Environment");
				if (let instance = env.CreateInstance("BlueSky", typeof(TextureAsset).GetFullName(.. scope .())))
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
		if (SeedAllPrimitives)
		{
			GeometryCreators.CreatePrimitive(meshes, "Cylinder", Primitives.Cylinder());
			GeometryCreators.CreatePrimitive(meshes, "Cone", Primitives.Cone());
			GeometryCreators.CreatePrimitive(meshes, "Torus", Primitives.Torus());
		}
		GlobalLog(.Information, "Editor: starter content seeded (font/sky/primitives{})", SeedAllPrimitives ? ", all primitives" : "");
	}
}
