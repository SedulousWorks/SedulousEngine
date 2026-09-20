using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.PropertyAnimation;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.PropertyAnimation;

/// The shared clip-editing surface: a transport row (the clip length and a sampled-value
/// readout), the selected track's strip (path, kind, interpolation, Key, remove), the keyframe
/// inspector for the selected key, and one interactive CurveCanvas per scalar track, or the
/// keys strip for a quaternion track. The dopesheet in the panel is the track list; this area
/// shows the selected track only. The view owns zero document policy: it reads and writes the
/// host's clip, pushes every edit through the host's command stack, one undo step per discrete
/// edit and one per curve-drag gesture, and tells the host when the scrub time moves.
class ClipEditorView
{
	private static readonly TrackValueKind[4] cKinds = .(.Float, .Float3, .Color, .Quat);
	private const float cRadToDeg = 57.29577951f;
	private const float cDegToRad = 0.01745329252f;

	private IClipEditorHost mHost;
	private ScrollView mScroll ~ _.ReleaseRef();
	/// Borrowed: the scroll owns it.
	private FlexLayout mRows;
	/// The sampled values at the scrub time plus the selected key; borrowed.
	private Label mPreview = null;
	/// A key is selected somewhere, the canvas or the dopesheet.
	private bool mPreviewSelActive = false;
	private int mPreviewSelTrack = 0;
	/// -1 is the whole track: a dopesheet diamond merges channels.
	private int32 mPreviewSelChannel = -1;
	private float mPreviewSelTime = 0.0f;
	private float mScrubTime = 0.0f;
	/// The canvas time-axis scale, the clip length.
	private float mEditDuration = 1.0f;
	/// The undo snapshot captured on OnEditBegin.
	private PropertyAnimationClip mGestureBefore = null ~ delete _;
	/// A canvas gesture actually changed a key, versus a bare select click.
	private bool mGestureDirty = false;
	/// The dopesheet-selected track; -1 is none.
	private int32 mSelectedTrack = -1;
	/// The persistent inspector host, its children rebuilt per selection; borrowed.
	private FlexLayout mInspectorRow = null;
	/// The live canvas, owned by the row tree; the sync target for the shared time axis.
	private CurveCanvas mCurveCanvas = null;

	public this(IClipEditorHost host)
	{
		mHost = host;
		// The authored length wins when longer than the key extent, so the curve axis always
		// matches the timeline ruler.
		mEditDuration = Math.Max(Math.Max(host.Clip.Duration, host.Clip.ComputeDuration()), 1.0f);
		mScroll = new ScrollView();
		mRows = new FlexLayout();
		mRows.Direction = .Vertical;
		mRows.Spacing = 2.0f;
		mScroll.AddView(mRows);
		Rebuild();
	}

	/// The scrollable rows container; the host wraps this with its chrome. Borrowed.
	public View Root => mScroll;
	public IClipEditorHost Host => mHost;
	public float ScrubTime => mScrubTime;
	public float EditDuration => mEditDuration;
	public int32 SelectedTrack => mSelectedTrack;

	private PropertyAnimationClip Clip => mHost.Clip;

	/// Replaces the host's clip with the state and, optionally, rebuilds the rows. The host's
	/// ApplyClipState forwards here so undo and redo never need a view pointer.
	public void ApplyState(PropertyAnimationClip state, bool rebuild)
	{
		state.CopyTo(mHost.Clip);
		if (rebuild)
			RequestRebuild();
	}

	/// Pushes a whole-clip before and after as one undo step; the dopesheet key-drag commit
	/// uses this, the view's own edits the internal Mutate. Takes ownership of both.
	public void PushClipEdit(PropertyAnimationClip before, PropertyAnimationClip after)
	{
		after.Duration = Math.Max(after.Duration, after.ComputeDuration());
		mHost.Commands.Execute(new ClipEditCommand(mHost, before, after));
	}

	/// Snapshot, mutate, push: the delegate edits a copy that becomes the new clip, one undo
	/// step. An authored longer duration is preserved and grows when keys extend past it.
	private void Mutate(delegate void(PropertyAnimationClip clip) fn)
	{
		let before = Clip.Clone();
		let after = Clip.Clone();
		fn(after);
		after.Duration = Math.Max(after.Duration, after.ComputeDuration());
		mHost.Commands.Execute(new ClipEditCommand(mHost, before, after));
	}

	// ---- construction helpers --------------------------------------------------------------

	private FlexLayout MakeRow(float indent, float height = 24.0f)
	{
		let row = new FlexLayout();
		row.Direction = .Horizontal;
		row.Spacing = 4.0f;
		row.Padding = .(indent, 0);
		var style = LayoutStyle();
		style.Width = SizeSpec.Match();
		style.Height = SizeSpec.Fixed(Unit.Dp(height));
		mRows.AddView(row, style);
		return row;
	}

	/// Takes ownership of the delegate.
	private Button MakeButton(FlexLayout row, StringView label, float width, delegate void() onClick)
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

	private void AddLabel(FlexLayout row, StringView text, float grow = 0.0f, float width = 0.0f)
	{
		let label = new Label(text);
		label.FontSize.Value = 12.0f;
		var style = LayoutStyle();
		if (grow > 0.0f)
			style.FlexGrow = grow;
		else if (width > 0.0f)
			style.Width = SizeSpec.Fixed(Unit.Dp(width));
		style.Height = SizeSpec.Match();
		row.AddView(label, style);
	}

	/// Takes ownership of the commit delegate.
	private void AddTextField(FlexLayout row, StringView value, delegate void(StringView text) commit, float width)
	{
		let field = new EditableLabel();
		field.SetText(value);
		field.FontSize.Value = 12.0f;
		field.OnRenameCommitted.Add(new [=commit](label, committed) =>
			{
				if (!committed.IsEmpty)
					commit(committed);
			} ~ delete commit);
		var style = LayoutStyle();
		style.Width = SizeSpec.Fixed(Unit.Dp(width));
		style.Height = SizeSpec.Match();
		row.AddView(field, style);
	}

	/// Takes ownership of the commit delegate.
	private void AddFloatField(FlexLayout row, float value, delegate void(float value) commit, float width = 56.0f)
	{
		let field = new EditableLabel();
		field.SetText(FormatFloat(value, .. scope .()));
		field.FontSize.Value = 12.0f;
		field.OnRenameCommitted.Add(new [=commit](label, committed) =>
			{
				if (committed.IsEmpty)
					return;
				if (float.Parse(committed) case .Ok(let parsed))
					commit(parsed);
			} ~ delete commit);
		var style = LayoutStyle();
		style.Width = SizeSpec.Fixed(Unit.Dp(width));
		style.Height = SizeSpec.Match();
		row.AddView(field, style);
	}

	public static void FormatFloat(float value, String outText)
	{
		value.ToString(outText);
	}

	// ---- the transport row and readout -----------------------------------------------------

	/// Sets the scrub time from the host's Timeline scrubber and refreshes the readout; the host
	/// separately runs live preview off OnScrubTimeChanged.
	public void SetScrubTime(float t)
	{
		mScrubTime = t;
		RefreshPreview();
	}

	private void BuildTransportRow()
	{
		// The scrub is the Timeline widget's; this row keeps the clip length and the readout.
		let row = MakeRow(0.0f, 26.0f);
		AddLabel(row, "Length", 0.0f, 52.0f);
		// The authoritative duration edit: the host clamps to at least the last key and commits
		// one undo step; the rebuild re-syncs this field and the timeline extent.
		AddFloatField(row, mEditDuration, new (d) => { mHost.SetClipDuration((d > 1e-3f) ? d : 1.0f); }, 56.0f);
		mPreview = new Label("");
		mPreview.FontSize.Value = 11.0f;
		var grow = LayoutStyle();
		grow.FlexGrow = 1.0f;
		grow.Height = SizeSpec.Match();
		row.AddView(mPreview, grow);
		RefreshPreview();
	}

	/// The per-channel labels for a kind; a quaternion has its own row.
	private static StringView ChannelLabel(TrackValueKind kind, int32 channel)
	{
		if (kind == .Color)
			return scope:: StringView[]("r", "g", "b", "a")[((channel >= 0) && (channel < 4)) ? channel : 0];
		return scope:: StringView[]("x", "y", "z")[((channel >= 0) && (channel < 3)) ? channel : 0];
	}

	/// One track's value at the time, formatted per kind. Rotation shows Euler degrees (pitch,
	/// yaw, roll), never raw quaternion parts.
	private static void AppendSampledValue(String outText, PropertyTrack t, float time)
	{
		let v = t.Sample(time);
		switch (t.Kind)
		{
		case .Float:
			FormatFloat(v.Scalar, outText);
		case .Float3:
			let f = v.Vector;
			outText.AppendF("({},{},{})", FormatFloat(f.X, .. scope .()), FormatFloat(f.Y, .. scope .()), FormatFloat(f.Z, .. scope .()));
		case .Color:
			let c = v.Color;
			outText.AppendF("({},{},{},{})", FormatFloat(c.R, .. scope .()), FormatFloat(c.G, .. scope .()), FormatFloat(c.B, .. scope .()), FormatFloat(c.A, .. scope .()));
		case .Quat:
			ToYawPitchRoll(v.Rotation, let yaw, let pitch, let roll);
			outText.AppendF("({},{},{})deg", FormatFloat(pitch * cRadToDeg, .. scope .()), FormatFloat(yaw * cRadToDeg, .. scope .()), FormatFloat(roll * cRadToDeg, .. scope .()));
		}
	}

	/// The sampled-values readout at the current scrub time, the selected key first.
	private void RefreshPreview()
	{
		if (mPreview == null)
			return;
		let text = scope String();
		let clip = Clip;
		if (mPreviewSelActive && (mPreviewSelTrack < clip.Tracks.Count))
		{
			let t = clip.Tracks[mPreviewSelTrack];
			text.AppendF("sel {}", t.PropertyPath);
			if (mPreviewSelChannel >= 0)
				text.AppendF(".{}", ChannelLabel(t.Kind, mPreviewSelChannel));
			text.AppendF(" @{}s=", FormatFloat(mPreviewSelTime, .. scope .()));
			AppendSampledValue(text, t, mPreviewSelTime);
			text.Append("   |   ");
		}
		for (int i < clip.Tracks.Count)
		{
			let t = clip.Tracks[i];
			if (i > 0)
				text.Append("   ");
			text.AppendF("{}=", t.PropertyPath);
			AppendSampledValue(text, t, mScrubTime);
		}
		mPreview.SetText(text);
	}

	/// Selects a key: drives the readout and the keyframe inspector. The canvas pushes its
	/// picks; the panel pushes dopesheet picks, channel -1 being the whole track at that time.
	public void ShowSelectedKey(int trackIndex, int32 channel, float time)
	{
		mPreviewSelActive = true;
		mPreviewSelTrack = trackIndex;
		mPreviewSelChannel = channel;
		mPreviewSelTime = time;
		RefreshPreview();
		RequestInspectorRefresh();
	}

	public void ClearSelectedKey()
	{
		if (!mPreviewSelActive)
			return;
		mPreviewSelActive = false;
		RefreshPreview();
		RequestInspectorRefresh();
	}

	/// Selects a track: the strip, the inspector and the single canvas all show it; -1 none.
	public void SetSelectedTrack(int32 trackIndex)
	{
		let clamped = ((trackIndex >= 0) && (trackIndex < Clip.Tracks.Count)) ? trackIndex : -1;
		if (clamped == mSelectedTrack)
			return;
		mSelectedTrack = clamped;
		if (mPreviewSelActive && (mPreviewSelTrack != clamped))
			mPreviewSelActive = false; // the previous track's key pick is stale here
		RequestRebuild();
	}

	// ---- the selected-track surface --------------------------------------------------------

	private void BuildSelectedTrackStrip()
	{
		let clip = Clip;
		let strip = MakeRow(0.0f, 26.0f);
		if (clip.Tracks.IsEmpty)
		{
			AddLabel(strip, "(no tracks - + Track adds one)", 1.0f);
			return;
		}
		if ((mSelectedTrack < 0) || (mSelectedTrack >= clip.Tracks.Count))
		{
			AddLabel(strip, "(select a track in the dopesheet)", 1.0f);
			return;
		}
		let trackIndex = (int)mSelectedTrack;
		let track = clip.Tracks[trackIndex];

		// One "Component.property.path" field: component type names never contain dots, so
		// the first dot splits; dot-less text edits just the property path.
		AddTextField(strip, scope $"{track.ComponentType}.{track.PropertyPath}", new [=trackIndex, =this](v) =>
			{
				let dot = v.IndexOf('.');
				Mutate(scope [&](c) =>
					{
						let t = c.Tracks[trackIndex];
						if (dot >= 0)
						{
							t.ComponentType.Set(StringView(v, 0, dot));
							t.PropertyPath.Set(StringView(v, dot + 1));
						}
						else
						{
							t.PropertyPath.Set(v);
						}
					});
			}, 190.0f);
		MakeButton(strip, KindName(track.Kind), 58.0f, new [=trackIndex, =this]() =>
			{
				Mutate(scope [&](c) =>
					{
						let t = c.Tracks[trackIndex];
						int k = 0;
						for (int j < 4)
						{
							if (cKinds[j] == t.Kind)
							{
								k = j;
								break;
							}
						}
						t.Kind = cKinds[(k + 1) % 4];
					});
			});
		if (track.Kind != .Quat)
		{
			let cur = (track.Channels[0].KeyCount > 0) ? track.Channels[0].Keys[0].Interpolation : CurveKeyInterpolation.Linear;
			MakeButton(strip, InterpName(cur), 64.0f, new [=trackIndex, =this]() =>
				{
					Mutate(scope [&](c) =>
						{
							let tr = c.Tracks[trackIndex];
							let chn = tr.Kind.ChannelCount;
							CurveKeyInterpolation next = .Linear;
							if ((chn > 0) && (tr.Channels[0].KeyCount > 0))
							{
								let prev = tr.Channels[0].Keys[0].Interpolation;
								next = (prev == .Constant) ? .Linear : (prev == .Linear) ? .Cubic : .Constant;
							}
							for (uint32 ch < chn)
							{
								for (int k < tr.Channels[ch].Keys.Count)
									tr.Channels[ch].Keys[k].Interpolation = next;
							}
						});
				});
		}
		// The key-from-scene capture, the primary value workflow: pose the entity, press Key.
		MakeButton(strip, "Key", 44.0f, new [=trackIndex, =this]() => { KeyTrackFromScene(trackIndex); });
		MakeButton(strip, "Key All", 64.0f, new () => { KeyAllFromScene(); });
		MakeButton(strip, "x", 22.0f, new [=trackIndex, =this]() =>
			{
				ClearSelectedKey();
				Mutate(scope [&](c) => { delete c.Tracks[trackIndex]; c.Tracks.RemoveAt(trackIndex); });
				mSelectedTrack = Math.Min(mSelectedTrack, (int32)Clip.Tracks.Count - 1);
			});
	}

	private void BuildKeyInspectorHost()
	{
		mInspectorRow = MakeRow(0.0f, 26.0f); // the persistent host; children swap per selection
		RefreshKeyInspector();
	}

	/// Rebuilds only the inspector row's children, so the canvas is not lost.
	private void RefreshKeyInspector()
	{
		if (mInspectorRow == null)
			return;
		mInspectorRow.RemoveAllViews();
		let clip = Clip;
		if (!mPreviewSelActive || (mPreviewSelTrack >= clip.Tracks.Count))
		{
			AddLabel(mInspectorRow, "(click a key to edit; Key captures the scene value at the playhead)", 1.0f);
			return;
		}
		let trackIndex = mPreviewSelTrack;
		let track = clip.Tracks[trackIndex];
		let selTime = mPreviewSelTime;

		// Del first: removes the selected key across every channel and the quaternion list at
		// the selected time; the delete path for quaternion keys.
		MakeButton(mInspectorRow, "Del", 36.0f, new [=trackIndex, =selTime, =this]() =>
			{
				ClearSelectedKey();
				Mutate(scope [&](c) =>
					{
						if (trackIndex < c.Tracks.Count)
							TrackKeys.RemoveKeysAt(c.Tracks[trackIndex], selTime);
					});
			});

		// Time: retimes every channel key at the selected time, one undo step.
		AddLabel(mInspectorRow, "Time", 0.0f, 34.0f);
		AddFloatField(mInspectorRow, selTime, new [=trackIndex, =selTime, =this](t) =>
			{
				let clampedT = Math.Max(t, 0.0f);
				Mutate(scope [&](c) =>
					{
						if (trackIndex < c.Tracks.Count)
							TrackKeys.RetimeTrackKeysAt(c.Tracks[trackIndex], selTime, clampedT);
					});
				mPreviewSelTime = clampedT;
			}, 52.0f);

		// Value: exact numeric entry per component; commits upsert at the selected time, so a
		// channel missing a key there gains one instead of dropping the edit.
		switch (track.Kind)
		{
		case .Float:
			AddChannelField(track, trackIndex, selTime, 0, "V");
		case .Float3:
			AddChannelField(track, trackIndex, selTime, 0, "X");
			AddChannelField(track, trackIndex, selTime, 1, "Y");
			AddChannelField(track, trackIndex, selTime, 2, "Z");
		case .Color:
			AddChannelField(track, trackIndex, selTime, 0, "R");
			AddChannelField(track, trackIndex, selTime, 1, "G");
			AddChannelField(track, trackIndex, selTime, 2, "B");
			AddChannelField(track, trackIndex, selTime, 3, "A");
		case .Quat:
			// Euler degrees, pitch, yaw, roll, converted to and from the stored quaternion.
			let at = TrackKeys.FindQuatKeyAt(track, selTime);
			let q = (at >= 0) ? track.QuatKeys[at].Value : Quaternion.Identity;
			ToYawPitchRoll(q, let yaw, let pitch, let roll);
			let eulerDeg = scope float[](pitch * cRadToDeg, yaw * cRadToDeg, roll * cRadToDeg);
			let names = scope StringView[]("P", "Y", "R");
			for (int32 ci < 3)
			{
				AddLabel(mInspectorRow, names[ci], 0.0f, 16.0f);
				AddFloatField(mInspectorRow, eulerDeg[ci], new [=trackIndex, =selTime, =ci, =yaw, =pitch, =roll, =this](vDeg) =>
					{
						var p = pitch;
						var y = yaw;
						var r = roll;
						let v = vDeg * cDegToRad;
						if (ci == 0)
							p = v;
						else if (ci == 1)
							y = v;
						else
							r = v;
						let nq = FromYawPitchRoll(y, p, r);
						Mutate(scope [&](c) =>
							{
								if (trackIndex < c.Tracks.Count)
									TrackKeys.UpsertQuatKeyAt(c.Tracks[trackIndex], selTime, nq);
							});
					}, 56.0f);
			}
		}
	}

	private void AddChannelField(PropertyTrack track, int trackIndex, float selTime, uint32 channel, StringView name)
	{
		let at = TrackKeys.FindChannelKeyAt(track, channel, selTime);
		let shown = (at >= 0) ? track.Channels[channel].Keys[at].Value : 0.0f;
		AddLabel(mInspectorRow, name, 0.0f, 16.0f);
		AddFloatField(mInspectorRow, shown, new [=trackIndex, =selTime, =channel, =this](v) =>
			{
				Mutate(scope [&](c) =>
					{
						if (trackIndex < c.Tracks.Count)
							TrackKeys.UpsertChannelKeyAt(c.Tracks[trackIndex], channel, selTime, v);
					});
			}, 56.0f);
	}

	/// Quaternion tracks have no canvas: the keys strip makes their keyframes visible and
	/// clickable, chips selecting into the inspector where Del removes.
	private void BuildQuatKeysRow(int trackIndex)
	{
		let track = Clip.Tracks[trackIndex];
		let row = MakeRow(0.0f, 24.0f);
		AddLabel(row, "Keys", 0.0f, 34.0f);
		if (track.QuatKeys.IsEmpty)
		{
			AddLabel(row, "(none - Key captures the pose at the playhead)", 1.0f);
			return;
		}
		for (let key in track.QuatKeys)
		{
			let keyTime = key.Time;
			let isSelected = mPreviewSelActive && (mPreviewSelTrack == trackIndex) && (Math.Abs(mPreviewSelTime - keyTime) < TrackKeys.cTimeEps);
			let chip = scope String();
			chip.Append(isSelected ? "[@" : "@");
			FormatFloat(keyTime, chip);
			if (isSelected)
				chip.Append("]");
			MakeButton(row, chip, 58.0f, new [=trackIndex, =keyTime, =this]() =>
				{
					ShowSelectedKey(trackIndex, -1, keyTime);
					RequestRebuild(); // the selected marker moves to this chip
				});
		}
	}

	/// Deferred via the UI mutation queue, mid dispatch safe.
	private void RequestInspectorRefresh()
	{
		let ctx = (mRows != null) ? mRows.Context : null;
		if (ctx == null)
		{
			RefreshKeyInspector();
			return;
		}
		ctx.MutationQueue.QueueAction(new () => { RefreshKeyInspector(); });
	}

	/// Captures the scene value at the playhead into the track.
	private void KeyTrackFromScene(int trackIndex)
	{
		if (trackIndex >= Clip.Tracks.Count)
			return;
		let track = Clip.Tracks[trackIndex];
		let value = mHost.ReadSceneValue(track.ComponentType, track.PropertyPath);
		if (!value.HasValue)
		{
			GlobalLog(.Warning, "PropertyAnimation: Key: no scene value for {}.{} (is the bound entity selected?)", track.ComponentType, track.PropertyPath);
			return;
		}
		let at = mScrubTime;
		bool matched = false;
		Mutate(scope [&](c) =>
			{
				if (trackIndex < c.Tracks.Count)
					matched = TrackKeys.UpsertTrackValueAt(c.Tracks[trackIndex], at, value);
			});
		if (!matched)
			GlobalLog(.Warning, "PropertyAnimation: Key: scene value type mismatch for {}.{}", track.ComponentType, track.PropertyPath);
		ShowSelectedKey(trackIndex, -1, at);
	}

	/// Reads every track's scene value first, then writes all captured ones as one undo step.
	private void KeyAllFromScene()
	{
		let clip = Clip;
		let values = scope List<PropertyValue>();
		int captured = 0;
		for (let track in clip.Tracks)
		{
			let v = mHost.ReadSceneValue(track.ComponentType, track.PropertyPath);
			if (v.HasValue)
				captured++;
			values.Add(v);
		}
		if (captured == 0)
		{
			GlobalLog(.Warning, "PropertyAnimation: Key All: no track resolved a scene value (is the bound entity selected?)");
			return;
		}
		let at = mScrubTime;
		Mutate(scope [&](c) =>
			{
				for (int i = 0; (i < c.Tracks.Count) && (i < values.Count); i++)
				{
					if (values[i].HasValue)
						TrackKeys.UpsertTrackValueAt(c.Tracks[i], at, values[i]);
				}
			});
	}

	// ---- the curve canvas ------------------------------------------------------------------

	/// Pushes the host's shared time transform into the live canvas so it follows the
	/// Timeline's zoom and scroll; the panel calls it on the Timeline's view change. Only the
	/// scale and scroll change, the gutter inset being fixed at build; invalidates on change
	/// only, so an idle canvas triggers no redraw.
	public void SyncCanvasTransform()
	{
		if (mCurveCanvas == null)
			return;
		let axis = mHost.ClipTimeTransform;
		if ((mCurveCanvas.PixelsPerSecond != axis.PixelsPerSecond) || (mCurveCanvas.ScrollSeconds != axis.ScrollSeconds))
		{
			mCurveCanvas.PixelsPerSecond = axis.PixelsPerSecond;
			mCurveCanvas.ScrollSeconds = axis.ScrollSeconds;
			mCurveCanvas.Invalidate();
		}
	}

	private void AddCurveCanvas(int trackIndex)
	{
		let track = Clip.Tracks[trackIndex];
		let channels = track.Kind.ChannelCount;
		if (channels == 0)
			return;

		let canvas = new CurveCanvas();
		canvas.MaxKeys = 64;
		canvas.AutoFitValueRange = true;
		canvas.LinkedTime = channels > 1;
		// The curve time axis is seconds matching the clip length, sharing the dopesheet axis;
		// key times are stored and edited in absolute seconds.
		canvas.TimeSpan = (mEditDuration > 1e-3f) ? mEditDuration : 1.0f;
		let axis = mHost.ClipTimeTransform;
		canvas.UseSharedTimeTransform = true;
		canvas.PixelsPerSecond = axis.PixelsPerSecond;
		canvas.ScrollSeconds = axis.ScrollSeconds;

		let trackInterp = (track.Channels[0].KeyCount > 0) ? track.Channels[0].Keys[0].Interpolation : CurveKeyInterpolation.Linear;
		let stroke = scope Color[](.(0.9f, 0.4f, 0.4f, 1.0f), .(0.4f, 0.9f, 0.5f, 1.0f), .(0.45f, 0.65f, 1.0f, 1.0f), .(0.85f, 0.85f, 0.4f, 1.0f));
		let descs = scope List<ChannelDescriptor>();
		for (int32 ch < (int32)channels)
		{
			var d = ChannelDescriptor();
			d.Name = ChannelLabel(track.Kind, ch);
			d.StrokeColor = stroke[(ch < 4) ? ch : 0];
			d.Interpolation = ClipToCanvasInterp(trackInterp);
			descs.Add(d);
		}
		canvas.SetChannels(descs);
		PushTrackToCanvas(trackIndex, canvas);

		mCurveCanvas = canvas; // the sync target the panel pushes zoom and scroll into
		canvas.OnEditBegin.Add(new () =>
			{
				delete mGestureBefore;
				mGestureBefore = Clip.Clone();
				mGestureDirty = false;
			});
		canvas.OnKeyChanged.Add(new [=trackIndex, =canvas, =this](ch, ki) =>
			{
				// A drag moves the selected key: the readout's time and value stay current. A
				// linked-time drag fires once per channel, so only the canvas's own selected key
				// updates the readout, or the last channel would win every click.
				if ((ch == canvas.SelectedChannel) && (ki == canvas.SelectedKeyIndex) && (ki >= 0) && (ki < canvas.GetKeyCount(ch)))
				{
					mPreviewSelActive = true;
					mPreviewSelTrack = trackIndex;
					mPreviewSelChannel = ch;
					mPreviewSelTime = canvas.GetKey(ch, ki).Time;
				}
				WriteBackTrack(trackIndex, canvas);
			});
		canvas.OnKeyAdded.Add(new [=trackIndex, =canvas, =this](ch, ki) => { WriteBackTrack(trackIndex, canvas); });
		canvas.OnKeyRemoved.Add(new [=trackIndex, =canvas, =this](ch, ki) => { WriteBackTrack(trackIndex, canvas); });
		canvas.OnSelectionChanged.Add(new [=trackIndex, =canvas, =this](ch, ki) =>
			{
				// Selection is selection: any key pick updates the readout.
				if ((ch >= 0) && (ki >= 0) && (ki < canvas.GetKeyCount(ch)))
					ShowSelectedKey(trackIndex, ch, canvas.GetKey(ch, ki).Time);
				else
					ClearSelectedKey();
			});
		canvas.OnEditEnd.Add(new () =>
			{
				// A bare select click fires begin and end with no key change: nothing is pushed,
				// so the selection and its tangent handles survive the mouse up.
				if (!mGestureDirty || (mGestureBefore == null))
					return;
				// One undo step per gesture. The live edits already mutated the clip and the
				// canvas shows them, so the command applies the after state without a rebuild.
				let after = Clip.Clone();
				after.Duration = Math.Max(after.Duration, after.ComputeDuration()); // the authored length stays
				let before = mGestureBefore;
				mGestureBefore = null;
				mHost.Commands.Execute(new ClipEditCommand(mHost, before, after, true));
			});

		let wrap = new FlexLayout();
		wrap.Direction = .Vertical;
		// Inset by the dopesheet's label-column gutter so t=0 sits at the same screen x as the
		// lanes above; no right inset, the canvas fills the rest.
		wrap.Padding = .(axis.LabelColumnWidth, 0.0f, 0.0f, 0.0f);
		var style = LayoutStyle();
		style.Width = SizeSpec.Match();
		style.Height = SizeSpec.Fixed(Unit.Dp(120.0f));
		wrap.AddView(canvas, style);
		var wrapStyle = LayoutStyle();
		wrapStyle.Width = SizeSpec.Match();
		wrapStyle.Height = SizeSpec.Fixed(Unit.Dp(122.0f));
		mRows.AddView(wrap, wrapStyle);
	}

	private void PushTrackToCanvas(int trackIndex, CurveCanvas canvas)
	{
		let track = Clip.Tracks[trackIndex];
		for (int32 ch < (int32)track.Kind.ChannelCount)
		{
			let keys = scope List<CurveCanvas.Key>();
			for (let k in track.Channels[ch].Keys)
				keys.Add(.(k.Time, k.Value, k.TangentIn, k.TangentOut)); // absolute seconds
			canvas.SetKeys(ch, keys);
		}
	}

	private void WriteBackTrack(int trackIndex, CurveCanvas canvas)
	{
		let clip = Clip;
		if (trackIndex >= clip.Tracks.Count)
			return;
		let track = clip.Tracks[trackIndex];
		for (int32 ch < (int32)track.Kind.ChannelCount)
		{
			// The canvas carries one interpolation per channel, so write-back flattens it onto
			// every key of the channel; authored per-key interpolation is not preserved.
			let interp = CanvasToClipInterp(canvas.GetChannelDescriptor(ch).Interpolation);
			let n = canvas.GetKeyCount(ch);
			track.Channels[ch].Clear();
			for (int32 i < n)
			{
				let k = canvas.GetKey(ch, i);
				var ck = CurveKey();
				ck.Time = k.Time;
				ck.Value = k.Value;
				ck.TangentIn = k.TangentIn;
				ck.TangentOut = k.TangentOut;
				ck.Interpolation = interp;
				track.Channels[ch].AddKey(ck);
			}
		}
		clip.Duration = Math.Max(clip.Duration, clip.ComputeDuration()); // an authored length stays
		mGestureDirty = true;
		mHost.MarkClipDirty();
		RefreshPreview();
	}

	// ---- rebuild ---------------------------------------------------------------------------

	/// Rebuilds the rows from the host's current clip, immediately: after an undo or redo
	/// replaces the clip, and once at construction.
	public void Rebuild()
	{
		// The canvas time axis and the Length field follow the clip's authored duration.
		mEditDuration = Math.Max(Math.Max(Clip.Duration, Clip.ComputeDuration()), 1.0f);
		let clip = Clip;
		if (mSelectedTrack >= clip.Tracks.Count)
			mSelectedTrack = (int32)clip.Tracks.Count - 1; // clamped after removals
		if ((mSelectedTrack < 0) && !clip.Tracks.IsEmpty)
			mSelectedTrack = 0; // something is always selected when tracks exist
		mRows.RemoveAllViews();
		mInspectorRow = null; // rebuilt below, the old row just destroyed
		mCurveCanvas = null;
		BuildTransportRow();
		BuildSelectedTrackStrip();
		BuildKeyInspectorHost();
		if ((mSelectedTrack >= 0) && (mSelectedTrack < clip.Tracks.Count))
		{
			if (clip.Tracks[mSelectedTrack].Kind != .Quat)
				AddCurveCanvas(mSelectedTrack); // one canvas, for the selected scalar track
			else
				BuildQuatKeysRow(mSelectedTrack);
		}
		mHost.OnClipViewRebuilt();
	}

	/// Appends a track as one undoable edit; it becomes the working track.
	public void AddTrack(StringView componentType, StringView propertyPath, TrackValueKind kind)
	{
		Mutate(scope [&](c) =>
			{
				let t = new PropertyTrack();
				t.ComponentType.Set(componentType);
				t.PropertyPath.Set(propertyPath);
				t.Kind = kind;
				c.Tracks.Add(t);
			});
		mSelectedTrack = (int32)Clip.Tracks.Count - 1;
	}

	/// Resyncs to the host's current clip after it was replaced wholesale, a new or loaded
	/// document rather than an edit: the axis recomputes, the scrub resets, the rows rebuild.
	public void ResetForClip()
	{
		mEditDuration = Math.Max(Math.Max(Clip.Duration, Clip.ComputeDuration()), 1.0f);
		mScrubTime = 0.0f;
		mPreviewSelActive = false;
		mSelectedTrack = Clip.Tracks.IsEmpty ? -1 : 0;
		Rebuild();
	}

	/// Defers a Rebuild through the UI mutation queue, mid dispatch safe.
	public void RequestRebuild()
	{
		let ctx = (mRows != null) ? mRows.Context : null;
		if (ctx == null)
		{
			Rebuild();
			return;
		}
		ctx.MutationQueue.QueueAction(new () => { Rebuild(); });
	}

	private static StringView KindName(TrackValueKind kind)
	{
		switch (kind)
		{
		case .Float: return "Float";
		case .Float3: return "Float3";
		case .Color: return "Color";
		case .Quat: return "Quat";
		}
	}

	private static StringView InterpName(CurveKeyInterpolation interp)
	{
		switch (interp)
		{
		case .Constant: return "Step";
		case .Linear: return "Linear";
		case .Cubic: return "Cubic";
		}
	}

	private static CurveInterpolation ClipToCanvasInterp(CurveKeyInterpolation i)
	{
		switch (i)
		{
		case .Constant: return .Step;
		case .Linear: return .Linear;
		case .Cubic: return .Hermite;
		}
	}

	private static CurveKeyInterpolation CanvasToClipInterp(CurveInterpolation i)
	{
		switch (i)
		{
		case .Step: return .Constant;
		case .Linear: return .Linear;
		case .Hermite: return .Cubic;
		}
	}
}
