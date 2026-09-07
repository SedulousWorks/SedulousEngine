using System;
using System.Collections;

namespace Sedulous.Runtime;

/// One loaded plugin, and what closing it will take with it.
class PluginEntry
{
	public IRuntimePlugin Plugin;
	/// The library handle, or null for a statically linked plugin.
	public void* Library;
	/// Serializable ids this plugin added, so they can be taken back before its code goes.
	public List<uint64> RegisteredIds = new .() ~ delete _;
	/// One list per extra recorder, in the host's recorder order, holding what that
	/// recorder saw this plugin add.
	public List<List<uint64>> Recorded = new .() ~ DeleteContainerAndItems!(_);
	public String Name = new .() ~ delete _;
}
