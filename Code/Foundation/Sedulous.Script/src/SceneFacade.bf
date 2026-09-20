using System;
using System.Collections;
using Sedulous.Scene;

namespace Sedulous.Script;

/// The base of a scene facade: the scene it fronts, set when the registry makes it.
abstract class SceneFacade
{
	/// BORROWED: the facade lives no longer than its scene.
	public Scene Scene { get; private set; }

	/// Nothing by default; a facade that caches a system looks it up here.
	protected virtual void OnAttached() {}

	private void Attach(Scene scene)
	{
		Scene = scene;
		OnAttached();
	}
}

/// The facades per scene: made on first use, one of each type per scene, released with
/// the scene by whoever owns the scene's scripting, the script scene system.
static class SceneFacades
{
	private static Dictionary<Scene, List<SceneFacade>> sByScene = new .() ~ { for (let kv in _) DeleteContainerAndItems!(kv.value); delete _; };

	/// The scene's facade of type T, made if it has none. Null for a null scene.
	public static T Resolve<T>(Scene scene) where T : SceneFacade, new, delete
	{
		if (scene == null)
			return null;
		List<SceneFacade> facades;
		if (!sByScene.TryGetValue(scene, out facades))
		{
			facades = new .();
			sByScene[scene] = facades;
		}
		for (let f in facades)
		{
			if (let found = f as T)
				return found;
		}
		let made = new T();
		made.[Friend]Attach(scene);
		facades.Add(made);
		return made;
	}

	/// Frees the scene's facades: the scene is going.
	public static void Release(Scene scene)
	{
		if ((scene != null) && sByScene.GetAndRemove(scene) case .Ok(let kv))
			DeleteContainerAndItems!(kv.value);
	}

	public static int CountFor(Scene scene)
	{
		if ((scene != null) && sByScene.TryGetValue(scene, let facades))
			return facades.Count;
		return 0;
	}
}
