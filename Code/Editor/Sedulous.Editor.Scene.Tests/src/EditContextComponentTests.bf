using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Scene.Tests;

/// The component and settings verbs: add, remove, property edits by Variant and by raw
/// bytes, and the scene setting edits.
class EditContextComponentTests
{
	private static bool Near(float a, float b) => Math.Abs(a - b) < 1e-3f;

	[Test]
	public static void ComponentPropertyCommandsVariantAndRawEnumMergeAndUndo()
	{
		let scene = scope Scene();
		let widgets = scene.AddSystem<WidgetManager>();
		let commands = scope EditorCommandStack();
		let edit = scope SceneEditContext(scene, commands);
		let id = edit.CreateEntity("E");
		let type = widgets.ComponentType;

		edit.AddComponent(id, type);
		Test.Assert(widgets.HasComponent(edit.Resolve(id)));
		commands.Undo();
		Test.Assert(!widgets.HasComponent(edit.Resolve(id)));
		commands.Redo();
		Test.Assert(widgets.HasComponent(edit.Resolve(id)));
		edit.AddComponent(id, type); // already present: dropped
		let afterAdd = commands.Count;

		edit.SetComponentProperty<float>(id, type, "Speed", 2.0f);
		edit.SetComponentProperty<float>(id, type, "Speed", 3.5f);
		Test.Assert(commands.Count == afterAdd + 1); // merged
		Test.Assert(Near(widgets.Get(edit.Resolve(id)).Speed, 3.5f));
		commands.Undo();
		Test.Assert(Near(widgets.Get(edit.Resolve(id)).Speed, 1.0f));
		commands.Redo();

		edit.SetComponentProperty<Float3>(id, type, "Offset", .(1, 2, 3));
		Test.Assert(commands.Count == afterAdd + 2); // a different field: a new step
		Test.Assert(Near(widgets.Get(edit.Resolve(id)).Offset.Y, 2.0f));

		edit.SetComponentPropertyRaw(id, type, "Mode", (int64)TestMode.Fast);
		Test.Assert(widgets.Get(edit.Resolve(id)).Mode == .Fast);
		commands.Undo();
		Test.Assert(widgets.Get(edit.Resolve(id)).Mode == .Off);

		// A remove of a NON serializable component comes back through the field snapshot.
		widgets.Get(edit.Resolve(id)).Spin = true;
		edit.RemoveComponent(id, type);
		Test.Assert(!widgets.HasComponent(edit.Resolve(id)));
		commands.Undo();
		Test.Assert(widgets.HasComponent(edit.Resolve(id)));
		Test.Assert(Near(widgets.Get(edit.Resolve(id)).Speed, 3.5f));
		Test.Assert(widgets.Get(edit.Resolve(id)).Spin);
		Test.Assert(Near(widgets.Get(edit.Resolve(id)).Offset.Z, 3.0f));
	}

	[Test]
	public static void APropertyOfTheWrongTypeIsRefused()
	{
		let scene = scope Scene();
		let widgets = scene.AddSystem<WidgetManager>();
		let commands = scope EditorCommandStack();
		let edit = scope SceneEditContext(scene, commands);
		let id = edit.CreateEntity("E");
		edit.AddComponent(id, widgets.ComponentType);
		let before = commands.Count;

		edit.SetComponentProperty<int32>(id, widgets.ComponentType, "Speed", 4); // not a float
		Test.Assert(commands.Count == before);
		edit.SetComponentProperty<float>(id, widgets.ComponentType, "NoSuchField", 4.0f);
		Test.Assert(commands.Count == before);
		Test.Assert(Near(widgets.Get(edit.Resolve(id)).Speed, 1.0f));
	}

	[Test]
	public static void RemoveComponentUndoViaTheSerializationBlob()
	{
		let scene = scope Scene();
		let health = scene.AddSystem<HealthManager>();
		let commands = scope EditorCommandStack();
		let edit = scope SceneEditContext(scene, commands);
		let id = edit.CreateEntity("E");

		health.Add(edit.Resolve(id)).Amount = 42;
		edit.RemoveComponent(id, health.ComponentType);
		Test.Assert(!health.HasComponent(edit.Resolve(id)));
		commands.Undo();
		Test.Assert(health.HasComponent(edit.Resolve(id)));
		Test.Assert(health.Get(edit.Resolve(id)).Amount == 42); // full fidelity via the blob
	}

	[Test]
	public static void SceneSettingEditsAreUndoableCommandsAndMergeLikeScrubs()
	{
		let scene = scope Scene("s");
		let wind = scene.AddSystem<WindSystem>();
		let commands = scope EditorCommandStack();
		let edit = scope SceneEditContext(scene, commands);
		let type = typeof(WindSettings);

		edit.SetSceneSettingProperty<float>(type, "Speed", 2.0f);
		edit.SetSceneSettingProperty<float>(type, "Speed", 3.0f);
		Test.Assert(commands.Count == 1);
		Test.Assert(wind.Settings.Speed == 3.0f);

		commands.Undo();
		Test.Assert(wind.Settings.Speed == 1.0f);
		commands.Redo();
		Test.Assert(wind.Settings.Speed == 3.0f);

		edit.SetSceneSettingProperty<float>(typeof(Widget), "Speed", 9.0f); // no such system
		Test.Assert(commands.Count == 1);
	}

	[Test]
	public static void ASettingsBlockAppliesWholeAndUndoesToTheCapturedBytes()
	{
		let scene = scope Scene("s");
		let wind = scene.AddSystem<WindSystem>();
		let commands = scope EditorCommandStack();
		let edit = scope SceneEditContext(scene, commands);

		// A block captured at one value, applied after the live value moved on.
		wind.Settings.Speed = 7.0f;
		let blob = new List<uint8>();
		SceneSettingsBlock.Capture(wind, blob);
		wind.Settings.Speed = 1.0f;

		Test.Assert(edit.ApplySceneSettingsBlock(typeof(WindSettings), blob));
		Test.Assert(wind.Settings.Speed == 7.0f);
		commands.Undo();
		Test.Assert(wind.Settings.Speed == 1.0f);
		commands.Redo();
		Test.Assert(wind.Settings.Speed == 7.0f);
	}
}
