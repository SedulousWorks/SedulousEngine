using System;
using Sedulous.Render;
using Sedulous.Editor.ViewportTools;

namespace Sedulous.Editor.App.Tests;

/// A viewport tool that only carries an id; the panel seam keys on Id alone.
class FakeTool : IViewportTool
{
	private String mId = new .() ~ delete _;

	public this(StringView id) { mId.Set(id); }

	public StringView Id => mId;
	public StringView DisplayName => mId;
	public bool IsAvailable => true;
	public void OnActivate() {}
	public void OnDeactivate() {}
	public bool Update(in ViewportToolInput input) => false;
	public void Draw(DebugDraw drawList) {}
	public StringView StatusText => "";
}
