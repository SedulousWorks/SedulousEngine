using System;
using Sedulous.Core;

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

/// What a part's load and unload are handed: the host's services, as far as its role has them.
/// One context per plugin, shared by its parts, alive from the plugin's load to its unload.
class PluginContext
{
	private HostRole mRole;
	private SubsystemManager mSubsystems;
	private String mPluginId = new .() ~ delete _;

	/// `subsystems` is BORROWED and outlives the context.
	public this(HostRole role, SubsystemManager subsystems, StringView pluginId)
	{
		mRole = role;
		mSubsystems = subsystems;
		mPluginId.Set(pluginId);
	}

	public HostRole Role => mRole;
	public SubsystemManager Subsystems => mSubsystems;
	public StringView PluginId => mPluginId;
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
