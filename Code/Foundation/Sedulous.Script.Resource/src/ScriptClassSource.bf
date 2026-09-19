using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Serialization;

namespace Sedulous.Script.Resource;

/// The cooked record of a script class: SOURCE TEXT plus what the cook harvested from it,
/// never bytecode. Compilation is fast and happens per run on first use, so the cooked
/// form stays the one a person can read and a hot reload can re-feed.
///
/// The harvested properties and handlers are what let the EDITOR render an inspector
/// without a VM, and the RUNTIME dispatch handlers without probing for them per frame.
[Serializable]
class ScriptClassSource
{
	/// The backend id, "angelscript".
	public String Language = new .() ~ delete _;
	/// Empty for a utility module with no behaviour class in it.
	public String ClassName = new .() ~ delete _;
	/// The source file identity, "Mover.as": the section name a compile error and a
	/// breakpoint key on. Stamped by the cook from the asset's file name.
	public String SourceName = new .() ~ delete _;
	public String Source = new .() ~ delete _;
	public List<ScriptPropertyDesc> Properties = new .() ~ DeleteContainerAndItems!(_);
	/// The lifecycle and event handlers the class declares: the dispatch gate.
	public List<String> Handlers = new .() ~ DeleteContainerAndItems!(_);
	/// The class starts coroutines, so a teardown has some to cancel.
	public bool UsesCoroutines = false;
}
