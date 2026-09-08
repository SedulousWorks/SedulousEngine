using System;
using System.Collections;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Resource;
using Sedulous.Xml.Serialization;

namespace Sedulous.Scene.Resource;

/// A scene as a content instance: a small document primary, and the world in a data stream.
///
/// A SOURCE saves as text, because it is diffed, merged and occasionally hand edited by
/// people. Export transcodes it to the binary wire for the player. One serialization path
/// feeds both, so the two can never come to describe different worlds.
static class SceneStorage
{
	private const String cStreamName = "scene";

	/// Reads the instance's scene stream into `scene`, which must ALREADY have its
	/// component managers: load deserializes into them rather than creating them.
	public static Result<void, ErrorCode> LoadScene(Instance instance, Scene scene)
	{
		let stream = instance.ReadData(cStreamName);
		if (stream == null)
			return .Err(.NotFound);
		defer delete stream;

		let reader = scope SceneStreamReader();
		if (!(reader.Open(stream) case .Ok(let ar)))
			return .Err(.Internal);

		SceneSerializer.SerializeScene(ar, scene, .Referenced, true, reader.Encoding);
		return .Ok;
	}

	public static Result<void, ErrorCode> SaveScene(Scene scene, Instance instance)
	{
		let document = scope SceneDocument();
		document.Name.Set(scene.Name);
		if (instance.WriteObject(document) case .Err(let error))
			return .Err(error);

		return WriteSceneStream(scene, instance, true);
	}

	/// The prefab twin.
	///
	/// A prefab is a SINGLE ROOTED subtree. A multi root layout is refused rather than
	/// saved, because a template whose capture path would silently drop the sibling roots
	/// is worse than no template.
	///
	/// Referenced and with NO settings: a nested instance persists as a record rather than
	/// flattening into plain entities, and a prefab is a subtree template rather than a
	/// world, so it carries nobody's settings into whatever scene it is spawned in.
	public static Result<void, ErrorCode> SavePrefab(Scene scene, Instance instance)
	{
		int rootCount = 0;
		var root = scene.FirstRoot;
		while (root.IsAssigned)
		{
			rootCount++;
			root = scene.GetNextSibling(root);
		}
		if (rootCount > 1)
			return .Err(.InvalidArgument);

		// A prefab whose edit scene contains an instance of ITSELF would reference itself
		// forever.
		var selfReference = false;
		let instanceId = instance.Id;
		scene.ForEachPrefabInstance(scope [&](state) =>
		{
			if (state.PrefabId == instanceId)
				selfReference = true;
		});
		if (selfReference)
			return .Err(.InvalidArgument);

		let document = scope PrefabDocument();
		document.Name.Set(scene.Name);
		if (instance.WriteObject(document) case .Err(let error))
			return .Err(error);

		return WriteSceneStream(scene, instance, false);
	}

	private static Result<void, ErrorCode> WriteSceneStream(Scene scene, Instance instance,
		bool includeSettings)
	{
		let serializer = scope XmlSerializer();
		SceneSerializer.SerializeScene(serializer, scene, .Referenced, includeSettings, .Text);
		if (!serializer.IsOk)
			return serializer.Status;

		let text = scope String();
		serializer.GetOutput(text);
		return instance.WriteData(cStreamName, .((uint8*)text.Ptr, text.Length), .Text);
	}
}
