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
		registry.Register(new AssetCreator("Scene", "", typeof(SceneDocument), new (context) => CreateScene(context.TargetOr("Scenes")), true));
		registry.Register(new AssetCreator("Prefab", "", typeof(PrefabDocument), new (context) => CreatePrefab(context.TargetOr("Prefabs"))));
	}

	public static Instance CreatePrefab(Group target)
	{
		if (target == null)
			return null;
		let name = target.UniqueInstanceName("Prefab", .. scope .());
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

	public static Instance CreateScene(Group target)
	{
		if (target == null)
			return null;
		let name = target.UniqueInstanceName("Scene", .. scope .());
		let instance = target.CreateInstance(name, typeof(SceneDocument).GetFullName(.. scope .()));
		if (instance == null)
			return null;
		let doc = scope SceneDocument();
		doc.Name.Set(name);
		if (!(instance.WriteObject(doc) case .Ok))
			return null;
		// A directional sun, angled so the first mesh dropped in is lit and shadowed. The
		// intensity stays the component default, so the value a user tunes is the one shown.
		let seeded = scope Sedulous.Scene.Scene(name);
		seeded.AddSystem<LightComponentManager>();
		let sun = seeded.CreateEntity("Sun");
		var t = Transform();
		t.Rotation = Quaternion.FromAxisAngle(.(0, 1, 0), 0.35f) * Quaternion.FromAxisAngle(.(1, 0, 0), -1.05f);
		seeded.SetLocalTransform(sun, t);
		let light = seeded.GetSystem<LightComponentManager>().Add(sun);
		light.CastsShadows = true;
		SceneStorage.SaveScene(seeded, instance).IgnoreError();
		return instance;
	}
}
