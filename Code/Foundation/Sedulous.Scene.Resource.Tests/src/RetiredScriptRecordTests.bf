using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Logging;
using Sedulous.Scene;
using Sedulous.Scene.Resource;
using Sedulous.Xml;
using Sedulous.Xml.Serialization;

namespace Sedulous.Scene.Resource.Tests;

/// A stream written while the engine ran scripts (version 3) may carry a Script component's
/// records and the scene's script settings block. It still reads, the script records dropped
/// with a warning that says why and every other record as before, and saves at the current
/// version without them; at the current version a `script` record is any record this build has no code for.
class RetiredScriptRecordTests
{
	private const String cOwner = "6d1c1a52-3a51-4f0e-9a1b-2a6c7d8e9f01";

	/// A Script component's record as a version 3 stream stored it.
	private const String cScriptComponent = """
		<object><string name="owner">6d1c1a52-3a51-4f0e-9a1b-2a6c7d8e9f01</string><string name="type">script</string>
		<object name="data"><array name="behaviors" count="0"/></object></object>
		""";

	/// The scene's script settings block as a version 3 stream stored it.
	private const String cScriptSettings = """
		<object><string name="system">script</string>
		<array name="dataVersions" count="1"><u64 name="type">12464980982266880842</u64><u32 name="version">1</u32></array>
		<object name="settings"><string name="script">00000000-0000-0000-0000-000000000000</string>
		<bool name="enabled">true</bool><array name="overrides" count="0"/></object></object>
		""";

	/// Listens to the global log for warnings while a read runs, and puts back the logger it
	/// found when it stops (or goes, should a failed assert skip the stop).
	private class WarningListener
	{
		private RingLogger mRing = new .(64, .Warning) ~ delete _;
		private ILogger mPrevious = null;
		private bool mPreviousOwned = false;
		private bool mListening = true;

		public this()
		{
			mPrevious = DetachGlobalLogger(out mPreviousOwned);
			InitGlobalLogger(mRing, false);
		}

		public ~this()
		{
			if (mListening)
				Restore();
		}

		/// Stops listening, appending each warning heard to `outText`, one a line.
		public void Stop(String outText)
		{
			if (mListening)
				Restore();
			for (int i < mRing.Count)
			{
				mRing.GetMessage(i, outText);
				outText.Append('\n');
			}
		}

		private void Restore()
		{
			bool ringOwned;
			DetachGlobalLogger(out ringOwned);
			if (mPrevious != null)
				InitGlobalLogger(mPrevious, mPreviousOwned);
			mPrevious = null;
			mListening = false;
		}
	}

	private static void ReplaceFirst(String text, StringView from, StringView to)
	{
		let at = text.IndexOf(from);
		Test.Assert(at >= 0, scope $"the stream carries {from}");
		if (at < 0)
			return;
		text.Remove(at, from.Length);
		text.Insert(at, to);
	}

	/// The stream's header at `version`: the first version element is the header's.
	private static void StampVersion(String text, uint32 version)
	{
		ReplaceFirst(text, scope $"<u32 name=\"version\">{SceneStreamFormat.cVersion}</u32>",
			scope $"<u32 name=\"version\">{version}</u32>");
	}

	/// A scene of a Player (its Health and its Ammo) and the world's settings, written by this
	/// build as text, then given the script records and stamped `version`.
	private static void LegacyScene(uint32 version, String outText)
	{
		let source = scope Scene();
		source.SetName("old");
		let health = source.AddSystem<HealthManager>();
		let ammo = source.AddSystem<AmmoManager>();
		let world = source.AddSystem<WorldSystem>();
		world.Settings.Gravity = -2.5f;
		let player = source.CreateEntity(Guid.Parse(cOwner).Get(), "Player");
		health.Add(player).Value = 42.0f;
		ammo.Add(player).Rounds = 7;

		let serializer = scope XmlSerializer();
		SceneSerializer.SerializeScene(serializer, source, .Referenced, true, .Text);
		Test.Assert(serializer.IsOk);
		serializer.GetOutput(outText);

		StampVersion(outText, version);
		ReplaceFirst(outText, "<array name=\"components\" count=\"2\">",
			scope $"<array name=\"components\" count=\"3\">{cScriptComponent}");
		ReplaceFirst(outText, "<array name=\"systemSettings\" count=\"1\">",
			scope $"<array name=\"systemSettings\" count=\"2\">{cScriptSettings}");
	}

	/// Reads `text` into `target` through the scene reader, as a page opens a source scene.
	private static bool ReadText(StringView text, Scene target)
	{
		let document = scope XmlDocument();
		Test.Assert(document.Parse(text) == .Ok, "the stream parses as XML");
		let reader = scope XmlSerializer(document);
		SceneSerializer.SerializeScene(reader, target, .Referenced, true, .Text);
		return reader.IsPayloadOk;
	}

	private static void WriteText(Scene scene, String outText)
	{
		let serializer = scope XmlSerializer();
		SceneSerializer.SerializeScene(serializer, scene, .Referenced, true, .Text);
		Test.Assert(serializer.IsOk);
		serializer.GetOutput(outText);
	}

	/// A version 3 scene reads with its Script component and its script block dropped, each
	/// with the warning that says scripts no longer run, not the one for a record kept unread:
	/// the Ammo record, whose manager this build also lacks, is kept and warned of as before.
	/// A save writes version 4 without the script records.
	[Test]
	public static void AVersion3ScenesScriptRecordsAreDroppedAsItReads()
	{
		let legacy = LegacyScene(3, .. scope .());

		let target = scope Scene();
		let health = target.AddSystem<HealthManager>();
		let world = target.AddSystem<WorldSystem>();
		let listener = scope WarningListener();
		let read = ReadText(legacy, target);
		let warnings = listener.Stop(.. scope .());
		Test.Assert(read, "a version 3 stream still reads");

		Test.Assert(target.Name == "old");
		let player = target.FindEntityByName("Player");
		Test.Assert(player.IsAssigned);
		Test.Assert(health.Get(player).Value == 42.0f);
		Test.Assert(world.Settings.Gravity == -2.5f);
		Test.Assert(target.UnresolvedComponents.Length == 1, "the script record dropped, the Ammo kept");
		Test.Assert(target.UnresolvedComponents[0].TypeId == "test.Ammo");
		Test.Assert(target.UnresolvedSettingsRecords.IsEmpty, "the script block dropped");
		Test.Assert(warnings.Contains("test.Ammo") && !warnings.Contains("'script'"), warnings);
		Test.Assert(warnings.Contains("SceneSerializer: scripts no longer run") && warnings.Contains("script component records were dropped"), warnings);
		Test.Assert(warnings.Contains("script settings were dropped"), warnings);

		let saved = WriteText(target, .. scope .());
		Test.Assert(saved.Contains(scope $"<u32 name=\"version\">{SceneStreamFormat.cVersion}</u32>"));
		Test.Assert(!saved.Contains("<string name=\"type\">script</string>"), "no Script component written back");
		Test.Assert(!saved.Contains("<string name=\"system\">script</string>"), "no script block written back");
		Test.Assert(saved.Contains("<string name=\"type\">test.Ammo</string>"), "the Ammo record written back");

		// And the saved scene reads back the same.
		let again = scope Scene();
		let againHealth = again.AddSystem<HealthManager>();
		again.AddSystem<WorldSystem>();
		Test.Assert(ReadText(saved, again));
		Test.Assert(againHealth.Get(again.FindEntityByName("Player")).Value == 42.0f);
		Test.Assert((again.UnresolvedComponents.Length == 1) && again.UnresolvedSettingsRecords.IsEmpty);
	}

	/// At the current version a `script` record is not retired: like any other record this
	/// build has no code for, it is kept unread.
	[Test]
	public static void AScriptRecordAtTheCurrentVersionIsKeptAsAnyUnknownRecord()
	{
		let current = LegacyScene(SceneStreamFormat.cVersion, .. scope .());

		let target = scope Scene();
		target.AddSystem<HealthManager>();
		target.AddSystem<WorldSystem>();
		let listener = scope WarningListener();
		let read = ReadText(current, target);
		let warnings = listener.Stop(.. scope .());
		Test.Assert(read);

		Test.Assert(target.UnresolvedComponents.Length == 2, "the script record and the Ammo kept");
		var script = false;
		for (let record in target.UnresolvedComponents)
		{
			if (record.TypeId == "script")
				script = true;
		}
		Test.Assert(script);
		Test.Assert((target.UnresolvedSettingsRecords.Length == 1) && (target.UnresolvedSettingsRecords[0].SystemId == "script"));
		Test.Assert(warnings.Contains("'script'"), warnings);
	}

	/// A version older than the oldest read, or newer than this build writes, is refused at the
	/// header.
	[Test]
	public static void AVersionOutsideTheReadRangeIsRefused()
	{
		Test.Assert(SceneStreamFormat.cMinReadVersion == 3);
		Test.Assert(SceneStreamFormat.cVersion == 4);
		uint32[2] refused = .(2, 5);
		for (let version in refused)
		{
			let text = LegacyScene(version, .. scope .());
			let target = scope Scene();
			target.AddSystem<HealthManager>();
			Test.Assert(!ReadText(text, target), scope $"version {version} refused");
			Test.Assert(target.EntityCount == 0, "nothing read past the header");
		}
	}

	/// A version 3 prefab payload's Script component is skipped as it spawns, with the warning
	/// that says scripts no longer run; the instance spawns with its other components, and a
	/// record of a type this build lacks is still skipped with its own warning.
	[Test]
	public static void AVersion3PrefabsScriptRecordIsSkippedWithAWarningAsItSpawns()
	{
		let template = scope Scene();
		let templateHealth = template.AddSystem<HealthManager>();
		let templateAmmo = template.AddSystem<AmmoManager>();
		let root = template.CreateEntity(Guid.Parse(cOwner).Get(), "Turret");
		templateHealth.Add(root).Value = 200.0f;
		templateAmmo.Add(root).Rounds = 30;

		let captured = scope MemoryStream();
		Test.Assert(PrefabCapture.Capture(template, root, captured, .Text) case .Ok);
		let text = scope String(StringView((char8*)captured.Bytes.Ptr, captured.Bytes.Length));
		StampVersion(text, 3);
		ReplaceFirst(text, "<array name=\"components\" count=\"2\">",
			scope $"<array name=\"components\" count=\"3\">{cScriptComponent}");
		let payload = scope MemoryStream();
		payload.Write(.((uint8*)text.Ptr, text.Length));
		payload.Seek(0, .Begin);

		let target = scope Scene();
		let health = target.AddSystem<HealthManager>();
		let listener = scope WarningListener();
		let spawned = PrefabSpawn.Spawn(target, payload, .(0xABCD, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1));
		let warnings = listener.Stop(.. scope .());

		Test.Assert(spawned.IsAssigned, "a version 3 payload still spawns");
		Test.Assert(health.Get(spawned).Value == 200.0f);
		Test.Assert(warnings.Contains("test.Ammo") && !warnings.Contains("'script'"), warnings);
		Test.Assert(warnings.Contains("PrefabSpawn: scripts no longer run") && warnings.Contains("script component records were dropped"), warnings);
	}
}
