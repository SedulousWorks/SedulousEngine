namespace Sedulous.Engine.Core.Resources;

using System;
using System.Collections;
using Sedulous.Engine.Core;
using Sedulous.Serialization;
using Sedulous.Resources;

/// In-memory snapshot of a Scene's serialized state.
///
/// Used by editor Simulate / Play modes to roll the scene back to its
/// pre-run state after gameplay has mutated it. The snapshot is the same
/// OpenDDL text that SceneResourceManager.SaveScene would write to disk -
/// kept in memory instead of written through a mount.
///
/// Capture serializes via SceneSerializer (the same path the editor uses
/// when saving .scene files). Restore drains every entity in the target
/// Scene, then deserializes the snapshot back into the SAME Scene instance.
/// Anyone holding a reference to the Scene (the editor page, render
/// pipelines, subsystems with per-scene state) keeps a valid reference
/// across the snapshot/restore boundary.
///
/// Per-scene subsystem state (physics bodies, animation runners, audio
/// voices) is cleaned up automatically as DestroyEntity fires
/// OnEntityDestroyed on each component manager - the same chain that
/// runs when a user manually deletes entities.
public class SceneSnapshot
{
	private String mData = new .() ~ delete _;
	private ComponentTypeRegistry mTypeRegistry;
	private ISerializerProvider mProvider;
	private ResourceSystem mResourceSystem;

	/// Bytes captured. Useful for diagnostics / quick sanity checks.
	public int Size => mData.Length;

	/// Captures `scene` to an in-memory blob. The serializer dependencies
	/// are cached on the snapshot so Restore can be called with just the
	/// target Scene. Returns null if any of the required dependencies is
	/// null or the underlying serializer fails.
	public static SceneSnapshot Capture(Scene scene,
		ComponentTypeRegistry typeRegistry,
		ISerializerProvider provider,
		ResourceSystem resourceSystem)
	{
		if (scene == null || typeRegistry == null || provider == null)
			return null;

		let writer = provider.CreateWriter();
		if (writer == null)
			return null;
		defer delete writer;

		let serializer = scope SceneSerializer(typeRegistry, provider, resourceSystem);
		if (serializer.Save(scene, writer) != .Ok)
			return null;

		let snapshot = new SceneSnapshot();
		snapshot.mTypeRegistry = typeRegistry;
		snapshot.mProvider = provider;
		snapshot.mResourceSystem = resourceSystem;
		provider.GetOutput(writer, snapshot.mData);
		return snapshot;
	}

	/// Restores the scene to the captured state. Destroys every entity in
	/// `scene` first (firing the usual OnEntityDestroyed chain on each
	/// component manager, which drops per-entity subsystem state), then
	/// deserializes the snapshot back into the same Scene. The Scene
	/// instance, its modules, and any held-by-the-caller references stay
	/// valid; only entity-level state is replaced.
	///
	/// Should not be called from inside the scene's Update / FixedUpdate
	/// path - DestroyEntity defers during update so the drain wouldn't
	/// complete before deserialization.
	public Result<void> Restore(Scene scene)
	{
		if (scene == null || mData.IsEmpty)
			return .Err;

		// Drain entities. Copy first because DestroyEntity mutates the
		// underlying storage and the enumerator can't be trusted mid-walk.
		let entities = scope List<EntityHandle>();
		for (let entity in scene.Entities)
			entities.Add(entity);
		for (let entity in entities)
			scene.DestroyEntity(entity);

		// Deserialize from the captured blob into the same scene.
		let reader = mProvider.CreateReader(mData);
		if (reader == null)
			return .Err;
		defer delete reader;

		let serializer = scope SceneSerializer(mTypeRegistry, mProvider, mResourceSystem);
		if (serializer.Load(scene, reader) != .Ok)
			return .Err;

		return .Ok;
	}
}
