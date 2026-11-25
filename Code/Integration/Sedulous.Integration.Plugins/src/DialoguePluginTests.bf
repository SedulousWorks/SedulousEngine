using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Runtime;
using Sedulous.Engine.Project;
using Sedulous.Engine.Domain;
using Sedulous.Engine.Composition;
using Dialogue;

namespace Sedulous.Integration.Plugins;

/// The engine's official dialogue plugin, linked here as the engine's hosts link it: its manifest
/// reads and passes the host's checks, an editor links its four parts, and a project that enables
/// it loads it: the project's settings for it read into its settings type, its domain added to the
/// engine's composition (the factories for a cooked dialogue file and cast), and all of it taken out
/// again when it unloads.
class DialoguePluginTests
{
	const String cId = "dialogue";

	[Test]
	public static void TheDialoguePluginIsLinkedWithItsFourPartsAndItsManifestPassesTheChecks()
	{
		bool[PluginPartKind.Count] seen = default;
		for (let part in PluginRegistry.Parts)
		{
			if (part.PluginId != cId)
				continue;
			Test.Assert(!seen[(int)part.Kind], "one part a kind");
			seen[(int)part.Kind] = true;
			let manifest = scope PluginManifest();
			Test.Assert(PluginManifest.Read(part.ManifestXml, manifest) case .Ok);
			for (int i < PluginPartKind.Count)
				Test.Assert(manifest.HasPart((PluginPartKind)i));
			let why = scope String();
			Test.Assert(manifest.Check(EngineVersion.String, why), why);
			Test.Assert(manifest.FindPlatform(PluginHost.HostPlatform) != null, "this platform among its platforms");
		}
		for (int i < PluginPartKind.Count)
			Test.Assert(seen[i], "every kind linked, as an editor links them");
	}

	static bool HasDomain(StringView id)
	{
		for (let module in EngineComposition.Modules)
		{
			if (module.Id == id)
				return true;
		}
		return false;
	}

	static bool SourceRegistered() => GlobalSerializableRegistry.IsRegistered(TypeIdOf(typeof(DialogueSource).GetFullName(.. scope .())));

	[Test]
	public static void AProjectThatEnablesDialogueLoadsItItsSettingsReadFromTheProjectsEntry()
	{
		let chosen = scope DialogueSettings();
		chosen.ProvidedFlags.Add(new .("seen_*"));
		chosen.StockBox = true;
		let entries = scope List<EnabledPlugin>();
		defer { ClearAndDeleteItems!(entries); }
		let entry = new EnabledPlugin();
		entry.Id.Set(cId);
		Test.Assert(EnabledPlugin.WriteSettings(chosen, entry.Settings) case .Ok);
		entries.Add(entry);

		let subsystems = scope SubsystemManager();
		let host = scope PluginHost(subsystems, .Player, EngineVersion.String);
		let engineServices = scope EnginePluginServices();
		Test.Assert(engineServices.Attach(host));
		Test.Assert(host.AddRegistered() case .Ok);
		host.Load((Span<EnabledPlugin>)entries, scope .());
		Test.Assert(host.IsLoaded(cId));
		let held = host.Settings(cId) as DialogueSettings;
		Test.Assert(held != null, "the plugin's settings, read into its type");
		Test.Assert(host.SettingsRead(cId));
		Test.Assert((held.ProvidedFlags.Count == 1) && (held.ProvidedFlags[0] == "seen_*"));
		Test.Assert(held.StockBox);
		Test.Assert(held.FlagPrefix == "flag.", "what the entry left out keeps its default");
		// The domain: its resource types, which the composition builds the factories from.
		Test.Assert(HasDomain(cId));
		Test.Assert(SourceRegistered());
		host.Unload();
		Test.Assert(!host.IsLoaded(cId));
		Test.Assert(!HasDomain(cId), "taken out with the plugin");
		Test.Assert(!SourceRegistered());
	}

	[Test]
	public static void AHostWithoutTheEnginesServiceStillRegistersTheCookedTypesAndAddsNoDomain()
	{
		let entries = scope List<EnabledPlugin>();
		defer { ClearAndDeleteItems!(entries); }
		let entry = new EnabledPlugin();
		entry.Id.Set(cId);
		entries.Add(entry);

		let subsystems = scope SubsystemManager();
		let host = scope PluginHost(subsystems, .Player, EngineVersion.String);
		Test.Assert(host.AddRegistered() case .Ok);
		host.Load((Span<EnabledPlugin>)entries, scope .());
		Test.Assert(host.IsLoaded(cId));
		Test.Assert(!HasDomain(cId), "no engine service, no domain");
		Test.Assert(SourceRegistered(), "the cooked types all the same");
		host.Unload();
		Test.Assert(!SourceRegistered());
	}
}
