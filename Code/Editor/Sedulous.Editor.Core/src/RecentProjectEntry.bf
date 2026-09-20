using System;
using Sedulous.Core.Serialization;

namespace Sedulous.Editor.Core;

/// One known project. Path is the project DIRECTORY as the user opened it, the identity
/// key, compared verbatim; the name and engine version are the last seen manifest snapshot.
[Serializable(1)]
class RecentProjectEntry
{
	public String Path = new .() ~ delete _;
	public String Name = new .() ~ delete _;
	public String EngineVersion = new .() ~ delete _;
}
