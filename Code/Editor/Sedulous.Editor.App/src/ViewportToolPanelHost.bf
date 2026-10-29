using System;
using Sedulous.GUI;
using Sedulous.Editor.ViewportTools;

namespace Sedulous.Editor.App;

/// Watches a ViewportToolManager's active tool and mounts and unmounts the matching panel
/// through host-supplied callbacks. Pure control logic, no widget of its own, so it tests
/// without a live viewport: the host owns where the panel shows. Call Sync once per frame from
/// the host's update, not mid dispatch, since a mount tears down the previous panel.
///
/// The mounted panel is BORROWED by the mount callback: the host keeps the panel's reference
/// for its activation, so a page that shows it takes a reference of its own first, and the
/// clear callback removes it from wherever it went.
class ViewportToolPanelHost
{
	public delegate void MountFn(Node panel, IViewportTool tool);
	public delegate void ClearFn();

	private ViewportToolManager mTools;
	private ViewportToolPanelRegistry mRegistry;
	private ViewportToolHostContext mContext;
	private MountFn mMount ~ delete _;
	private ClearFn mClear ~ delete _;
	/// Keeps the mounted panel alive for its activation.
	private Node mCurrent = null ~ { if (_ != null) _.ReleaseRef(); };
	/// The active tool id at the last Sync; empty for none.
	private String mCurrentId = new .() ~ delete _;

	/// `mount` receives the freshly built panel and the tool it is for (for its chrome); `clear`
	/// removes whatever mount last showed. Both fire only on an active-tool change. Takes
	/// ownership of both delegates.
	public this(ViewportToolManager tools, ViewportToolPanelRegistry registry, ViewportToolHostContext context,
		MountFn mount, ClearFn clear)
	{
		mTools = tools;
		mRegistry = registry;
		mContext = context;
		mMount = mount;
		mClear = clear;
	}

	public Node CurrentPanel => mCurrent;
	public StringView CurrentToolId => mCurrentId;

	/// Re-mounts the panel if the active tool changed since the last call; otherwise a no-op.
	public void Sync()
	{
		let active = mTools.ActiveTool;
		let activeId = (active != null) ? active.Id : StringView();
		if (activeId == mCurrentId)
			return;

		// Tear down the panel of the tool being left, then build the one for the tool being
		// entered, so the host never shows two panels at once.
		if (mCurrent != null)
		{
			if (mClear != null)
				mClear();
			mCurrent.ReleaseRef();
			mCurrent = null;
		}
		mCurrentId.Set(activeId);

		if (activeId.IsEmpty)
			return;
		let provider = mRegistry.FindByToolId(activeId);
		if (provider == null)
			return;
		let panel = provider.CreatePanel(active, mContext);
		if (panel == null)
			return;
		mCurrent = panel;
		if (mMount != null)
			mMount(panel, active);
	}
}
