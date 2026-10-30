using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Content;
using Sedulous.Resource;
using Sedulous.Animation;
using Sedulous.Animation.Resource;
using Sedulous.Animation.Pipeline;
using Sedulous.Runtime.Client;
using Sedulous.Graphics;
using Sedulous.GUI;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Animation;

/// An animation clip on the GUI from its markup (Data/Editor/AnimationClipPage.gml; Raptor's
/// editor-gui spec, 5.4, layer 10, part 2). The preview plays the cooked clip on a skeleton (the
/// bones, and a skinned mesh over them when one is picked), both chosen on the preview's bar and kept
/// per clip with the project; the skeleton the importer named is the one it starts on. Travel, the
/// preview's own choice (it had been among the clip's rows), walks it by the clip's root motion; off,
/// it plays in place, as it is cooked, the path drawn on the ground either way. The kit's transport
/// plays it; under the preview, the ruler on the clip's time scrubs it, and the clip's events are its
/// markers: one chosen opens its rows, one dragged moves its time, one step.
///
/// The clip's tracks and keys come from its import and nothing here edits them, so the rows are the
/// page's own, not its reflection's: under Clip whether it loops; under Root motion the bone it is
/// read from and what it extracts (travel, height, turning); under Events a list, each a time and a
/// name (a new one at the playhead), named by its name and summed up by its time while closed. Its
/// facts (its name, duration, tracks and keys) are read-only rows. Each edit is one undo step (the
/// whole asset before and after). Clips come from import: there is no creator.
class AnimationClipEditorPage : AssetObjectPage, IPlaybackPage
{
	/// The clip's events as the ruler's markers: the page's own (a source is a class, and the page
	/// already has its base).
	private class EventMarkers : ITimeMarkerSource
	{
		private AnimationClipEditorPage mPage;

		public this(AnimationClipEditorPage page)
		{
			mPage = page;
		}

		public override int MarkerCount => mPage.MarkerCount;
		public override void GetMarker(int marker, TimeMarker outMarker) => mPage.GetMarker(marker, outMarker);
		public override void BeginMarkerMove(int marker) => mPage.BeginMarkerMove(marker);
		public override void PreviewMarkerMove(int marker, float time) => mPage.PreviewMarkerMove(marker, time);
		public override void CommitMarkerMove() => mPage.CommitMarkerMove();
		public override void CancelMarkerMove() => mPage.CancelMarkerMove();
		public void Changed() => NotifyTimeMarkersChanged();
	}

	public const String cMarkupPath = "Editor/AnimationClipPage.gml";
	private const String cEvents = "events";
	private const String cNewEventName = "Event";

	/// The rows; the base's sections let go of them first (ClearSections).
	private Sedulous.GUI.PropertyBag mClipRows = null;
	private Sedulous.GUI.PropertyBag mRootRows = null;
	private Sedulous.GUI.PropertyBag mEventRows = null;
	private PreviewPane mPane = null;
	private AnimationPreviewRig mRig = null;
	/// The cooked product, retained.
	private Proxy<AnimationClip> mClip = default;
	private Sedulous.GUI.TimeAxis mAxis = new .() ~ _.ReleaseRef();
	// The markup's (its tree holds them).
	private TimeRuler mRuler = null;
	private Sedulous.GUI.Label mState = null;
	private ButtonBase mTravelButton = null;
	private List<BoneTransform> mPose = new .() ~ delete _;
	private float mTime = 0.0f;
	private bool mPlaying = true;
	private bool mTravel = false;
	/// The clock moving the playhead: not a scrub.
	private bool mMoving = false;
	/// The ruler's width and the clip's length, as last fitted.
	private float mRulerWidth = 0.0f;
	private float mFittedLength = 0.0f;
	/// The event a marker drag moves, and its time when the drag began.
	private int32 mMarkerMoving = -1;
	private float mMarkerFrom = 0.0f;
	/// After the ruler lets go of it (the destructor).
	private EventMarkers mMarkers ~ delete _;

	/// It takes `services`.
	public this(EditorContext context, AssetPageServices services, Instance instance)
		: base(context, services, instance, typeof(AnimationClipAsset), cMarkupPath)
	{
		// Its tracks and keys are its import's: the rows are the page's own.
		HideAssetRows();
		mMarkers = new .(this);
		BuildRows();

		mAxis.FrameRate = 30.0f;
		mAxis.Duration = Length;
		mAxis.SetOnPlayheadChanged(new [=this] (time) =>
			{
				if (mMoving)
					return;
				// A scrub: the preview holds where it is put.
				mTime = time;
				mPlaying = false;
			});
		if (Content != null)
		{
			mPane = new PreviewPane(Content, Services, "animclip.preview");
			mPane.OnFrame = new [=this] () => { FramePreview(); };
			mRig = new AnimationPreviewRig(Context, Services, mPane);
			mRig.SetOnPicked(new [=this] () => { SavePreviewPref(); });
			mRig.SetOnFirstShown(new [=this] () => { FramePreview(); });
			BindAction(Find<ButtonBase>("clip-restart"), "playback.restart");
			BindAction(Find<ButtonBase>("clip-play"), "playback.play");
			BindAction(Find<ButtonBase>("clip-stop"), "playback.stop");
			mState = Find<Sedulous.GUI.Label>("clip-state");
			mTravelButton = Find<ButtonBase>("clip-travel");
			if (mTravelButton != null)
				mTravelButton.SetOnClick(new [=this] () => { SetTravel(!mTravel); });
			mRuler = Find<TimeRuler>("clip-ruler");
			if (mRuler != null)
			{
				mRuler.TimeAxis = mAxis;
				mRuler.MarkerSource = mMarkers;
				mRuler.SetOnMarkerChosen(new [=this] (marker) => { ChooseEvent(marker); });
			}
		}
		if (Context.Resources != null)
		{
			mClip = Context.Resources.Bind<AnimationClip>(InstanceId);
			mClip.Retain();
		}
		LoadPreviewPref();
		ShowRows();
		ShowFacts();
	}

	public ~this()
	{
		if (mRuler != null)
		{
			mRuler.MarkerSource = null;
			mRuler.SetOnMarkerChosen(null);
		}
		// The rig before the pane whose preview it draws in.
		DeleteAndNullify!(mRig);
		DeleteAndNullify!(mPane);
		mClip.Forget();
		// The grid's sections let go of the rows before they go (the base's outlive these).
		ClearSections();
		DeleteAndNullify!(mClipRows);
		DeleteAndNullify!(mRootRows);
		DeleteAndNullify!(mEventRows);
	}

	public AnimationClipAsset Clip => ObjectAs<AnimationClipAsset>();

	/// The clip's length as the ruler and the clock take it: the cooked clip's, else the source's.
	public float Length
	{
		get
		{
			let cooked = mClip.Get;
			if ((cooked != null) && (cooked.Duration > 0.0f))
				return cooked.Duration;
			let clip = Clip;
			return ((clip != null) && (clip.Source.Duration > 0.0f)) ? clip.Source.Duration : 1.0f;
		}
	}

	// === For tests ===

	public Sedulous.GUI.PropertyBag ClipRows => mClipRows;
	public Sedulous.GUI.PropertyBag RootRows => mRootRows;
	public Sedulous.GUI.PropertyBag EventRows => mEventRows;
	public AnimationPreviewRig Rig => mRig;
	public TimeRuler Ruler => mRuler;
	public ITimeMarkerSource Markers => mMarkers;

	/// Where the preview is in the clip (seconds); a scrub of the ruler moves it.
	public float Time => mTime;

	public void SetTime(float seconds)
	{
		mTime = Math.Clamp(seconds, 0.0f, Length);
		mMoving = true;
		mAxis.Playhead = mTime;
		mMoving = false;
	}

	/// The preview walking by the clip's root motion (the bar's Travel).
	public void SetTravel(bool travel)
	{
		mTravel = travel;
		if (mTravelButton != null)
			mTravelButton.Checked = travel;
	}

	public bool Travels => mTravel;

	/// The event `index` chosen: its rows opened in the grid, its marker the ruler's chosen one.
	public void ChooseEvent(int32 index)
	{
		let clip = Clip;
		if ((clip == null) || (index < 0) || (index >= clip.Source.EventTime.Count))
			return;
		if ((mRuler != null) && (mRuler.ChosenMarker != index))
			mRuler.ChooseMarker(index); // tells this again, which opens it below
		let grid = Grid;
		if (grid == null)
			return;
		grid.SetOpen(Sections.PathIn("events", cEvents, .. scope String()), true);
		let path = Sections.PathIn("events", scope String()..AppendF("{}.{}", cEvents, index), .. scope String());
		grid.SetOpen(path, true);
		let found = grid.FindRow(path);
		if (found >= 0)
			grid.ScrollToItem(found, .Start);
	}

	// === The rows ===

	private void BuildRows()
	{
		mClipRows = new Sedulous.GUI.PropertyBag();
		mRootRows = new Sedulous.GUI.PropertyBag();
		mEventRows = new Sedulous.GUI.PropertyBag();

		let looping = mClipRows.Add("looping", .Bool, Sedulous.GUI.Variant(false));
		looping.DisplayName.Set("Looping");
		looping.Description.Set("Whether it plays again from its start when it ends (an animator may say otherwise)");

		let bone = mRootRows.Add("bone", .String, Sedulous.GUI.Variant(""));
		bone.DisplayName.Set("Root bone");
		bone.Description.Set("The bone its travel is read from, by name (empty: the skeleton's first root)");
		void Axis(StringView path, StringView shown, StringView about)
		{
			let info = mRootRows.Add(path, .Bool, Sedulous.GUI.Variant(false));
			info.DisplayName.Set(shown);
			info.Description.Set(about);
		}
		Axis("horizontal", "Travel", "Its travel along the ground taken out of the pose, for the character to move by");
		Axis("vertical", "Height", "Its rise and fall taken out too (a jump that should lift the character)");
		Axis("yaw", "Turning", "Its turning about the vertical taken out, for the character to turn by");

		// The events as every page's lists: each a group of its time and its name, a new one at the
		// playhead. Their order means nothing (a time places each), so the list does not move them.
		let list = mEventRows.AddList(cEvents, .Group, .());
		list.DisplayName.Set("Events");
		list.Description.Set("What the clip tells its listeners as it plays past each (a footstep, a hit); each a marker on the ruler");
		list.ListOps = PropertyListAdd | PropertyListRemove;
		if (let time = mEventRows.AddElementField(cEvents, "time", .Float, Sedulous.GUI.Variant(0.0)))
		{
			time.DisplayName.Set("Time");
			time.Description.Set("When it fires, in seconds from the clip's start (kept within the clip)");
			time.Step = 0.01;
		}
		if (let name = mEventRows.AddElementField(cEvents, "name", .String, Sedulous.GUI.Variant(cNewEventName)))
		{
			name.DisplayName.Set("Name");
			name.Description.Set("What its listeners are told");
		}

		for (let rows in Sedulous.GUI.PropertyBag[3](mClipRows, mRootRows, mEventRows))
		{
			rows.SetOnCommit(new [=this, =rows] (commit) =>
				{
					if (!commit.After.IsEmpty)
						Committed(rows, commit.Path, commit.After[0]);
				});
			rows.PropertiesChanged(); // Add told the grid before the rows' names were set
		}
		mEventRows.SetOnListEdited(new [=this] (path, edit) => { EditEvents(edit); });
		// Each event by its name, closed showing when it fires.
		mEventRows.SetOnDescribe(new [=this] (path, info) =>
			{
				if (ParentPropertyPath(path) != cEvents)
					return;
				let index = EventOf(path);
				let clip = Clip;
				if ((clip == null) || (index < 0) || (index >= clip.Source.EventTime.Count))
					return;
				let name = (index < clip.Source.EventName.Count) ? (StringView)clip.Source.EventName[index] : "";
				info.DisplayName.Clear();
				if (name.IsEmpty)
					info.DisplayName.AppendF("Event {}", index + 1);
				else
					info.DisplayName.Set(name);
				info.Summary.Set("at ");
				Seconds(clip.Source.EventTime[index], info.Summary);
			});
		AddSection("clip", "Clip", mClipRows);
		AddSection("root", "Root motion", mRootRows);
		AddSection("events", "Events", mEventRows);
	}

	private void ShowRows()
	{
		let clip = Clip;
		if ((clip == null) || (mClipRows == null))
			return;
		let source = clip.Source;
		mClipRows.SetValue("looping", 0, Sedulous.GUI.Variant(source.IsLooping));
		mRootRows.SetValue("bone", 0, Sedulous.GUI.Variant(source.RootBone));
		mRootRows.SetValue("horizontal", 0, Sedulous.GUI.Variant(source.RootHorizontal));
		mRootRows.SetValue("vertical", 0, Sedulous.GUI.Variant(source.RootVertical));
		mRootRows.SetValue("yaw", 0, Sedulous.GUI.Variant(source.RootYaw));
		let count = Math.Max(source.EventTime.Count, source.EventName.Count); // an edit squares them
		mEventRows.ResizeList(cEvents, 0, count);
		let path = scope String();
		for (int i < count)
		{
			let time = (i < source.EventTime.Count) ? source.EventTime[i] : 0.0f;
			let name = (i < source.EventName.Count) ? (StringView)source.EventName[i] : "";
			path.Clear();
			path.AppendF("{}.{}.time", cEvents, i);
			mEventRows.SetValue(path, 0, Sedulous.GUI.Variant((double)time));
			path.Clear();
			path.AppendF("{}.{}.name", cEvents, i);
			mEventRows.SetValue(path, 0, Sedulous.GUI.Variant(name));
		}
		mEventRows.PropertiesChanged(); // the names and summaries described again
	}

	private void ShowFacts()
	{
		let clip = Clip;
		if (clip == null)
			return;
		let source = clip.Source;
		SetFact("Name", source.Name.IsEmpty ? "Unnamed" : (StringView)source.Name);
		SetFact("Duration", Seconds(source.Duration, .. scope String()));
		SetFact("Tracks", scope String()..AppendF("{}", source.TrackBone.Count));
		SetFact("Keys", scope String()..AppendF("{}", source.KeyTime.Count));
	}

	private void Committed(Sedulous.GUI.PropertyBag rows, StringView path, Sedulous.GUI.Variant value)
	{
		if (Clip == null)
			return;
		if (rows === mClipRows)
		{
			let looping = value.AsBool;
			EditWhole("edit_animclip", scope (object) => { ((AnimationClipAsset)object).Source.IsLooping = looping; });
			return;
		}
		if (rows === mRootRows)
		{
			if (path == "bone")
			{
				var bone = scope String(value.AsString);
				bone.Trim();
				EditWhole("edit_animclip", scope [&] (object) => { ((AnimationClipAsset)object).Source.RootBone.Set(bone); });
				return;
			}
			let on = value.AsBool;
			EditWhole("edit_animclip", scope [&] (object) =>
				{
					let source = ((AnimationClipAsset)object).Source;
					if (path == "horizontal")
						source.RootHorizontal = on;
					else if (path == "vertical")
						source.RootVertical = on;
					else
						source.RootYaw = on;
				});
			return;
		}
		let index = EventOf(path);
		if ((index < 0) || (index >= Clip.Source.EventTime.Count))
			return;
		let field = LastSegment(path);
		if (field == "time")
		{
			let time = (float)Math.Clamp(value.AsFloat, 0.0, (double)Length);
			EditWhole("edit_animclip", scope [&] (object) =>
				{
					let source = ((AnimationClipAsset)object).Source;
					Square(source);
					source.EventTime[index] = time;
				});
		}
		else if (field == "name")
		{
			let name = scope String(value.AsString);
			EditWhole("edit_animclip", scope [&] (object) =>
				{
					let source = ((AnimationClipAsset)object).Source;
					Square(source);
					source.EventName[index].Set(name);
				});
		}
	}

	private void EditEvents(ListEdit edit)
	{
		let clip = Clip;
		if (clip == null)
			return;
		if (edit.Kind == .Insert)
		{
			// At the playhead, at the end of the list: its place in the list means nothing.
			let time = Math.Clamp(mTime, 0.0f, Length);
			EditWhole("edit_animclip", scope [&] (object) =>
				{
					let source = ((AnimationClipAsset)object).Source;
					Square(source);
					source.EventTime.Add(time);
					source.EventName.Add(new String(cNewEventName));
				});
		}
		else if ((edit.Kind == .Remove) && (edit.Index >= 0) && (edit.Index < clip.Source.EventTime.Count))
		{
			let index = edit.Index;
			EditWhole("edit_animclip", scope [&] (object) =>
				{
					let source = ((AnimationClipAsset)object).Source;
					Square(source);
					source.EventTime.RemoveAt(index);
					delete source.EventName[index];
					source.EventName.RemoveAt(index);
				});
		}
		ShowRows(); // the list as the clip holds it (a move, which the list does not offer, goes back)
	}

	protected override void OnObjectChanged()
	{
		ShowRows();
		ShowFacts();
		if (mMarkers != null)
			mMarkers.Changed();
	}

	// === The events as the ruler's markers (EventMarkers asks these) ===

	public int MarkerCount
	{
		get
		{
			let clip = Clip;
			return (clip != null) ? clip.Source.EventTime.Count : 0;
		}
	}

	public void GetMarker(int marker, TimeMarker outMarker)
	{
		outMarker.Time = 0.0f;
		outMarker.Label.Clear();
		let clip = Clip;
		if ((clip == null) || (marker < 0) || (marker >= clip.Source.EventTime.Count))
			return;
		let name = (marker < clip.Source.EventName.Count) ? (StringView)clip.Source.EventName[marker] : "";
		outMarker.Time = clip.Source.EventTime[marker];
		if (name.IsEmpty)
			outMarker.Label.AppendF("Event {}", marker + 1);
		else
			outMarker.Label.Set(name);
	}

	public void BeginMarkerMove(int marker)
	{
		let clip = Clip;
		if ((clip == null) || (marker < 0) || (marker >= clip.Source.EventTime.Count))
			return;
		mMarkerMoving = (int32)marker;
		mMarkerFrom = clip.Source.EventTime[marker];
	}

	public void PreviewMarkerMove(int marker, float time)
	{
		let clip = Clip;
		if ((clip == null) || (marker != mMarkerMoving) || (marker >= clip.Source.EventTime.Count))
			return;
		// Live in the asset (the row follows), the step taken once the drag ends.
		clip.Source.EventTime[marker] = Math.Clamp(time, 0.0f, Length);
		mEventRows.SetValue(scope String()..AppendF("{}.{}.time", cEvents, marker), 0,
			Sedulous.GUI.Variant((double)clip.Source.EventTime[marker]));
	}

	public void CommitMarkerMove()
	{
		let clip = Clip;
		let moving = mMarkerMoving;
		mMarkerMoving = -1;
		if ((clip == null) || (moving < 0) || (moving >= clip.Source.EventTime.Count))
			return;
		let time = clip.Source.EventTime[moving];
		clip.Source.EventTime[moving] = mMarkerFrom; // the step's before is where the drag began
		if (time == mMarkerFrom)
			return;
		EditWhole("edit_animclip", scope [&] (object) =>
			{
				let source = ((AnimationClipAsset)object).Source;
				Square(source);
				source.EventTime[moving] = time;
			});
	}

	public void CancelMarkerMove()
	{
		let clip = Clip;
		let moving = mMarkerMoving;
		mMarkerMoving = -1;
		if ((clip == null) || (moving < 0) || (moving >= clip.Source.EventTime.Count))
			return;
		clip.Source.EventTime[moving] = mMarkerFrom;
		ShowRows();
	}

	// === The preview ===

	private void LoadPreviewPref()
	{
		if (mRig == null)
			return;
		var skeleton = Guid();
		var mesh = Guid();
		if (ClipPreviewPrefs.Load(Context.ProjectEditorSettings, InstanceId, ref skeleton, ref mesh))
		{
			mRig.SetSkeleton(skeleton);
			mRig.SetMesh(mesh);
			return;
		}
		// Never shown before: on the skeleton its import names, the one its bones address.
		if (let clip = Clip)
			mRig.SetSkeleton(clip.Skeleton);
		mRig.SetMesh(.());
	}

	private void SavePreviewPref()
	{
		if ((mRig != null) && ClipPreviewPrefs.Save(Context.ProjectEditorSettings, InstanceId, mRig.SkeletonId, mRig.MeshId))
			Context.RequestProjectEditorSettingsSave();
	}

	private void FramePreview()
	{
		if ((mPane == null) || (mPane.Viewport == null))
			return;
		if ((mRig != null) && mRig.Frame())
			return;
		// Nothing shown yet: a character's height in view, from a little above its middle.
		let camera = mPane.Viewport.Camera;
		camera.Position = .(0.0f, 1.4f, 3.2f);
		camera.LookAt(.(0.0f, 0.9f, 0.0f));
	}

	private void Pose()
	{
		if (mRig == null)
			return;
		let clip = mClip.Get;
		let skeleton = mRig.CookedSkeleton;
		if (mPane != null)
		{
			if (skeleton == null)
				mPane.ShowEmpty("No skeleton to play it on", "Pick the skeleton its bones belong to on the preview's bar.");
			else
				mPane.Show();
		}
		if ((clip == null) || (skeleton == null) || (skeleton.BoneCount <= 0))
		{
			mRig.Show(.(), .Identity());
			return;
		}
		mPose.Count = skeleton.BoneCount;
		AnimationSampler.SampleClip(clip, skeleton, mTime, mPose);
		// Under the armature's rest transform, as the model places it (a Z-up file's turn, its units);
		// cooked, the pose plays in place, travelling, it goes where its root motion takes it.
		let rest = (Clip != null) ? Clip.ModelRest.ToMatrix() : Float4x4.Identity();
		let placement = mTravel ? (rest * AnimationPreview.RootMotionPlacement(clip, mTime)) : rest;
		mRig.Show(mPose, placement);
		if ((mPane != null) && (mPane.Viewport != null) && mPane.Viewport.IsValid)
			AnimationPreview.DrawRootMotionPath(mPane.Viewport.SceneDebugDraw, clip, mTime);
	}

	private void FollowAxis()
	{
		// The ruler shows the whole clip, fitted again when its width or the clip's length changes.
		let length = Length;
		if (mAxis.Duration != length)
			mAxis.Duration = length;
		let width = (mRuler != null) ? mRuler.ContentBounds.Width : 0.0f;
		if ((width > 0.0f) && ((width != mRulerWidth) || (length != mFittedLength)))
		{
			mRulerWidth = width;
			mFittedLength = length;
			mAxis.Frame(0.0f, length, width);
		}
	}

	private void ShowTransport()
	{
		if (mState == null)
			return;
		// Its width fixed by the sheet; paused says so by its colour, as the Play button does by its icon.
		let text = scope String();
		if (mClip.Get == null)
			text.Set("Not cooked yet");
		else
		{
			Seconds(mTime, text);
			text.Append(" / ");
			Seconds(Length, text);
		}
		if (mState.Text != text)
			mState.Text = text;
		if (mPlaying)
		{
			mState.AddClass("playing");
			mState.RemoveClass("paused");
		}
		else
		{
			mState.AddClass("paused");
			mState.RemoveClass("playing");
		}
	}

	// === IPlaybackPage: the preview's clock, never the clip's ===

	public bool CanPlay => mClip.Get != null;
	public bool IsPlaying => mPlaying;

	public void Play()
	{
		// Resumes; one that ran to its end starts over.
		if (mTime >= Length)
			SetTime(0.0f);
		mPlaying = true;
	}

	public void Pause()
	{
		mPlaying = false;
	}

	public void Stop()
	{
		mPlaying = false;
		SetTime(0.0f);
	}

	public void Restart()
	{
		SetTime(0.0f);
		mPlaying = true;
	}

	public override void OnUpdate(IApplicationHost host, float dt)
	{
		base.OnUpdate(host, dt);
		FollowAxis();
		if (mPlaying && CanPlay)
		{
			let clip = mClip.Get;
			let length = Length;
			var time = mTime + dt;
			if (time > length)
			{
				if (clip.IsLooping)
					time = time % length;
				else
				{
					time = length;
					mPlaying = false;
				}
			}
			SetTime(time);
		}
		ShowTransport();
		Pose();
		if (mPane != null)
			mPane.Update(dt);
	}

	public override void OnRenderWindow(IApplicationHost host, ref FrameContext frame)
	{
		if (mPane != null)
			mPane.Render(ref frame);
	}

	public override void OnClose()
	{
		if (mPane != null)
			mPane.Close();
	}

	// === Helpers ===

	// The event a row's path names ("events.2.time": 2), or -1.
	private static int32 EventOf(StringView path)
	{
		var element = path;
		if (ParentPropertyPath(element) != cEvents)
			element = ParentPropertyPath(path);
		if (ParentPropertyPath(element) != cEvents)
			return -1;
		if (int32.Parse(element.Substring(cEvents.Length + 1)) case .Ok(let index))
			return (index >= 0) ? index : -1;
		return -1;
	}

	private static StringView LastSegment(StringView path)
	{
		let dot = path.LastIndexOf('.');
		return (dot >= 0) ? path.Substring(dot + 1) : path;
	}

	// The events' two lists as long as each other, whatever an older clip kept.
	private static void Square(AnimationClipSource source)
	{
		while (source.EventName.Count < source.EventTime.Count)
			source.EventName.Add(new String());
		while (source.EventTime.Count < source.EventName.Count)
			source.EventTime.Add(0.0f);
	}

	// Two decimals always, so a time running past ("0.90 s", "0.95 s") keeps its width; appended.
	private static void Seconds(float seconds, String outText)
	{
		let cents = (int64)(Math.Max(seconds, 0.0f) * 100.0f + 0.5f);
		outText.AppendF("{}.{}{} s", cents / 100, (cents % 100) / 10, cents % 10);
	}
}
