using System;
using Sedulous.GUI;
using Sedulous.Editor.ViewportTools;

namespace Sedulous.Editor.App.Tests;

/// A panel provider for one tool id. Counts CreatePanel calls; can be told to yield no panel
/// (the "this context has nothing to show" path).
class FakeProvider : IViewportToolPanelProvider
{
	private String mId = new .() ~ delete _;
	private bool mNull;
	public int CreateCount = 0;

	public this(StringView toolId, bool yieldNull = false)
	{
		mId.Set(toolId);
		mNull = yieldNull;
	}

	public StringView ToolId => mId;
	public Node CreatePanel(IViewportTool tool, in ViewportToolHostContext context)
	{
		CreateCount++;
		return mNull ? null : new Panel();
	}
}
