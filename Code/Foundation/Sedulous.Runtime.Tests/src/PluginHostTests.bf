using System;
using System.Collections;
using Sedulous.Core.Serialization;
using Sedulous.Runtime;

namespace Sedulous.Runtime.Tests;

[Serializable]
class PluginOwnedType
{
	public int32 Value;
}

[Serializable]
class HostOwnedType
{
	public int32 Value;
}

/// A statically linked plugin that registers a subsystem and a serializable type, the way
/// a real one would.
class TestPlugin : IRuntimePlugin
{
	private String mName = new .() ~ delete _;
	private Recording mSubsystem ~ delete _;
	public bool RegistersASerializable;
	/// Off for tests that only care about ordering. Two plugins registering the SAME
	/// subsystem type is a genuine conflict, and not the thing under test here.
	public bool RegistersASubsystem = true;

	public this(StringView name)
	{
		mName.Set(name);
	}

	public StringView Name => mName;

	public void OnLoad(Context context)
	{
		Trace.Add(scope $"{mName}.load");
		if (RegistersASubsystem)
		{
			mSubsystem = new Recording(mName, 0);
			context.RegisterSubsystem(mSubsystem);
		}

		if (RegistersASerializable)
			GlobalSerializableRegistry.Register(PluginOwnedType.TypeId, () => new PluginOwnedType());
	}

	public void OnUnload(Context context)
	{
		Trace.Add(scope $"{mName}.unload");
		// The plugin owns its subsystem, so it takes it back out itself. Doing this here
		// rather than later is the point: a dynamically loaded plugin's code is still
		// mapped during OnUnload and gone afterwards.
		if (mSubsystem != null)
		{
			context.RemoveSubsystem<Recording>();
			delete mSubsystem;
			mSubsystem = null;
		}
	}
}

/// The plugin host, and specifically getting a plugin back OUT.
class PluginHostTests
{
	[Test]
	public static void AddingAPluginLoadsItIntoTheContext()
	{
		let context = scope Context();
		Trace.Clear();

		let plugin = scope TestPlugin("alpha");
		let host = scope PluginHost(context);

		host.Add(plugin);
		Test.Assert(host.Count == 1);
		Test.Assert(Trace.Has("alpha.load"));
		Test.Assert(context.HasSubsystem<Recording>(), "the plugin registered its subsystem");

		host.UnloadAll();
		Test.Assert(host.Count == 0);
		Test.Assert(Trace.Has("alpha.unload"));
		Test.Assert(!context.HasSubsystem<Recording>(), "and took it back out");
	}

	/// Plugins come down in reverse load order, so one built on another goes first.
	[Test]
	public static void PluginsUnloadInReverseOrder()
	{
		let context = scope Context();
		Trace.Clear();

		let first = scope TestPlugin("first");
		let second = scope TestPlugin("second");
		first.RegistersASubsystem = false;
		second.RegistersASubsystem = false;
		let host = scope PluginHost(context);

		host.Add(first);
		host.Add(second);
		Test.Assert(Trace.Before("first.load", "second.load"));

		host.UnloadAll();
		Test.Assert(Trace.Before("second.unload", "first.unload"), "reverse");
	}

	/// The reason the host records anything at all.
	///
	/// A factory is a function pointer into the plugin's library. Left in the registry
	/// after the library closes, the next load of that type jumps into unmapped memory.
	/// The host takes the registration back without the plugin having to declare it.
	[Test]
	public static void APluginsRegistrationsAreTakenBackOnUnload()
	{
		let context = scope Context();
		Trace.Clear();

		GlobalSerializableRegistry.Clear();
		defer GlobalSerializableRegistry.Clear();

		// Something the HOST registered, which must survive the plugin coming and going.
		GlobalSerializableRegistry.Register(HostOwnedType.TypeId, () => new HostOwnedType());
		Test.Assert(GlobalSerializableRegistry.Count == 1);

		let plugin = scope TestPlugin("registrar");
		plugin.RegistersASerializable = true;

		let host = scope PluginHost(context);
		host.Add(plugin);

		Test.Assert(GlobalSerializableRegistry.IsRegistered(PluginOwnedType.TypeId), "the plugin added its type");
		Test.Assert(GlobalSerializableRegistry.Count == 2);

		host.UnloadAll();

		Test.Assert(!GlobalSerializableRegistry.IsRegistered(PluginOwnedType.TypeId),
			"the plugin's registration went with it");
		Test.Assert(GlobalSerializableRegistry.IsRegistered(HostOwnedType.TypeId),
			"and the host's did not");
		Test.Assert(GlobalSerializableRegistry.Count == 1);
	}

	/// A plugin that registers nothing takes nothing away, which is the case that would
	/// otherwise quietly unregister a type someone else owns.
	[Test]
	public static void APluginThatRegistersNothingRemovesNothing()
	{
		let context = scope Context();
		Trace.Clear();

		GlobalSerializableRegistry.Clear();
		defer GlobalSerializableRegistry.Clear();
		GlobalSerializableRegistry.Register(HostOwnedType.TypeId, () => new HostOwnedType());
		GlobalSerializableRegistry.Register(PluginOwnedType.TypeId, () => new PluginOwnedType());

		let plugin = scope TestPlugin("quiet");
		let host = scope PluginHost(context);
		host.Add(plugin);
		host.UnloadAll();

		Test.Assert(GlobalSerializableRegistry.Count == 2, "both registrations are untouched");
		Test.Assert(GlobalSerializableRegistry.IsRegistered(PluginOwnedType.TypeId));
	}

	/// Re-registering a type the host already had is NOT the plugin's to take away. The
	/// snapshot compares ids, so a type that was already there is not in the difference.
	[Test]
	public static void ReRegisteringAnExistingTypeDoesNotClaimIt()
	{
		let context = scope Context();
		Trace.Clear();

		GlobalSerializableRegistry.Clear();
		defer GlobalSerializableRegistry.Clear();
		GlobalSerializableRegistry.Register(PluginOwnedType.TypeId, () => new PluginOwnedType());

		let plugin = scope TestPlugin("overrider");
		plugin.RegistersASerializable = true; // registers the SAME id the host already had

		let host = scope PluginHost(context);
		host.Add(plugin);
		host.UnloadAll();

		Test.Assert(GlobalSerializableRegistry.IsRegistered(PluginOwnedType.TypeId),
			"it was already registered before the plugin, so it stays");
	}

	/// A library that is not there fails with a reason rather than taking the host down.
	[Test]
	public static void LoadingAMissingLibraryFailsCleanly()
	{
		let context = scope Context();
		let host = scope PluginHost(context);

		Test.Assert(host.Load("./no_such_plugin_library.so") case .Err);
		Test.Assert(host.Count == 0, "nothing was recorded for a load that did not happen");
	}
}
