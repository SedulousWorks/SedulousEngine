using System;
using Sedulous.Core.Serialization;
using Sedulous.Resource;

namespace Sedulous.Scene.Resource;

/// A field naming a scene (a level's exit, the next course): its id, which a level load takes.
///
/// Not a Ref<T>: a scene is read once per load, whole, so nothing binds or caches it, and a
/// reference to one never loads it. It is an id reference ([IdReference]), so the inspector
/// offers scenes for it, an agent sets it by guid, and a pruned export keeps the scene it names
/// (from a reflected component). Stored as its guid alone.
[IdReference(typeof(SceneDocument)), Reflect(.NonStaticFields)]
struct SceneRef
{
	/// The scene's id; nil names none.
	public Guid Id;

	/// Names none.
	public this()
	{
		Id = Guid.Empty;
	}

	public this(Guid id)
	{
		Id = id;
	}

	/// Whether it names a scene.
	public bool IsSet => Id != Guid.Empty;

	public void Serialize(ISerializer ar) mut
	{
		Sedulous.Core.Serialization.Serialize(ar, ref Id);
	}
}
