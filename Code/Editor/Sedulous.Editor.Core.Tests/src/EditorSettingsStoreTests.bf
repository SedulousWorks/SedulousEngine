using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Settings;
using Sedulous.Xml.Serialization;
using Sedulous.Editor.Core;
using Sedulous.Editor.Look;
using Sedulous.Editor.Project;
using Sedulous.Editor.Projects;

namespace Sedulous.Editor.Core.Tests;

/// The editor's user store: every section its registration names instantiable, and each one
/// surviving a round trip, older shapes of them included.
static class EditorSettingsStoreTests
{
	[Test]
	public static void EveryRegisteredSectionTypeIsInstantiable()
	{
		// A section the store cannot instantiate makes every later Load abort at it and
		// drop the sections after: the empty project list incident.
		// Every type the editor's registration puts in a table, asked of the table, not a list
		// kept by hand here: a hand list is what let the shortcut section land uncovered.
		let registry = scope SerializableRegistry();
		EditorSerializables.RegisterAll(registry);
		let ids = scope List<uint64>();
		registry.CopyIds(ids);
		for (let id in ids)
		{
			let made = registry.Create(id);
			Test.Assert(made != null, scope $"type id {id}");
			delete made;
		}
		// Export, ui, mcp, shortcuts (and its entry), recent projects (and its entry), at least.
		Test.Assert(ids.Count >= 8);
		for (let type in scope Type[](typeof(EditorShortcutSettings), typeof(ShortcutOverrideEntry), typeof(RecentProjectsSettings)))
			Test.Assert(registry.IsRegistered(TypeIdOf(type.GetFullName(.. scope .()))));
	}

	[Test]
	public static void TheMcpSectionRoundTripsAndAMintedTokenIsAFreshGuid()
	{
		EditorSerializables.RegisterAll();
		// Defaults: off, the documented port, no token yet.
		{
			let store = scope Settings();
			let mcp = store.Section<EditorMcpSettings>();
			Test.Assert(!mcp.Enabled);
			Test.Assert(mcp.Port == EditorMcpSettings.DefaultPort);
			Test.Assert(mcp.Token.IsEmpty);
		}
		let store = scope Settings();
		let mcp = store.Section<EditorMcpSettings>();
		mcp.Enabled = true;
		mcp.Port = 7500;
		EditorMcpSettings.GenerateToken(mcp.Token);
		Test.Assert(mcp.Token.Length == 36);
		Test.Assert(EditorMcpSettings.GenerateToken(.. scope .()) != mcp.Token); // every mint is a new secret

		let buffer = scope Sedulous.Core.IO.MemoryStream();
		let factory = XmlSerializerFactory();
		defer delete factory;
		Test.Assert(store.Save(buffer, factory) case .Ok);
		buffer.Seek(0, .Begin);
		let loaded = scope Settings();
		Test.Assert(loaded.Load(buffer, factory) case .Ok);
		let back = loaded.Find<EditorMcpSettings>();
		Test.Assert(back != null);
		Test.Assert(back.Enabled);
		Test.Assert(back.Port == 7500);
		Test.Assert(back.Token == mcp.Token);
	}

	[Test]
	public static void TheMcpSectionTakesThePreferencesFieldsRefusingABadPort()
	{
		let mcp = scope EditorMcpSettings();
		mcp.Token.Set("old");
		Test.Assert(mcp.ApplyFromPreferences(true, "7500", "new"));
		Test.Assert(mcp.Enabled);
		Test.Assert(mcp.Port == 7500);
		Test.Assert(mcp.Token == "new");
		// A port outside 1024..65535, or not a number, is refused and the port stands.
		Test.Assert(!mcp.ApplyFromPreferences(true, "80", "new"));
		Test.Assert(!mcp.ApplyFromPreferences(true, "70000", "new"));
		Test.Assert(!mcp.ApplyFromPreferences(true, "lots", "new"));
		Test.Assert(mcp.Port == 7500);
		// Disabling with an empty token: off, and the next enable mints a fresh secret.
		Test.Assert(mcp.ApplyFromPreferences(false, "7500", ""));
		Test.Assert(!mcp.Enabled);
		Test.Assert(mcp.Token.IsEmpty);
	}

	[Test]
	public static void AStoreWithEverySectionRoundTrips()
	{
		EditorSerializables.RegisterAll();
		let store = scope Settings();
		store.Section<EditorUiSettings>().UiScale = 1.2f;
		store.Section<EditorUiSettings>().Scheme.Set("light");
		store.Section<EditorUiSettings>().Accent.Set("#0f8a7e");
		store.Section<EditorUiSettings>().Density.Set("comfortable");
		store.Section<EditorUiSettings>().ReduceMotion = true;
		ProjectRegistry.TouchRecentProject(store, "/proj/a", "A", "0.1.0");
		let buffer = scope Sedulous.Core.IO.MemoryStream();
		let factory = XmlSerializerFactory();
		defer delete factory;
		Test.Assert(store.Save(buffer, factory) case .Ok);
		buffer.Seek(0, .Begin);
		let loaded = scope Settings();
		Test.Assert(loaded.Load(buffer, factory) case .Ok);
		let registry = loaded.Find<RecentProjectsSettings>();
		Test.Assert((registry != null) && (registry.Entries.Count == 1) && (registry.Entries[0].Name == "A"));
		let ui = loaded.Find<EditorUiSettings>();
		Test.Assert((ui != null) && (Math.Abs(ui.UiScale - 1.2f) < 1e-5f));
		Test.Assert(ui.Scheme == "light"); // the look's inputs (appended 2026-10-27)
		Test.Assert(ui.Accent == "#0f8a7e");
		Test.Assert(ui.Density == "comfortable");
		Test.Assert(ui.ReduceMotion);
	}

	/// The font section the editor kept before its fonts became its sheet's (the type is gone):
	/// its paths, under its old identity and version.
	private class LegacyFontSection : ISerializable
	{
		public const String cTypeName = "Sedulous.Editor.Core.EditorFontSettings";
		public String FontPath = new .() ~ delete _;
		public String MonoFontPath = new .() ~ delete _;

		public void Serialize(ISerializer ar)
		{
			BeginVersionedPayload(ar, TypeIdOf(cTypeName), 1);
			ar.BeginObject();
			Sedulous.Core.Serialization.Serialize(ar, "fontPath", FontPath);
			Sedulous.Core.Serialization.Serialize(ar, "monoFontPath", MonoFontPath);
			ar.EndObject();
			EndVersionedPayload(ar);
		}
	}

	/// A store still holding the font section loads: the section no type reads is kept aside (and
	/// written back, so an older build keeps its paths), and the sections after it read as ever.
	[Test]
	public static void AStoreStillHoldingTheFontSectionLoadsTheSectionsAfterIt()
	{
		EditorSerializables.RegisterAll();
		Test.Assert(GlobalSerializableRegistry.Create(TypeIdOf(LegacyFontSection.cTypeName)) == null, "no type reads it now");
		let factory = XmlSerializerFactory();
		defer delete factory;
		let buffer = scope Sedulous.Core.IO.MemoryStream();
		{
			let fonts = scope LegacyFontSection();
			fonts.FontPath.Set("/fonts/ui.ttf");
			let ui = scope EditorUiSettings();
			ui.UiScale = 1.25f;
			ui.Scheme.Set("light");
			let writing = factory(buffer, .Write);
			defer delete writing;
			let archive = writing.Serializer;
			uint32 count = 2;
			archive.Key("sections");
			archive.BeginArray(ref count);
			// The font section first, so a load that stopped at it would lose the UI's.
			archive.BeginObject();
			archive.Key("typeName");
			archive.Text(LegacyFontSection.cTypeName);
			archive.BeginFramedRegion();
			archive.Key("payload");
			archive.BeginObject();
			fonts.Serialize(archive);
			archive.EndObject();
			archive.EndFramedRegion();
			archive.EndObject();
			archive.BeginObject();
			archive.Key("typeName");
			archive.Text(typeof(EditorUiSettings).GetFullName(.. scope .()));
			archive.BeginFramedRegion();
			archive.Key("payload");
			archive.BeginObject();
			ISerializable uiPayload = ui;
			uiPayload.Serialize(archive);
			archive.EndObject();
			archive.EndFramedRegion();
			archive.EndObject();
			archive.EndArray();
			Test.Assert(archive.IsOk);
			writing.Flush(buffer);
		}

		buffer.Seek(0, .Begin);
		let loaded = scope Settings();
		Test.Assert(loaded.Load(buffer, factory) case .Ok);
		Test.Assert(loaded.UnknownSectionCount == 1, "kept aside, not refused");
		Test.Assert(loaded.SectionCount == 1);
		let ui = loaded.Find<EditorUiSettings>();
		Test.Assert(ui != null, "the section after it read");
		Test.Assert(Math.Abs(ui.UiScale - 1.25f) < 1e-5f);
		Test.Assert(ui.Scheme == "light");

		// Saved again, the kept section goes back out with its paths.
		let again = scope Sedulous.Core.IO.MemoryStream();
		Test.Assert(loaded.Save(again, factory) case .Ok);
		let text = scope String((char8*)again.Bytes.Ptr, again.Bytes.Length);
		Test.Assert(text.Contains(LegacyFontSection.cTypeName) && text.Contains("/fonts/ui.ttf"));
		again.Seek(0, .Begin);
		let reloaded = scope Settings();
		Test.Assert(reloaded.Load(again, factory) case .Ok);
		Test.Assert((reloaded.UnknownSectionCount == 1) && (reloaded.Find<EditorUiSettings>() != null));
	}

	/// The UI section as the editor saved it before the look's inputs: the scale and axis views
	/// only, under the section's identity (or the one it had before it moved) and version.
	private class LegacyUiSection : ISerializable
	{
		public float UiScale = 1.0f;
		public bool AutoOrthographic = true;
		public uint64 TypeId = EditorUiSettings.TypeId;

		public void Serialize(ISerializer ar)
		{
			BeginVersionedPayload(ar, TypeId, EditorUiSettings.DataVersion);
			ar.BeginObject();
			SerializeValue(ar, "uiScale", ref UiScale);
			SerializeValue(ar, "autoOrthographic", ref AutoOrthographic);
			ar.EndObject();
			EndVersionedPayload(ar);
		}
	}

	/// A settings file from before the look's inputs reads through the store: what it has comes
	/// back, the inputs it lacks are their defaults, and saved again it carries them.
	[Test]
	public static void AUiSectionSavedBeforeTheLooksInputsReadsWithThemAtTheirDefaults()
	{
		EditorSerializables.RegisterAll();
		let factory = XmlSerializerFactory();
		defer delete factory;
		let buffer = scope Sedulous.Core.IO.MemoryStream();
		{
			let legacy = scope LegacyUiSection();
			legacy.UiScale = 1.5f;
			legacy.AutoOrthographic = false;
			let writing = factory(buffer, .Write);
			defer delete writing;
			let archive = writing.Serializer;
			Test.Assert(archive.IsSelfDescribing, "a self describing file has no format version to write");
			uint32 count = 1;
			archive.Key("sections");
			archive.BeginArray(ref count);
			archive.BeginObject();
			archive.Key("typeName");
			archive.Text(typeof(EditorUiSettings).GetFullName(.. scope .()));
			archive.BeginFramedRegion();
			archive.Key("payload");
			archive.BeginObject();
			legacy.Serialize(archive);
			archive.EndObject();
			archive.EndFramedRegion();
			archive.EndObject();
			archive.EndArray();
			Test.Assert(archive.IsOk);
			writing.Flush(buffer);
		}
		let text = scope String((char8*)buffer.Bytes.Ptr, buffer.Bytes.Length);
		Test.Assert(!text.Contains("scheme") && !text.Contains("accent"), "written without the inputs");

		buffer.Seek(0, .Begin);
		let loaded = scope Settings();
		Test.Assert(loaded.Load(buffer, factory) case .Ok);
		Test.Assert(loaded.UnknownSectionCount == 0);
		let ui = loaded.Find<EditorUiSettings>();
		Test.Assert(ui != null, "read, not refused");
		Test.Assert(Math.Abs(ui.UiScale - 1.5f) < 1e-5f);
		Test.Assert(!ui.AutoOrthographic);
		Test.Assert(ui.Scheme == "dark");
		Test.Assert(ui.Accent == "#2f6fdf");
		Test.Assert(ui.Density == "compact");
		Test.Assert(!ui.ReduceMotion);

		// Saved again, the inputs are in it and read back.
		ui.Scheme.Set("light");
		let again = scope Sedulous.Core.IO.MemoryStream();
		Test.Assert(loaded.Save(again, factory) case .Ok);
		again.Seek(0, .Begin);
		let reloaded = scope Settings();
		Test.Assert(reloaded.Load(again, factory) case .Ok);
		let back = reloaded.Find<EditorUiSettings>();
		Test.Assert((back != null) && (back.Scheme == "light") && (back.Accent == "#2f6fdf") && !back.AutoOrthographic);
	}

	/// The UI section moved from Editor.Core to the look's library, and the recent list from
	/// Editor.Core to the headless project half, then on to the project and build library: a
	/// store saved under a former name still reads, as the current type.
	[Test]
	public static void SectionsSavedUnderTheNamesTheyHadBeforeTheyMovedRead()
	{
		EditorSerializables.RegisterAll();
		const String cFormerUi = "Sedulous.Editor.Core.EditorUiSettings";
		let factory = XmlSerializerFactory();
		defer delete factory;
		let buffer = scope Sedulous.Core.IO.MemoryStream();
		{
			let legacy = scope LegacyUiSection();
			legacy.UiScale = 1.75f;
			legacy.AutoOrthographic = false;
			legacy.TypeId = TypeIdOf(cFormerUi);
			let writing = factory(buffer, .Write);
			defer delete writing;
			let archive = writing.Serializer;
			uint32 count = 1;
			archive.Key("sections");
			archive.BeginArray(ref count);
			archive.BeginObject();
			archive.Key("typeName");
			archive.Text(cFormerUi);
			archive.BeginFramedRegion();
			archive.Key("payload");
			archive.BeginObject();
			legacy.Serialize(archive);
			archive.EndObject();
			archive.EndFramedRegion();
			archive.EndObject();
			archive.EndArray();
			Test.Assert(archive.IsOk);
			writing.Flush(buffer);
		}
		buffer.Seek(0, .Begin);
		let loaded = scope Settings();
		Test.Assert(loaded.Load(buffer, factory) case .Ok);
		Test.Assert(loaded.UnknownSectionCount == 0, "known by its former name");
		let ui = loaded.Find<EditorUiSettings>();
		Test.Assert(ui != null, "read as the current type");
		Test.Assert(Math.Abs(ui.UiScale - 1.75f) < 1e-5f);
		Test.Assert(!ui.AutoOrthographic);
		Test.Assert(typeof(EditorUiSettings).GetFullName(.. scope .()) == "Sedulous.Editor.Look.EditorUiSettings");

		// The recent list's two types, from either name they were saved under: a rename is one
		// step, so each former name leads to the current one.
		for (let type in scope Type[](typeof(RecentProjectsSettings), typeof(RecentProjectEntry)))
		{
			let current = type.GetFullName(.. scope .());
			let leaf = type.GetName(.. scope .());
			for (let former in scope String[](scope $"Sedulous.Editor.Core.{leaf}", scope $"Sedulous.Editor.Project.{leaf}"))
			{
				let named = scope String();
				Test.Assert(SerializableRenames.TryCurrentName(former, named), former);
				Test.Assert(named == current, scope $"{former} reads as {named}");
				Test.Assert(SerializableRenames.IsFormerId(TypeIdOf(former), TypeIdOf(current)), former);
			}
		}
	}

	/// The Game tab's preview resolutions: the common sizes seed once, a user's removal stays
	/// removed, and the list round trips through the store.
	[Test]
	public static void ThePreviewResolutionsSeedOnceAndRoundTrip()
	{
		EditorSerializables.RegisterAll();
		Test.Assert(GamePreviewSettings.From(null) == null, "no store, nothing");
		let store = scope Settings();
		let previews = GamePreviewSettings.From(store);
		Test.Assert(previews.Seeded && (previews.Presets.Count == 6));
		Test.Assert((previews.Presets[3].Name == "Steam Deck") && (previews.Presets[3].Width == 1280) && (previews.Presets[3].Height == 800));

		ClearAndDeleteItems!(previews.Presets);
		previews.Presets.Add(new .("Handheld", 960, 544));
		Test.Assert(GamePreviewSettings.From(store).Presets.Count == 1, "not seeded again");

		let buffer = scope Sedulous.Core.IO.MemoryStream();
		let factory = XmlSerializerFactory();
		defer delete factory;
		Test.Assert(store.Save(buffer, factory) case .Ok);
		buffer.Seek(0, .Begin);
		let loaded = scope Settings();
		Test.Assert(loaded.Load(buffer, factory) case .Ok);
		let back = GamePreviewSettings.From(loaded);
		Test.Assert((back.Presets.Count == 1) && (back.Presets[0].Name == "Handheld") && (back.Presets[0].Width == 960) && (back.Presets[0].Height == 544));
	}
}
