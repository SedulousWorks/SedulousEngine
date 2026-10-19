using System;
using System.Collections;
using Sedulous.Core.Serialization;
using Sedulous.Script.Resource;

namespace Sedulous.Script.Resource.Tests;

/// The cooked script record's fields with no data version: the layout a cook wrote before
/// the record carried one, which this build has to refuse rather than misread.
[Serializable]
class UnversionedScriptRecord
{
	public String Language = new .() ~ delete _;
	public String ClassName = new .() ~ delete _;
	public String SourceName = new .() ~ delete _;
	public String Source = new .() ~ delete _;
	public List<ScriptPropertyDesc> Properties = new .() ~ DeleteContainerAndItems!(_);
	public List<String> Handlers = new .() ~ DeleteContainerAndItems!(_);
	public bool UsesCoroutines = false;
}
