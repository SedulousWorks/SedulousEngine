using System;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Pipeline.Core;

namespace Sedulous.Script.Pipeline;

/// A project file whose folder's sources of its language, every one under it, build together
/// into one assembly (ScriptAssemblyAssetBuilder); each class asset there names the assembly.
/// The file name is the project file's.
[Category("Scripting")]
[DisplayName("Script Project")]
[Serializable]
class ScriptAssemblyAsset : Asset
{
	/// The backend id, from the project file's extension.
	[DisplayName("Language")]
	public String Language = new .() ~ delete _;

	public override bool IsCode => true;
}
