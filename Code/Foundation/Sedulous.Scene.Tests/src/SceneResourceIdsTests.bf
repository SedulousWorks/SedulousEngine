using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Resource;

namespace Sedulous.Scene.Tests;

/// A product type for the references below; nothing builds it.
class HeldProduct
{
}

/// A component holding a reference, as a real one does.
[Reflect(.NonStaticFields)]
struct Skin
{
	public Ref<HeldProduct> Texture;
	public List<Ref<HeldProduct>> Extras;

	public this()
	{
		Texture = .(Guid.Empty);
		Extras = null;
	}
}

class SkinManager : ComponentManager<Skin>
{
}

/// What a scene answers a resource manager's holder with: the ids its components reference, as
/// they are now (a reference re-pointed after binding included), for every live scene, and none
/// once the scene is gone.
class SceneResourceIdsTests
{
	[Test]
	public static void ALiveScenesComponentsNameTheirResourcesUntilTheSceneGoes()
	{
		let first = Guid.Create();
		let extra = Guid.Create();
		let repointed = Guid.Create();
		let scene = new Scene("held");
		let manager = scene.AddSystem<SkinManager>();
		let entity = scene.CreateEntity("a");
		let skin = manager.Add(entity);
		skin.Texture = .(first);
		let extras = scope List<Ref<HeldProduct>>();
		extras.Add(.(extra));
		skin.Extras = extras;

		let held = scope HashSet<Guid>();
		Scene.CollectLiveResourceIds(held);
		Test.Assert(held.Contains(first) && held.Contains(extra));

		// Re-pointed by any path: the next answer has the new id, not the old.
		skin.Texture.SetId(repointed);
		held.Clear();
		Scene.CollectLiveResourceIds(held);
		Test.Assert(held.Contains(repointed) && !held.Contains(first));

		skin.Extras = null; // the list is the test's
		delete scene;
		held.Clear();
		Scene.CollectLiveResourceIds(held);
		Test.Assert(!held.Contains(repointed) && !held.Contains(extra), "a gone scene names nothing");
	}
}
