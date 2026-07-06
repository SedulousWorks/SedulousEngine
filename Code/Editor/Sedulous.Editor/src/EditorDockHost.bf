namespace Sedulous.Editor;

using System;
using System.Collections;
using Sedulous.RHI;
using Sedulous.RuntimeGraphics;
using Sedulous.Shell;
using Sedulous.Shaders;
using Sedulous.Fonts;
using Sedulous.VG;
using Sedulous.VG.Renderer;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Core.Logging.Abstractions;

/// Manages floating OS windows for detached dock panels.
/// Implements IDockableWindowHost so the DockManager can create, move,
/// resize and destroy secondary windows.
class EditorDockHost : IDockableWindowHost
{
	private EditorApplication mEditor;

	// Multi-window (floating dock panels + cross-window drag)
	private Dictionary<View, RenderWindow> mDockableWindowMap = new .() ~ delete _;
	private IWindow mDragSourceWindow;
	private float mDragWindowOffsetX;
	private float mDragWindowOffsetY;

	public this(EditorApplication editor)
	{
		mEditor = editor;
	}

	/// The map of dockable views to their OS render windows. Used by
	/// EditorApplication's input routing and shutdown logic.
	public Dictionary<View, RenderWindow> DockableWindowMap => mDockableWindowMap;

	/// The drag source window for cross-window drag operations.
	public IWindow DragSourceWindow
	{
		get => mDragSourceWindow;
		set => mDragSourceWindow = value;
	}

	/// Drag offset X for cross-window drag operations.
	public float DragWindowOffsetX
	{
		get => mDragWindowOffsetX;
		set => mDragWindowOffsetX = value;
	}

	/// Drag offset Y for cross-window drag operations.
	public float DragWindowOffsetY
	{
		get => mDragWindowOffsetY;
		set => mDragWindowOffsetY = value;
	}

	// ==================== IDockableWindowHost ====================

	public bool SupportsOSWindows => true;

	public void CreateDockableWindow(View dockableWindow, float width, float height,
		float screenX, float screenY, delegate void(View) onCloseRequested = null)
	{
		let settings = Sedulous.Shell.WindowSettings()
		{
			Title = scope .("Float"),
			Width = (int32)width,
			Height = (int32)height,
			Resizable = true,
			Bordered = false
		};

		let renderDesc = RenderWindowDesc()
		{
			Format = mEditor.ApplicationHost.MainWindow.Swap.Format,
			PresentMode = .Fifo
		};

		let rw = mEditor.ApplicationHost.OpenWindow(settings, renderDesc);
		if (rw == null)
		{
			mEditor.Logger?.Log(.Error, "Failed to create floating OS window");
			delete onCloseRequested;
			return;
		}

		rw.Window.X = mEditor.Window.X + (int32)screenX;
		rw.Window.Y = mEditor.Window.Y + (int32)screenY;

		let data = new DockableWindowData();
		data.OnCloseDelegate = onCloseRequested;

		data.RootView = new RootView();
		data.RootView.DpiScale = rw.Window.ContentScale;
		data.RootView.ViewportSize = .((float)rw.Window.Width, (float)rw.Window.Height);
		mEditor.UIContext.AddRootView(data.RootView);
		data.RootView.AddView(dockableWindow);
		data.DockableView = dockableWindow;

		data.VGContext = new VGContext(mEditor.FontService);
		data.VGRenderer = new VGRenderer();
		data.VGRenderer.Initialize(mEditor.Device, rw.Swap.Format,
			(int32)rw.Swap.BufferCount, mEditor.ShaderSystem);
		data.VGRenderer.SetExternalCache(mEditor.ExternalTextureCache);

		rw.SetData(data);
		mDockableWindowMap[dockableWindow] = rw;
	}

	public void DestroyDockableWindow(View dockableWindow)
	{
		DestroyDockableWindowImpl(dockableWindow);
	}

	public void MoveDockableWindow(View dockableWindow, float screenX, float screenY)
	{
		if (mDockableWindowMap.TryGetValue(dockableWindow, let rw))
		{
			let nx = mEditor.Window.X + (int32)screenX;
			let ny = mEditor.Window.Y + (int32)screenY;
			if (rw.Window.X != nx) rw.Window.X = nx;
			if (rw.Window.Y != ny) rw.Window.Y = ny;
		}
	}

	public void ResizeDockableWindow(View dockableWindow, float screenX, float screenY, float width, float height)
	{
		if (mDockableWindowMap.TryGetValue(dockableWindow, let rw))
		{
			// Only push when the value actually changes - SDL_SetWindowPosition
			// and SDL_SetWindowSize fire a window event each call, invalidating
			// the swapchain even on no-ops. Spammed VK_ERROR_OUT_OF_DATE_KHR
			// during resize otherwise.
			let nx = mEditor.Window.X + (int32)screenX;
			let ny = mEditor.Window.Y + (int32)screenY;
			let nw = (int32)width;
			let nh = (int32)height;
			if (rw.Window.X != nx) rw.Window.X = nx;
			if (rw.Window.Y != ny) rw.Window.Y = ny;
			if (rw.Window.Width != nw) rw.Window.Width = nw;
			if (rw.Window.Height != nh) rw.Window.Height = nh;
		}
	}

	public bool TryGetDockableWindowBounds(View dockableWindow, out float x, out float y, out float width, out float height)
	{
		if (mDockableWindowMap.TryGetValue(dockableWindow, let rw))
		{
			x = rw.Window.X - mEditor.Window.X;
			y = rw.Window.Y - mEditor.Window.Y;
			width = rw.Window.Width;
			height = rw.Window.Height;
			return true;
		}
		x = 0;
		y = 0;
		width = 0;
		height = 0;
		return false;
	}

	public void GetGlobalMousePosition(out float globalX, out float globalY)
	{
		let mouse = mEditor.Shell.InputManager.Mouse;
		if (mouse != null)
		{
			globalX = mouse.GlobalX;
			globalY = mouse.GlobalY;
		}
		else
		{
			globalX = 0;
			globalY = 0;
		}
	}

	// ==================== Internal ====================

	/// Destroy a dockable window, optionally detaching the view from
	/// the root. Called from DestroyDockableWindow and shutdown.
	public void DestroyDockableWindowImpl(View dockableWindow, bool detachView = true)
	{
		if (!mDockableWindowMap.TryGetValue(dockableWindow, let rw))
			return;

		mDockableWindowMap.Remove(dockableWindow);

		if (let data = rw.Data as DockableWindowData)
		{
			if (detachView && dockableWindow.Parent == data.RootView)
				data.RootView.RemoveView(dockableWindow, false);

			mEditor.UIContext.RemoveRootView(data.RootView);
		}

		// RenderWindow dtor calls WaitIdle and cleans up GPU resources + data
		mEditor.ApplicationHost.CloseWindow(rw);
	}

	// ==================== Window Event Handling ====================

	/// Handles OS window close events for secondary (dockable) windows.
	/// Subscribe to WindowManager.OnWindowEvent.
	public void HandleWindowEvent(IWindow window, WindowEvent evt)
	{
		if (evt.Type != .CloseRequested)
			return;

		// Check if it's a dockable window
		for (let kv in mDockableWindowMap)
		{
			if (kv.value.Window == window)
			{
				if (let data = kv.value.Data as DockableWindowData)
				{
					if (data.OnCloseDelegate != null)
						data.OnCloseDelegate(kv.key);
				}
				return;
			}
		}
	}

	// ==================== Rendering ====================

	/// Renders the UI for a secondary (dockable) OS window.
	public void RenderDockableWindow(DockableWindowData data, ref Sedulous.RuntimeGraphics.FrameContext frame)
	{
		// Prepare: update root view dimensions and layout
		data.RootView.DpiScale = frame.Window.Window.ContentScale;
		data.RootView.ViewportSize = .((float)frame.Window.Window.Width, (float)frame.Window.Window.Height);
		mEditor.UIContext.UpdateRootView(data.RootView);

		// Clear the dockable window
		ColorAttachment[1] colorAttachments = .(.()
		{
			View = frame.BackbufferView,
			LoadOp = .Clear,
			StoreOp = .Store,
			ClearValue = .(0.12f, 0.12f, 0.15f, 1)
		});

		RenderPassDesc passDesc = .() { ColorAttachments = .(colorAttachments) };
		let renderPass = frame.Encoder.BeginRenderPass(passDesc);
		if (renderPass == null)
			return;

		// Render UI into the dockable window
		let vg = data.VGContext;
		let renderer = data.VGRenderer;
		let w = frame.Window.Swap.Width;
		let h = frame.Window.Swap.Height;

		vg.Clear();
		mEditor.UIContext.DrawRootView(data.RootView, vg);
		let batch = vg.GetBatch();
		if (batch != null && batch.Commands.Count > 0)
		{
			let fi = (int32)frame.FrameIndex;
			renderer.BeginFrame(fi);
			let slice = renderer.Prepare(batch, fi, w, h);
			renderer.Render(renderPass, w, h, fi, slice);
		}

		renderPass.End();
	}
}
