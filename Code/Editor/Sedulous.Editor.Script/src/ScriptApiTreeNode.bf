using System;
using System.Collections;

namespace Sedulous.Editor.Script;

/// One row of the API browser: a type at depth zero, its members under it.
class ScriptApiTreeNode
{
	/// The row text: the type name, or the member's language-formatted signature.
	public String Label = new .() ~ delete _;
	/// What activating the row types into the editor.
	public String InsertText = new .() ~ delete _;
	public int32 Depth = 0;
	/// Node indices; type rows only.
	public List<int32> Children = new .() ~ delete _;
}
