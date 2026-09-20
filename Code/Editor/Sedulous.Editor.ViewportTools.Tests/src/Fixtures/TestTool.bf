using System;
using Sedulous.Render;

namespace Sedulous.Editor.ViewportTools.Tests;

class TestTool : IViewportTool
{
	private String mId = new .() ~ delete _;
	private ToolLog mLog;
	public bool Available = true;
	public bool Consume = false;

	public this(StringView id, ToolLog log)
	{
		mId.Set(id);
		mLog = log;
	}

	public StringView Id => mId;
	public StringView DisplayName => mId;
	public bool IsAvailable => Available;
	public void OnActivate() { mLog.Activations++; }
	public void OnDeactivate() { mLog.Deactivations++; }
	public bool Update(in ViewportToolInput input)
	{
		mLog.Updates++;
		return Consume;
	}
	public void Draw(DebugDraw drawList) {}
	public StringView StatusText => "";
}
