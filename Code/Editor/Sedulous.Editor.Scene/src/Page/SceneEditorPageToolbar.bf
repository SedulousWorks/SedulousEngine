using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Scene.Resource;
using Sedulous.Render;
using Sedulous.Engine.Render;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Scene;

/// The viewport toolbar: gizmo mode and space, the grid, LOD and collider overlays, the post
/// and debug view menus, one toggle per registered tool, and Simulate.
extension SceneEditorPage
{
	private void BuildViewportToolbar()
	{
		mToolbar = new Toolbar();
		let gizmos = (mSelectTool != null) ? mSelectTool.Gizmos : null;

		mTranslateToggle = mToolbar.AddToggle("");
		mTranslateToggle.SetIcon(new (ctx, rect) => { DrawIcon(EditorIcons.Translate, ctx, rect); });
		mTranslateToggle.OnCheckedChanged.Add(new [=gizmos](t, value) => { if (value && (gizmos != null)) gizmos.SetMode(.Translate); });
		mRotateToggle = mToolbar.AddToggle("");
		mRotateToggle.SetIcon(new (ctx, rect) => { DrawIcon(EditorIcons.Rotate, ctx, rect); });
		mRotateToggle.OnCheckedChanged.Add(new [=gizmos](t, value) => { if (value && (gizmos != null)) gizmos.SetMode(.Rotate); });
		mScaleToggle = mToolbar.AddToggle("");
		mScaleToggle.SetIcon(new (ctx, rect) => { DrawIcon(EditorIcons.Scale, ctx, rect); });
		mScaleToggle.OnCheckedChanged.Add(new [=gizmos](t, value) => { if (value && (gizmos != null)) gizmos.SetMode(.Scale); });

		mToolbar.AddSeparator();

		mSpaceToggle = mToolbar.AddToggle("World");
		mSpaceToggle.SetIcon(new [=gizmos](ctx, rect) =>
		{
			let world = (gizmos == null) || (gizmos.Space == .World);
			DrawIcon(world ? EditorIcons.WorldSpace : EditorIcons.LocalSpace, ctx, rect);
		});
		mSpaceToggle.OnCheckedChanged.Add(new [=gizmos](toggle, value) =>
		{
			if (gizmos != null)
				gizmos.SetSpace(value ? .World : .Local);
			toggle.SetText(value ? "World" : "Local");
		});

		mToolbar.AddSeparator();

		mGridToggle = mToolbar.AddToggle("");
		mGridToggle.SetIcon(new (ctx, rect) => { DrawIcon(EditorIcons.Grid, ctx, rect); });
		mGridToggle.OnCheckedChanged.Add(new [=this](t, value) => { mView.ShowGrid = value; SaveViewPrefs(); });
		mLodToggle = mToolbar.AddToggle("LOD");
		mLodToggle.OnCheckedChanged.Add(new [=this](t, value) => { mView.ShowLodOverlay = value; SaveViewPrefs(); });
		mCollidersToggle = mToolbar.AddToggle("Colliders");
		mCollidersToggle.OnCheckedChanged.Add(new [=this](t, value) => { mView.ShowColliders = value; SaveViewPrefs(); });
		LoadViewPrefs();

		let postButton = mToolbar.AddButton("Post");
		postButton.OnClick.Add(new [=this](btn) => { ShowPostFlagsMenu(btn); });
		let debugButton = mToolbar.AddButton("Debug");
		debugButton.OnClick.Add(new [=this](btn) => { ShowDebugViewMenu(btn); });

		if (mViewportTools.Count > 1)
		{
			mToolbar.AddSeparator();
			for (int i = 1; i < mViewportTools.Count; i++)
			{
				let tool = mViewportTools.ToolAt(i);
				if (tool == null)
					continue;
				let id = new String(tool.Id);
				let toggle = mToolbar.AddToggle(tool.DisplayName);
				toggle.OnCheckedChanged.Add(new [=this, =id](t, value) =>
				{
					if (value)
					{
						// A refusal, the tool having nothing here to work on, is SAID rather
						// than swallowed; the toggle snaps back through the sync below.
						if (!mViewportTools.ActivateById(id))
						{
							let refused = mViewportTools.FindById(id);
							if (refused != null)
								mContext.Notify(.Warning, refused.UnavailableReason);
						}
					}
					else if ((mViewportTools.ActiveTool != null) && (mViewportTools.ActiveTool.Id == id))
						mViewportTools.ActivateDefault();
					SyncToolbar();
				});
				mToolToggles.Add((toggle, id));
			}
		}

		let spacer = new Panel();
		var grow = LayoutStyle();
		grow.FlexGrow = 1.0f;
		mToolbar.AddView(spacer, grow);

		mPlayButton = mToolbar.AddButton("Play");
		mPlayButton.OnClick.Add(new [=this](b) => { StartSimulation(); });
		mPauseToggle = mToolbar.AddToggle("Pause");
		mPauseToggle.OnCheckedChanged.Add(new [=this](t, value) => { PauseSimulation(value); });
		mStopButton = mToolbar.AddButton("Stop");
		mStopButton.OnClick.Add(new [=this](b) => { StopSimulation(); });
		mSimLabel = new Label("");
		mSimLabel.FontSize.Value = 13.0f;
		mToolbar.AddItem(mSimLabel);
		RefreshSimToolbar();
	}

	private static void DrawIcon(SVGDrawable drawable, UIDrawContext ctx, Rectangle rect)
	{
		if (drawable != null)
			drawable.Draw(ctx, rect);
	}

	// ---- simulate ----

	/// Snapshots the scene, starts it and locks the undo stack; Stop restores the snapshot.
	private void StartSimulation()
	{
		if (mIsSimulating || (mScene == null))
			return;
		delete mSimSnapshot;
		mSimSnapshot = SceneSnapshot.Capture(mScene);
		if (mSimSnapshot == null)
		{
			GlobalLog(.Error, "Editor: Simulate: scene snapshot capture failed");
			return;
		}
		mScene.Start();
		mScene.SetSimulationEnabled(true);
		Commands.IsLocked = true;
		mViewportTools.ActivateDefault();
		SyncToolbar();
		mIsSimulating = true;
		mIsPaused = false;
		RefreshSimToolbar();
	}

	private void PauseSimulation(bool paused)
	{
		if (!mIsSimulating || (mScene == null))
			return;
		mIsPaused = paused;
		mScene.SetSimulationEnabled(!paused);
		RefreshSimToolbar();
	}

	private void StopSimulation()
	{
		if (!mIsSimulating || (mScene == null))
			return;
		mScene.Stop();
		if (mSimSnapshot != null)
		{
			if (mSimSnapshot.Restore(mScene, mContext.Resources) case .Err)
				GlobalLog(.Error, "Editor: Simulate: snapshot restore failed");
			delete mSimSnapshot;
			mSimSnapshot = null;
		}
		mScene.SetSimulationEnabled(false);
		Commands.IsLocked = false;
		mIsSimulating = false;
		mIsPaused = false;
		RefreshSimToolbar();
	}

	private void RefreshSimToolbar()
	{
		if (mPlayButton == null)
			return;
		mPlayButton.IsEnabled = !mIsSimulating;
		mPauseToggle.IsEnabled = mIsSimulating;
		mStopButton.IsEnabled = mIsSimulating;
		mPauseToggle.IsChecked = mIsPaused;
		if (mSimLabel != null)
		{
			if (!mIsSimulating)
			{
				mSimLabel.SetText("");
			}
			else
			{
				mSimLabel.SetText(mIsPaused ? " PAUSED " : " SIMULATING ");
				mSimLabel.TextColor.Value = mIsPaused ? Color(0.95f, 0.85f, 0.4f, 1.0f) : Color(0.95f, 0.55f, 0.35f, 1.0f);
			}
		}
		mPlayButton.Invalidate();
		mPauseToggle.Invalidate();
		mStopButton.Invalidate();
	}

	// ---- view prefs ----

	/// This scene's saved view state, per project, by guid.
	private void LoadViewPrefs()
	{
		mView = SceneViewPrefs.Load(mContext.ProjectEditorSettings, InstanceId, mView);
	}

	/// Persists it on any viewport toggle.
	private void SaveViewPrefs()
	{
		if (SceneViewPrefs.Save(mContext.ProjectEditorSettings, InstanceId, mView))
			mContext.RequestProjectEditorSettingsSave();
	}

	/// Persists the camera framing and the entity selection, written when the page closes.
	private void SaveViewState()
	{
		let camera = SceneViewCamera(mCamera.Position, mCamera.Yaw, mCamera.Pitch, mCamera.FocusDistance);
		let selection = (mEditContext != null) ? mEditContext.EntitySelection.Items : Span<Guid>();
		if (SceneViewPrefs.SaveView(mContext.ProjectEditorSettings, InstanceId, camera, selection))
			mContext.RequestProjectEditorSettingsSave();
	}

	/// Restores that framing and selection, after the scene's content has loaded so the ids
	/// can be checked. A pref with no camera leaves the default framing standing.
	private void RestoreViewState()
	{
		let pref = SceneViewPrefs.Find(mContext.ProjectEditorSettings, InstanceId);
		if ((pref == null) || !pref.HasCamera)
			return;
		mCamera.Position = pref.Camera.Position;
		mCamera.Yaw = pref.Camera.Yaw;
		mCamera.Pitch = pref.Camera.Pitch;
		mCamera.FocusDistance = pref.Camera.FocusDistance;
		if ((mEditContext == null) || (mScene == null) || pref.Selection.IsEmpty)
			return;
		// Only ids the scene still has: one deleted since, or spawned by a Simulate run that
		// has ended, must not come back as a selected ghost.
		List<Guid> live = scope .();
		for (let id in pref.Selection)
		{
			if (mScene.FindEntity(id).IsAssigned)
				live.Add(id);
		}
		if (!live.IsEmpty)
			mEditContext.EntitySelection.Set(live);
	}

	private void SyncToolbar()
	{
		if ((mToolbar == null) || (mSelectTool == null))
			return;
		let mode = mSelectTool.Gizmos.Mode;
		mTranslateToggle.IsChecked = mode == .Translate;
		mRotateToggle.IsChecked = mode == .Rotate;
		mScaleToggle.IsChecked = mode == .Scale;
		mSpaceToggle.IsChecked = mSelectTool.Gizmos.Space == .World;
		mGridToggle.IsChecked = mView.ShowGrid;
		if (mLodToggle != null)
			mLodToggle.IsChecked = mView.ShowLodOverlay;
		if (mCollidersToggle != null)
			mCollidersToggle.IsChecked = mView.ShowColliders;

		let activeTool = mViewportTools.ActiveTool;
		let activeId = (activeTool != null) ? activeTool.Id : StringView();
		for (let tt in mToolToggles)
		{
			if (tt.toggle != null)
				tt.toggle.IsChecked = tt.id == activeId;
		}
	}

	// ---- menus ----

	private static StringView Mark(bool on) => on ? "[x] " : "[ ] ";

	/// The viewport's post flags: each a toggle, then the MSAA levels.
	private void ShowPostFlagsMenu(View anchor)
	{
		if (anchor == null)
			return;
		let menu = new ContextMenu();
		defer menu.ReleaseRef();
		menu.AddItem(scope $"{Mark(mPostOverride.DisablePost)}No Post (bloom/AO/SSR/AA off)", new [=this]() => { mPostOverride.DisablePost = !mPostOverride.DisablePost; });
		menu.AddSeparator();
		menu.AddItem(scope $"{Mark(mPostOverride.DisableBloom)}No Bloom", new [=this]() => { mPostOverride.DisableBloom = !mPostOverride.DisableBloom; });
		menu.AddItem(scope $"{Mark(mPostOverride.DisableAo)}No AO", new [=this]() => { mPostOverride.DisableAo = !mPostOverride.DisableAo; });
		menu.AddItem(scope $"{Mark(mPostOverride.DisableSsr)}No SSR", new [=this]() => { mPostOverride.DisableSsr = !mPostOverride.DisableSsr; });
		menu.AddItem(scope $"{Mark(mPostOverride.DisableSsgi)}No SSGI", new [=this]() => { mPostOverride.DisableSsgi = !mPostOverride.DisableSsgi; });
		menu.AddItem(scope $"{Mark(mPostOverride.DisableAa)}No AA (crisp)", new [=this]() => { mPostOverride.DisableAa = !mPostOverride.DisableAa; });
		menu.AddSeparator();
		for (let level in MsaaLevels.All)
		{
			let count = (uint8)level.Samples;
			let on = (count <= 1) ? (mPostOverride.MsaaOverride <= 1) : (mPostOverride.MsaaOverride == count);
			menu.AddItem(scope $"{Mark(on)}MSAA {level.Label}", new [=this, =count]() => { mPostOverride.MsaaOverride = count; });
		}
		let pos = anchor.LocalToScreen(.(0.0f, anchor.Height));
		menu.Show(anchor.Context, pos.X, pos.Y);
	}

	/// The debug view: final, a semantic view, or a render resource.
	private void ShowDebugViewMenu(View anchor)
	{
		if ((anchor == null) || (mRender == null))
			return;
		let menu = new ContextMenu();
		defer menu.ReleaseRef();

		menu.AddItem(scope $"{Mark(mDebugView.IsOff)}Final (debug view off)", new [=this]() =>
		{
			mDebugView.Resource.Clear();
			mDebugView.Semantic = .Off;
		});
		menu.AddSeparator();

		for (let entry in scope (StringView label, ViewDebugSemantic mode)[](
			("Albedo (base color)", .Albedo), ("Normals (world, mapped)", .Normal), ("Roughness", .Roughness),
			("Metallic", .Metallic), ("Shadow cascades", .Cascades), ("Light-cluster heatmap", .ClusterHeat),
			("Overbright / invalid", .Overbright)))
		{
			let on = (mDebugView.Semantic == entry.mode) && mDebugView.Resource.IsEmpty;
			let mode = entry.mode;
			menu.AddItem(scope $"{Mark(on)}{entry.label}", new [=this, =mode]() =>
			{
				mDebugView.Resource.Clear(); // a semantic and a resource are exclusive
				mDebugView.Semantic = mode;
			});
		}
		menu.AddSeparator();

		let rows = scope List<DebugResourceInfo>();
		defer { ClearAndDeleteItems(rows); }
		mRender.GetDebugResources(rows);
		for (let row in rows)
		{
			if (row.Samples > 1)
				continue;
			let name = new String(row.Name);
			let text = scope $"{Mark(mDebugView.Resource == row.Name)}{row.Name}  {row.Width}x{row.Height}{row.IsDepth ? " depth" : ""}";
			menu.AddItem(text, new [=this, =name]() =>
			{
				mDebugView.Resource.Set(name);
				mDebugView.Semantic = .Off;
				mDebugView.NearZ = 0.1f;
				mDebugView.FarZ = 1000.0f;
			} ~ delete name);
		}

		let pos = anchor.LocalToScreen(.(0.0f, anchor.Height));
		menu.Show(anchor.Context, pos.X, pos.Y);
	}
}
