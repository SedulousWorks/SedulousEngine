namespace Sedulous.Editor.ViewportTools.Tests;

class TestProvider : IViewportToolProvider
{
	private ToolLog mLog;

	public this(ToolLog log) { mLog = log; }

	public void CreateTools(ViewportToolManager manager, in ViewportToolHostContext context)
	{
		manager.Add(new TestTool("provided", mLog));
	}
}
