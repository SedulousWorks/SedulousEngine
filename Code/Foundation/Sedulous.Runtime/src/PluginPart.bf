using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Serialization;

namespace Sedulous.Runtime;

/// The kind of process enabling plugins.
enum HostRole : uint8
{
	case Player;
	case Editor;
	case Cook;
	case Export;
	case Mcp;

	public const int Count = 5;

	/// Whether a host of this role takes parts of `kind`: a player has no use for an asset
	/// importer, and a cook has no window to put an editor page in.
	public bool Loads(PluginPartKind kind)
	{
		if (kind == .Engine)
			return true;
		if (kind == .Pipeline)
			return this != .Player;
		if (kind == .Tooling)
			return (this == .Editor) || (this == .Export) || (this == .Mcp);
		return this == .Editor; // an Editor part
	}
}

/// What a part's load and unload are handed: the host's services, as far as its role has them,
/// and the project's settings for the plugin. One context per plugin, shared by its parts, alive
/// from the plugin's load to its unload.
class PluginContext
{
	private HostRole mRole;
	private SubsystemManager mSubsystems;
	private String mPluginId = new .() ~ delete _;
	/// The host's, which outlives every context. BORROWED; null for none.
	private Dictionary<Type, Object> mServices;
	/// The project entry's settings, read by Settings<T>.
	private List<uint8> mSettingsXml = new .() ~ delete _;
	/// The settings object a part asked for; null until one did.
	private Object mSettings = null ~ delete _;
	private bool mSettingsRead = true;

	/// `subsystems` and `services` are BORROWED and outlive the context; `settings` is copied.
	public this(HostRole role, SubsystemManager subsystems, StringView pluginId, Dictionary<Type, Object> services = null,
		Span<uint8> settings = default)
	{
		mRole = role;
		mSubsystems = subsystems;
		mPluginId.Set(pluginId);
		mServices = services;
		mSettingsXml.AddRange(settings);
	}

	public HostRole Role => mRole;
	public SubsystemManager Subsystems => mSubsystems;
	public StringView PluginId => mPluginId;

	/// The host's service of type T, or null when this host has none (a cook has no window, so
	/// no application host): a part checks, and leaves out what the host cannot support.
	/// Foundation's Runtime cannot name the engine's, the pipeline's or the editor's services;
	/// the layer that owns each provides it (PluginHost.Provide).
	public T Find<T>() where T : class
	{
		if ((mServices != null) && mServices.TryGetValue(typeof(T), let found))
			return (T)found;
		return null;
	}

	/// The plugin's settings, read from the project's entry into T, its reflected settings type,
	/// on the first call (T's defaults when the entry has none); every part asking for them
	/// shares one object, alive until the plugin unloads. A plugin has one settings type: null
	/// when an earlier call named another. When the entry's settings do not read as a T, the
	/// defaults are used and SettingsRead says so, so an editor never writes them over what it
	/// could not read.
	public T Settings<T>() where T : class, ISerializable, new, delete
	{
		if (mSettings != null)
			return (mSettings.GetType() == typeof(T)) ? (T)mSettings : null;
		let settings = new T();
		mSettings = settings;
		if (EnabledPlugin.ReadSettings((Span<uint8>)mSettingsXml, settings) case .Err)
		{
			mSettingsRead = false;
			delete mSettings;
			mSettings = new T(); // the defaults, not what the reader left
		}
		return (T)mSettings;
	}

	/// The settings object a part asked for (Settings<T>), or null when none did. BORROWED.
	public Object SettingsObject => mSettings;

	/// False when the project's settings did not read into the plugin's type.
	public bool SettingsRead => mSettingsRead;
}

/// One part of a plugin package, compiled into this binary: its load and unload, nothing else.
/// A part linked in but not enabled does no work: its load runs only when the host enables its
/// plugin. Every registration is explicit in Load; what the loader records (serializable types,
/// the recorders' tables) it reverses itself, and Unload removes the rest, such as a subsystem.
/// A package's part registers itself (PluginRegistry) and carries its package's manifest.
abstract class PluginPart
{
	/// The manifest's id, checked against it when the plugin is enabled.
	public abstract StringView PluginId { get; }
	public abstract PluginPartKind Kind { get; }
	/// The package's Plugin.xml, compiled in (`Compiler.ReadText`), so a player with no package
	/// files on disk still checks versions, dependencies and slots. A registered part must have
	/// one; a part handed to PluginHost.AddLinked with its manifest needs none.
	public virtual StringView ManifestXml => "";

	public abstract void Load(PluginContext context);
	public virtual void Unload(PluginContext context) {}
}
