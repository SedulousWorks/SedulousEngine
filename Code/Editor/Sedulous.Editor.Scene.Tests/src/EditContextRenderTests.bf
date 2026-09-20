using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Resource;
using Sedulous.Scene;
using Sedulous.Materials;
using Sedulous.Editor.Core;
using Sedulous.Engine.Render;

namespace Sedulous.Editor.Scene.Tests;

/// The edit context over the engine's render components: a destroy-undo keeps a light's
/// values, and a container edit through the inspector's mutate path is one undo step.
class EditContextRenderTests
{
	[Test]
	public static void DestroyUndoRestoresLightComponentsAndTheirValues()
	{
		let scene = scope Scene();
		let lights = scene.AddSystem<LightComponentManager>();
		let commands = scope EditorCommandStack();
		let edit = scope SceneEditContext(scene, commands);

		let id = edit.CreateEntity("Sun");
		let light = lights.Add(edit.Resolve(id));
		light.Type = .Spot;
		light.Intensity = 3.5f;
		light.Range = 42.0f;
		light.CastsShadows = true;

		edit.DestroyEntity(id);
		Test.Assert(!edit.Resolve(id).IsAssigned);

		commands.Undo();
		let restored = edit.Resolve(id);
		Test.Assert(restored.IsAssigned);
		let back = lights.Get(restored);
		Test.Assert(back != null); // the component came back...
		Test.Assert(back.Type == .Spot); // ...with its exact values
		Test.Assert(Math.Abs(back.Intensity - 3.5f) < 1e-5f);
		Test.Assert(Math.Abs(back.Range - 42.0f) < 1e-5f);
		Test.Assert(back.CastsShadows);
	}

	[Test]
	public static void AContainerMutationPersistsAndUndoes()
	{
		let scene = scope Scene();
		let meshes = scene.AddSystem<MeshComponentManager>();
		let commands = scope EditorCommandStack();
		let edit = scope SceneEditContext(scene, commands);
		let a = edit.CreateEntity("Mesh");
		meshes.Add(edit.Resolve(a)); // empty materials
		let before = commands.Count;

		// The inspector's list rows edit through the target's mutate: snapshot, change,
		// restore, paste, so the change lands as ONE undo step.
		let target = scope ComponentTarget(edit, a, typeof(MeshComponent));
		target.Mutate(scope (p) => { ((MeshComponent*)p).Materials.Add(Ref<Material>(Guid())); });
		Test.Assert(meshes.Get(edit.Resolve(a)).Materials.Count == 1);
		Test.Assert(commands.Count == before + 1);

		commands.Undo();
		Test.Assert(meshes.Get(edit.Resolve(a)).Materials.Count == 0);
		commands.Redo();
		Test.Assert(meshes.Get(edit.Resolve(a)).Materials.Count == 1);

		// A non serializable component has nothing to snapshot, so a mutate is refused.
		let widgets = scene.AddSystem<WidgetManager>();
		widgets.Add(edit.Resolve(a));
		let plain = scope ComponentTarget(edit, a, typeof(Widget));
		let count = commands.Count;
		plain.Mutate(scope (p) => { ((Widget*)p).Speed = 9.0f; });
		Test.Assert(commands.Count == count);
	}
}
