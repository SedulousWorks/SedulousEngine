using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Shell;
using Sedulous.Input; // ScriptedInputSource (a playtest of the view)
using Sedulous.Graphics;
using Sedulous.RHI;
using Sedulous.Runtime.Client;
using Sedulous.Scene;
using Sedulous.Render;
using Sedulous.Engine.Render;
using Sedulous.GUI;
using Sedulous.Editor.Camera;
using Sedulous.Editor.ViewportTools;

namespace Sedulous.Editor.Scene;

// A scene page's viewport: the GUI's Viewport the scene is drawn into by the real renderer, through
// a camera override, in the app's one renderer bracket before the GUI's frame (the render graph
// imports the colour target in the viewport's state and leaves it ready to sample, so the widget
// keeps it); the editor camera flying on the viewport's input, the mouse while it is hovered or
// holds a press, the keyboard only while it has the focus (a click focuses it), so keys typed in a
// field elsewhere never fly it; GPU picking keyed by the viewport; the capture of what it shows (an
// agent's screenshot, the project's picture); and framing entities. A hidden viewport (a tab not in
// front) renders nothing. Out of the page's class (Raptor's editor-gui spec, 5.3, layer 2), on the
// GUI where it was on Sedulous.UI's ViewportView.

/// What a viewport draws with: the context's subsystems, borrowed; null renders nothing (a test).
struct SceneViewportServices
{
	public RenderSubsystem Render = null;
	public Sedulous.Engine.GUI.GuiSubsystem GameGui = null;
}

class SceneViewport
{
	private SceneViewportServices mServices;
	/// One reference, this one's: the page's pane holds its own.
	private Sedulous.GUI.Viewport mView ~ _.ReleaseRef();
	private EditorCamera mCamera = new .() ~ delete _;
	private ViewportPicker mPicker ~ delete _;
	private ViewportCaptureRecorder mCapture = new .() ~ delete _;
	private bool mCleanCapture = false;
	/// Render added the view this frame, at:
	private bool mRenderedThisFrame = false;
	private uint32 mCaptureWidth = 0;
	private uint32 mCaptureHeight = 0;
	/// A playtest's devices (BeginScripted), OWNED; null while none runs.
	private ScriptedInputSource mScripted ~ delete _;
	private double mScriptedTime = 0;
	private bool mScriptedEnding = false;
	private bool mScriptedReleased = false;

	public this(SceneViewportServices services)
	{
		mServices = services;
		mPicker = new .(this);
		mView = new Sedulous.GUI.Viewport();
		mView.AddClass("scene-view");
		mView.ClearColor = .(0.349f, 0.366f, 0.396f, 1.0f); // sRGB, like every UI colour
		// Start framed on the origin (the grid's centre), the orbit's pivot there, the horizon level.
		mCamera.LookAt(.Zero);
	}

	public Sedulous.GUI.Viewport View => mView;
	public EditorCamera Camera => mCamera;
	/// The renderer it draws with; null in a host with none.
	public RenderSubsystem Renderer => mServices.Render;
	public IViewportPicker Picker => mPicker;
	/// What its debug list and its picks are keyed by.
	public void* Key => Internal.UnsafeCastToPtr(mView);

	/// Drawn and given input by `host` from now on (null: not hosted, a test).
	public void HostIn(GuiHost host)
	{
		if (host != null)
			mView.HostIn(host);
	}

	/// Whether it is on screen with targets to draw into.
	public bool IsShown => mView.IsReady && mView.IsTreeVisible && (mView.RenderWidth > 0) && (mView.RenderHeight > 0);

	/// Whether its content has the input this frame: hovered, focused, or holding a press (a look
	/// drag, its pointer locked and hidden, may drift off it).
	public bool IsActive
	{
		get
		{
			if (mScripted != null)
				return true; // a playtest of the view holds it
			let surface = mView.HostedSurface;
			return mView.Hovered || mView.IsFocused || ((surface != null) && surface.Captured);
		}
	}

	public bool IsHovered => (mScripted != null) ? ScriptedPointerInside : mView.Hovered;
	/// Whether its content has the keyboard focus (a click into it gives it).
	public bool IsFocused => mView.IsFocused;
	/// The mouse, in the targets' pixels.
	public IMouse Mouse => (mScripted != null) ? mScripted.Mouse : mView.Mouse;

	/// The keyboard while it has the focus or holds a press; null otherwise.
	public IKeyboard Keyboard
	{
		get
		{
			if (mScripted != null)
				return mScripted.Keyboard; // as if focused: the playtest's keys are the view's
			let surface = mView.HostedSurface;
			return (mView.IsFocused || ((surface != null) && surface.Captured)) ? mView.Keyboard : null;
		}
	}

	/// Whether Shift is held for what the pointer does over the view (a brush's Shift + wheel resize, a
	/// Shift click): read with the pointer, so it holds while the keys' focus is elsewhere (the
	/// brush's own panel, picked a moment ago).
	public bool ShiftHeld
	{
		get
		{
			if (mScripted != null)
				return ShiftHeldOver(mScripted.Keyboard, null, true);
			let surface = mView.HostedSurface;
			let raw = (surface != null) ? surface.Raw : null;
			return ShiftHeldOver(Keyboard, (raw != null) ? raw.Keyboard : null, mView.Hovered);
		}
	}

	/// Whether Shift is held for what the pointer does over a view: the keyboard the view has while
	/// focused, else, while the pointer is over it, the device's own (a wheel goes where the pointer
	/// is, whatever has the keys). Pure, so tested without a window.
	public static bool ShiftHeldOver(IKeyboard focused, IKeyboard device, bool hovered)
	{
		if (focused != null)
			return focused.IsKeyDown(.LeftShift) || focused.IsKeyDown(.RightShift);
		return hovered && (device != null) && (device.IsKeyDown(.LeftShift) || device.IsKeyDown(.RightShift));
	}

	/// The camera's frame: flown while the viewport has the input (`wheel` false leaves the wheel
	/// to a tool), released when it has not, its eased framing carried on either way. Whether the
	/// viewport had the input.
	public bool UpdateCamera(float deltaSeconds, bool wheel)
	{
		let active = IsActive;
		let surface = mView.HostedSurface;
		if (active)
		{
			mCamera.Update(Keyboard, Mouse, deltaSeconds, wheel);
			// An orbit, look or pan drag: the pointer locked meanwhile, granted by the router to
			// this surface alone and ended with the press (not the user's pointer for a playtest's).
			if ((surface != null) && (mScripted == null))
				surface.SetPointerLock(mCamera.WantsPointerLock);
		}
		else
		{
			// Losing the input releases a captured fly at once (relative mode makes losing it easy).
			mCamera.ReleaseCapture(Mouse);
			if (surface != null)
				surface.SetPointerLock(false);
		}
		// A framing glides on whether or not the viewport has the input (a hierarchy double click
		// frames while the mouse is over the hierarchy).
		mCamera.Advance(deltaSeconds);
		return active;
	}

	public bool ZoomedThisFrame => mCamera.ZoomedThisUpdate;

	// === A playtest of the view (viewport_run) ===

	/// `source` (OWNED from here) stands for the devices over the view from now: its mouse in the
	/// targets' pixels, its keys as if the view had the focus, the pointer over the view while
	/// inside it. Nothing real is merged in: where the user's mouse is must not change a playtest.
	/// A run already in hand is dropped for it.
	public void BeginScripted(ScriptedInputSource source)
	{
		if (mScripted != source)
			delete mScripted;
		mScripted = source;
		mScriptedTime = 0;
		mScriptedEnding = false;
		mScriptedReleased = false;
	}

	/// Ends it: everything held is let go for a frame (a brush lifts, the camera stops), then the
	/// devices are the view's again.
	public void EndScripted()
	{
		if (mScripted != null)
			mScriptedEnding = true;
	}

	/// Once a frame, before the view's input is read: the playtest's next frame.
	public void AdvanceScripted(float deltaSeconds)
	{
		if (mScripted == null)
			return;
		if (!mScriptedEnding)
		{
			mScriptedTime += (double)deltaSeconds;
			mScripted.Advance(mScriptedTime);
			return;
		}
		if (!mScriptedReleased)
		{
			mScripted.ReleaseAll();
			mScriptedReleased = true;
			return;
		}
		DeleteAndNullify!(mScripted);
	}

	/// Seconds the playtest has run; negative when none does.
	public double ScriptedTime => (mScripted != null) ? mScriptedTime : -1.0;

	/// A playtest's pointer is over the view while it is inside its targets.
	private bool ScriptedPointerInside
	{
		get
		{
			let mouse = mScripted.Mouse;
			return (mouse.X >= 0.0f) && (mouse.Y >= 0.0f) && (mouse.X < (float)mView.RenderWidth) && (mouse.Y < (float)mView.RenderHeight);
		}
	}

	/// Alt orbit, right button fly, or the Tab captured fly (which owns WASD too).
	public bool CameraOwnsInput
	{
		get
		{
			let mouse = Mouse;
			let keyboard = Keyboard;
			return ((keyboard != null) && (keyboard.IsKeyDown(.LeftAlt) || keyboard.IsKeyDown(.RightAlt)))
				|| ((mouse != null) && mouse.IsButtonDown(.Right)) || mCamera.MouseCaptured;
		}
	}

	/// The camera's ray through the mouse, from its basis (no matrix inverse).
	public bool MouseRay(out GizmoRay outRay)
	{
		outRay = .();
		let mouse = Mouse;
		let w = mView.RenderWidth;
		let h = mView.RenderHeight;
		if ((mouse == null) || (w == 0) || (h == 0))
			return false;
		let ndcX = 2.0f * (mouse.X / (float)w) - 1.0f;
		let ndcY = 1.0f - 2.0f * (mouse.Y / (float)h);
		mCamera.RayThrough(ndcX, ndcY, (float)w / (float)h, out outRay.Origin, out outRay.Direction);
		return true;
	}

	/// The view camera the renderer draws from, at the targets' aspect: from the draw eye (behind
	/// the eye under orthographic); Position stays the eye, for what the renderer measures from it
	/// (foliage fade, terrain, level of detail).
	public ViewCamera RenderCamera()
	{
		let w = mView.RenderWidth;
		let h = mView.RenderHeight;
		var camera = Sedulous.Render.ViewCamera();
		camera.View = Float4x4.LookAtRH(mCamera.DrawEye, mCamera.DrawEye + mCamera.Forward, mCamera.Up);
		camera.Projection = mCamera.Projection((h > 0) ? (float)w / (float)h : 16.0f / 9.0f);
		camera.Position = mCamera.Position;
		camera.FarZ = mCamera.DrawFar;
		camera.PullBack = mCamera.DrawPullBack;
		return camera;
	}

	/// The overlays' debug list (this viewport's own, never another view's of the scene); null
	/// with no renderer.
	public DebugDraw Overlay => (mServices.Render != null) ? mServices.Render.DebugView(Key) : null;

	/// Adds this frame's view of `scene` (inside the renderer's bracket): nothing while hidden or
	/// with no renderer. `debugView` null on a clean capture's frame.
	public void Render(ref FrameContext frame, Sedulous.Scene.Scene scene, ViewPostOverride* post, ViewDebugView debugView)
	{
		let render = mServices.Render;
		if (!frame.Valid || (render == null) || !render.IsReady || !IsShown)
			return;
		let w = mView.RenderWidth;
		let h = mView.RenderHeight;
		// RenderTexture canvases stay live in editing viewports too: an in world screen must not
		// show stale content while its scene is edited (Simulate renders through here as well).
		// The subsystems draw at most once a frame, so several pages share one draw of each.
		if (mServices.GameGui != null)
			mServices.GameGui.RenderTextures(frame.Encoder, (uint32)frame.FrameIndex);

		var cameraOverride = CameraOverride();
		cameraOverride.Camera = RenderCamera();
		// The viewport's colour is a UI colour (sRGB); the render view takes linear.
		let clear = mView.LinearClearColor;
		cameraOverride.ClearColor = .(clear.R, clear.G, clear.B, clear.A);
		// The graph imports the colour target and owns its transitions: from the viewport's state
		// (Undefined right after it is made again) to ShaderRead for the GUI to sample.
		let target = TargetState(mView.ColorTexture, mView.ColorState, .ShaderRead);
		render.RenderScene(scene, mView.ColorView, mView.ColorFormat, w, h, .(0, 0, w, h), &cameraOverride, target, post, Key, debugView);
		mView.ColorState = .ShaderRead;
		mRenderedThisFrame = true;
		mCaptureWidth = w;
		mCaptureHeight = h;
	}

	/// A capture asked for, recorded once the renderer composed the frame (RenderScene only adds
	/// the view; EndRendering, before this, writes the image).
	public void AfterRender(IApplicationHost host, ref FrameContext frame)
	{
		let rendered = mRenderedThisFrame;
		mRenderedThisFrame = false;
		if (!rendered || !mCapture.Armed || (host.Graphics == null))
			return;
		mCapture.Record(host.Graphics.Raw, frame.Encoder, mView.ColorTexture, mView.ColorFormat, mCaptureWidth, mCaptureHeight, .ShaderRead);
		mCleanCapture = false;
	}

	/// A capture recorded last frame, written once the GPU finished the copy.
	public void CompleteCapture(IApplicationHost host)
	{
		mCapture.Complete(((host != null) && (host.Graphics != null)) ? host.Graphics.Raw : null);
	}

	/// The next rendered frame to `path`; `clean`, without the editor's overlays.
	public Result<void, ErrorCode> RequestCapture(StringView path, bool clean)
	{
		mCapture.Request(path);
		mCleanCapture = clean;
		return .Ok;
	}

	/// The frame an armed clean capture records: the overlays held back.
	public bool CleanCaptureFrame => mCleanCapture && mCapture.Armed;
	public ViewportCapture LastCapture => mCapture.State;

	/// Frames `entities`, each with everything under it, as the scene's systems measure them (a
	/// small box at an entity's place when nothing does); false when none resolves.
	public bool Frame(Sedulous.Scene.Scene scene, Span<Guid> entities, bool ease)
	{
		var merged = AABB.Empty();
		var any = false;
		let pending = scope List<EntityHandle>();
		for (let id in entities)
		{
			let e = scene.FindEntity(id);
			if (!scene.IsValid(e))
				continue;
			var span = AABB.Empty();
			var measured = false;
			pending.Clear();
			pending.Add(e);
			while (!pending.IsEmpty)
			{
				let current = pending.PopBack();
				if (scene.EntityWorldBounds(current, let part))
				{
					span = measured ? Merge(span, part) : part;
					measured = true;
				}
				for (var child = scene.GetFirstChild(current); scene.IsValid(child); child = scene.GetNextSibling(child))
					pending.Add(child);
			}
			if (!measured)
			{
				// Nothing in it measures (an empty, a light): its place, the marker's size.
				let world = scene.GetWorldMatrix(e);
				span = AABB.FromCenterExtents(.(world.M[3][0], world.M[3][1], world.M[3][2]), .(0.35f, 0.35f, 0.35f));
			}
			merged = any ? Merge(merged, span) : span;
			any = true;
		}
		if (!any)
			return false;
		mCamera.FrameSphere(merged.Center(), Length(merged.Extents()), mCamera.FovY, ease);
		return true;
	}

	/// Before the page goes: the camera never closes captured, the picks keyed by it are
	/// cancelled, a picture recorded and not yet written is written (it waits for the GPU: a save's
	/// launcher picture, the editor closing that same frame, was freed while the copy was still
	/// running), then the readback buffer goes while the device lives.
	public void Close(IApplicationHost host)
	{
		mCamera.ReleaseCapture(Mouse);
		if (mServices.Render != null)
			mServices.Render.CancelPicks(Key);
		if ((host != null) && (host.Graphics != null) && (host.Graphics.Raw != null))
		{
			CompleteCapture(host);
			mCapture.Release(host.Graphics.Raw);
		}
	}

	/// The GPU pick seam the tools see: the renderer's picks keyed by this viewport (the key its
	/// RenderScene carries), hits decoded to entity handles.
	private class ViewportPicker : IViewportPicker
	{
		private SceneViewport mViewport;
		private PickResult mResult = new .() ~ delete _;

		public this(SceneViewport viewport) { mViewport = viewport; }

		public uint32 RequestPick(int32 x, int32 y, uint32 width, uint32 height)
		{
			let render = mViewport.mServices.Render;
			if ((render == null) || !render.IsReady)
				return 0;
			return render.RequestPick(mViewport.Key, x, y, width, height);
		}

		public bool TryTakePick(uint32 request, List<EntityHandle> hits)
		{
			let render = mViewport.mServices.Render;
			if ((render == null) || !render.TryTakePickResult(request, mResult))
				return false;
			hits.Clear();
			for (let hit in mResult.Hits)
				hits.Add(.(hit.EntityIndex, hit.Generation));
			return true;
		}
	}
}
