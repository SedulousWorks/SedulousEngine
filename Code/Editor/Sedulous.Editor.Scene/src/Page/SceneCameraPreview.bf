using System;
using Sedulous.Core;
using Sedulous.Graphics;
using Sedulous.Scene;
using Sedulous.Render;
using Sedulous.Engine.Render;
using Sedulous.GUI;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Scene;

// The camera preview in the HUD's bottom end (the mock's
// scene.xml): what a scene camera sees while the scene is edited from elsewhere. It shows the
// selected camera, or the one pinned (a pin wins while its entity is alive and still a camera; a
// stale pin clears itself, CameraPreview.Resolve's decision), titled with that camera's name and
// icon, its picture at the camera's own aspect. The picture is a second view of the scene through
// the camera, keyed by the preview's own viewport, so the editor's grid, gizmos and markers (the
// main view's debug list) never show in it, nor the main view's shading override. It takes no
// input: the main view keeps the pointer under it.

/// What the camera preview works over: borrowed.
struct SceneCameraPreviewServices
{
	public SceneEditContext Edit = null;
	/// The camera's icon; null: the generic one.
	public EditorIcons Icons = null;
	/// Null: nothing renders (a test).
	public RenderSubsystem Render = null;
}

class SceneCameraPreview
{
	/// The picture's width: the panel's 200 px less its padding (editor.css, .camera-preview).
	public const float cPictureWidth = 194.0f;

	private SceneCameraPreviewServices mServices;
	/// One reference, this one's: its holder in the pane keeps its own.
	private Sedulous.GUI.Viewport mView ~ _.ReleaseRef();
	// The pane's: the tree holds them.
	private Node mPanel = null;
	private Sedulous.GUI.Image mIcon = null;
	private Sedulous.GUI.Label mName = null;
	private Sedulous.GUI.Button mPin = null;
	/// The camera shown (nil: none).
	private Guid mTarget = .Empty;
	/// The camera pinned (nil: the selection's).
	private Guid mPinned = .Empty;
	private Float2 mSize = .Zero;

	/// The preview over the edit context's scene in `pane` (the markup's `camera-preview`,
	/// `camera-preview-view`, `camera-preview-icon`, `camera-preview-name` and
	/// `camera-preview-pin`, by id). `pane` is borrowed.
	public this(SceneCameraPreviewServices services, Node pane)
	{
		mServices = services;
		mView = new Sedulous.GUI.Viewport();
		mView.AddClass("camera-preview-picture");
		mView.ClearColor = .(0.0f, 0.0f, 0.0f, 1.0f);
		mView.TabFocusable = false;
		mView.HitTestVisible = false; // the main view keeps the pointer under it
		mPanel = pane.FindElement("camera-preview");
		mIcon = pane.FindElement("camera-preview-icon") as Sedulous.GUI.Image;
		mName = pane.FindElement("camera-preview-name") as Sedulous.GUI.Label;
		mPin = pane.FindElement("camera-preview-pin") as Sedulous.GUI.Button;
		if (let holder = pane.FindElement("camera-preview-view"))
			holder.AddChild(mView);
		if (mPanel != null)
			mPanel.Displayed = false; // until a camera is shown
		if (mPin != null)
			mPin.SetOnClick(new () => { TogglePin(); });
	}

	/// Drawn by `host` from now on (null: not hosted, a test).
	public void HostIn(GuiHost host)
	{
		if (host != null)
			mView.HostIn(host);
	}

	/// Once a frame: which camera, its title and aspect, shown or hidden.
	public void Update()
	{
		let edit = mServices.Edit;
		if (edit == null)
			return;
		let scene = edit.Scene;
		let selection = edit.EntitySelection;
		let selected = (!selection.IsEmpty && IsCamera(selection.Primary)) ? selection.Primary : Guid.Empty;
		// Resolve's decision, over the live scene: a pin wins while its entity is alive and still a
		// camera, else the selection when it is a camera. The pin is kept by guid (a handle does not
		// outlive a reload), so a stale one (its entity gone, or no longer a camera) is cleared here
		// and the decision sees no pin.
		if (!IsCamera(mPinned))
			mPinned = .Empty;
		let selectedAt = selected.IsNil ? EntityHandle.Invalid : scene.FindEntity(selected);
		let pinnedAt = mPinned.IsNil ? EntityHandle.Invalid : scene.FindEntity(mPinned);
		let resolved = CameraPreview.Resolve(selectedAt, selectedAt.IsAssigned, pinnedAt, pinnedAt.IsAssigned);
		mTarget = resolved.Visible ? scene.GetEntityId(resolved.Target) : .Empty;

		if ((mPanel != null) && (mPanel.Displayed != !mTarget.IsNil))
			mPanel.Displayed = !mTarget.IsNil;
		if (mTarget.IsNil)
			return;
		// Titled with its camera: its name, the camera's icon.
		let name = scene.GetEntityName(scene.FindEntity(mTarget));
		if (mName != null)
			mName.Text = name.IsEmpty ? "(unnamed)" : name;
		if ((mIcon != null) && (mServices.Icons != null))
		{
			let icon = mServices.Icons.For(typeof(CameraComponent), "");
			mIcon.Source = icon.Source;
			if (!icon.Class.IsEmpty && !mIcon.HasClass(icon.Class))
				mIcon.AddClass(icon.Class);
		}
		if (mPin != null)
		{
			let on = !mPinned.IsNil && (mPinned == mTarget);
			if (on != mPin.HasClass("checked"))
			{
				if (on)
					mPin.AddClass("checked");
				else
					mPin.RemoveClass("checked");
			}
			mPin.Tooltip = on ? "Unpin: show the selected camera again" : "Pin: keep showing this camera";
		}
		// At the camera's aspect, kept sensible (a thin strip or a tower helps no one).
		let camera = CameraOf(mTarget);
		let aspect = Math.Clamp(((camera != null) && (camera.Aspect > 0.0f)) ? camera.Aspect : 16.0f / 9.0f, 0.5f, 3.0f);
		let size = Float2(cPictureWidth, Math.Round(cPictureWidth / aspect));
		if ((size.X != mSize.X) || (size.Y != mSize.Y))
		{
			mSize = size;
			mView.EditLayoutStyle(scope (s) =>
				{
					s.Width = LayoutLength.Px(size.X);
					s.Height = LayoutLength.Px(size.Y);
				});
		}
	}

	/// Pins the camera shown, or unpins it when it is the pinned one.
	public void TogglePin()
	{
		if (!mPinned.IsNil && (mPinned == mTarget))
			mPinned = .Empty;
		else if (!mTarget.IsNil)
			mPinned = mTarget;
		Update();
	}

	/// This frame's picture (inside the renderer's bracket): nothing while hidden.
	public void Render(ref FrameContext frame)
	{
		let render = mServices.Render;
		if (!frame.Valid || (render == null) || !render.IsReady || (mServices.Edit == null) || mTarget.IsNil)
			return;
		if (!mView.IsReady || !mView.IsTreeVisible || (mView.RenderWidth == 0) || (mView.RenderHeight == 0))
			return;
		let camera = CameraOf(mTarget);
		if (camera == null)
			return;
		let scene = mServices.Edit.Scene;
		let w = mView.RenderWidth;
		let h = mView.RenderHeight;
		var cameraOverride = CameraPreview.BuildOverride(*camera, scene.GetWorldMatrix(scene.FindEntity(mTarget)));
		let target = TargetState(mView.ColorTexture, mView.ColorState, .ShaderRead);
		// Keyed by the preview's own viewport: its debug list is empty, so the editor's overlays
		// (drawn into the main view's) never show here; no shading override, the game's look.
		render.RenderScene(scene, mView.ColorView, mView.ColorFormat, w, h, .(0, 0, w, h), &cameraOverride, target, null, Internal.UnsafeCastToPtr(mView), null);
		mView.ColorState = .ShaderRead;
	}

	// === What it shows (for tests) ===

	public bool IsShown => (mPanel != null) && mPanel.Displayed && !mTarget.IsNil;
	public Guid Target => mTarget;
	public Guid Pinned => mPinned;
	public StringView Title => ((mName != null) && IsShown) ? mName.Text : default;
	/// The picture's size in the layout's pixels.
	public Float2 PictureSize => mSize;
	public Sedulous.GUI.Viewport Picture => mView;

	private CameraComponent* CameraOf(Guid entity)
	{
		if ((mServices.Edit == null) || entity.IsNil)
			return null;
		let scene = mServices.Edit.Scene;
		let e = scene.FindEntity(entity);
		let cameras = scene.GetSystem<CameraComponentManager>();
		return (e.IsAssigned && scene.IsValid(e) && (cameras != null)) ? cameras.Get(e) : null;
	}

	private bool IsCamera(Guid entity) => CameraOf(entity) != null;
}
