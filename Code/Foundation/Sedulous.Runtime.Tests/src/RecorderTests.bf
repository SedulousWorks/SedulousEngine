using System;
using System.Collections;
using Sedulous.Core.Serialization;
using Sedulous.Runtime;

namespace Sedulous.Runtime.Tests;

/// The extension point that lets a layer ABOVE Runtime have its registrations reversed by
/// the same unload.
///
/// The recorder here is over a stand-in table rather than a scene manager's contribution
/// table; the contract being tested is the host's, not the table's.
class RecorderTests
{
	[Test]
	public static void ARecordersRegistrationsAreReversedOnUnload()
	{
		let context = scope Context();
		let recorder = scope FakeContributionRecorder();

		// Something the layer owned BEFORE any plugin, which must survive.
		recorder.Contribute(1000);

		let host = scope PluginHost(context);
		host.AddRecorder(recorder);

		let plugin = scope ContributingPlugin(recorder, 2000);
		host.Add(plugin);

		Test.Assert(recorder.ArmCount == 1 && recorder.DisarmCount == 1,
			"armed for exactly the duration of OnLoad");
		Test.Assert(recorder.Contributions.Contains(2000), "the plugin contributed");
		Test.Assert(recorder.Contributions.Contains(1000));

		host.UnloadAll();

		Test.Assert(!recorder.Contributions.Contains(2000), "and the unload took it back");
		Test.Assert(recorder.Contributions.Contains(1000), "without touching what it did not add");
	}

	/// Contributing something the layer already holds is not this plugin's to reverse.
	[Test]
	public static void ARecorderDoesNotReverseWhatAnotherPartyOwns()
	{
		let context = scope Context();
		let recorder = scope FakeContributionRecorder();
		recorder.Contribute(3000);

		let host = scope PluginHost(context);
		host.AddRecorder(recorder);
		host.Add(scope ContributingPlugin(recorder, 3000));

		host.UnloadAll();
		Test.Assert(recorder.Contributions.Contains(3000),
			"the plugin re-registered what was already there, so it owns none of it");
	}

	/// A recorder is disarmed between plugins, or the second plugin's contributions get
	/// attributed to the first and reversed with it.
	[Test]
	public static void RecordingDoesNotLeakBetweenPlugins()
	{
		let context = scope Context();
		let recorder = scope FakeContributionRecorder();

		let host = scope PluginHost(context);
		host.AddRecorder(recorder);
		host.Add(scope ContributingPlugin(recorder, 4000));
		host.Add(scope ContributingPlugin(recorder, 5000));

		Test.Assert(recorder.ArmCount == 2 && recorder.DisarmCount == 2);
		Test.Assert(recorder.Contributions.Count == 2);

		host.UnloadAll();
		Test.Assert(recorder.Contributions.IsEmpty, "each plugin took back exactly its own");
	}

	/// A recorder added after a plugin loaded never saw that plugin, so its unload cannot
	/// reverse anything through it. Recorded here because it is a real footgun.
	[Test]
	public static void ARecorderAddedTooLateRecordsNothing()
	{
		let context = scope Context();
		let recorder = scope FakeContributionRecorder();

		let host = scope PluginHost(context);
		let plugin = scope ContributingPlugin(recorder, 6000);
		host.Add(plugin);
		host.AddRecorder(recorder); // Too late.

		Test.Assert(recorder.ArmCount == 0);
		host.UnloadAll();
		Test.Assert(recorder.Contributions.Contains(6000),
			"nothing recorded it, so nothing reverses it");
	}

	/// The observer records only what the PLUGIN inserted.
	///
	/// A snapshot either side of OnLoad cannot tell who added an id: anything else that
	/// registered while OnLoad ran would be attributed to the plugin and torn out with it.
	[Test]
	public static void RegistrationsMadeByOthersAreNotAttributedToThePlugin()
	{
		let context = scope Context();
		GlobalSerializableRegistry.Clear();
		defer GlobalSerializableRegistry.Clear();

		let host = scope PluginHost(context);

		// A plugin whose OnLoad causes a THIRD party to register as a side effect, which is
		// what a snapshot cannot distinguish from the plugin registering it itself.
		let plugin = scope TestPlugin("registrar");
		plugin.RegistersASerializable = true;
		host.Add(plugin);

		// Registered after OnLoad returned, by someone else.
		GlobalSerializableRegistry.Register(HostOwnedType.TypeId, () => new HostOwnedType());

		host.UnloadAll();
		Test.Assert(GlobalSerializableRegistry.IsRegistered(HostOwnedType.TypeId),
			"not the plugin's, so not reversed");
		Test.Assert(!GlobalSerializableRegistry.IsRegistered(PluginOwnedType.TypeId));
	}
}
