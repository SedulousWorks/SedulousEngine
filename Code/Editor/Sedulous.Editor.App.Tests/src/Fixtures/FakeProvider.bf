using System;
using Sedulous.UI;
using Sedulous.Editor.ViewportTools;

namespace Sedulous.Editor.App.Tests;

/// A panel provider for one tool id. Counts CreatePanel calls; can be told to yield no view
/// (the "this context has nothing to show" path).
class FakeProvider : IViewportToolPanelProvider
{
	private String mId = new .() ~ delete _;
	private bool mNull;
	/// The host must forward this to mount.
	public ToolPanelPlacement PlacementHint = .Dock;
	public int CreateCount = 0;

	public this(StringView toolId, bool yieldNull = false)
	{
		mId.Set(toolId);
		mNull = yieldNull;
	}

	public StringView ToolId => mId;
	public ToolPanelPlacement Placement => PlacementHint;
	public View CreatePanel(IViewportTool tool, in ViewportToolHostContext context)
	{
		CreateCount++;
		return mNull ? null : new FlexLayout();
	}
}
