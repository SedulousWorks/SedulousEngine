using System;
using System.Collections;
using Sedulous.Render;

namespace Sedulous.Editor.ViewportTools;

/// Owns the tools of one viewport host and routes input to the active one. The first tool
/// added is the default: always available, activated at start, fallen back to when the
/// active tool deactivates or becomes unavailable.
class ViewportToolManager
{
	private List<IViewportTool> mTools = new .() ~ DeleteContainerAndItems!(_);
	/// Borrowed from mTools; null until the first Add.
	private IViewportTool mActive = null;

	public int Count => mTools.Count;
	public IViewportTool ActiveTool => mActive;

	/// Takes ownership. The first Add sets the default and active tool.
	public IViewportTool Add(IViewportTool tool)
	{
		if (tool == null)
			return null;
		mTools.Add(tool);
		if (mActive == null)
		{
			mActive = tool;
			mActive.OnActivate();
		}
		return tool;
	}

	public IViewportTool ToolAt(int index) => ((index >= 0) && (index < mTools.Count)) ? mTools[index] : null;

	public IViewportTool FindById(StringView id)
	{
		for (let tool in mTools)
		{
			if (tool.Id == id)
				return tool;
		}
		return null;
	}

	/// Deactivates the current tool first, so its gesture ends. False when the id is unknown
	/// or the tool reports unavailable; the already-active tool is a no-op success.
	public bool ActivateById(StringView id)
	{
		let target = FindById(id);
		if ((target == null) || !target.IsAvailable)
			return false;
		if (target == mActive)
			return true;
		if (mActive != null)
			mActive.OnDeactivate();
		mActive = target;
		mActive.OnActivate();
		return true;
	}

	/// Back to the default tool; a no-op when it is active or nothing was added.
	public void ActivateDefault()
	{
		if (mTools.IsEmpty || (mActive == mTools[0]))
			return;
		if (mActive != null)
			mActive.OnDeactivate();
		mActive = mTools[0];
		mActive.OnActivate();
	}

	/// Routes one frame to the active tool, falling back to the default first when the active
	/// one reports unavailable, so a dead tool never sees another frame.
	public bool Update(in ViewportToolInput input)
	{
		if (mActive == null)
			return false;
		if (!mActive.IsAvailable)
			ActivateDefault();
		return (mActive != null) && mActive.Update(input);
	}

	public void Draw(DebugDraw drawList)
	{
		if (mActive != null)
			mActive.Draw(drawList);
	}
}
