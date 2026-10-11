using System;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Content;
using Sedulous.Scene.Resource;
using Sedulous.Engine.Render;
using Sedulous.Pipeline.Core;

namespace Sedulous.Scene.Pipeline;

/// The scene domain's New Asset creators: a scene seeded with a directional sun under Scenes/,
/// and a prefab with a single root entity under Prefabs/, unless a group was picked. The sun
/// needs the render engine's light component in a plain scene, not a device, which is why the
/// scene domain has a pipeline library of its own linking Engine.Render.
static class SceneCreators
{
	public static void Register(AssetCreatorRegistry registry)
	{
		registry.Register(new AssetCreator("Scene", "", typeof(SceneDocument), new (context) => CreateScene(context.Target, context.NameOr("Scene")), true).Under("Scenes"));
		registry.Register(new AssetCreator("Prefab", "", typeof(PrefabDocument), new (context) => CreatePrefab(context.Target, context.NameOr("Prefab"))).Under("Prefabs"));
	}

	public static Instance CreatePrefab(Group target, StringView baseName = "Prefab")
	{
		if (target == null)
			return null;
		let name = target.UniqueInstanceName(baseName, .. scope .());
		let instance = target.CreateInstance(name, typeof(PrefabDocument).GetFullName(.. scope .()));
		if (instance == null)
			return null;
		let doc = scope PrefabDocument();
		doc.Name.Set(name);
		if (!(instance.WriteObject(doc) case .Ok))
			return null;
		let seed = scope Sedulous.Scene.Scene("seed");
		let root = seed.CreateEntity(name);
		let buffer = scope MemoryStream();
		if (PrefabCapture.Capture(seed, root, buffer) case .Ok)
			instance.WriteData("scene", buffer.Bytes).IgnoreError();
		return instance;
	}

	public static Instance CreateScene(Group target, StringView baseName = "Scene")
	{
		if (target == null)
			return null;
		let name = target.UniqueInstanceName(baseName, .. scope .());
		let instance = target.CreateInstance(name, typeof(SceneDocument).GetFullName(.. scope .()));
		if (instance == null)
			return null;
		let doc = scope SceneDocument();
		doc.Name.Set(name);
		if (!(instance.WriteObject(doc) case .Ok))
			return null;
		// A directional sun, angled and strong enough that the first mesh dropped in casts a
		// shadow you can see: at the component default (1) and 60 degrees up, the sky's light
		// filled a short shadow in until it read as a smudge (user, 2026-10-11).
		let seeded = scope Sedulous.Scene.Scene(name);
		seeded.AddSystem<LightComponentManager>();
		let sun = seeded.CreateEntity("Sun");
		var t = Transform();
		// Shines along the entity's forward (-Z): 40 degrees down, travelling toward +X and +Z, so
		// a shadow falls toward a camera that looks at the origin from that side.
		t.Rotation = Quaternion.FromAxisAngle(.(0, 1, 0), -2.35619f) * Quaternion.FromAxisAngle(.(1, 0, 0), -0.698132f);
		seeded.SetLocalTransform(sun, t);
		let light = seeded.GetSystem<LightComponentManager>().Add(sun);
		light.CastsShadows = true;
		light.Intensity = 4.0f;
		SceneStorage.SaveScene(seeded, instance).IgnoreError();
		return instance;
	}
}
