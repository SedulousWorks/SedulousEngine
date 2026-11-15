using System;
using Sedulous.Core;
using Sedulous.Core.Serialization;

namespace Sedulous.Script.Resource;

/// A file a script includes (AngelScript's `#include`), as the cook resolved and read it: its path
/// in the project's sources, which names its section (so an error or a breakpoint in it keys on
/// that file), and its text, so a class compiled from source includes it as the cook did.
class ScriptIncludedSource : ISerializable
{
	public String Path = new .() ~ delete _;
	public String Source = new .() ~ delete _;

	public void Serialize(ISerializer ar)
	{
		Sedulous.Core.Serialization.Serialize(ar, "path", Path);
		Sedulous.Core.Serialization.Serialize(ar, "source", Source);
	}
}
