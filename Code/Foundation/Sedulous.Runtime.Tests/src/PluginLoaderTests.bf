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

/// A part that registers a subsystem and a serializable type, the way a real one would.
class TestPart : PluginPart
{
	private String mName = new .() ~ delete _;
	private Recording mSubsystem ~ delete _;
	public bool RegistersASerializable;
	/// Off for tests that only care about ordering. Two parts registering the SAME subsystem
	/// type is a genuine conflict, and not the thing under test here.
	public bool RegistersASubsystem = true;

	public this(StringView name)
	{
		mName.Set(name);
	}

	public override StringView PluginId => mName;
	public override PluginPartKind Kind => .Engine;

	public override void Load(PluginContext context)
	{
		Trace.Add(scope $"{mName}.load");
		if (RegistersASubsystem)
		{
			mSubsystem = new Recording(mName, 0);
			context.Subsystems.RegisterSubsystem(mSubsystem);
		}

		if (RegistersASerializable)
			GlobalSerializableRegistry.Register(PluginOwnedType.TypeId, () => new PluginOwnedType());
	}

	public override void Unload(PluginContext context)
	{
		Trace.Add(scope $"{mName}.unload");
		// The part owns its subsystem, so it takes it back out itself: the recording reverses
		// registrations, not what a part made.
		if (mSubsystem != null)
		{
			context.Subsystems.RemoveSubsystem<Recording>();
			delete mSubsystem;
			mSubsystem = null;
		}
	}
}

/// The plugin loader, and specifically getting a part back OUT.
class PluginLoaderTests
{
	[Test]
	public static void AddingAPluginLoadsItIntoTheContext()
	{
		let context = scope SubsystemManager();
		Trace.Clear();

		let plugin = scope TestPart("alpha");
		let host = scope PluginLoader();

		host.AddPart(plugin, scope:: PluginContext(.Player, context, plugin.PluginId));
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
		let context = scope SubsystemManager();
		Trace.Clear();

		let first = scope TestPart("first");
		let second = scope TestPart("second");
		first.RegistersASubsystem = false;
		second.RegistersASubsystem = false;
		let host = scope PluginLoader();

		host.AddPart(first, scope:: PluginContext(.Player, context, first.PluginId));
		host.AddPart(second, scope:: PluginContext(.Player, context, second.PluginId));
		Test.Assert(Trace.Before("first.load", "second.load"));

		host.UnloadAll();
		Test.Assert(Trace.Before("second.unload", "first.unload"), "reverse");
	}

	/// The reason the host records anything at all.
	///
	/// A plugin that is no longer enabled must leave no type of its constructible: the
	/// loader takes the registration back without the part having to declare it.
	[Test]
	public static void APluginsRegistrationsAreTakenBackOnUnload()
	{
		let context = scope SubsystemManager();
		Trace.Clear();

		GlobalSerializableRegistry.Clear();
		defer GlobalSerializableRegistry.Clear();

		// Something the HOST registered, which must survive the plugin coming and going.
		GlobalSerializableRegistry.Register(HostOwnedType.TypeId, () => new HostOwnedType());
		Test.Assert(GlobalSerializableRegistry.Count == 1);

		let plugin = scope TestPart("registrar");
		plugin.RegistersASerializable = true;

		let host = scope PluginLoader();
		host.AddPart(plugin, scope:: PluginContext(.Player, context, plugin.PluginId));

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
		let context = scope SubsystemManager();
		Trace.Clear();

		GlobalSerializableRegistry.Clear();
		defer GlobalSerializableRegistry.Clear();
		GlobalSerializableRegistry.Register(HostOwnedType.TypeId, () => new HostOwnedType());
		GlobalSerializableRegistry.Register(PluginOwnedType.TypeId, () => new PluginOwnedType());

		let plugin = scope TestPart("quiet");
		let host = scope PluginLoader();
		host.AddPart(plugin, scope:: PluginContext(.Player, context, plugin.PluginId));
		host.UnloadAll();

		Test.Assert(GlobalSerializableRegistry.Count == 2, "both registrations are untouched");
		Test.Assert(GlobalSerializableRegistry.IsRegistered(PluginOwnedType.TypeId));
	}

	/// Re-registering a type the host already had is NOT the plugin's to take away. The
	/// snapshot compares ids, so a type that was already there is not in the difference.
	[Test]
	public static void ReRegisteringAnExistingTypeDoesNotClaimIt()
	{
		let context = scope SubsystemManager();
		Trace.Clear();

		GlobalSerializableRegistry.Clear();
		defer GlobalSerializableRegistry.Clear();
		GlobalSerializableRegistry.Register(PluginOwnedType.TypeId, () => new PluginOwnedType());

		let plugin = scope TestPart("overrider");
		plugin.RegistersASerializable = true; // registers the SAME id the host already had

		let host = scope PluginLoader();
		host.AddPart(plugin, scope:: PluginContext(.Player, context, plugin.PluginId));
		host.UnloadAll();

		Test.Assert(GlobalSerializableRegistry.IsRegistered(PluginOwnedType.TypeId),
			"it was already registered before the plugin, so it stays");
	}
}
