using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.Script.Resource;

/// A project's script assembly at run time: what its classes load in place of compiling their
/// source (BehaviorClass.Assembly). Owned by the resource manager.
class ScriptAssembly
{
	public String Language = new .() ~ delete _;
	public List<uint8> Image = new .() ~ delete _;
	public List<uint8> Symbols = new .() ~ delete _;

	/// Fills from the cooked record. The class descriptions stay with the record: they are the
	/// cook's, and nothing at run time reads them.
	public void From(ScriptAssemblySource source)
	{
		Language.Set(source.Language);
		Image.Clear();
		Image.AddRange(source.Image);
		Symbols.Clear();
		Symbols.AddRange(source.Symbols);
	}
}
