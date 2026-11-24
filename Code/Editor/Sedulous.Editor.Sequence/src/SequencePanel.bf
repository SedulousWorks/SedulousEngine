using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Scene;
using Sedulous.GUI;
using Sedulous.PropertyAnimation;
using Sedulous.Sequence;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;
using Sedulous.Editor.PropertyAnimation;

namespace Sedulous.Editor.Sequence;

/// A track Track offers: a kind, and for a property track the property it animates. A class: it
/// owns its label and its property.
class SequenceTrackOffer
{
	public Type Kind = null;
	public String Label = new .() ~ delete _;
	/// The part it is for; -1: the whole sequence.
	public int32 Binding = -1;
	public bool Property = false;
	/// A property track's.
	public AnimatablePropertyInfo Target = null ~ delete _;
	public bool Enabled = true;

	public SequenceTrackOffer Clone()
	{
		let copy = new SequenceTrackOffer();
		copy.Kind = Kind;
		copy.Label.Set(Label);
		copy.Binding = Binding;
		copy.Property = Property;
		copy.Target = (Target != null) ? Target.Clone() : null;
		copy.Enabled = Enabled;
		return copy;
	}
}

/// A name of the cast and the entity filling it, as a sequence component's cast gives it.
struct SequencePanelCast
{
	public StringView Name;
	public Guid Entity;

	public this(StringView name, Guid entity)
	{
		Name = name;
		Entity = entity;
	}
}

/// Authors a sequence in the scene, on the GUI from its markup (Data/Editor/SequencePanel.xml). The
/// scene page holds it under its viewport, beside the property animation panel, and shows it only
/// when asked (its toggle, the Scene menu, a sequence component's Edit Sequence): selecting an entity
/// never opens it. It edits a sequence asset of its own, never the scene: its own history, Undo, Redo
/// and Save on its bar, and its own unsaved mark; while it holds the focus Ctrl+Z, Ctrl+Y and Ctrl+S
/// act on the sequence.
///
/// The ruler (the sequence's markers), the dopesheet (key rows and section rows, by part) and the
/// curve view share one time axis (SequenceSource). The inspector beside them shows the chosen
/// track's fields (a section's clip, an event's name), and each edit there is one step of the
/// sequence's history. The cast is the panel's own (Cast fills a part with the scene's selection),
/// and scrubbing or playing poses the scene through the game's own play (SequencePreview), put back
/// when the preview stops; the preview stands down while the scene simulates. Track offers every
/// registered kind (and a property track for each of the chosen part's animatable properties), so a
/// kind a domain or a plugin adds is offered with no list to extend.
class SequencePanel
{
	public const String cMarkupPath = "Editor/SequencePanel.xml";

	private EditorContext mContext;
	/// BORROWED: the page's, which outlives it.
	private Sedulous.Scene.Scene mScene;
	/// A reference of its own.
	private Node mContent ~ _?.ReleaseRef();
	private SequenceDocument mDocument;
	private Sedulous.Editor.Sequence.SequenceSource mSource;
	private SequencePreview mPreview;
	/// Reads the cast's properties: Track's property offers, and a new property track's first key.
	private ClipPreview mSeeds;
	private ClipTransport mTransport = new .() ~ delete _;
	private TimeAxis mAxis ~ _?.ReleaseRef();
	/// The chosen track's fields; null: none or several chosen.
	private FieldPropertySource mInspected = null;
	private int mInspectedTrack = -1;
	private uint64 mInspectedVersion = 0;
	private bool mSimulating = false;
	/// The transport moving the playhead: not a scrub.
	private bool mMoving = false;
	/// The tracks the curve view shows, as last chosen.
	private List<int> mShownTracks = new .() ~ delete _;
	/// The root's command handlers.
	private List<uint32> mCommands = new .() ~ delete _;
	private Menu mMenu = null ~ _?.ReleaseRef();

	// The markup's (its tree holds them).
	private Dopesheet mSheet = null;
	private CurveView mCurves = null;
	private TimeRuler mRuler = null;
	private PropertyGrid mGrid = null;
	private Sedulous.GUI.Label mName = null;
	private Sedulous.GUI.Label mTrackName = null;
	private Node mDirty = null;
	private NumberField mLength = null;
	private Node mEmpty = null;
	private Node mBody = null;
	private ButtonBase mSave = null;
	private ButtonBase mUndo = null;
	private ButtonBase mRedo = null;
	private ButtonBase mPlay = null;
	private ButtonBase mCast = null;
	private ButtonBase mAddTrack = null;
	private ButtonBase mAddSection = null;
	private ButtonBase mAddMarker = null;
	private ButtonBase mAddHold = null;
	private ButtonBase mRemove = null;
	private ButtonBase mRestart = null;
	private ButtonBase mStop = null;

	// === The page's seams ===

	/// The scene's selected entity; null or empty: none.
	public delegate Guid() SelectedEntity ~ delete _;
	/// New and Open: the page's dialogs, which end by LoadSequence. Null: the buttons do nothing.
	public delegate void() RequestNewSequence ~ delete _;
	public delegate void() RequestOpenSequence ~ delete _;
	/// Runs `proceed` now, or once the user has saved or discarded the unsaved sequence (the page's
	/// prompt; it takes `proceed`); null: at once.
	public delegate void(delegate void() proceed) GuardUnsaved ~ delete _;
	/// The bar's Close: the page hides the panel (the sequence stays open in it). Null: nothing.
	public delegate void() RequestClose ~ delete _;

	/// Over `scene` (the page's, which outlives it), its markup `content` loaded (a reference of its
	/// own taken); `refs` (may be null) picks the assets the inspector refers to.
	public this(EditorContext context, Sedulous.Scene.Scene scene, Node content, ResourceRefServices refs)
	{
		mContext = context;
		mScene = scene;
		mContent = content;
		if (mContent != null)
			mContent.AddRef();
		mDocument = new .(context);
		mSource = new .(mDocument);
		mPreview = new .(scene, context.Resources);
		mSeeds = new .(scene);
		mDocument.OnChanged = new [=this] () => { Changed(); };

		// One axis under the ruler, the dopesheet and the curve view; a scrub poses the scene.
		mAxis = new .();
		mAxis.PixelsPerSecond = 80.0f;
		mAxis.FrameRate = 30.0f;
		mAxis.Duration = mDocument.Length;
		mAxis.SetOnPlayheadChanged(new [=this] (time) =>
			{
				if (mMoving)
					return;
				mTransport.SetTime(time);
				Pose();
			});
		mRuler = Find<TimeRuler>("seq-ruler");
		if (mRuler != null)
		{
			mRuler.TimeAxis = mAxis;
			mRuler.MarkerSource = mSource.Markers;
		}
		mSheet = Find<Dopesheet>("seq-sheet");
		if (mSheet != null)
		{
			mSheet.TimeAxis = mAxis;
			mSheet.Source = mSource;
		}
		mCurves = Find<CurveView>("seq-curves");
		if (mCurves != null)
		{
			mCurves.TimeAxis = mAxis;
			mCurves.Source = mSource;
		}
		mGrid = Find<PropertyGrid>("seq-inspector");
		if ((mGrid != null) && (refs != null))
			ResourceRefEditor.Register(mGrid.Editors, refs);

		mName = Find<Sedulous.GUI.Label>("seq-name");
		mTrackName = Find<Sedulous.GUI.Label>("seq-track-name");
		mDirty = Find<Node>("seq-dirty");
		mEmpty = Find<Node>("seq-empty");
		mBody = Find<Node>("seq-body");
		mLength = Find<NumberField>("seq-length");
		if (mLength != null)
			mLength.SetOnValueChanged(new [=this] (value) => { SetLength((float)value); });
		Wire("seq-new", new [=this] () => { if (RequestNewSequence != null) RequestNewSequence(); });
		Wire("seq-open", new [=this] () => { if (RequestOpenSequence != null) RequestOpenSequence(); });
		mSave = Wire("seq-save", new [=this] () => { Save().IgnoreError(); });
		mUndo = Wire("seq-undo", new [=this] () => { Undo(); });
		mRedo = Wire("seq-redo", new [=this] () => { Redo(); });
		mCast = Wire("seq-cast", new [=this] () => { OpenCastMenu(); });
		mAddTrack = Wire("seq-add-track", new [=this] () => { OpenTrackMenu(); });
		mAddSection = Wire("seq-add-section", new [=this] () => { AddSectionAtPlayhead(); });
		mAddMarker = Wire("seq-add-marker", new [=this] () => { AddMarkerAtPlayhead(false); });
		mAddHold = Wire("seq-add-hold", new [=this] () => { AddMarkerAtPlayhead(true); });
		mRemove = Wire("seq-remove", new [=this] () => { RemoveChosen(); });
		mRestart = Wire("seq-restart", new [=this] () => { Restart(); });
		Wire("seq-frame", new [=this] () => { FrameCurves(); });
		Wire("seq-close", new [=this] () => { if (RequestClose != null) RequestClose(); });
		mStop = Wire("seq-stop", new [=this] () => { Stop(); });
		mPlay = Find<ButtonBase>("seq-play");
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
		if (let loop = Find<ButtonBase>("seq-loop"))
			loop.SetOnToggled(new [=this] (on) => { SetLooping(on); });
		mTransport.SetLooping(false); // a cutscene plays once

		// The keys it binds, while it holds the focus: the sequence's, never the scene's.
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
		if (mGrid != null)
			mGrid.Source = null;
		delete mInspected;
		if (mSheet != null)
			mSheet.Source = null;
		if (mCurves != null)
			mCurves.Source = null;
		if (mRuler != null)
			mRuler.MarkerSource = null;
		if (mContent != null)
		{
			for (let token in mCommands)
				mContent.RemoveCommandHandler(token);
		}
		// The preview first (it plays its copy on the scene), the source and the document after.
		delete mPreview;
		delete mSeeds;
		delete mSource;
		delete mDocument;
	}

	public Node Content => mContent;

	// === The sequence ===

	/// Edits the sequence asset `sequenceId` (false: no such sequence), the transport stopped at the
	/// start.
	public bool LoadSequence(Guid sequenceId)
	{
		mPreview.Stop();
		if (!mDocument.Load(sequenceId))
			return false;
		mPreview.ClearCast();
		mTransport.Stop();
		MovePlayhead(0.0f);
		if (mSheet != null)
		{
			mSheet.SetSelection(default);
			mSheet.ClearSelectedSection();
		}
		Pose();
		return true;
	}

	/// Asks about an unsaved sequence, then opens `sequenceId` and fills its cast with `cast` (a
	/// sequence component's).
	public void RequestEditSequence(Guid sequenceId, Span<SequencePanelCast> cast)
	{
		let names = new List<String>();
		let entities = new List<Guid>();
		for (let part in cast)
		{
			names.Add(new .(part.Name));
			entities.Add(part.Entity);
		}
		delegate void() open = new [=this, =sequenceId, =names, =entities] () =>
			{
				if (sequenceId != mDocument.SequenceId)
					LoadSequence(sequenceId);
				for (int i < names.Count)
					mPreview.Bind(names[i], entities[i]);
				Pose();
			} ~ { DeleteContainerAndItems!(names); delete entities; };
		if ((GuardUnsaved != null) && mDocument.IsDirty && (sequenceId != mDocument.SequenceId))
			GuardUnsaved(open);
		else
		{
			open();
			delete open;
		}
	}

	public Result<void, ErrorCode> Save()
	{
		if (!mDocument.HasSequence)
			return .Err(.NotFound);
		if (mDocument.Save() case .Err(let error))
		{
			mContext.Notify(.Warning, scope $"The sequence '{mDocument.Name}' did not save; the Console says why.");
			return .Err(error);
		}
		mContext.Notify(.Info, scope $"Saved the sequence '{mDocument.Name}'.");
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
		mDocument.Edit("sequence-length", scope (sequence) => { sequence.Duration = Math.Max(0.0f, seconds); });
	}

	// === The cast ===

	/// Fills the part `name` with the entity selected in the scene.
	public void CastSelected(StringView name)
	{
		let entity = (SelectedEntity != null) ? SelectedEntity() : Guid.Empty;
		if (entity == .Empty)
			return;
		mPreview.Bind(name, entity);
		Pose();
		ShowBar();
	}

	/// Adds a part named for the selected entity and fills it with it; its index, or -1.
	public int AddPartForSelected()
	{
		let entity = (SelectedEntity != null) ? SelectedEntity() : Guid.Empty;
		let handle = (entity == .Empty) ? EntityHandle.Invalid : mScene.FindEntity(entity);
		if (!mDocument.HasSequence || !handle.IsAssigned)
			return -1;
		// Named for the entity, made unique among the parts.
		let name = scope String(mScene.GetEntityName(handle));
		if (name.IsEmpty)
			name.Set("Actor");
		let unique = scope String(name);
		for (int n = 2; mDocument.Sequence.FindBinding(unique) >= 0; n++)
		{
			unique.Clear();
			unique.AppendF("{} {}", name, n);
		}
		mDocument.Edit("sequence-add-part", scope [&] (sequence) => { sequence.Bindings.Add(new .(unique)); });
		mPreview.Bind(unique, entity);
		Pose();
		ShowBar();
		return mDocument.Sequence.FindBinding(unique);
	}

	public Guid CastEntity(StringView name) => mPreview.BoundEntity(name);

	// === The tracks ===

	/// The tracks of the keys or the section chosen in the dopesheet, into `outTracks`.
	public void ChosenTracks(List<int> outTracks)
	{
		outTracks.Clear();
		if (mSheet == null)
			return;
		let channels = mSource.Channels;
		if (mSheet.HasSelectedSection && (mSheet.SelectedSection.Channel < channels.Length))
			outTracks.Add(channels[mSheet.SelectedSection.Channel].Track);
		for (let key in mSheet.Selection)
		{
			if ((key.Channel < 0) || (key.Channel >= channels.Length))
				continue;
			let track = channels[key.Channel].Track;
			if (!outTracks.Contains(track))
				outTracks.Add(track);
		}
	}

	/// The part of the first chosen track; else the first part; -1 when there is none.
	public int32 ChosenPart()
	{
		let sequence = mDocument.Sequence;
		let tracks = scope List<int>();
		ChosenTracks(tracks);
		if (!tracks.IsEmpty && (tracks[0] < sequence.Tracks.Count))
		{
			let binding = sequence.Tracks[tracks[0]].Binding;
			if ((binding >= 0) && (binding < sequence.Bindings.Count))
				return binding;
		}
		return sequence.Bindings.IsEmpty ? -1 : 0;
	}

	/// What Track offers, appended (the list owns them): every registered kind (for the chosen part
	/// when the kind needs one) and a property track for each of the chosen part's animatable
	/// properties without one.
	public void OfferedTracks(List<SequenceTrackOffer> outOffers)
	{
		if (!mDocument.HasSequence)
			return;
		let sequence = mDocument.Sequence;
		let part = ChosenPart();
		let partName = (part >= 0) ? (StringView)sequence.Bindings[part].Name : "";
		for (let kind in SequenceTracks.Kinds)
		{
			// Offered per property below.
			if (kind == typeof(PropertySequenceTrack))
				continue;
			let probe = MakeTrack(kind);
			if (probe == null)
				continue;
			defer delete probe;
			let offer = new SequenceTrackOffer();
			offer.Kind = kind;
			let kindName = KindLabel(kind, .. scope .());
			if (probe.NeedsBinding)
			{
				offer.Binding = part;
				offer.Enabled = part >= 0;
				if (part >= 0)
					offer.Label.AppendF("{} for {}", kindName, partName);
				else
					offer.Label.AppendF("{} (cast a part first)", kindName);
			}
			else
				offer.Label.Set(kindName);
			outOffers.Add(offer);
		}
		// A property track for each of the part's animatable properties without one.
		let entity = (part >= 0) ? mPreview.BoundEntity(partName) : Guid.Empty;
		if (entity == .Empty)
			return;
		let seeds = scope List<AnimatablePropertyInfo>();
		mSeeds.TrackSeeds(entity, seeds);
		for (let seed in seeds)
		{
			if (HasPropertyTrack(sequence, part, seed.ComponentType, seed.PropertyPath))
			{
				delete seed;
				continue;
			}
			let offer = new SequenceTrackOffer();
			offer.Kind = typeof(PropertySequenceTrack);
			offer.Binding = part;
			offer.Property = true;
			offer.Label.AppendF("{}: {}.{}", partName, seed.ComponentType, seed.PropertyPath);
			offer.Target = seed;
			outOffers.Add(offer);
		}
	}

	public void AddTrack(SequenceTrackOffer offer)
	{
		if (!mDocument.HasSequence || (offer.Kind == null) || !offer.Enabled)
			return;
		let track = MakeTrack(offer.Kind);
		if (track == null)
			return;
		track.Binding = offer.Binding;
		if (offer.Property)
		{
			let property = track as PropertySequenceTrack;
			if ((property == null) || (offer.Target == null) || (offer.Binding < 0))
			{
				delete track;
				return;
			}
			property.Property.ComponentType.Set(offer.Target.ComponentType);
			property.Property.PropertyPath.Set(offer.Target.PropertyPath);
			property.Property.Kind = offer.Target.Kind;
			// It starts with what the part's entity shows now, keyed at the playhead.
			let partName = mDocument.Sequence.Bindings[offer.Binding].Name;
			mPreview.Stop(); // the entity as the scene has it, not as posed
			let value = mSeeds.Read(mPreview.BoundEntity(partName), offer.Target.ComponentType, offer.Target.PropertyPath);
			if (value.HasValue)
				KeyFirst(property.Property, mTransport.Time, value);
		}
		mDocument.Edit("sequence-add-track", scope [&] (sequence) => { sequence.Tracks.Add(track); });
	}

	/// Adds a section at the playhead to the chosen section track; false when none is chosen.
	public bool AddSectionAtPlayhead()
	{
		let tracks = scope List<int>();
		ChosenTracks(tracks);
		for (let t in tracks)
		{
			// A track of keys.
			if (mDocument.Sequence.Tracks[t].KeyChannelCount != 0)
				continue;
			let time = mTransport.Time;
			var made = -1;
			mDocument.Edit("sequence-add-section", scope [&] (sequence) => { made = sequence.Tracks[t].AddSection(time); });
			return made >= 0;
		}
		return false;
	}

	/// Adds a marker (a hold, when `hold`) at the playhead.
	public void AddMarkerAtPlayhead(bool hold)
	{
		if (!mDocument.HasSequence)
			return;
		let time = mTransport.Time;
		mDocument.Edit(hold ? "sequence-add-hold" : "sequence-add-marker", scope (sequence) =>
			{
				int at = 0;
				while ((at < sequence.Markers.Count) && (sequence.Markers[at].Time <= time))
					at++;
				sequence.Markers.Insert(at, new .(time, hold ? "hold" : "marker", hold));
			});
	}

	/// Takes the chosen tracks away, one step; false with none chosen.
	public bool RemoveChosen()
	{
		let tracks = scope List<int>();
		ChosenTracks(tracks);
		if (tracks.IsEmpty)
			return false;
		mPreview.Stop(); // what the tracks wrote goes back before they go
		if (mSheet != null)
		{
			mSheet.SetSelection(default);
			mSheet.ClearSelectedSection();
		}
		// Last first, so each index still names its track.
		tracks.Sort(scope (a, b) => b <=> a);
		mDocument.Edit("sequence-remove-tracks", scope [&] (sequence) =>
			{
				for (let t in tracks)
				{
					delete sequence.Tracks[t];
					sequence.Tracks.RemoveAt(t);
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

	/// The curves shown framed (the bar's Frame).
	public void FrameCurves()
	{
		if (mCurves != null)
			mCurves.FrameAll();
	}

	/// Once a frame from the page: the transport, the preview (stood down while `simulating`), the
	/// inspector and the bar.
	public void Update(float dt, bool simulating)
	{
		if (simulating != mSimulating)
		{
			mSimulating = simulating;
			if (simulating)
			{
				mTransport.Pause(); // the scene's own plays run: the preview stands down
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
		// The dopesheet tells no one of its choice: the curve view and the inspector follow it here.
		ShowCurves();
		ShowInspector();
	}

	/// The preview put back (the page saving the scene, starting a simulation); Repose poses it again
	/// where the playhead stands.
	public void StopPreview() => mPreview.Stop();
	public void Repose() => Pose();

	// === For tests ===

	public SequenceDocument Document => mDocument;
	public Sedulous.Editor.Sequence.SequenceSource Source => mSource;
	public SequencePreview Preview => mPreview;
	public ClipTransport Transport => mTransport;
	public Dopesheet Sheet => mSheet;
	public TimeAxis Axis => mAxis;
	public FieldPropertySource Inspected => mInspected;

	// === Showing it ===

	private void Changed()
	{
		mSource.Refresh();
		mAxis.Duration = mDocument.Length;
		let length = mDocument.Length;
		if ((mLength != null) && ((float)mLength.Value != length))
			mLength.Value = length;
		Pose(); // an edit, an undo: the scene shows the sequence as it is now
		ShowBar();
	}

	private void Pose()
	{
		if (mSimulating || !mDocument.HasSequence || mDocument.Sequence.Tracks.IsEmpty)
		{
			mPreview.Stop();
			return;
		}
		mPreview.Pose(mDocument.Sequence, mDocument.Version, mTransport.Time);
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
		var same = tracks.Count == mShownTracks.Count;
		for (int i = 0; same && (i < tracks.Count); i++)
			same = tracks[i] == mShownTracks[i];
		if (same)
			return;
		mShownTracks.Clear();
		mShownTracks.AddRange(tracks);
		mSource.ShowTracks(tracks);
	}

	private void ShowInspector()
	{
		let tracks = scope List<int>();
		ChosenTracks(tracks);
		let chosen = (tracks.Count == 1) ? tracks[0] : -1;
		if ((chosen == mInspectedTrack) && (mDocument.Version == mInspectedVersion))
			return;
		mInspectedTrack = chosen;
		mInspectedVersion = mDocument.Version;
		let sequence = mDocument.Sequence;
		if ((chosen < 0) || (chosen >= sequence.Tracks.Count))
		{
			if (mGrid != null)
				mGrid.Source = null;
			DeleteAndNullify!(mInspected);
			if (mTrackName != null)
				mTrackName.Text = tracks.IsEmpty ? "No track chosen" : "Several tracks chosen";
			return;
		}
		let track = sequence.Tracks[chosen];
		if (mTrackName != null)
		{
			let title = scope String();
			Sedulous.Editor.Sequence.SequenceSource.TrackLabel(track, title);
			title.Append(" (");
			KindLabel(track.GetType(), title);
			title.Append(")");
			mTrackName.Text = title;
		}
		// The track is rebuilt by each step: the grid finds it again by its place, and an edit there
		// is one step of the sequence's.
		let index = chosen;
		let inspected = new FieldPropertySource(track.GetType(), 1,
			new [=this, =index] (object) =>
			{
				let now = mDocument.Sequence;
				return (index < now.Tracks.Count) ? Internal.UnsafeCastToPtr(now.Tracks[index]) : null;
			},
			new [=this, =index] (apply) =>
			{
				let now = mDocument.Sequence;
				if (index >= now.Tracks.Count)
					return;
				apply(0, Internal.UnsafeCastToPtr(now.Tracks[index]));
				mDocument.RecordEdit("sequence-inspector");
			}, mContext.Resources);
		if (mGrid != null)
			mGrid.Source = inspected;
		// After the grid let go of the old one.
		delete mInspected;
		mInspected = inspected;
	}

	private void ShowBar()
	{
		let open = mDocument.HasSequence;
		if (mName != null)
			mName.Text = open ? mDocument.Name : "No sequence";
		if (mDirty != null)
			mDirty.Displayed = mDocument.IsDirty;
		if (mEmpty != null)
			mEmpty.Displayed = !open;
		if (mBody != null)
			mBody.Displayed = open;
		let editable = open && !mSimulating;
		Enable(mSave, mDocument.IsDirty);
		Enable(mUndo, mDocument.Commands.CanUndo);
		Enable(mRedo, mDocument.Commands.CanRedo);
		Enable(mCast, editable);
		Enable(mAddTrack, editable);
		Enable(mAddSection, editable);
		Enable(mAddMarker, editable);
		Enable(mAddHold, editable);
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

	private void OpenCastMenu()
	{
		if ((mCast == null) || !mDocument.HasSequence)
			return;
		mMenu?.ReleaseRef();
		mMenu = new .();
		mMenu.SetAutoWidth(true);
		let selected = (SelectedEntity != null) && (SelectedEntity() != .Empty);
		for (let binding in mDocument.Sequence.Bindings)
		{
			let name = new String(binding.Name);
			let entity = mPreview.BoundEntity(name);
			let handle = (entity == .Empty) ? EntityHandle.Invalid : mScene.FindEntity(entity);
			let playedBy = handle.IsAssigned ? mScene.GetEntityName(handle) : "no one";
			mMenu.AddItem(scope $"{name} (played by {playedBy}): fill with the selection", new [=this, =name] () => { CastSelected(name); } ~ delete name).Enabled = selected;
		}
		mMenu.AddItem("Add a part for the selection", new [=this] () => { AddPartForSelected(); }).Enabled = selected;
		mMenu.OpenBelow(mCast, mCast);
	}

	private void OpenTrackMenu()
	{
		if (mAddTrack == null)
			return;
		// Made fresh each time: what it offers follows the parts and the tracks.
		mMenu?.ReleaseRef();
		mMenu = new .();
		mMenu.SetAutoWidth(true);
		let offers = scope List<SequenceTrackOffer>();
		defer { ClearAndDeleteItems!(offers); }
		OfferedTracks(offers);
		for (let offer in offers)
		{
			let pick = offer.Clone();
			mMenu.AddItem(offer.Label, new [=this, =pick] () => { AddTrack(pick); } ~ delete pick).Enabled = offer.Enabled;
		}
		mMenu.OpenBelow(mAddTrack, mAddTrack);
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

	/// The kind's name, as it shows it, appended to `outName`.
	public static void KindLabel(Type kind, String outName)
	{
		if (kind.GetCustomAttribute<DisplayNameAttribute>() case .Ok(let shown))
			outName.Append(shown.Name);
		else
			kind.GetName(outName);
	}

	/// A new track of `kind`, OWNED by the caller, made as a sequence being read makes it (each kind
	/// registers its factory), so no list of kinds is kept here; null when it cannot be.
	private static SequenceTrack MakeTrack(Type kind)
	{
		let made = GlobalSerializableRegistry.Create(TypeIdOf(kind.GetFullName(.. scope .())));
		if (let track = made as SequenceTrack)
			return track;
		delete made;
		return null;
	}

	private static bool HasPropertyTrack(Sedulous.Sequence.Sequence sequence, int32 binding, StringView componentType, StringView propertyPath)
	{
		for (let track in sequence.Tracks)
		{
			if (let property = track as PropertySequenceTrack)
			{
				if ((track.Binding == binding) && (property.Property.ComponentType == componentType) &&
					(property.Property.PropertyPath == propertyPath))
					return true;
			}
		}
		return false;
	}

	// The value's parts keyed into a new property track at `time`.
	private static void KeyFirst(PropertyTrack track, float time, Sedulous.PropertyAnimation.PropertyValue value)
	{
		void Set(int channel, float v)
		{
			var key = CurveKey(time, v, .Cubic);
			key.TangentMode = .Auto;
			track.Channels[channel].AddKey(key);
			track.Channels[channel].ApplyTangentModes();
		}
		switch (track.Kind)
		{
		case .Float:
			if (value.Kind == .Float)
				Set(0, value.Scalar);
		case .Float3:
			if (value.Kind == .Float3)
			{
				Set(0, value.Vector.X);
				Set(1, value.Vector.Y);
				Set(2, value.Vector.Z);
			}
		case .Color:
			if (value.Kind == .Color)
			{
				Set(0, value.Color.R);
				Set(1, value.Color.G);
				Set(2, value.Color.B);
				Set(3, value.Color.A);
			}
		case .Quat:
			if (value.Kind == .Quat)
				track.QuatKeys.Add(QuatKey(time, value.Rotation));
		}
	}
}
