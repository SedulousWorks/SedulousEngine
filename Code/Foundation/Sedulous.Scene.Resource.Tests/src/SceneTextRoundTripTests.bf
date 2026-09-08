using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Scene;
using Sedulous.Scene.Resource;
using Sedulous.Xml;
using Sedulous.Xml.Serialization;

namespace Sedulous.Scene.Resource.Tests;

/// The TEXT encoding, which is what a source scene is actually stored in.
///
/// Binary and text are the same serialization path, so most behaviour is proven once in
/// binary. What has to be proven here is the half that differs: records live in their own
/// element scopes, and a record whose code is absent is captured as raw markup and written
/// back out as markup.
class SceneTextRoundTripTests
{
	private static void WriteText(Scene scene, String outText)
	{
		let serializer = scope XmlSerializer();
		SceneSerializer.SerializeScene(serializer, scene, .Referenced, true, .Text);
		Test.Assert(serializer.IsOk);
		serializer.GetOutput(outText);
	}

	private static void ReadText(StringView text, Scene target)
	{
		let document = scope XmlDocument();
		Test.Assert(document.Parse(text) == .Ok, "the scene we just wrote parses as XML");
		let reader = scope XmlSerializer(document);
		SceneSerializer.SerializeScene(reader, target, .Referenced, true, .Text);
	}

	[Test]
	public static void AWholeSceneSurvivesATextRoundTrip()
	{
		let source = scope Scene();
		source.SetName("world");
		let sourceManager = source.AddSystem<HealthManager>();
		let sourceWorld = source.AddSystem<WorldSystem>();
		sourceWorld.Settings.Gravity = -3.5f;

		let player = source.CreateEntity("Player");
		let weapon = source.CreateEntity("Weapon");
		source.SetParent(weapon, player);
		sourceManager.Add(player).Value = 55.0f;

		let text = scope String();
		WriteText(source, text);

		let target = scope Scene();
		let manager = target.AddSystem<HealthManager>();
		let world = target.AddSystem<WorldSystem>();
		ReadText(text, target);

		Test.Assert(target.Name == "world");
		Test.Assert(target.EntityCount == 2);
		Test.Assert(target.FindEntityByPath("Player/Weapon").IsAssigned);
		Test.Assert(manager.Get(target.FindEntityByName("Player")).Value == 55.0f);
		Test.Assert(world.Settings.Gravity == -3.5f);
	}

	/// The record for an absent manager is captured as RAW MARKUP and written back
	/// untouched, then becomes a real component once its manager arrives. The text path
	/// has to re-parse the fragment, which the binary path does not, so it is worth its
	/// own walk.
	[Test]
	public static void AnAbsentManagersRecordSurvivesTheTextPathAndResolvesLater()
	{
		let source = scope Scene();
		let sourceManager = source.AddSystem<HealthManager>();
		let entity = source.CreateEntity("Player");
		sourceManager.Add(entity).Value = 42.0f;

		let text = scope String();
		WriteText(source, text);

		// A build WITHOUT the manager: the record has nowhere to go.
		let bare = scope Scene();
		ReadText(text, bare);
		Test.Assert(bare.UnresolvedComponents.Length == 1);
		Test.Assert(bare.UnresolvedComponents[0].Text, "captured as text");

		// The manager arrives, as a plugin loading would bring it.
		let manager = bare.AddSystem<HealthManager>();
		SceneResolve.ResolveUnresolvedComponents(bare, manager);

		Test.Assert(bare.UnresolvedComponents.IsEmpty, "the record was consumed");
		Test.Assert(manager.Count == 1);
		Test.Assert(manager.Get(bare.FindEntityByName("Player")).Value == 42.0f);
	}

	/// The same for a settings block, resolved through ResolveAllUnresolvedRecords rather
	/// than by naming the system.
	[Test]
	public static void AbsentSettingsSurviveTheTextPathAndResolveLater()
	{
		let source = scope Scene();
		source.AddSystem<HealthManager>();
		let sourceWorld = source.AddSystem<WorldSystem>();
		sourceWorld.Settings.Gravity = -1.25f;
		sourceWorld.Settings.Wind = .(4, 5, 6);

		let text = scope String();
		WriteText(source, text);

		let bare = scope Scene();
		bare.AddSystem<HealthManager>();
		ReadText(text, bare);
		Test.Assert(bare.UnresolvedSettingsRecords.Length == 1);

		let world = bare.AddSystem<WorldSystem>();
		SceneResolve.ResolveAllUnresolvedRecords(bare);

		Test.Assert(bare.UnresolvedSettingsRecords.IsEmpty);
		Test.Assert(world.Settings.Gravity == -1.25f);
		Test.Assert(world.Settings.Wind.Y == 5.0f);
	}

	/// A record whose ENTITY is gone resolves to nothing rather than attaching itself to
	/// whatever now holds that slot.
	[Test]
	public static void ARecordWhoseEntityIsGoneIsDroppedOnResolve()
	{
		let source = scope Scene();
		let sourceManager = source.AddSystem<HealthManager>();
		sourceManager.Add(source.CreateEntity("Doomed")).Value = 9.0f;

		let text = scope String();
		WriteText(source, text);

		let bare = scope Scene();
		ReadText(text, bare);
		Test.Assert(bare.UnresolvedComponents.Length == 1);

		bare.DestroyEntity(bare.FindEntityByName("Doomed"));

		let manager = bare.AddSystem<HealthManager>();
		SceneResolve.ResolveUnresolvedComponents(bare, manager);

		Test.Assert(bare.UnresolvedComponents.IsEmpty, "taken and discarded, not left to rot");
		Test.Assert(manager.Count == 0);
	}
}
