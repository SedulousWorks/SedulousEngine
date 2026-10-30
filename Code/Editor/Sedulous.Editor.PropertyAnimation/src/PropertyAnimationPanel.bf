using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.GUI;
using Sedulous.PropertyAnimation;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.PropertyAnimation;

/// The property animation panel on the GUI from its markup (Data/Editor/PropertyAnimationPanel.gml;
/// Raptor's editor-gui spec, 5.4, layer 9, part 2), over part 1's clip document, source, preview and
/// transport, under the scene page's viewport. Its bar holds the clip (its name and unsaved mark, New,
/// Open, Save, its own Undo and Redo), the entity it animates (Use Selected), its tracks (Add Track
/// offers the entity's properties without one, Key keys the chosen tracks with what the entity shows
/// at the playhead, Remove takes them away), the kit's transport with Loop, and the clip's length. The
/// ruler, the dopesheet and the curve view share one time axis; the curve view shows the chosen
/// tracks' curves, every track's with none chosen.
///
/// While it holds the focus its keys are its own (the user's ruling): Undo, Redo and Save are handled
/// on its root, so Ctrl+Z, Ctrl+Y and Ctrl+S act on the clip and never reach the scene, even with
/// nothing left to undo; a key it does not bind goes on to the scene page. The preview stands down
/// while the scene simulates. New, Open and the prompt for an unsaved clip are the page's seams.
class PropertyAnimationPanel
{
	public const String cMarkupPath = "Editor/PropertyAnimationPanel.gml";

	/// A key this close to a time is the one at it.
	private const float cSameTime = 1e-4f;

	private EditorContext mContext;
	/// Borrowed: the page's, which outlives it.
	private Sedulous.Scene.Scene mScene;
	/// A reference of its own.
	private Node mContent ~ _?.ReleaseRef();
	private ClipDocument mDocument ~ delete _;
	private ClipSource mSource ~ delete _;
	private ClipPreview mPreview ~ delete _;
	private ClipTransport mTransport = new .() ~ delete _;
	private TimeAxis mAxis ~ _?.ReleaseRef();
	private Guid mEntity = .Empty;
	private bool mSimulating = false;
	/// The transport moving the playhead: not a scrub.
	private bool mMoving = false;
	/// The tracks the curve view shows, as last chosen.
	private List<int> mShownTracks = new .() ~ delete _;
	/// What the curve view shows changed: fit its values.
	private bool mFitValues = true;
	/// The clip's tracks, as last shown.
	private int mTrackCount = 0;
	/// The clip, as last shown.
	private Guid mShownClip = .Empty;
	/// The root's command handlers.
	private List<uint32> mCommands = new .() ~ delete _;
	private Menu mTrackMenu = null ~ _?.ReleaseRef();

	// The markup's (its tree holds them).
	private Dopesheet mSheet = null;
	private CurveView mCurves = null;
	private Sedulous.GUI.Label mClipName = null;
	private Node mDirty = null;
	private Sedulous.GUI.Label mEntityName = null;
	private NumberField mLength = null;
	private Node mEmpty = null;
	private Node mBody = null;
	private ButtonBase mSave = null;
	private ButtonBase mUndo = null;
	private ButtonBase mRedo = null;
	private ButtonBase mPlay = null;
	private ButtonBase mAddTrack = null;
	private ButtonBase mKey = null;
	private ButtonBase mRemove = null;
	private ButtonBase mRestart = null;
	private ButtonBase mStop = null;

	// === The page's seams ===

	/// The scene's selected entity (Use Selected binds it); null: none.
	public delegate Guid() SelectedEntity ~ delete _;
	/// New and Open: the page's dialogs, which end by LoadClip. Null: the buttons do nothing.
	public delegate void() RequestNewClip ~ delete _;
	public delegate void() RequestOpenClip ~ delete _;
	/// Runs `proceed` now, or once the user has saved or discarded the unsaved clip (the page's
	/// prompt; it takes `proceed`); null: at once.
	public delegate void(delegate void() proceed) GuardUnsaved ~ delete _;
	/// The bar's Close: the page hides the panel (the clip stays open in it). Null: nothing.
	public delegate void() RequestClose ~ delete _;

	/// Over `scene` (the page's, which outlives it), its markup `content` loaded (a reference of its
	/// own taken).
	public this(EditorContext context, Sedulous.Scene.Scene scene, Node content)
	{
		mContext = context;
		mScene = scene;
		mContent = content;
		if (mContent != null)
			mContent.AddRef();
		mDocument = new .(context);
		mSource = new .(mDocument);
		mPreview = new .(scene);
		mDocument.OnChanged = new [=this] () => { Changed(); };
		mSource.CurrentValue = new [=this] (track) => EntityValue(track.ComponentType, track.PropertyPath);

		// One axis under the ruler, the dopesheet and the curve view; a scrub poses the entity.
		mAxis = new .();
		mAxis.PixelsPerSecond = 120.0f;
		mAxis.FrameRate = 30.0f;
		mAxis.Duration = mDocument.Length;
		mAxis.SetOnPlayheadChanged(new [=this] (time) =>
			{
				if (mMoving)
					return;
				mTransport.SetTime(time);
				Pose();
			});
		if (let ruler = Find<TimeRuler>("anim-ruler"))
			ruler.TimeAxis = mAxis;
		mSheet = Find<Dopesheet>("anim-sheet");
		if (mSheet != null)
		{
			mSheet.TimeAxis = mAxis;
			mSheet.Source = mSource;
		}
		mCurves = Find<CurveView>("anim-curves");
		if (mCurves != null)
		{
			mCurves.TimeAxis = mAxis;
			mCurves.Source = mSource;
		}

		mClipName = Find<Sedulous.GUI.Label>("anim-clip");
		mDirty = Find<Node>("anim-dirty");
		mEntityName = Find<Sedulous.GUI.Label>("anim-entity");
		mEmpty = Find<Node>("anim-empty");
		mBody = Find<Node>("anim-body");
		mLength = Find<NumberField>("anim-length");
		if (mLength != null)
			mLength.SetOnValueChanged(new [=this] (value) => { SetLength((float)value); });
		if (let button = Find<ButtonBase>("anim-new"))
			button.SetOnClick(new [=this] () => { if (RequestNewClip != null) RequestNewClip(); });
		if (let button = Find<ButtonBase>("anim-open"))
			button.SetOnClick(new [=this] () => { if (RequestOpenClip != null) RequestOpenClip(); });
		mSave = Wire("anim-save", new [=this] () => { Save().IgnoreError(); });
		mUndo = Wire("anim-undo", new [=this] () => { Undo(); });
		mRedo = Wire("anim-redo", new [=this] () => { Redo(); });
		Wire("anim-bind", new [=this] () => { BindSelected(); }); // always on: the page's selection is read when clicked
		mAddTrack = Wire("anim-add-track", new [=this] () => { OpenTrackMenu(); });
		mKey = Wire("anim-key", new [=this] () => { KeyChosen(); });
		mRemove = Wire("anim-remove", new [=this] () => { RemoveChosen(); });
		mRestart = Wire("anim-restart", new [=this] () => { Restart(); });
		Wire("anim-frame", new [=this] () => { FrameCurves(); });
		Wire("anim-close", new [=this] () =>
			{
				if (RequestClose != null)
					RequestClose();
			});
		mStop = Wire("anim-stop", new [=this] () => { Stop(); });
		mPlay = Find<ButtonBase>("anim-play");
		if (mPlay != null)
		{
			mPlay.SetOnToggled(new [=this] (on) =>
				{
					if (on)
						Play();
					else
						Pause();
				});
		}
		if (let loop = Find<ButtonBase>("anim-loop"))
			loop.SetOnToggled(new [=this] (on) => { SetLooping(on); });

		// The keys it binds, while it holds the focus: the clip's, never the scene's.
		if (mContent != null)
		{
			mCommands.Add(mContent.OnCommand("edit.undo", new [=this] (command) => { Undo(); }));
			mCommands.Add(mContent.OnCommand("edit.redo", new [=this] (command) => { Redo(); }));
			mCommands.Add(mContent.OnCommand("file.save", new [=this] (command) => { Save().IgnoreError(); }));
		}
		Changed();
	}

	public ~this()
	{
		mPreview.Stop();
		if (mSheet != null)
			mSheet.Source = null;
		if (mCurves != null)
			mCurves.Source = null;
		if (mContent != null)
		{
			for (let token in mCommands)
				mContent.RemoveCommandHandler(token);
		}
	}

	public Node Content => mContent;

	// === The clip ===

	/// Edits the clip asset `clipId` (false: no such clip); the transport stopped, at the start.
	public bool LoadClip(Guid clipId)
	{
		mPreview.Stop();
		if (!mDocument.Load(clipId))
			return false;
		mTransport.Stop();
		MovePlayhead(0.0f);
		if (mSheet != null)
			mSheet.SetSelection(default);
		return true;
	}

	/// Asks about an unsaved clip, then opens `clipId` and binds `entity` (empty: keeps the bound one).
	public void RequestEditClip(Guid clipId, Guid entity)
	{
		delegate void() open = new [=this, =clipId, =entity] () =>
			{
				if (clipId != mDocument.ClipId)
					LoadClip(clipId);
				if (entity != .Empty)
					BindEntity(entity);
			};
		if ((GuardUnsaved != null) && mDocument.IsDirty && (clipId != mDocument.ClipId))
			GuardUnsaved(open);
		else
		{
			open();
			delete open;
		}
	}

	public Result<void, ErrorCode> Save()
	{
		if (!mDocument.HasClip)
			return .Err(.NotFound);
		if (mDocument.Save() case .Err(let error))
		{
			mContext.Notify(.Warning, scope $"The clip '{mDocument.Name}' did not save; the Console says why.");
			return .Err(error);
		}
		mContext.Notify(.Info, scope $"Saved the clip '{mDocument.Name}'.");
		return .Ok;
	}

	public void Undo()
	{
		if (mDocument.Commands.CanUndo)
			mDocument.Commands.Undo();
	}

	public void Redo()
	{
		if (mDocument.Commands.CanRedo)
			mDocument.Commands.Redo();
	}

	public void SetLength(float seconds)
	{
		mDocument.Edit("propanim-length", scope (clip) => { clip.Duration = Math.Max(0.0f, seconds); });
	}

	// === The entity it animates ===

	public Guid BoundEntity => mEntity;

	public void BindEntity(Guid entity)
	{
		if (entity == mEntity)
			return;
		mPreview.Stop(); // the one posed goes back first
		mEntity = entity;
		Pose();
		ShowBar();
	}

	public void BindSelected()
	{
		if (SelectedEntity != null)
			BindEntity(SelectedEntity());
	}

	// === The tracks ===

	/// What Add Track offers: the bound entity's properties without a track yet; appended (the list
	/// owns them).
	public void OfferedTracks(List<AnimatablePropertyInfo> outOffered)
	{
		let seeds = scope List<AnimatablePropertyInfo>();
		mPreview.TrackSeeds(mEntity, seeds);
		for (let seed in seeds)
		{
			if (HasTrack(mDocument.Clip, seed.ComponentType, seed.PropertyPath))
				delete seed;
			else
				outOffered.Add(seed);
		}
	}

	/// A track for `seed`, keyed at the playhead with what the entity shows (when it can be read).
	public void AddTrack(AnimatablePropertyInfo seed)
	{
		if (!mDocument.HasClip || HasTrack(mDocument.Clip, seed.ComponentType, seed.PropertyPath))
			return;
		let value = EntityValue(seed.ComponentType, seed.PropertyPath);
		let time = mTransport.Time;
		mPreview.Stop(); // the tracks change: what the preview keeps is taken again
		mDocument.Edit("propanim-add-track", scope [&] (clip) =>
			{
				let track = new PropertyTrack();
				track.ComponentType.Set(seed.ComponentType);
				track.PropertyPath.Set(seed.PropertyPath);
				track.Kind = seed.Kind;
				if (value.HasValue)
					KeyValue(track, time, value); // it starts holding what the entity shows
				clip.Tracks.Add(track);
			});
	}

	/// The tracks of the keys chosen in the dopesheet, into `outTracks`.
	public void ChosenTracks(List<int> outTracks)
	{
		outTracks.Clear();
		if (mSheet == null)
			return;
		let channels = mSource.Channels;
		for (let key in mSheet.Selection)
		{
			if ((key.Channel < 0) || (key.Channel >= channels.Length))
				continue;
			let track = channels[key.Channel].Track;
			if (!outTracks.Contains(track))
				outTracks.Add(track);
		}
	}

	/// Keys the chosen tracks (every one, with none chosen) at the playhead with what the entity
	/// shows, one step; how many it keyed.
	public int KeyChosen()
	{
		if (!mDocument.HasClip || (mEntity == .Empty))
			return 0;
		let tracks = scope List<int>();
		ChosenTracks(tracks);
		if (tracks.IsEmpty)
		{
			for (int t < mDocument.Clip.Tracks.Count)
				tracks.Add(t);
		}
		// What the entity shows, read before the edit (the preview poses it after).
		let values = scope List<Sedulous.PropertyAnimation.PropertyValue>();
		var keyed = 0;
		for (let t in tracks)
		{
			let track = mDocument.Clip.Tracks[t];
			let value = EntityValue(track.ComponentType, track.PropertyPath);
			values.Add(value);
			keyed += value.HasValue ? 1 : 0;
		}
		if (keyed == 0)
			return 0;
		let time = mTransport.Time;
		mDocument.Edit("propanim-key", scope [&] (clip) =>
			{
				for (int i < tracks.Count)
				{
					if (values[i].HasValue)
						KeyValue(clip.Tracks[tracks[i]], time, values[i]);
				}
			});
		return keyed;
	}

	/// Takes the chosen tracks away, one step; false with none chosen.
	public bool RemoveChosen()
	{
		let tracks = scope List<int>();
		ChosenTracks(tracks);
		if (tracks.IsEmpty)
			return false;
		mPreview.Stop(); // what it wrote goes back before its tracks go
		if (mSheet != null)
			mSheet.SetSelection(default);
		// Last first, so each index still names its track.
		tracks.Sort(scope (a, b) => b <=> a);
		mDocument.Edit("propanim-remove-tracks", scope [&] (clip) =>
			{
				for (let t in tracks)
				{
					delete clip.Tracks[t];
					clip.Tracks.RemoveAt(t);
				}
			});
		return true;
	}

	// === The transport ===

	public void Play()
	{
		mTransport.Play(mDocument.Length);
		ShowBar();
	}

	public void Pause()
	{
		mTransport.Pause();
		ShowBar();
	}

	public void Stop()
	{
		mTransport.Stop();
		MovePlayhead(0.0f);
		Pose(); // the start pose
		ShowBar();
	}

	public void Restart()
	{
		mTransport.Stop();
		mTransport.Play(mDocument.Length);
		MovePlayhead(0.0f);
		Pose();
		ShowBar();
	}

	public void SetLooping(bool looping) => mTransport.SetLooping(looping);

	/// The playhead moved to `time`, as a scrub of the ruler moves it.
	public void Scrub(float time)
	{
		mAxis.Playhead = time; // as the ruler's scrub: the transport and the pose follow
	}

	/// The curves shown framed, in time and value (the bar's Frame).
	public void FrameCurves()
	{
		if (mCurves != null)
			mCurves.FrameAll();
	}

	/// Once a frame from the page: the transport, the preview (stood down while `simulating`), the
	/// bar's state.
	public void Update(float dt, bool simulating)
	{
		if (simulating != mSimulating)
		{
			mSimulating = simulating;
			if (simulating)
			{
				mTransport.Pause(); // the scene's own animators run; the preview stands down
				mPreview.Stop();
			}
			ShowBar();
		}
		if (!mSimulating && mTransport.Advance(dt, mDocument.Length))
		{
			MovePlayhead(mTransport.Time);
			Pose();
			if (!mTransport.IsPlaying)
				ShowBar(); // it stopped at the end
		}
		// The dopesheet tells no one of its choice: the curve view follows it here.
		ShowCurves();
		if (mFitValues)
		{
			mFitValues = false;
			FitValues();
		}
	}

	/// The preview put back (the page saving the scene, starting a simulation); Repose poses it again
	/// where the playhead stands.
	public void StopPreview() => mPreview.Stop();
	public void Repose() => Pose();

	// === For tests ===

	public ClipDocument Document => mDocument;
	public ClipSource Source => mSource;
	public ClipPreview Preview => mPreview;
	public ClipTransport Transport => mTransport;
	public Dopesheet Sheet => mSheet;
	public TimeAxis Axis => mAxis;

	// === Showing it ===

	private void Changed()
	{
		mSource.Refresh();
		mAxis.Duration = mDocument.Length;
		// Another clip, or tracks come or gone: the curves shown are others (a key's edit is not).
		if ((mDocument.ClipId != mShownClip) || (mDocument.Clip.Tracks.Count != mTrackCount))
		{
			mShownClip = mDocument.ClipId;
			mTrackCount = mDocument.Clip.Tracks.Count;
			mFitValues = true;
		}
		// The length it plays over (a new clip's second, its last key's time when later).
		let length = mDocument.Length;
		if ((mLength != null) && ((float)mLength.Value != length))
			mLength.Value = length;
		Pose(); // an edit, an undo: the entity shows the clip as it is now
		ShowBar();
	}

	private void Pose()
	{
		if (mSimulating || !mDocument.HasClip || (mEntity == .Empty) || mDocument.Clip.Tracks.IsEmpty)
		{
			mPreview.Stop();
			return;
		}
		mPreview.Pose(mEntity, mDocument.Clip, mTransport.Time);
	}

	// The playhead where the transport has it (not a scrub: the pose is the caller's).
	private void MovePlayhead(float time)
	{
		mMoving = true;
		mAxis.Playhead = time;
		mMoving = false;
	}

	private void ShowCurves()
	{
		let tracks = scope List<int>();
		ChosenTracks(tracks);
		if (tracks.IsEmpty)
		{
			for (int t < mDocument.Clip.Tracks.Count)
				tracks.Add(t); // none chosen: every track's
		}
		var same = tracks.Count == mShownTracks.Count;
		for (int i = 0; same && (i < tracks.Count); i++)
			same = tracks[i] == mShownTracks[i];
		if (same && (tracks.Count == mSource.ShownTracks.Length))
			return;
		mShownTracks.Clear();
		mShownTracks.AddRange(tracks);
		mSource.ShowTracks(tracks);
		mFitValues = true; // other curves: their values fill the view
	}

	// The curve view's values fitted to the curves it shows (never its time: the dopesheet shares
	// that axis, and a choice made there must not rezoom it under the mouse).
	private void FitValues()
	{
		if (mCurves == null)
			return;
		var low = 0.0f;
		var high = 0.0f;
		var any = false;
		for (int c < mSource.CurveCount)
		{
			for (let key in mSource.GetKeys(c))
			{
				low = any ? Math.Min(low, key.Value) : key.Value;
				high = any ? Math.Max(high, key.Value) : key.Value;
				any = true;
			}
		}
		if (!any)
		{
			low = 0.0f;
			high = 1.0f;
		}
		if (high - low < 1e-3f)
		{
			low -= 1.0f; // one value: a span about it
			high += 1.0f;
		}
		let margin = (high - low) * 0.1f;
		mCurves.SetValueRange(low - margin, high + margin);
	}

	private void ShowBar()
	{
		let clip = mDocument.HasClip;
		if (mClipName != null)
			mClipName.Text = clip ? mDocument.Name : "No clip";
		if (mDirty != null)
			mDirty.Displayed = mDocument.IsDirty;
		if (mEmpty != null)
			mEmpty.Displayed = !clip;
		if (mBody != null)
			mBody.Displayed = clip;
		if (mEntityName != null)
		{
			let handle = (mEntity == .Empty) ? EntityHandle.Invalid : mScene.FindEntity(mEntity);
			mEntityName.Text = handle.IsAssigned ? mScene.GetEntityName(handle) : "No entity";
		}
		let editable = clip && !mSimulating;
		Enable(mSave, mDocument.IsDirty);
		Enable(mUndo, mDocument.Commands.CanUndo);
		Enable(mRedo, mDocument.Commands.CanRedo);
		Enable(mAddTrack, editable && (mEntity != .Empty));
		Enable(mKey, editable && (mEntity != .Empty) && !mDocument.Clip.Tracks.IsEmpty);
		Enable(mRemove, editable);
		Enable(mPlay, editable);
		Enable(mRestart, editable);
		Enable(mStop, editable);
		if (mPlay != null)
			mPlay.Checked = mTransport.IsPlaying;
	}

	private static void Enable(ButtonBase button, bool on)
	{
		if (button != null)
			button.Enabled = on;
	}

	private void OpenTrackMenu()
	{
		if (mAddTrack == null)
			return;
		// Made fresh each time: what it offers follows the entity and the tracks.
		mTrackMenu?.ReleaseRef();
		mTrackMenu = new .();
		mTrackMenu.SetAutoWidth(true);
		let offered = scope List<AnimatablePropertyInfo>();
		defer { ClearAndDeleteItems!(offered); }
		OfferedTracks(offered);
		for (let seed in offered)
		{
			let pick = seed.Clone();
			mTrackMenu.AddItem(scope $"{seed.ComponentType}.{seed.PropertyPath}", new [=this, =pick] () => { AddTrack(pick); } ~ delete pick);
		}
		if (offered.IsEmpty)
			mTrackMenu.AddItem((mEntity == .Empty) ? "Bind an entity first" : "Every property has a track", new () => { }).Enabled = false;
		mTrackMenu.OpenBelow(mAddTrack, mAddTrack);
	}

	private Sedulous.PropertyAnimation.PropertyValue EntityValue(StringView componentType, StringView propertyPath)
	{
		return mPreview.Read(mEntity, componentType, propertyPath);
	}

	private ButtonBase Wire(StringView id, delegate void() click)
	{
		let found = Find<ButtonBase>(id);
		if (found != null)
			found.SetOnClick(click);
		else
			delete click;
		return found;
	}

	private T Find<T>(StringView id) where T : Node
	{
		return (mContent != null) ? (mContent.FindElement(id) as T) : null;
	}

	private static bool HasTrack(PropertyAnimationClip clip, StringView componentType, StringView propertyPath)
	{
		for (let track in clip.Tracks)
		{
			if ((track.ComponentType == componentType) && (track.PropertyPath == propertyPath))
				return true;
		}
		return false;
	}

	// The value's parts as a track's channels take them (a Float3's three, a Color's four); a key
	// already at `time` takes the value.
	private static void KeyValue(PropertyTrack track, float time, Sedulous.PropertyAnimation.PropertyValue value)
	{
		if (!value.HasValue)
			return;
		switch (track.Kind)
		{
		case .Float:
			if (value.Kind == .Float)
				SetChannel(track, 0, time, value.Scalar);
		case .Float3:
			if (value.Kind == .Float3)
			{
				SetChannel(track, 0, time, value.Vector.X);
				SetChannel(track, 1, time, value.Vector.Y);
				SetChannel(track, 2, time, value.Vector.Z);
			}
		case .Color:
			if (value.Kind == .Color)
			{
				SetChannel(track, 0, time, value.Color.R);
				SetChannel(track, 1, time, value.Color.G);
				SetChannel(track, 2, time, value.Color.B);
				SetChannel(track, 3, time, value.Color.A);
			}
		case .Quat:
			if (value.Kind == .Quat)
			{
				for (var existing in ref track.QuatKeys)
				{
					if (Math.Abs(existing.Time - time) < cSameTime)
					{
						existing.Value = value.Rotation;
						return;
					}
				}
				var at = 0;
				while ((at < track.QuatKeys.Count) && (track.QuatKeys[at].Time < time))
					at++;
				track.QuatKeys.Insert(at, QuatKey(time, value.Rotation));
			}
		}
	}

	private static void SetChannel(PropertyTrack track, int channel, float time, float v)
	{
		let curve = track.Channels[channel];
		for (var existing in ref curve.Keys)
		{
			if (Math.Abs(existing.Time - time) < cSameTime)
			{
				existing.Value = v;
				curve.ApplyTangentModes();
				return;
			}
		}
		var key = CurveKey(time, v, .Cubic);
		key.TangentMode = .Auto;
		curve.AddKey(key);
		curve.ApplyTangentModes();
	}
}
