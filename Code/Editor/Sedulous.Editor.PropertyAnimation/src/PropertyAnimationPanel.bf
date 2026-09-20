using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Content;
using Sedulous.Scene;
using Sedulous.Render;
using Sedulous.PropertyAnimation;
using Sedulous.PropertyAnimation.Resource;
using Sedulous.PropertyAnimation.Pipeline;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;

namespace Sedulous.Editor.PropertyAnimation;

/// The persistent in-scene property-animation editor: a docked view, not a viewport tool
/// mode, that the scene page owns for its whole lifetime below the viewport. Persistent, so
/// the editing view is never recreated mid edit and an undo command can never outlive it, and
/// the preview snapshot is re-taken whenever the track set changes. The panel is the clip
/// editor host: it owns the editing clip, routes edits through the scene page's command
/// stack, loads, creates and saves the clip asset, owns the live-preview state, and hosts the
/// Timeline scrubber above the shared ClipEditorView. The scene page calls Tick and
/// DrawOverlay each frame.
class PropertyAnimationPanel : FlexLayout, IClipEditorHost
{
	/// The entity's local transform is animated by naming it with this reserved component
	/// type; it is baked into the scene, not a reflected component.
	public const String cTransformName = "Transform";

	// The dopesheet lane sizing.
	private const float cLaneHeight = 22.0f;
	private const float cRulerBand = 24.0f;
	private const float cTimelineMinHeight = 28.0f;
	private const float cTimelineMaxHeight = 220.0f;

	// Borrowed: the scene page owns them and the panel.
	private EditorContext mEditorCtx;
	private Scene mScene;
	private EditorCommandStack mCommands;
	private Selection<Guid> mSelection;
	/// The editing model, durable across the panel's life.
	private PropertyAnimationClip mClip = new .() ~ delete _;
	/// The clip asset being edited; Empty is none loaded.
	private Guid mClipId = .Empty;
	private String mClipName = new .() ~ delete _;
	private bool mDirty = false;
	/// The transient header status; empty is none.
	private String mStatusFlash = new .() ~ delete _;
	private float mStatusFlashSeconds = 0.0f;

	// The chrome, built once; borrowed, the tree owns them.
	private Label mClipLabel = null;
	/// Anchors the "+ Track" property-picker menu.
	private Button mAddTrackButton = null;
	private Button mPlayButton = null;
	private Button mPauseButton = null;
	private Button mLoopButton = null;
	private Timeline mTimeline = null;
	/// Sizes the timeline pane to its lanes.
	private LayoutStyle mTimelineParams = .();
	/// The clip and entity chrome, hidden while empty.
	private FlexLayout mHeader = null;
	/// The "no clip" message with Create and Open, exclusive with the body.
	private FlexLayout mEmptyState = null;
	private Label mEntityLabel = null;
	/// The transport, Timeline and ClipEditorView.
	private FlexLayout mBody = null;
	private ClipEditorView mView = null ~ delete _;
	/// The explicit preview, key and seed target; Empty is unbound.
	private Guid mBoundEntity = .Empty;

	/// The scene page wires this to its entity picker; the panel cannot depend on the scene
	/// editor. Called with the current binding and a callback for the pick. Owned.
	public delegate void(Guid current, delegate void(Guid picked) onPicked) RequestEntityPick ~ delete _;

	// The dopesheet lane bookkeeping: the sorted key time each marker on a lane represents,
	// parallel to the Timeline's lanes, so a (lane, index) selection maps to a time.
	private List<List<float>> mLaneKeyTimes = new .() ~ DeleteContainerAndItems!(_);
	/// The moved keys' new times, consumed by the next BuildLanes.
	private List<ReselectMark> mReselectTimes = new .() ~ delete _;
	private bool mHaveReselect = false;

	// The transport, editor-local. Loop defaults on, matching a fresh animator component.
	private bool mPlaying = false;
	private bool mPaused = false;
	private bool mLoop = true;
	/// The transport clock, mirrored to the Timeline widget.
	private float mPlayheadTime = 0.0f;

	// The preview state, transient: never dirties the document or goes through undo.
	/// The last Tick's Simulate or Play gate; no preview when true.
	private bool mEditingLocked = false;
	private bool mPreviewing = false;
	private EntityHandle mPreviewEntity = .();
	private float mPreviewTime = 0.0f;
	/// The pre-preview values, restored on stop.
	private List<PreviewSnapshotEntry> mSnapshot = new .() ~ DeleteContainerAndItems!(_);
	/// The track identity the snapshot was taken against.
	private List<String> mSnapshotIdentity = new .() ~ DeleteContainerAndItems!(_);

	public this(EditorContext editorCtx, Scene scene, EditorCommandStack commands, Selection<Guid> selection)
	{
		mEditorCtx = editorCtx;
		mScene = scene;
		mCommands = commands;
		mSelection = selection;
		BuildChrome();
		RefreshHeader();
		RefreshEntitySlot();
		RefreshTransportButtons();
		BuildLanes();
		RefreshClipStateUI(); // no clip yet: the empty state is the whole panel
	}

	public ~this()
	{
		StopPreview();
	}

	// ---- IClipEditorHost -------------------------------------------------------------------

	public PropertyAnimationClip Clip => mClip;
	public EditorCommandStack Commands => mCommands;

	public void MarkClipDirty()
	{
		let wasDirty = mDirty;
		mDirty = true;
		if (!wasDirty)
			RefreshHeader(); // the dirty star shows as soon as the first edit lands
		// A live canvas edit mutates keys without a view rebuild: the dopesheet markers resync
		// now, or they lag until the next full rebuild.
		if (mTimeline != null)
			mTimeline.SetDuration(Math.Max(Math.Max(mClip.Duration, mClip.ComputeDuration()), 1.0f));
		BuildLanes();
	}

	/// The scrub moved: ignored while Playing, since the transport owns the playhead then.
	/// Drives live preview off the new time.
	public void OnScrubTimeChanged(float time)
	{
		if (mPlaying && !mPaused)
			return;
		mPlayheadTime = time; // a scrub repositions the transport clock
		if (mView != null)
			mView.SetScrubTime(time);
		PreviewSelected(time);
	}

	/// The view rebuilt its rows: the Timeline axis resyncs to the authored duration and the
	/// lanes rebuild, selection preserved by time.
	public void OnClipViewRebuilt()
	{
		if (mTimeline != null)
			mTimeline.SetDuration(Math.Max(Math.Max(mClip.Duration, mClip.ComputeDuration()), 1.0f));
		BuildLanes();
	}

	/// The undo and redo whole-clip apply, routed through the view; the command holds this
	/// host, never a view pointer.
	public void ApplyClipState(PropertyAnimationClip state, bool rebuild)
	{
		if (mView != null)
			mView.ApplyState(state, rebuild);
		else
			state.CopyTo(mClip);
	}

	/// Authors the clip's duration, never below the last key; one undo step.
	public void SetClipDuration(float seconds)
	{
		if (mView == null)
			return;
		let before = mClip.Clone();
		let after = mClip.Clone();
		after.Duration = Math.Max(seconds, after.ComputeDuration());
		if (after.Duration == before.Duration)
		{
			delete before;
			delete after;
			return;
		}
		mView.PushClipEdit(before, after);
	}

	public ClipTimeAxis ClipTimeTransform
	{
		get
		{
			var axis = ClipTimeAxis();
			if (mTimeline != null)
			{
				axis.PixelsPerSecond = mTimeline.PixelsPerSecond;
				axis.ScrollSeconds = mTimeline.ScrollSeconds;
				axis.LabelColumnWidth = mTimeline.LabelColumnWidth;
			}
			return axis;
		}
	}

	/// The key-from-scene capture source: the bound entity's live value. Every failure names
	/// its stage, since the chain has five distinct ways to miss.
	public PropertyValue ReadSceneValue(StringView componentType, StringView propertyPath)
	{
		if (mScene == null)
		{
			GlobalLog(.Warning, "PropertyAnimation: Key capture: the panel has no scene");
			return .Empty;
		}
		if (!mBoundEntity.IsSet)
		{
			GlobalLog(.Warning, "PropertyAnimation: Key capture: no entity bound (use Bind... or Use Selected)");
			return .Empty;
		}
		let entity = mScene.FindEntity(mBoundEntity);
		if (!entity.IsAssigned)
		{
			GlobalLog(.Warning, "PropertyAnimation: Key capture: the bound guid {} is not an entity of scene '{}'", mBoundEntity, mScene.Name);
			return .Empty;
		}
		let value = ReadTrackTarget(entity, componentType, propertyPath);
		if (!value.HasValue)
		{
			if (componentType == cTransformName)
			{
				GlobalLog(.Warning, "PropertyAnimation: Key capture: property path '{}' did not resolve on the Transform", propertyPath);
			}
			else
			{
				let mgr = FindManagerByComponentTypeName(componentType);
				if (mgr == null)
					GlobalLog(.Warning, "PropertyAnimation: Key capture: no component manager named '{}' on this scene", componentType);
				else if (!mgr.HasComponent(entity))
					GlobalLog(.Warning, "PropertyAnimation: Key capture: the bound entity has no '{}' component", componentType);
				else
					GlobalLog(.Warning, "PropertyAnimation: Key capture: property path '{}' did not resolve on '{}'", propertyPath, componentType);
			}
		}
		return value;
	}

	// ---- the frame hooks -------------------------------------------------------------------

	/// Advances playback when Playing, driving the playhead and preview; caches the edit gate
	/// and stands playback and preview down when locked. Only mutates widgets while playing.
	public void Tick(float dt, bool editingLocked)
	{
		if (mStatusFlashSeconds > 0.0f)
		{
			mStatusFlashSeconds -= Math.Max(dt, 0.0f);
			if (mStatusFlashSeconds <= 0.0f)
			{
				mStatusFlash.Clear();
				RefreshHeader();
			}
		}
		mEditingLocked = editingLocked;
		if (mEditingLocked)
		{
			StopPlaybackInternal(); // no editor playback under Simulate or Play
			StopPreview();
			return;
		}
		if (mPlaying && !mPaused)
			Advance(dt);
	}

	/// The preview marker overlay: at the previewed entity's world position, over geometry.
	public void DrawOverlay(DebugDraw drawList)
	{
		if (!mPreviewing || (mScene == null) || !mPreviewEntity.IsAssigned)
			return;
		let world = mScene.GetWorldMatrix(mPreviewEntity);
		let p = Float3(world.M[3][0], world.M[3][1], world.M[3][2]);
		let marker = Color(1.0f, 0.85f, 0.2f, 1.0f);
		drawList.DrawWireSphereOverlay(p, 0.35f, marker);
		drawList.DrawText3D(p, "preview", marker);
	}

	// ---- the transport ---------------------------------------------------------------------

	/// Starts or resumes advancing from the current playhead, restarting if at the end.
	public void Play()
	{
		if (mClip.Tracks.IsEmpty)
			return;
		let dur = Math.Max(Math.Max(mClip.Duration, mClip.ComputeDuration()), 1e-3f);
		if (mPlayheadTime >= dur - 1e-4f)
			mPlayheadTime = 0.0f;
		mPlaying = true;
		mPaused = false;
		RefreshTransportButtons();
	}

	/// Pauses or resumes while Playing; a no-op when stopped.
	public void TogglePause()
	{
		if (!mPlaying)
			return;
		mPaused = !mPaused;
		RefreshTransportButtons();
	}

	/// Stops and rewinds the playhead to 0, showing the start pose.
	public void Stop()
	{
		mPlaying = false;
		mPaused = false;
		mPlayheadTime = 0.0f;
		if (mTimeline != null)
			mTimeline.SetPlayheadTime(0.0f);
		if (mView != null)
			mView.SetScrubTime(0.0f);
		PreviewSelected(0.0f);
		RefreshTransportButtons();
	}

	/// Stops advancing without rewinding, the Simulate override.
	private void StopPlaybackInternal()
	{
		if (!mPlaying && !mPaused)
			return;
		mPlaying = false;
		mPaused = false;
		RefreshTransportButtons();
	}

	public void SetLooping(bool loop)
	{
		mLoop = loop;
		RefreshTransportButtons();
	}

	public bool IsLooping => mLoop;
	public bool IsPlaying => mPlaying;
	public bool IsPaused => mPaused;
	public float PlayheadTime => mPlayheadTime;

	private void Advance(float dt)
	{
		if (mClip.Tracks.IsEmpty)
		{
			Stop();
			return;
		}
		let dur = Math.Max(Math.Max(mClip.Duration, mClip.ComputeDuration()), 1e-3f);
		mPlayheadTime += Math.Max(dt, 0.0f);
		if (mPlayheadTime >= dur)
		{
			if (mLoop)
			{
				while (mPlayheadTime >= dur)
					mPlayheadTime -= dur; // dt is far below dur, so a subtract loop is enough
			}
			else
			{
				mPlayheadTime = dur; // clamped and stopped at the end
				mPlaying = false;
				mPaused = false;
				RefreshTransportButtons();
			}
		}
		if (mTimeline != null)
			mTimeline.SetPlayheadTime(mPlayheadTime); // the scrubber event is guarded while playing
		if (mView != null)
			mView.SetScrubTime(mPlayheadTime);
		PreviewSelected(mPlayheadTime); // the advance loop owns the playhead, so it previews directly
	}

	private void RefreshTransportButtons()
	{
		if (mPauseButton != null)
			mPauseButton.SetText(mPaused ? "Resume" : "Pause");
		if (mLoopButton != null)
			mLoopButton.SetText(mLoop ? "Loop: on" : "Loop: off");
	}

	// ---- the clip document -----------------------------------------------------------------

	public StringView ClipName => mClipName;
	public bool HasClip => mClipId.IsSet;
	public bool IsDirty => mDirty;
	public Guid ClipId => mClipId;
	public EditorContext EditorCtx => mEditorCtx;
	public ClipEditorView View => mView;
	public Timeline Dopesheet => mTimeline;
	public bool IsPreviewing => mPreviewing;

	/// Drops the loaded clip; no asset written.
	private void ClearClip()
	{
		StopPreview(); // never a live preview pointing at the old clip's tracks
		mPlaying = false; // a new document starts stopped at the top
		mPaused = false;
		mPlayheadTime = 0.0f;
		if (mTimeline != null)
			mTimeline.SetPlayheadTime(0.0f);
		RefreshTransportButtons();
		ClearAndDeleteItems(mClip.Tracks);
		mClip.Duration = 0.0f;
		mClipId = .Empty;
		mClipName.Clear();
		mDirty = false;
	}

	/// Loads an existing clip asset, unguarded, and owns the whole refresh.
	public void LoadClip(Guid instanceId)
	{
		if (mEditorCtx.Project == null)
			return;
		let inst = mEditorCtx.Project.SourceDb.GetInstance(instanceId);
		if (inst == null)
			return;
		ClearClip();
		let object = inst.ReadObject();
		if (let asset = object as PropertyAnimationClipAsset)
			asset.Source.FillClip(mClip);
		delete object;
		mClipId = instanceId;
		mClipName.Set(inst.Name);
		if (mView != null)
			mView.ResetForClip();
		RefreshHeader();
		RefreshClipStateUI();
	}

	/// Flattens, writes and re-cooks. Every outcome is visible: the header flashes the result.
	public void SaveClip()
	{
		if (!mClipId.IsSet || (mEditorCtx.Project == null))
		{
			GlobalLog(.Warning, "PropertyAnimation: Save: no clip asset loaded, use Create or Open first");
			FlashStatus("save: no clip loaded");
			return;
		}
		let inst = mEditorCtx.Project.SourceDb.GetInstance(mClipId);
		if (inst == null)
		{
			GlobalLog(.Warning, "PropertyAnimation: Save: the clip asset {} no longer exists in the project", mClipId);
			FlashStatus("save FAILED: asset missing");
			return;
		}
		let asset = scope PropertyAnimationClipAsset();
		PropertyAnimationClipSource.FromClip(mClip, asset.Source);
		if (inst.WriteObject(asset) case .Ok)
		{
			mDirty = false;
			mEditorCtx.RequestCook(false);
			GlobalLog(.Information, "Editor: saved in-scene property-animation clip '{}'", mClipName);
			FlashStatus("saved"); // RefreshHeader inside clears the dirty star
		}
		else
		{
			GlobalLog(.Warning, "PropertyAnimation: Save: writing clip '{}' failed", mClipName);
			FlashStatus("save FAILED (see log)");
		}
	}

	/// The pencil-claim and programmatic entry: a dirty-guarded load (Save, Discard, Cancel
	/// when a modified clip is open), then optionally binds the entity whose animator slot
	/// invoked the edit; Empty keeps the current binding.
	public void RequestEditClip(Guid clipId, Guid bindEntity)
	{
		if (!clipId.IsSet)
			return;
		if (mClipId == clipId)
		{
			// Already the open document: just the binding request.
			if (bindEntity.IsSet)
				BindEntity(bindEntity);
			return;
		}
		RunDirtyGuarded(new [=clipId, =bindEntity, =this]() =>
			{
				LoadClip(clipId);
				if ((mClipId == clipId) && bindEntity.IsSet)
					BindEntity(bindEntity); // the pencil's animator entity auto-binds
			});
	}

	// ---- the bound entity ------------------------------------------------------------------

	public void BindEntity(Guid entityId)
	{
		if (mBoundEntity == entityId)
			return;
		StopPreview(); // the preview snapshot belongs to the old binding: restored first
		mBoundEntity = entityId;
		RefreshEntitySlot();
	}

	/// Binds the primary selection; flashes when there is none.
	public void BindSelectedEntity()
	{
		if ((mSelection == null) || (mSelection.Count == 0))
		{
			FlashStatus("bind: nothing selected");
			return;
		}
		BindEntity(mSelection.Primary);
	}

	public Guid BoundEntity => mBoundEntity;

	private void RefreshEntitySlot()
	{
		if (mEntityLabel == null)
			return;
		let text = scope String("Entity: ");
		if (!mBoundEntity.IsSet)
		{
			text.Append("(none)");
		}
		else
		{
			let entity = (mScene != null) ? mScene.FindEntity(mBoundEntity) : EntityHandle();
			if (!entity.IsAssigned)
			{
				text.Append("(missing)"); // the bound guid no longer resolves in this scene
			}
			else
			{
				let name = mScene.GetEntityName(entity);
				text.Append(name.IsEmpty ? "(unnamed)" : name);
			}
		}
		mEntityLabel.SetText(text);
	}

	/// Adds a track for each animatable property of the bound entity's components, as one
	/// undo group. Answers the count; 0 for no bound entity or nothing animatable.
	public int AddTracksFromSelection(ClipEditorView view)
	{
		let seeds = scope List<AnimatablePropertyInfo>();
		defer { ClearAndDeleteItems(seeds); }
		CollectSelectionTrackSeeds(seeds);
		if (seeds.IsEmpty)
			return 0;
		// One undo step for the whole seed set.
		mCommands.BeginGroup("propanim-add-tracks-from-selection");
		for (let seed in seeds)
			view.AddTrack(seed.ComponentType, seed.PropertyPath, seed.Kind);
		mCommands.EndGroup();
		mCommands.LockGroup(); // a second "+ Tracks" is its own undo entry
		return seeds.Count;
	}

	/// The animatable-property seeds for the bound entity: the Transform TRS plus each
	/// reflected component's animatable leaves. The list owns the entries.
	private void CollectSelectionTrackSeeds(List<AnimatablePropertyInfo> outSeeds)
	{
		if ((mScene == null) || !mBoundEntity.IsSet)
			return;
		let entity = mScene.FindEntity(mBoundEntity);
		if (!entity.IsAssigned)
			return;
		// Every entity has a scene transform, so its TRS is always offered.
		outSeeds.Add(new AnimatablePropertyInfo(cTransformName, "Position", .Float3));
		outSeeds.Add(new AnimatablePropertyInfo(cTransformName, "Rotation", .Quat));
		outSeeds.Add(new AnimatablePropertyInfo(cTransformName, "Scale", .Float3));
		mScene.ForEachManager(scope [&](mgr) =>
			{
				if (!mgr.HasComponent(entity) || (mgr.ComponentType == null))
					return;
				AnimatableProperties.Collect(mgr.ComponentType, outSeeds);
			});
	}

	private bool ClipHasTrack(StringView componentType, StringView propertyPath)
	{
		for (let t in mClip.Tracks)
		{
			if ((t.ComponentType == componentType) && (t.PropertyPath == propertyPath))
				return true;
		}
		return false;
	}

	private ComponentManagerBase FindManagerByComponentTypeName(StringView name)
	{
		if (mScene == null)
			return null;
		ComponentManagerBase found = null;
		mScene.ForEachManager(scope [&](m) =>
			{
				if ((found == null) && (m.ComponentType != null))
				{
					let typeName = scope:: String();
					m.ComponentType.GetName(typeName);
					if (typeName == name)
						found = m;
				}
			});
		return found;
	}

	// ---- live preview ----------------------------------------------------------------------
	//
	// Scrubbing writes the clip's sampled values onto the bound entity through the runtime's
	// binding resolver. The writes are transient: a snapshot is captured on the first scrub and
	// restored on stop, Simulate, or clip change. Nothing goes through the command stack or
	// dirties the document. The snapshot is re-taken when the track set changes, so it never
	// restores stale targets after a track is added, removed or retargeted.

	private void PreviewSelected(float time)
	{
		if (mClip.Tracks.IsEmpty || mEditingLocked || (mScene == null))
			return;
		if (!mBoundEntity.IsSet)
		{
			StopPreview();
			return;
		}
		let entity = mScene.FindEntity(mBoundEntity);
		if (!entity.IsAssigned)
		{
			StopPreview();
			return;
		}
		PreviewAt(entity, time);
	}

	/// Reads a track target on an entity: the built-in Transform through the scene's local
	/// transform, or a reflected component through its manager. No value when unresolved.
	private PropertyValue ReadTrackTarget(EntityHandle entity, StringView componentType, StringView propertyPath)
	{
		if (mScene == null)
			return .Empty;
		let binding = scope PropertyBinding();
		if (componentType == cTransformName)
		{
			PropertyBindingResolver.Resolve(typeof(Transform), propertyPath, binding);
			if (!binding.IsResolved)
				return .Empty;
			var local = mScene.GetLocalTransform(entity);
			return PropertyBindingResolver.Read(binding, &local, typeof(Transform));
		}
		let mgr = FindManagerByComponentTypeName(componentType);
		if ((mgr == null) || (mgr.ComponentType == null) || !mgr.HasComponent(entity))
			return .Empty;
		PropertyBindingResolver.Resolve(mgr.ComponentType, propertyPath, binding);
		if (!binding.IsResolved)
			return .Empty;
		return PropertyBindingResolver.Read(binding, mgr.GetComponentAddress(entity), mgr.ComponentType);
	}

	private void WriteTrackTarget(EntityHandle entity, StringView componentType, StringView propertyPath, PropertyValue value)
	{
		if (mScene == null)
			return;
		let binding = scope PropertyBinding();
		if (componentType == cTransformName)
		{
			PropertyBindingResolver.Resolve(typeof(Transform), propertyPath, binding);
			if (!binding.IsResolved)
				return;
			// Read, modify, write through SetLocalTransform so the world matrix is flagged.
			var local = mScene.GetLocalTransform(entity);
			if (PropertyBindingResolver.Write(binding, &local, typeof(Transform), value) case .Ok)
				mScene.SetLocalTransform(entity, local);
			return;
		}
		let mgr = FindManagerByComponentTypeName(componentType);
		if ((mgr == null) || (mgr.ComponentType == null) || !mgr.HasComponent(entity))
			return;
		PropertyBindingResolver.Resolve(mgr.ComponentType, propertyPath, binding);
		if (binding.IsResolved)
			PropertyBindingResolver.Write(binding, mgr.GetComponentAddress(entity), mgr.ComponentType, value).IgnoreError();
	}

	/// The identity of the tracks a snapshot was taken against, "component|path" per track.
	private void TrackIdentity(List<String> outIdentity)
	{
		for (let track in mClip.Tracks)
			outIdentity.Add(new $"{track.ComponentType}|{track.PropertyPath}");
	}

	private static bool SameIdentity(List<String> a, List<String> b)
	{
		if (a.Count != b.Count)
			return false;
		for (int i < a.Count)
		{
			if (a[i] != b[i])
				return false;
		}
		return true;
	}

	private void SnapshotEntity(EntityHandle entity)
	{
		ClearAndDeleteItems(mSnapshot);
		for (let track in mClip.Tracks)
		{
			let current = ReadTrackTarget(entity, track.ComponentType, track.PropertyPath);
			if (!current.HasValue)
				continue;
			let entry = new PreviewSnapshotEntry();
			entry.ComponentType.Set(track.ComponentType);
			entry.PropertyPath.Set(track.PropertyPath);
			entry.Value = current;
			mSnapshot.Add(entry);
		}
	}

	/// Snapshots if needed and writes the sampled values.
	private void PreviewAt(EntityHandle entity, float time)
	{
		let identity = scope List<String>();
		defer { ClearAndDeleteItems(identity); }
		TrackIdentity(identity);
		// A re-snapshot when the previewed entity changes or the track set changed: the old
		// snapshot describes targets that may no longer exist or were retargeted.
		if (!mPreviewing || (mPreviewEntity != entity) || !SameIdentity(identity, mSnapshotIdentity))
		{
			if (mPreviewing)
				StopPreview(); // the old targets restore before a fresh snapshot
			SnapshotEntity(entity);
			ClearAndDeleteItems(mSnapshotIdentity);
			for (let s in identity)
				mSnapshotIdentity.Add(new String(s));
			mPreviewing = true;
			mPreviewEntity = entity;
		}
		mPreviewTime = time;
		for (let track in mClip.Tracks)
		{
			// SampleMerged keeps the live value for empty channels, no teleport to the origin.
			let current = ReadTrackTarget(entity, track.ComponentType, track.PropertyPath);
			WriteTrackTarget(entity, track.ComponentType, track.PropertyPath, track.SampleMerged(time, current));
		}
	}

	/// Restores the snapshot and ends the preview; idempotent.
	public void StopPreview()
	{
		if (!mPreviewing)
			return;
		if ((mScene != null) && mPreviewEntity.IsAssigned)
		{
			for (let entry in mSnapshot)
				WriteTrackTarget(mPreviewEntity, entry.ComponentType, entry.PropertyPath, entry.Value);
		}
		ClearAndDeleteItems(mSnapshot);
		ClearAndDeleteItems(mSnapshotIdentity);
		mPreviewing = false;
		mPreviewEntity = .();
	}
}
