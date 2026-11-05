using System;
using System.Collections;

namespace Sedulous.Runtime;

/// One loaded plugin part, and what unloading it will take with it.
class PluginEntry
{
	/// BORROWED: compiled in.
	public PluginPart Part;
	/// The context the part's load and unload are handed. BORROWED: the plugin host's.
	public PluginContext Context;
	/// Serializable ids its load added, so they can be taken back when it unloads.
	public List<uint64> RegisteredIds = new .() ~ delete _;
	/// One list per extra recorder, in the host's recorder order, holding what that
	/// recorder saw the part add.
	public List<List<uint64>> Recorded = new .() ~ DeleteContainerAndItems!(_);
	public String Name = new .() ~ delete _;
}
