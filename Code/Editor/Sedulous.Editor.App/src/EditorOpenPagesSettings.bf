using System;
using System.Collections;
using Sedulous.Core.Serialization;

namespace Sedulous.Editor.App;

/// The open page instance guids and the active one, a per-project section.
[Serializable(1)]
class EditorOpenPagesSettings
{
	public List<Guid> Pages = new .() ~ delete _;
	public Guid Active = .Empty;
}
