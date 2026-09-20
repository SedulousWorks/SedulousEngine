using System;
using Sedulous.PropertyAnimation;

namespace Sedulous.Editor.PropertyAnimation;

/// One property captured before a transient preview write, so it can be restored exactly;
/// re-resolved each time, never a cached instance.
class PreviewSnapshotEntry
{
	public String ComponentType = new .() ~ delete _;
	public String PropertyPath = new .() ~ delete _;
	public PropertyValue Value = .Empty;
}
