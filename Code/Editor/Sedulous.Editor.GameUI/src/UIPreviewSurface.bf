using System;
using Sedulous.Core;
using Sedulous.Graphics;
using Sedulous.RHI;
using Sedulous.Runtime.Client;
using Sedulous.UI;
using Sedulous.UI.Runtime;
using Sedulous.UI.Viewport;
using Sedulous.UI.Resource;
using Sedulous.Engine.UI;

namespace Sedulous.Editor.GameUI;

/// The viewport a UI page previews into, and the preview root it draws: bound to whichever
/// window the viewport lands in, the root created on the RUNTIME UI context so the game's
/// fonts and theme apply, and rendered after the scene each frame. Shared by the document
/// and theme pages. The host and UI host are borrowed.
class UIPreviewSurface
{
	private IApplicationHost mHost;
	private UIHost mUiHost;
	/// The runtime context's subsystem; null in a headless host.
	private UISubsystem mUi;
	private RenderWindow mHostWindow = null;
	/// Owned through its reference.
	private ViewportView mViewport = null ~ { if (_ != null) _.ReleaseRef(); };
	/// Owned through its reference; registered on the runtime context while it shows.
	private RootView mPreviewRoot = null;

	public this(IApplicationHost host, UIHost uiHost)
	{
		mHost = host;
		mUiHost = uiHost;
		mUi = (host != null) ? host.Context.GetSubsystem<UISubsystem>() : null;
		mViewport = new ViewportView();
		mViewport.AddRef();
		mViewport.ClearColor = .(0.08f, 0.09f, 0.11f, 1.0f);
	}

	/// The viewport as a view, for layout.
	public View View => mViewport;
	public bool HasSubsystem => mUi != null;
	public RootView PreviewRoot => mPreviewRoot;

	/// Binds the viewport to the window it lives in, once it has one.
	public void EnsureBound()
	{
		let root = mViewport.Root();
		if (root == null)
			return;
		let window = mUiHost.WindowForRoot(root);
		if ((window == null) || (window == mHostWindow))
			return;
		let renderer = mUiHost.RendererFor(window);
		if (renderer == null)
			return;
		if (mHostWindow == null)
			mViewport.Initialize(mHost.Graphics.Raw, renderer, mHost.Shell.Input, window.Window.Id);
		else
			mViewport.AttachToWindow(renderer, window.Window.Id);
		mHostWindow = window;
	}

	/// Instantiates `markup` as the new preview, replacing the last good one only on
	/// success; false when the markup fails or there is no subsystem.
	public bool Rebuild(StringView markup, StyleSheet localSheet = null)
	{
		if (mUi == null)
		{
			if (localSheet != null)
				localSheet.ReleaseRef();
			return false;
		}
		let document = scope UIDocument();
		document.Markup.Set(markup);
		let fresh = mUi.CreatePreview(document);
		if (fresh == null)
		{
			if (localSheet != null)
				localSheet.ReleaseRef();
			return false;
		}
		if (localSheet != null)
		{
			fresh.SetLocalStyleSheet(localSheet); // consumed
			fresh.Invalidate(); // restyle the subtree at the next layout
		}
		DropPreviewRoot();
		mPreviewRoot = fresh;
		return true;
	}

	/// Draws the preview root into the viewport's colour target.
	public void Render(ref FrameContext frame)
	{
		if (!mViewport.IsReady || !frame.Valid)
			return;
		mViewport.ClearContent(frame.Encoder);
		if ((mUi == null) || (mPreviewRoot == null))
			return;
		let w = mViewport.RenderWidth;
		let h = mViewport.RenderHeight;
		if ((w == 0) || (h == 0))
			return;
		frame.Encoder.TransitionTexture(mViewport.ColorTexture, mViewport.ColorState, .RenderTarget);
		mUi.RenderPreview(mPreviewRoot, frame.Encoder, mViewport.ColorTargetView, mViewport.ColorFormat, w, h, (int32)frame.FrameIndex);
		frame.Encoder.TransitionTexture(mViewport.ColorTexture, .RenderTarget, .ShaderRead);
		mViewport.ColorState = .ShaderRead;
	}

	public void Shutdown()
	{
		DropPreviewRoot();
		mViewport.Shutdown();
	}

	public ~this()
	{
		DropPreviewRoot();
	}

	/// Detaches the root from the runtime context and releases it.
	private void DropPreviewRoot()
	{
		if (mPreviewRoot == null)
			return;
		if (mUi != null)
			mUi.DestroyPreview(mPreviewRoot);
		mPreviewRoot.ReleaseRef();
		mPreviewRoot = null;
	}
}
