using System;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Content;
using Sedulous.Scene;
using Sedulous.Scene.Resource;
using Sedulous.Engine.Render;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Scene;

/// New scene and prefab assets: a scene seeded with a directional sun under Scenes/, and a
/// prefab with a single root entity under Prefabs/. Both answer the instance, borrowed.
static class SceneAssetCreators
{
	public static Instance CreatePrefabInstance(EditorContext context, Group target = null)
	{
		let project = context.Project;
		if (project == null)
			return null;
		let prefabs = GroupFor(project, target, "Prefabs");
		if (prefabs == null)
			return null;

		let name = prefabs.UniqueInstanceName("Prefab", .. scope .());
		let instance = prefabs.CreateInstance(name, typeof(PrefabDocument).GetFullName(.. scope .()));
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

	public static Instance CreateSceneInstance(EditorContext context, Group target = null)
	{
		let project = context.Project;
		if (project == null)
			return null;
		let scenes = GroupFor(project, target, "Scenes");
		if (scenes == null)
			return null;

		let name = scenes.UniqueInstanceName("Scene", .. scope .());
		let instance = scenes.CreateInstance(name, typeof(SceneDocument).GetFullName(.. scope .()));
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

	/// `target`, or the named group under the root, made when missing.
	private static Group GroupFor(EditorProject project, Group target, StringView name)
	{
		if (target != null)
			return target;
		let root = project.SourceDb.RootGroup;
		var group = root.GetGroup(name);
		if (group == null)
			group = root.CreateGroup(name);
		return group;
	}
}
