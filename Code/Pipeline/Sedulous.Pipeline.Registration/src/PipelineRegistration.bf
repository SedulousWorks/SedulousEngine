using System;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Script;
using Sedulous.Script.AngelScript;
using Sedulous.UI;
using Sedulous.UI.Gamekit;
using Sedulous.Animation.Resource;
using Sedulous.Audio.Resource;
using Sedulous.Fonts.Resource;
using Sedulous.Geometry;
using Sedulous.Heightfield.Resource;
using Sedulous.Image.Resource;
using Sedulous.Input.Resource;
using Sedulous.Materials.Resource;
using Sedulous.Model.Resource;
using Sedulous.Navigation.Resource;
using Sedulous.Particles.Resource;
using Sedulous.Physics.Resource;
using Sedulous.PropertyAnimation.Resource;
using Sedulous.Scene.Resource;
using Sedulous.Script.Resource;
using Sedulous.Shaders.Resource;
using Sedulous.Terrain.Resource;
using Sedulous.Texture.Resource;
using Sedulous.UI.Resource;
using Sedulous.Animation.Pipeline;
using Sedulous.Audio.Pipeline;
using Sedulous.Fonts.Pipeline;
using Sedulous.Geometry.Pipeline;
using Sedulous.Heightfield.Pipeline;
using Sedulous.Image.Pipeline;
using Sedulous.Input.Pipeline;
using Sedulous.Materials.Pipeline;
using Sedulous.ModelImporter;
using Sedulous.Navigation.Pipeline;
using Sedulous.Particles.Pipeline;
using Sedulous.Physics.Pipeline;
using Sedulous.Pipeline.Core;
using Sedulous.Pipeline.Importer;
using Sedulous.Pipeline.ScriptSurface;
using Sedulous.PropertyAnimation.Pipeline;
using Sedulous.Script.AngelScript.Pipeline;
using Sedulous.Script.Pipeline;
using Sedulous.Shaders.Pipeline;
using Sedulous.Terrain.Pipeline;
using Sedulous.Texture.Pipeline;
using Sedulous.UI.Pipeline;

namespace Sedulous.Pipeline.Registration;

/// The pipeline's COMPOSITION ROOT as a library.
///
/// Every host that cooks or imports, the cooker, the export packager, the editor, the
/// headless MCP server, needs the SAME set of builders, importers and type registrations.
/// Restating that set in each host's main duplicates it verbatim, and a builder added to two
/// of three copies is a silent gap: the cook works in the editor and is missing from the
/// export. This library links every pipeline module, which is its whole job and the
/// deliberate fan in point, and the hosts call its three entry points instead of keeping a
/// list.
///
/// The counts are tripwires the tests assert against: a new builder or importer bumps the
/// matching constant DELIBERATELY, and a lost registration then fails the test loudly.
static class PipelineRegistration
{
	public const int cBuilderCount = 26;
	public const int cImporterCount = 9;

	/// The pipeline surface the script cooks compile against, made by the type registration
	/// and released by Teardown.
	private static ScriptSurface sSurface = null;

	public static ScriptSurface Surface => sSurface;

	/// Registers every asset, product and resource type, the script backend and the per
	/// language cooks, into the global serializable and cook registries. A headless cook
	/// needs these because reading constructs a cooked product BY TYPE NAME. Once at
	/// startup, before a cook is planned. Touches no BuilderRegistry, which is
	/// RegisterAllBuilders, and registers nothing editor only, which stays host side.
	public static void RegisterPipelineTypes()
	{
		// The markup vocabulary the UI document cook validates against.
		MarkupLoader.Initialize();
		GamekitMarkup.Register();

		// The resource tier: every product a cooked file names.
		AnimationResources.RegisterAll();
		AudioResources.RegisterAll();
		FontResources.RegisterAll();
		GeometryResources.RegisterAll();
		HeightfieldResources.RegisterAll();
		ImageResources.RegisterAll();
		InputResources.RegisterAll();
		MaterialResources.RegisterAll();
		ModelResources.RegisterAll();
		NavigationResources.RegisterAll();
		ParticleResources.RegisterAll();
		PhysicsResources.RegisterAll();
		PropertyAnimationResources.RegisterAll();
		SceneResources.RegisterAll();
		ScriptResources.RegisterAll();
		ShaderResources.RegisterAll();
		TerrainResources.RegisterAll();
		TextureResources.RegisterAll();
		UIResources.RegisterAll();

		// The pipeline tier: every asset a source file is.
		AnimationPipeline.RegisterAll();
		AudioPipeline.RegisterAll();
		FontsPipeline.RegisterAll();
		GeometryPipeline.RegisterAll();
		HeightfieldPipeline.RegisterAll();
		ImagePipeline.RegisterAll();
		InputPipeline.RegisterAll();
		MaterialsPipeline.RegisterAll();
		ModelImporterPipeline.RegisterAll();
		NavigationPipeline.RegisterAll();
		ParticlesPipeline.RegisterAll();
		PhysicsPipeline.RegisterAll();
		PropertyAnimationPipeline.RegisterAll();
		ScriptPipeline.RegisterAll();
		ShadersPipeline.RegisterAll();
		TerrainPipeline.RegisterAll();
		TexturePipeline.RegisterAll();
		UIPipeline.RegisterAll();

		// The script languages and their cooks, against the pipeline surface.
		AngelScriptBackend.Register();
		if (sSurface == null)
		{
			sSurface = new ScriptSurface();
			PipelineScriptSurface.Populate(sSurface);
		}
		if (ScriptLanguageCooks.Find(AngelScriptBackend.cLanguage) == null)
			AngelScriptCook.Register(sSurface);
	}

	/// Releases what RegisterPipelineTypes made: the cooks and the surface they borrow.
	public static void Teardown()
	{
		ScriptLanguageCooks.Clear();
		delete sSurface;
		sSurface = null;
	}

	/// Fills `registry` with every asset builder the engine ships. Independent of
	/// RegisterPipelineTypes, though a cook needs both.
	public static void RegisterAllBuilders(BuilderRegistry registry)
	{
		registry.Register(new TextureAssetBuilder());
		registry.Register(new FontAssetBuilder());
		registry.Register(new ImageAssetBuilder());
		registry.Register(new HeightfieldAssetBuilder());
		registry.Register(new TerrainAssetBuilder());
		registry.Register(new SplatmapAssetBuilder());
		registry.Register(new StaticMeshAssetBuilder());
		registry.Register(new SkinnedMeshAssetBuilder());
		registry.Register(new SkeletonAssetBuilder());
		registry.Register(new AnimationClipAssetBuilder());
		registry.Register(new AnimationGraphAssetBuilder());
		registry.Register(new PropertyAnimationClipAssetBuilder());
		registry.Register(new MaterialAssetBuilder());
		registry.Register(new ShaderAssetBuilder());
		registry.Register(new ParticleEffectAssetBuilder());
		registry.Register(new InputMapAssetBuilder());
		registry.Register(new ModelManifestAssetBuilder());
		registry.Register(new CollisionShapeAssetBuilder());
		registry.Register(new PhysicalMaterialAssetBuilder());
		registry.Register(new NavigationZoneAssetBuilder());
		registry.Register(new UIDocumentAssetBuilder());
		registry.Register(new UIThemeAssetBuilder());
		registry.Register(new AudioClipAssetBuilder());
		registry.Register(new AudioBusLayoutAssetBuilder());
		registry.Register(new SoundCueAssetBuilder());
		registry.Register(new ScriptClassAssetBuilder());
	}

	/// Fills `registry` with every OS file importer the engine ships, the drag and drop
	/// and MCP import surface.
	public static void RegisterAllImporters(ImporterRegistry registry)
	{
		registry.Register(new TextureFileImporter());
		registry.Register(new ModelFileImporter());
		registry.Register(new UIFileImporter());
		registry.Register(new AudioFileImporter());
		registry.Register(new ScriptFileImporter());
		registry.Register(new FontAssetImporter());
		registry.Register(new ImageFileImporter());
		registry.Register(new HeightfieldFileImporter());
		registry.Register(new SplatmapFileImporter());
	}
}
