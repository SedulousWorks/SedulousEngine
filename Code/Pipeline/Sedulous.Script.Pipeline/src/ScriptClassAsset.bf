using System;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Pipeline.Core;

namespace Sedulous.Script.Pipeline;

/// A script file as authored: the source under the sources tree and the language it is in,
/// defaulted from the file's extension at import. Nothing language specific lives here;
/// the cook for the language does the rest.
[Category("Scripting")]
[DisplayName("Script Class")]
[Serializable]
class ScriptClassAsset : Asset
{
	/// The backend id, "angelscript".
	[DisplayName("Language")]
	public String Language = new .() ~ delete _;
	/// The class the cook harvests, or empty for the first class the source declares.
	[DisplayName("Class Name")]
	public String ClassName = new .() ~ delete _;
}
