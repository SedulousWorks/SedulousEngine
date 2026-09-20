using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Content;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;

namespace Sedulous.Editor.PropertyAnimation;

/// The docked chrome: the header with the document actions and the bound-entity slot, the
/// exclusive empty state, and the body with the transport, the Timeline and the shared view;
/// plus the header actions and the dopesheet lanes.
extension PropertyAnimationPanel
{
	/// Takes ownership of the delegate.
	private Button AddButton(FlexLayout row, StringView label, float width, delegate void() onClick)
	{
		let button = new Button(label);
		button.FontSize.Value = 11.0f;
		button.OnClick.Add(new [=onClick](b) => { onClick(); } ~ delete onClick);
		var style = LayoutStyle();
		style.Width = SizeSpec.Fixed(Unit.Dp(width));
		style.Height = SizeSpec.Match();
		row.AddView(button, style);
		return button;
	}

	private static LayoutStyle RowStyle(float height)
	{
		var style = LayoutStyle();
		style.Width = SizeSpec.Match();
		style.Height = SizeSpec.Fixed(Unit.Dp(height));
		return style;
	}

	private void BuildChrome()
	{
		Direction = .Vertical;
		Padding = .(6, 6);
		Spacing = 4.0f;

		// The header, shown with a clip loaded: the document actions, the clip label and the
		// bound-entity slot.
		mHeader = new FlexLayout();
		mHeader.Direction = .Horizontal;
		mHeader.Spacing = 4.0f;
		AddButton(mHeader, "Create...", 70.0f, new () => { OnCreateClip(); });
		AddButton(mHeader, "Open...", 62.0f, new () => { OnOpenClip(); });
		AddButton(mHeader, "Save", 52.0f, new () => { OnSave(); });
		AddButton(mHeader, "+ Tracks", 72.0f, new () => { OnAddFromSelection(); });
		mAddTrackButton = AddButton(mHeader, "+ Track", 62.0f, new () => { OnAddTrackMenu(); });
		mClipLabel = new Label("");
		mClipLabel.FontSize.Value = 11.0f;
		var grow = LayoutStyle();
		grow.FlexGrow = 1.0f;
		grow.Height = SizeSpec.Match();
		mHeader.AddView(mClipLabel, grow);
		// The bound-entity slot: preview, keying and seeding target this entity, never the live
		// selection; "Use Selected" is where selection enters, "Bind..." opens the scene page's
		// entity picker through the RequestEntityPick seam.
		mEntityLabel = new Label("");
		mEntityLabel.FontSize.Value = 11.0f;
		var slot = LayoutStyle();
		slot.Width = SizeSpec.Fixed(Unit.Dp(170));
		slot.Height = SizeSpec.Match();
		mHeader.AddView(mEntityLabel, slot);
		AddButton(mHeader, "Bind...", 58.0f, new () =>
			{
				if (RequestEntityPick == null)
					return; // no host wiring, headless: the slot is read-only then
				RequestEntityPick(mBoundEntity, new (picked) =>
					{
						if (picked.IsSet)
							BindEntity(picked);
					});
			});
		AddButton(mHeader, "Use Selected", 96.0f, new () => { BindSelectedEntity(); });
		AddView(mHeader, RowStyle(26));

		// The exclusive empty state: no clip means just the message with Create and Open.
		mEmptyState = new FlexLayout();
		mEmptyState.Direction = .Vertical;
		mEmptyState.Spacing = 8.0f;
		mEmptyState.Padding = .(12, 12);
		{
			let message = new Label("No animation clip selected for editing.");
			message.FontSize.Value = 12.0f;
			var match = LayoutStyle();
			match.Width = SizeSpec.Match();
			mEmptyState.AddView(message, match);
			let row = new FlexLayout();
			row.Direction = .Horizontal;
			row.Spacing = 6.0f;
			AddButton(row, "Create Clip...", 104.0f, new () => { OnCreateClip(); });
			AddButton(row, "Open Clip...", 96.0f, new () => { OnOpenClip(); });
			mEmptyState.AddView(row, RowStyle(26));
			AddView(mEmptyState, match);
		}

		// The body: the transport, the Timeline scrubber and the shared view.
		mBody = new FlexLayout();
		mBody.Direction = .Vertical;
		mBody.Spacing = 4.0f;

		let transport = new FlexLayout();
		transport.Direction = .Horizontal;
		transport.Spacing = 4.0f;
		mPlayButton = AddButton(transport, "Play", 52.0f, new () => { Play(); });
		mPauseButton = AddButton(transport, "Pause", 60.0f, new () => { TogglePause(); });
		AddButton(transport, "Stop", 52.0f, new () => { Stop(); });
		mLoopButton = AddButton(transport, "Loop: on", 76.0f, new () => { SetLooping(!mLoop); });
		mBody.AddView(transport, RowStyle(26));

		mTimeline = new Timeline();
		mTimeline.SetDuration(Math.Max(Math.Max(mClip.Duration, mClip.ComputeDuration()), 1.0f));
		mTimeline.LabelColumnWidth = 140.0f; // the track-label gutter: the dopesheet is the track list
		// The scrubber routes through OnScrubTimeChanged, which ignores it while Playing; a key
		// drag on a lane commits through MoveSelectedKeys, one undo step.
		mTimeline.OnPlayheadMoved.Add(new (t) => { OnScrubTimeChanged(t); });
		mTimeline.OnKeysMoved.Add(new (d) => { MoveSelectedKeys(d); });
		// When the dopesheet zooms or scrolls, the curve canvas follows.
		mTimeline.OnViewChanged.Add(new () => { if (mView != null) mView.SyncCanvasTransform(); });
		// A gutter or key pick selects the track: the strip, inspector and canvas re-target.
		mTimeline.OnLaneSelected.Add(new (lane) => { if (mView != null) mView.SetSelectedTrack(lane); });
		// A dopesheet pick updates the value readout too. A lane is a track; a diamond merges
		// channels, so channel -1 is the whole track at that key time.
		mTimeline.OnSelectionChanged.Add(new () =>
			{
				if (mView == null)
					return;
				let sel = scope List<DopesheetKeyRef>();
				mTimeline.GetSelection(sel);
				if (sel.IsEmpty)
				{
					mView.ClearSelectedKey();
					return;
				}
				let r = sel.Back;
				if ((r.Lane < mLaneKeyTimes.Count) && (r.Index < mLaneKeyTimes[r.Lane].Count))
					mView.ShowSelectedKey(r.Lane, -1, mLaneKeyTimes[r.Lane][r.Index]);
			});
		mTimelineParams = RowStyle(cTimelineMinHeight);
		mBody.AddView(mTimeline, mTimelineParams);

		mView = new ClipEditorView(this);
		mView.Root.AddRef();
		var fill = LayoutStyle();
		fill.Width = SizeSpec.Match();
		fill.FlexGrow = 1.0f;
		mBody.AddView(mView.Root, fill);
		AddView(mBody, fill);
	}

	/// The header shows only with a clip loaded; the empty state owns the no-clip case.
	private void RefreshHeader()
	{
		let text = scope String();
		if (HasClip)
		{
			text.AppendF("Clip: {}", ClipName);
			if (mDirty)
				text.Append(" *");
		}
		if (!mStatusFlash.IsEmpty)
			text.AppendF("   [{}]", mStatusFlash);
		if (mClipLabel != null)
			mClipLabel.SetText(text);
	}

	/// A transient header status, shown for a few seconds, then RefreshHeader restores the clip
	/// line; driven by Tick.
	private void FlashStatus(StringView status)
	{
		mStatusFlash.Set(status);
		mStatusFlashSeconds = 2.5f;
		RefreshHeader();
	}

	/// The empty state and the editor body are exclusive.
	private void RefreshClipStateUI()
	{
		let hasClip = HasClip;
		if (mHeader != null)
			mHeader.Visibility = hasClip ? .Visible : .Gone;
		if (mBody != null)
			mBody.Visibility = hasClip ? .Visible : .Gone;
		if (mEmptyState != null)
			mEmptyState.Visibility = hasClip ? .Gone : .Visible;
		Invalidate();
	}

	// ---- the header actions ----------------------------------------------------------------

	/// Runs the action now, or, when a modified clip is loaded, after a Save, Discard or Cancel
	/// prompt, Cancel dropping it. The dirty guard every load and create path shares. Takes
	/// ownership of the delegate.
	private void RunDirtyGuarded(delegate void() proceed)
	{
		if (proceed == null)
			return;
		if (!HasClip || !mDirty)
		{
			proceed();
			delete proceed;
			return;
		}
		let ctx = Context;
		if (ctx == null)
		{
			proceed(); // headless: no dialog host to ask, the caller decided
			delete proceed;
			return;
		}
		let dialog = new ConfirmDialog("Unsaved Clip", scope $"Clip '{mClipName}' has unsaved changes.", scope StringView[]("Save", "Discard", "Cancel"));
		dialog.OnChosen = new [=proceed, =this](choice) =>
			{
				if (choice == 2)
					return; // Cancel keeps editing the current clip
				if (choice == 0)
				{
					SaveClip();
					if (mDirty)
						return; // the save failed and the header flashed why
				}
				proceed();
			} ~ delete proceed;
		dialog.Show(ctx);
	}

	private void OnCreateClip()
	{
		RunDirtyGuarded(new () =>
			{
				let ctx = Context;
				if ((ctx == null) || (mEditorCtx.Project == null))
					return;
				let dialog = new AssetCreateDialog(mEditorCtx, "Create Animation Clip", "clip name");
				dialog.OnCreate = new (group, name) =>
					{
						let inst = PropertyAnimationEditor.CreateClipNamed(mEditorCtx, group, name);
						if (inst == null)
						{
							GlobalLog(.Warning, "PropertyAnimation: Create clip '{}' failed", name);
							return;
						}
						LoadClip(inst.Id); // the guid is the open and identity currency
					};
				dialog.Show(ctx);
			});
	}

	private void OnOpenClip()
	{
		RunDirtyGuarded(new () =>
			{
				let ctx = Context;
				if ((ctx == null) || (mEditorCtx.Project == null))
					return;
				let dialog = new AssetPickerDialog(mEditorCtx, scope StringView[]("PropertyAnimationClipAsset"));
				dialog.OnPicked = new (picked) =>
					{
						if (picked.IsSet)
							LoadClip(picked);
					};
				dialog.Show(ctx);
			});
	}

	private void OnAddFromSelection()
	{
		let added = AddTracksFromSelection(mView);
		if (added == 0)
			GlobalLog(.Information, "Editor: add-tracks: no bound entity or no animatable properties");
		RefreshHeader();
	}

	/// "+ Track": a property picker over the bound entity's animatable leaves.
	private void OnAddTrackMenu()
	{
		let ctx = Context;
		if (ctx == null)
			return;
		let seeds = scope List<AnimatablePropertyInfo>();
		defer { ClearAndDeleteItems(seeds); }
		CollectSelectionTrackSeeds(seeds);
		let menu = new ContextMenu();
		defer menu.ReleaseRef();
		int offered = 0;
		for (let seed in seeds)
		{
			if (ClipHasTrack(seed.ComponentType, seed.PropertyPath))
				continue; // already a track for this property
			let pick = seed.Clone();
			menu.AddItem(scope $"{seed.ComponentType}.{seed.PropertyPath}", new [=pick, =this]() =>
				{
					mView.AddTrack(pick.ComponentType, pick.PropertyPath, pick.Kind);
					RefreshHeader();
				} ~ delete pick);
			offered++;
		}
		if (offered == 0)
			menu.AddItem(seeds.IsEmpty ? "(bind an entity first)" : "(all properties already tracked)", new () => {});
		let pos = (mAddTrackButton != null) ? mAddTrackButton.LocalToScreen(.(0.0f, 24.0f)) : Float2.Zero;
		menu.Show(ctx, pos.X, pos.Y);
	}

	private void OnSave()
	{
		SaveClip();
		RefreshHeader();
	}

	// ---- the dopesheet lanes ---------------------------------------------------------------

	/// Rebuilds the lanes from the clip, one per track, preserving the selection by time
	/// across the rebuild since keys have no id; sizes the timeline pane.
	private void BuildLanes()
	{
		if (mTimeline == null)
			return;

		// A pending move overrides with the moved keys' new times; otherwise the current
		// selection's times are re-captured.
		let marks = scope List<ReselectMark>();
		if (mHaveReselect)
		{
			marks.AddRange(mReselectTimes);
			mReselectTimes.Clear();
			mHaveReselect = false;
		}
		else
		{
			let sel = scope List<DopesheetKeyRef>();
			mTimeline.GetSelection(sel);
			for (let r in sel)
			{
				if ((r.Lane < mLaneKeyTimes.Count) && (r.Index < mLaneKeyTimes[r.Lane].Count))
					marks.Add(.(r.Lane, mLaneKeyTimes[r.Lane][r.Index]));
			}
		}

		// One lane per track; markers at the track's distinct key times.
		let lanes = new List<DopesheetLane>();
		ClearAndDeleteItems(mLaneKeyTimes);
		for (let track in mClip.Tracks)
		{
			let times = new List<float>();
			TrackKeys.CollectKeyTimes(track, times);
			let lane = new DopesheetLane(scope $"{track.ComponentType}.{track.PropertyPath}");
			lane.KeyTimes.AddRange(times);
			lanes.Add(lane);
			mLaneKeyTimes.Add(times);
		}
		mTimeline.SetLanes(lanes); // clears the widget's selection
		// The dopesheet is the track list: the view's selected track mirrors into the lane
		// highlight, programmatically.
		mTimeline.SetSelectedLane((mView != null) ? mView.SelectedTrack : -1);

		// The selection re-resolves by time against the rebuilt lanes.
		let newSel = scope List<DopesheetKeyRef>();
		for (let mark in marks)
		{
			if (mark.Lane >= mLaneKeyTimes.Count)
				continue;
			let lt = mLaneKeyTimes[mark.Lane];
			for (int i < lt.Count)
			{
				if (Math.Abs(lt[i] - mark.Time) < TrackKeys.cTimeEps)
				{
					newSel.Add(.(mark.Lane, (uint32)i));
					break;
				}
			}
		}
		mTimeline.SetSelection(newSel);

		// The timeline pane sizes to the ruler plus the lanes, capped.
		let h = Math.Clamp(cRulerBand + (float)mClip.Tracks.Count * cLaneHeight, cTimelineMinHeight, cTimelineMaxHeight);
		mTimelineParams.Height = SizeSpec.Fixed(Unit.Dp(h));
		mTimeline.SetLayout(mTimelineParams);
		if (mBody != null)
			mBody.Invalidate();
	}

	/// A dopesheet key drag: the selected keys' times shift by the delta as one undo step,
	/// then the lanes rebuild and the moved keys re-select by their new time.
	private void MoveSelectedKeys(float deltaSeconds)
	{
		if ((mView == null) || (mTimeline == null) || (Math.Abs(deltaSeconds) < 1e-5f))
			return;
		let sel = scope List<DopesheetKeyRef>();
		mTimeline.GetSelection(sel);
		if (sel.IsEmpty)
			return;

		let before = mClip.Clone();
		let after = mClip.Clone();
		let marks = scope List<ReselectMark>();
		for (let r in sel)
		{
			if ((r.Lane >= after.Tracks.Count) || (r.Lane >= mLaneKeyTimes.Count) || (r.Index >= mLaneKeyTimes[r.Lane].Count))
				continue;
			let t0 = mLaneKeyTimes[r.Lane][r.Index];
			let t1 = Math.Max(t0 + deltaSeconds, 0.0f);
			TrackKeys.RetimeTrackKeysAt(after.Tracks[r.Lane], t0, t1);
			marks.Add(.(r.Lane, t1));
		}
		if (marks.IsEmpty)
		{
			delete before;
			delete after;
			return;
		}
		mReselectTimes.Clear();
		mReselectTimes.AddRange(marks);
		mHaveReselect = true;
		mView.PushClipEdit(before, after); // one undo step; applies and defers a row rebuild
		BuildLanes(); // the lanes rebuild now and the moved keys re-select
	}
}
