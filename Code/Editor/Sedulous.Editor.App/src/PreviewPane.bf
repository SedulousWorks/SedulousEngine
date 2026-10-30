using System;
using Sedulous.Core;
using Sedulous.Graphics;
using Sedulous.GUI;
using Sedulous.Editor.Preview;

namespace Sedulous.Editor.App;

// The preview half of a preview page's markup (Data/Editor/PreviewPage.gml; Raptor's editor-gui
// spec, 5.4, layer 3), bound: the preview in `preview-stage`, Frame (`preview-frame`, and F over
// the preview), the preview's own choices after `preview-own`, and what shows when there is nothing
// to preview (`preview-empty`, its words `preview-empty-title` and `preview-empty-text`). The
// page fills the preview's scene and frames what it shows.

class PreviewPane
{
	/// Null without a host.
	private PreviewViewport mViewport = null ~ delete _;
	// The markup's: the tree holds them.
	private Node mStage = null;
	private Node mEmpty = null;
	private Sedulous.GUI.Label mEmptyTitle = null;
	private Sedulous.GUI.Label mEmptyText = null;
	private Node mOwn = null;
	private int mControls = 0;
	private bool mShowing = false;

	/// Told when Frame is clicked or F pressed over the preview: the page frames what it shows.
	public delegate void() OnFrame ~ delete _;

	/// The pane over `root`'s parts, its preview's scene named `sceneName`; `root` and `services`
	/// are borrowed.
	public this(Node root, AssetPageServices services, StringView sceneName)
	{
		if (services.Host != null)
			mViewport = new PreviewViewport(services.Host, services.Gui, sceneName);
		mStage = root.FindElement("preview-stage");
		mEmpty = root.FindElement("preview-empty");
		mEmptyTitle = root.FindElement("preview-empty-title") as Sedulous.GUI.Label;
		mEmptyText = root.FindElement("preview-empty-text") as Sedulous.GUI.Label;
		mOwn = root.FindElement("preview-own");
		if ((mStage != null) && (mViewport != null))
			mStage.AddChild(mViewport.View);
		if (let frame = root.FindElement("preview-frame") as ButtonBase)
			frame.SetOnClick(new [=this] () =>
				{
					if (OnFrame != null)
						OnFrame();
				});
		ShowEmpty("", "");
	}

	/// The preview (null without a host).
	public PreviewViewport Viewport => mViewport;
	public bool Showing => mShowing;

	/// The preview shown (its stage), the empty state hidden.
	public void Show()
	{
		mShowing = true;
		if (mStage != null)
			mStage.Displayed = mViewport != null;
		if (mEmpty != null)
			mEmpty.Displayed = mViewport == null;
	}

	/// Nothing to preview: `title` and `why` in its place (empty: the markup's words).
	public void ShowEmpty(StringView title, StringView why)
	{
		mShowing = false;
		if (mStage != null)
			mStage.Displayed = false;
		if (mEmpty != null)
			mEmpty.Displayed = true;
		if ((mEmptyTitle != null) && !title.IsEmpty)
			mEmptyTitle.Text = title;
		if ((mEmptyText != null) && !why.IsEmpty)
			mEmptyText.Text = why;
	}

	/// Puts `control` among the preview's own choices, after those placed before it; the bar takes
	/// its own reference.
	public void AddControl(Node control)
	{
		let bar = (mOwn != null) ? mOwn.Parent : null;
		if (bar == null)
			return;
		bar.AddChildAt(control, bar.GetChildIndex(mOwn) + 1 + mControls);
		mControls++;
	}

	/// Once a frame, from the page's OnUpdate: the camera, and F.
	public void Update(float dt)
	{
		if ((mViewport != null) && mViewport.Update(dt) && (OnFrame != null))
			OnFrame();
	}

	/// From the page's OnRenderWindow.
	public void Render(ref FrameContext frame)
	{
		if ((mViewport != null) && mShowing)
			mViewport.RenderFrame(ref frame);
	}

	/// From the page's OnClose: the preview's scene goes while the device lives.
	public void Close()
	{
		if (mViewport != null)
			mViewport.Shutdown();
	}
}
