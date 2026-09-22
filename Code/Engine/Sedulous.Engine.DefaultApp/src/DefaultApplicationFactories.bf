using System;
using Sedulous.Animation.Resource;
using Sedulous.Audio.Resource;
using Sedulous.Core;
using Sedulous.Core.Serialization;
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
using Sedulous.Resource;
using Sedulous.Runtime.Client;
using Sedulous.Scene.Resource;
using Sedulous.Script.Resource;
using Sedulous.Shaders.Resource;
using Sedulous.Terrain.Resource;
using Sedulous.Vegetation.Resource;
using Sedulous.Texture.Resource;
using Sedulous.UI.Resource;

namespace Sedulous.Engine.DefaultApp;

/// The batteries: every cooked product type the engine understands, and a factory for each.
extension DefaultApplication
{
	/// The factories this application owns, freed with it. They are handed to a manager
	/// which only BORROWS them, so their lifetime is this application's rather than any
	/// manager's, and a manager attached later gets the same set.
	private System.Collections.List<Object> mFactories
		= new .() ~ DeleteContainerAndItems!(_);

	/// The product TYPES: a factory constructs a cooked product by the type name stored with
	/// it, so a reader that meets an unregistered name cannot build anything at all.
	///
	/// Every domain's registrar, so the set is complete rather than whichever subset the
	/// application happened to need. Registering into the GLOBAL registry, which is what a
	/// content database falls back to when it was given none.
	private void RegisterProductTypes()
	{
		AnimationResources.RegisterAll();
		AudioResources.RegisterAll();
		FontResources.RegisterAll();
		GeometryResources.RegisterAll();
		HeightfieldResources.RegisterAll();
		ImageResources.RegisterAll();
		InputResources.RegisterAll();
		ScriptResources.RegisterAll();
		MaterialResources.RegisterAll();
		ModelResources.RegisterAll();
		NavigationResources.RegisterAll();
		ParticleResources.RegisterAll();
		PhysicsResources.RegisterAll();
		SceneResources.RegisterAll();
		ShaderResources.RegisterAll();
		TerrainResources.RegisterAll();
		TextureResources.RegisterAll();
		UIResources.RegisterAll();
	}

	/// Adds one factory and keeps it alive for as long as this application is.
	private void AddOwnedFactory(ResourceManager resources, IResourceFactory factory)
	{
		mFactories.Add(factory);
		resources.AddFactory(factory);
	}

	/// Registers the standard set on a manager.
	///
	/// IDEMPOTENT per manager, and safe to run again for a manager attached after startup,
	/// which is how an editor hands one over late.
	private void RegisterStandardFactories(ResourceManager resources, IApplicationHost host)
	{
		AddOwnedFactory(resources, new StaticMeshFactory());
		AddOwnedFactory(resources, new SkinnedMeshFactory());
		AddOwnedFactory(resources, new MaterialFactory());
		AddOwnedFactory(resources, new SkeletonFactory());
		AddOwnedFactory(resources, new AnimationClipFactory());
		AddOwnedFactory(resources, new AnimationGraphFactory());
		AddOwnedFactory(resources, new PropertyAnimationClipFactory());
		AddOwnedFactory(resources, new ParticleEffectFactory());
		AddOwnedFactory(resources, new InputMapFactory());
		AddOwnedFactory(resources, new ScriptClassFactory());
		AddOwnedFactory(resources, new CollisionShapeFactory());
		AddOwnedFactory(resources, new NavigationZoneFactory());
		AddOwnedFactory(resources, new PhysicalMaterialFactory());
		AddOwnedFactory(resources, new AudioClipFactory());
		AddOwnedFactory(resources, new AudioBusLayoutFactory());
		AddOwnedFactory(resources, new SoundCueFactory());
		AddOwnedFactory(resources, new ModelFactory());
		AddOwnedFactory(resources, new UIDocumentFactory());
		AddOwnedFactory(resources, new UIThemeFactory());
		AddOwnedFactory(resources, new FontFactory());
		AddOwnedFactory(resources, new HeightfieldFactory());
		AddOwnedFactory(resources, new TerrainFactory());
		AddOwnedFactory(resources, new SplatWeightsFactory());
		AddOwnedFactory(resources, new VegetationMaskFactory());
		AddOwnedFactory(resources, new ImageFactory());

		// The textures are device backed, so they only register where there IS a device: a
		// headless application loads everything else and simply has no textures.
		let graphics = host.Graphics;
		if ((graphics != null) && (graphics.Raw != null))
			AddOwnedFactory(resources, new TextureFactory(graphics.Raw));
	}
}
