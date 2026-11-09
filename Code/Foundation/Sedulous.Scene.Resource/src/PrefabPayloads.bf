using System;
using System.Collections;
using Sedulous.Core.IO;
using Sedulous.Core.Logging;
using Sedulous.Resource;

namespace Sedulous.Scene.Resource;

/// Prefab payloads from the loaded prefabs of a resource manager: what a runtime spawn and a
/// scene load read, in place of the content database, with Resolver for the prefabs a payload
/// nests.
///
/// Each prefab is its own cached handle, bound when first asked for (synchronously, so a spawn
/// never waits a frame for it), so an edit of an inner prefab reaches every placement of it with
/// no dependency link between the two.
///
/// A payload opened here stays OPEN until its stream is deleted, which is when the spawn reading
/// it has finished. A prefab asked for while it is already open is nesting itself (a bad edit, or
/// two prefabs naming each other), and is refused rather than spawned again; so is a chain of open
/// prefabs cMaxDepth deep. Scope one of these around a spawn or a load: the manager is BORROWED,
/// and every stream opened here must be deleted before this goes.
class PrefabPayloads
{
	/// Deeper than any honest nesting; a chain this deep is a cycle the id check did not see.
	public const int cMaxDepth = 16;

	private ResourceManager mResources;
	/// The prefabs whose payloads are open, outermost first.
	private List<Guid> mOpen = new .() ~ delete _;
	private ScenePrefabs.PayloadResolver mResolver ~ delete _;

	public this(ResourceManager resources)
	{
		mResources = resources;
		mResolver = new (id) => Open(id);
	}

	/// Hands back Open's payloads, for PrefabSpawn and ScenePrefabs: the spawn deletes each
	/// stream when done with it. Owned here.
	public ScenePrefabs.PayloadResolver Resolver => mResolver;

	/// How many payloads are open now.
	public int Depth => mOpen.Count;

	/// The prefab, bound through the manager when it is not yet; null when it does not load
	/// (an unknown id, a record that is not a prefab, one evicted).
	public PrefabResource Load(Guid prefabId)
	{
		if ((mResources == null) || (prefabId == Guid.Empty))
			return null;
		return mResources.Bind<PrefabResource>(prefabId).Get;
	}

	/// The prefab's payload, open until the stream is deleted; THE CALLER OWNS it. Null, with a
	/// warning, when the prefab does not load, is open already (it nests itself), or the open
	/// chain is cMaxDepth deep.
	public IStream Open(Guid prefabId)
	{
		if (mOpen.Contains(prefabId))
		{
			GlobalLog(.Warning, "PrefabPayloads: prefab {} nests itself, its nested instance was refused", prefabId);
			return null;
		}
		if (mOpen.Count >= cMaxDepth)
		{
			GlobalLog(.Warning, "PrefabPayloads: prefab {} is nested deeper than {}, refused", prefabId, cMaxDepth);
			return null;
		}

		let prefab = Load(prefabId);
		if (prefab == null)
			return null;

		let stream = (PrefabPayloadStream)prefab.OpenPayload();
		stream.[Friend]OpenedIn(this, prefabId);
		mOpen.Add(prefabId);
		return stream;
	}

	/// A stream Open handed out was deleted: its spawn is done with the prefab.
	private void Closed(Guid prefabId)
	{
		let at = mOpen.LastIndexOf(prefabId);
		if (at >= 0)
			mOpen.RemoveAt(at);
	}
}
