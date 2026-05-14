namespace Sedulous.UI.Toolkit;

using System;
using System.Collections;
using Sedulous.UI;
using Sedulous.Core.Mathematics;

/// Interpolation modes available per-channel on CurveCanvas. Hermite is
/// first (=0) so a zero-initialized ChannelDescriptor defaults to Hermite,
/// which is the right pick for particle / animation curves.
public enum CurveInterpolation : uint8
{
	/// Cubic Hermite using per-key TangentIn / TangentOut.
	Hermite,
	/// Linear between adjacent keys; tangents ignored.
	Linear,
	/// Step / hold; value jumps to the next key's value at that key's Time.
	Step
}

/// Per-channel metadata pushed into CurveCanvas via SetChannels. Lets the
/// widget render N curves on the same canvas without knowing what the
/// channels represent (X/Y, R/G/B/A, gain/cutoff/resonance, ...).
///
/// All fields are designed so a zero-initialized descriptor (e.g. a
/// freshly-allocated `scope ChannelDescriptor[N]` slot) gives sensible
/// defaults: visible, unlocked, no value clamps, Hermite interpolation.
public struct ChannelDescriptor
{
	/// Short identifier shown in legend strips (e.g. "X", "R", "Gain").
	public String Name;

	/// Stroke color used for the polyline and key markers.
	public Color StrokeColor;

	/// Value used when a key is added to this channel implicitly - e.g.
	/// LinkedTime mode adds a key to every channel; the channel the user
	/// did NOT click uses this fallback value.
	public float DefaultValue;

	/// When true, the channel is hidden (not rendered or hit-tested).
	/// Inverted polarity so the zero-init default is "visible".
	public bool Hidden;

	/// When true, the channel rejects edits but still renders.
	public bool Locked;

	/// Inclusive value clamps applied on edit. If `MinValue >= MaxValue`
	/// (e.g. both zero from zero-init) the clamp is treated as disabled
	/// and values pass through unchanged. Auto-fit always reads actual
	/// key values, never these clamps.
	public float MinValue;
	public float MaxValue;

	/// How this channel's curve interpolates between keys. Hermite = 0 so
	/// zero-init lands on the right pick for particle / animation curves.
	public CurveInterpolation Interpolation;

	/// Optional longer description (reserved for hover tooltips; not yet
	/// rendered by the canvas itself, but available to wrapping editors).
	public String Description;
}

/// Multi-channel interactive curve editor canvas. Model-agnostic: callers
/// describe their channels via SetChannels, push initial keys via
/// SetKeys(channelIdx, ...), and listen to OnKey* events to project
/// mutations back to their domain types. Reusable for any keyframe-based
/// authoring - particle curves, animation easing, audio envelopes,
/// tone-mapping LUTs, post-FX over time, gameplay tuning curves.
///
/// v1 interactions:
///   - Left click empty space      -> add a key to the active channel
///                                    (LinkedTime: adds to every channel
///                                    at the same Time)
///   - Left click on key           -> select that (channel, key);
///                                    drag moves it (LinkedTime: drag
///                                    moves Time for all channels at
///                                    that index; Value only for the
///                                    active one)
///   - Right click on key          -> delete (LinkedTime: removes the
///                                    matching index in every channel)
///
/// Tangent handle editing is not yet exposed; tangents stay at the values
/// pushed via SetKeys (typically zero for newly added keys).
public class CurveCanvas : View
{
	/// One keypoint. Times in [0, 1]; Values in user space. Tangents are
	/// slope (dy/dt) at the key.
	public struct Key
	{
		public float Time;
		public float Value;
		public float TangentIn;
		public float TangentOut;

		public this(float time, float value, float tangentIn = 0, float tangentOut = 0)
		{
			Time = time;
			Value = value;
			TangentIn = tangentIn;
			TangentOut = tangentOut;
		}
	}

	private class Channel
	{
		public ChannelDescriptor Descriptor;
		public List<Key> Keys = new .() ~ delete _;
	}

	private List<Channel> mChannels = new .() ~ DeleteContainerAndItems!(_);

	private int32 mSelectedChannelIdx = -1;
	private int32 mSelectedKeyIdx = -1;
	private int32 mDraggingChannelIdx = -1;
	private int32 mDraggingKeyIdx = -1;
	private bool mInGesture;

	/// Max keypoints per channel. Default matches the particle limit.
	public int32 MaxKeys = 8;

	/// When true, all channels share a single Time axis: every channel has
	/// the same KeyCount and the i-th key has the same Time across all
	/// channels. Add / remove / Time-drag propagate to every channel;
	/// Value-drag affects only the active channel.
	public bool LinkedTime = false;

	/// When true, ValueMin / ValueMax are recomputed from current visible
	/// keys (with a small margin). When false, the explicit ValueMin /
	/// ValueMax are honored.
	public bool AutoFitValueRange = true;

	public float ValueMin = 0;
	public float ValueMax = 1;

	/// Fired when an edit gesture begins (mouse-down starting a drag, or
	/// click-add, or right-click delete).
	public Event<delegate void()> OnEditBegin ~ _.Dispose();

	/// Fired when the current edit gesture commits.
	public Event<delegate void()> OnEditEnd ~ _.Dispose();

	/// Fired when an existing key was repositioned. Payload: channel index,
	/// key index.
	public Event<delegate void(int32, int32)> OnKeyChanged ~ _.Dispose();

	/// Fired after a new key was inserted.
	public Event<delegate void(int32, int32)> OnKeyAdded ~ _.Dispose();

	/// Fired after an existing key was deleted; payload carries the OLD
	/// index (before removal) so callers can mirror it in their model.
	public Event<delegate void(int32, int32)> OnKeyRemoved ~ _.Dispose();

	public int32 ChannelCount => (int32)mChannels.Count;
	public int32 SelectedChannel => mSelectedChannelIdx;
	public int32 SelectedKeyIndex => mSelectedKeyIdx;

	public ChannelDescriptor GetChannelDescriptor(int32 idx) => mChannels[idx].Descriptor;
	public int32 GetKeyCount(int32 channelIdx) => (int32)mChannels[channelIdx].Keys.Count;
	public Key GetKey(int32 channelIdx, int32 keyIdx) => mChannels[channelIdx].Keys[keyIdx];

	/// Configure the channel set. Clears existing keys. Selection resets to
	/// channel 0 if any channels exist.
	public void SetChannels(Span<ChannelDescriptor> channels)
	{
		ClearChannels();
		for (let desc in channels)
		{
			let ch = new Channel();
			ch.Descriptor = desc;
			mChannels.Add(ch);
		}
		mSelectedChannelIdx = mChannels.Count > 0 ? 0 : -1;
		mSelectedKeyIdx = -1;
		mDraggingChannelIdx = -1;
		mDraggingKeyIdx = -1;
		Invalidate();
	}

	private void ClearChannels()
	{
		for (let ch in mChannels) delete ch;
		mChannels.Clear();
	}

	/// Replace one channel's keys. Does not enforce LinkedTime alignment -
	/// callers should push matched-time keys for all channels when using
	/// LinkedTime. After SetKeys, in-progress drag state on that channel
	/// is invalidated.
	public void SetKeys(int32 channelIdx, Span<Key> keys)
	{
		if (channelIdx < 0 || channelIdx >= mChannels.Count) return;
		let ch = mChannels[channelIdx];
		ch.Keys.Clear();
		for (let k in keys) ch.Keys.Add(k);
		if (mDraggingChannelIdx == channelIdx)
		{
			mDraggingChannelIdx = -1;
			mDraggingKeyIdx = -1;
		}
		if (mSelectedChannelIdx == channelIdx) mSelectedKeyIdx = -1;
		Invalidate();
	}

	// === Curve evaluation ===

	private float Evaluate(int32 channelIdx, float t)
	{
		let ch = mChannels[channelIdx];
		if (ch.Keys.Count == 0) return 0;
		if (ch.Keys.Count == 1) return ch.Keys[0].Value;
		if (t <= ch.Keys[0].Time) return ch.Keys[0].Value;
		if (t >= ch.Keys[ch.Keys.Count - 1].Time) return ch.Keys[ch.Keys.Count - 1].Value;

		for (int32 i = 0; i < ch.Keys.Count - 1; i++)
		{
			let a = ch.Keys[i];
			let b = ch.Keys[i + 1];
			if (t >= a.Time && t <= b.Time)
			{
				let seg = b.Time - a.Time;
				if (seg < 0.0001f) return a.Value;
				let lt = (t - a.Time) / seg;
				switch (ch.Descriptor.Interpolation)
				{
				case .Linear: return a.Value + (b.Value - a.Value) * lt;
				case .Step:   return a.Value;
				case .Hermite:
					let lt2 = lt * lt;
					let lt3 = lt2 * lt;
					return (2 * lt3 - 3 * lt2 + 1) * a.Value
						+ (lt3 - 2 * lt2 + lt) * (a.TangentOut * seg)
						+ (-2 * lt3 + 3 * lt2) * b.Value
						+ (lt3 - lt2) * (b.TangentIn * seg);
				}
			}
		}
		return ch.Keys[ch.Keys.Count - 1].Value;
	}

	// === Auto-fit value range ===

	private void UpdateAutoFit()
	{
		if (!AutoFitValueRange) return;
		float lo = float.MaxValue, hi = float.MinValue;
		bool any = false;
		for (let ch in mChannels)
		{
			if (ch.Descriptor.Hidden) continue;
			for (let k in ch.Keys)
			{
				if (k.Value < lo) lo = k.Value;
				if (k.Value > hi) hi = k.Value;
				any = true;
			}
		}
		if (!any) { ValueMin = 0; ValueMax = 1; return; }
		if (lo == hi) { ValueMin = lo - 1; ValueMax = hi + 1; return; }
		let margin = (hi - lo) * 0.1f;
		ValueMin = lo - margin;
		ValueMax = hi + margin;
	}

	// === Coordinate transforms ===

	private float TimeToX(float t) => t * Width;
	private float ValueToY(float v)
	{
		let denom = (ValueMax - ValueMin);
		if (denom < 0.0001f) return Height * 0.5f;
		return Height * (1.0f - (v - ValueMin) / denom);
	}
	private float XToTime(float x) => Math.Clamp(x / Width, 0, 1);
	private float YToValue(float y)
	{
		let r = Math.Clamp(y / Height, 0, 1);
		return ValueMax - r * (ValueMax - ValueMin);
	}

	// === Hit testing ===

	private const float KeyHitRadius = 8;
	private const float KeyDrawRadius = 4;

	private bool HitKey(float x, float y, out int32 channelIdx, out int32 keyIdx)
	{
		channelIdx = -1;
		keyIdx = -1;
		UpdateAutoFit();

		// Prefer the currently selected channel so overlapping keys disambiguate
		// in favor of "the one you were just using".
		if (mSelectedChannelIdx >= 0 && mSelectedChannelIdx < mChannels.Count)
		{
			if (HitKeyInChannel(mSelectedChannelIdx, x, y, out keyIdx))
			{
				channelIdx = mSelectedChannelIdx;
				return true;
			}
		}
		for (int32 c = 0; c < mChannels.Count; c++)
		{
			if (c == mSelectedChannelIdx) continue;
			if (HitKeyInChannel(c, x, y, out keyIdx))
			{
				channelIdx = c;
				return true;
			}
		}
		return false;
	}

	private bool HitKeyInChannel(int32 channelIdx, float x, float y, out int32 keyIdx)
	{
		keyIdx = -1;
		let ch = mChannels[channelIdx];
		if (ch.Descriptor.Hidden) return false;
		for (int32 i = 0; i < ch.Keys.Count; i++)
		{
			let kx = TimeToX(ch.Keys[i].Time);
			let ky = ValueToY(ch.Keys[i].Value);
			let dx = x - kx;
			let dy = y - ky;
			if (dx * dx + dy * dy <= KeyHitRadius * KeyHitRadius)
			{
				keyIdx = i;
				return true;
			}
		}
		return false;
	}

	// === Mouse ===

	public override void OnMouseDown(MouseEventArgs e)
	{
		if (mChannels.Count == 0) return;

		if (e.Button == .Left)
		{
			int32 hitCh, hitKey;
			if (HitKey(e.X, e.Y, out hitCh, out hitKey))
			{
				if (mChannels[hitCh].Descriptor.Locked) return;
				mSelectedChannelIdx = hitCh;
				mSelectedKeyIdx = hitKey;
				mDraggingChannelIdx = hitCh;
				mDraggingKeyIdx = hitKey;
				BeginGesture();
				Context?.FocusManager.SetCapture(this);
				e.Handled = true;
				Invalidate();
				return;
			}

			// Empty click - add a key.
			let activeIdx = ResolveActiveChannel();
			if (activeIdx < 0) return;
			let activeCh = mChannels[activeIdx];
			if (activeCh.Keys.Count >= MaxKeys) return;

			let t = XToTime(e.X);
			let v = ClampToChannel(activeIdx, YToValue(e.Y));

			BeginGesture();
			if (LinkedTime)
			{
				// Update every channel BEFORE firing any events so listeners
				// always see a consistent state across channels (the wrapper
				// editor for LinkedTime reads all channels in lockstep).
				let addedIndices = scope int32[mChannels.Count];
				int32 newIdx = -1;
				for (int32 c = 0; c < mChannels.Count; c++)
				{
					let chVal = (c == activeIdx) ? v : ClampToChannel(c, mChannels[c].Descriptor.DefaultValue);
					addedIndices[c] = InsertSortedKey(c, .(t, chVal));
					if (c == activeIdx) newIdx = addedIndices[c];
				}
				mSelectedChannelIdx = activeIdx;
				mSelectedKeyIdx = newIdx;
				mDraggingChannelIdx = activeIdx;
				mDraggingKeyIdx = newIdx;
				for (int32 c = 0; c < mChannels.Count; c++)
					OnKeyAdded(c, addedIndices[c]);
			}
			else
			{
				let idx = InsertSortedKey(activeIdx, .(t, v));
				mSelectedChannelIdx = activeIdx;
				mSelectedKeyIdx = idx;
				mDraggingChannelIdx = activeIdx;
				mDraggingKeyIdx = idx;
				OnKeyAdded(activeIdx, idx);
			}
			Context?.FocusManager.SetCapture(this);
			e.Handled = true;
			Invalidate();
		}
		else if (e.Button == .Right)
		{
			int32 hitCh, hitKey;
			if (HitKey(e.X, e.Y, out hitCh, out hitKey))
			{
				if (mChannels[hitCh].Descriptor.Locked) return;
				BeginGesture();
				if (LinkedTime)
				{
					// Same consistency concern as the LinkedTime add path:
					// remove from every channel first, then fire events.
					let removedChannels = scope List<int32>();
					for (int32 c = 0; c < mChannels.Count; c++)
					{
						if (hitKey < mChannels[c].Keys.Count)
						{
							mChannels[c].Keys.RemoveAt(hitKey);
							removedChannels.Add(c);
						}
					}
					for (let c in removedChannels)
						OnKeyRemoved(c, hitKey);
				}
				else
				{
					mChannels[hitCh].Keys.RemoveAt(hitKey);
					OnKeyRemoved(hitCh, hitKey);
				}
				if (mSelectedChannelIdx == hitCh && mSelectedKeyIdx == hitKey)
					mSelectedKeyIdx = -1;
				EndGesture();
				e.Handled = true;
				Invalidate();
			}
		}
	}

	public override void OnMouseMove(MouseEventArgs e)
	{
		if (mDraggingChannelIdx < 0 || mDraggingKeyIdx < 0) return;
		let dragCh = mDraggingChannelIdx;
		if (dragCh >= mChannels.Count) return;
		if (mDraggingKeyIdx >= mChannels[dragCh].Keys.Count) return;

		let newTime = XToTime(e.X);
		let newValue = ClampToChannel(dragCh, YToValue(e.Y));

		if (LinkedTime)
		{
			// Update Time on all channels at this index; Value only on active.
			for (int32 c = 0; c < mChannels.Count; c++)
			{
				if (mDraggingKeyIdx >= mChannels[c].Keys.Count) continue;
				var k = mChannels[c].Keys[mDraggingKeyIdx];
				k.Time = newTime;
				if (c == dragCh) k.Value = newValue;
				mChannels[c].Keys[mDraggingKeyIdx] = k;
			}
			ReSortLinked(dragCh);
		}
		else
		{
			let ch = mChannels[dragCh];
			var k = ch.Keys[mDraggingKeyIdx];
			k.Time = newTime;
			k.Value = newValue;
			ch.Keys[mDraggingKeyIdx] = k;
			let moved = ch.Keys[mDraggingKeyIdx];
			ch.Keys.RemoveAt(mDraggingKeyIdx);
			let newIdx = InsertSortedKey(dragCh, moved);
			mDraggingKeyIdx = newIdx;
			mSelectedKeyIdx = newIdx;
		}

		OnKeyChanged(dragCh, mDraggingKeyIdx);
		if (LinkedTime)
		{
			for (int32 c = 0; c < mChannels.Count; c++)
			{
				if (c != dragCh && mDraggingKeyIdx < mChannels[c].Keys.Count)
					OnKeyChanged(c, mDraggingKeyIdx);
			}
		}

		e.Handled = true;
		Invalidate();
	}

	public override void OnMouseUp(MouseEventArgs e)
	{
		if (mDraggingChannelIdx >= 0)
		{
			mDraggingChannelIdx = -1;
			mDraggingKeyIdx = -1;
			Context?.FocusManager.ReleaseCapture();
			EndGesture();
			e.Handled = true;
		}
	}

	// === Gesture ===

	private void BeginGesture()
	{
		if (!mInGesture) { mInGesture = true; OnEditBegin(); }
	}

	private void EndGesture()
	{
		if (mInGesture) { mInGesture = false; OnEditEnd(); }
	}

	// === Helpers ===

	private int32 ResolveActiveChannel()
	{
		if (mSelectedChannelIdx >= 0 && mSelectedChannelIdx < mChannels.Count)
		{
			let d = mChannels[mSelectedChannelIdx].Descriptor;
			if (!d.Hidden && !d.Locked)
				return mSelectedChannelIdx;
		}
		for (int32 i = 0; i < mChannels.Count; i++)
		{
			let d = mChannels[i].Descriptor;
			if (!d.Hidden && !d.Locked) return i;
		}
		return -1;
	}

	private int32 InsertSortedKey(int32 channelIdx, Key k)
	{
		let ch = mChannels[channelIdx];
		int32 idx = (int32)ch.Keys.Count;
		for (int32 i = 0; i < ch.Keys.Count; i++)
		{
			if (ch.Keys[i].Time > k.Time) { idx = i; break; }
		}
		ch.Keys.Insert(idx, k);
		return idx;
	}

	private float ClampToChannel(int32 channelIdx, float v)
	{
		let d = mChannels[channelIdx].Descriptor;
		// MinValue >= MaxValue (including the zero-init 0,0 case) means
		// "no clamp configured" - pass the value through.
		if (d.MinValue >= d.MaxValue) return v;
		return Math.Clamp(v, d.MinValue, d.MaxValue);
	}

	/// In LinkedTime mode after a drag, the driver channel may have moved
	/// its key past a neighbor's Time. Sort the driver in place and apply
	/// the same permutation to every other channel so they stay aligned.
	private void ReSortLinked(int32 driverIdx)
	{
		let driverCh = mChannels[driverIdx];
		let n = (int32)driverCh.Keys.Count;
		if (n <= 1) return;

		// Build a permutation: indices[i] = old position of the i-th sorted key.
		let indices = scope int32[n];
		for (int32 i = 0; i < n; i++) indices[i] = i;
		for (int32 i = 1; i < n; i++)
		{
			let cur = indices[i];
			let curTime = driverCh.Keys[cur].Time;
			int32 j = i - 1;
			while (j >= 0 && driverCh.Keys[indices[j]].Time > curTime)
			{
				indices[j + 1] = indices[j];
				j--;
			}
			indices[j + 1] = cur;
		}

		// Apply the permutation to every channel.
		for (let ch in mChannels)
		{
			if (ch.Keys.Count != n) continue; // Defensive: only re-sort matched channels.
			let oldKeys = scope Key[n];
			for (int32 i = 0; i < n; i++) oldKeys[i] = ch.Keys[i];
			for (int32 i = 0; i < n; i++) ch.Keys[i] = oldKeys[indices[i]];
		}

		// Translate the dragging index through the permutation.
		for (int32 i = 0; i < n; i++)
		{
			if (indices[i] == mDraggingKeyIdx)
			{
				mDraggingKeyIdx = i;
				mSelectedKeyIdx = i;
				break;
			}
		}
	}

	// === Drawing ===

	public override void OnDraw(UIDrawContext ctx)
	{
		UpdateAutoFit();

		// Background.
		ctx.VG.FillRect(.(0, 0, Width, Height), .(28, 28, 33, 255));

		// Grid.
		let gridColor = Color(50, 50, 58, 255);
		for (int i = 0; i <= 4; i++)
		{
			let x = (i / 4.0f) * Width;
			ctx.VG.FillRect(.(x, 0, 1, Height), gridColor);
		}
		ctx.VG.FillRect(.(0, 0, Width, 1), gridColor);
		ctx.VG.FillRect(.(0, Height * 0.5f, Width, 1), gridColor);
		ctx.VG.FillRect(.(0, Height - 1, Width, 1), gridColor);

		// Draw each visible channel - polyline first, then markers.
		for (int32 c = 0; c < mChannels.Count; c++)
		{
			let ch = mChannels[c];
			if (ch.Descriptor.Hidden || ch.Keys.Count == 0) continue;

			const int32 SAMPLES = 128;
			ctx.VG.BeginPath();
			for (int32 i = 0; i <= SAMPLES; i++)
			{
				let t = i / (float)SAMPLES;
				let v = Evaluate(c, t);
				let x = TimeToX(t);
				let y = ValueToY(v);
				if (i == 0) ctx.VG.MoveTo(x, y);
				else ctx.VG.LineTo(x, y);
			}
			ctx.VG.Stroke(ch.Descriptor.StrokeColor, 1.5f);

			for (int32 i = 0; i < ch.Keys.Count; i++)
			{
				let cx = TimeToX(ch.Keys[i].Time);
				let cy = ValueToY(ch.Keys[i].Value);
				let isSel = (c == mSelectedChannelIdx && i == mSelectedKeyIdx);
				ctx.VG.FillCircle(.(cx, cy), KeyDrawRadius,
					isSel ? .(255, 220, 100, 255) : ch.Descriptor.StrokeColor);
				if (isSel)
				{
					ctx.VG.BeginPath();
					for (int32 a = 0; a <= 32; a++)
					{
						let theta = (a / 32.0f) * 2.0f * Math.PI_f;
						let px = cx + (KeyDrawRadius + 2) * Math.Cos(theta);
						let py = cy + (KeyDrawRadius + 2) * Math.Sin(theta);
						if (a == 0) ctx.VG.MoveTo(px, py);
						else ctx.VG.LineTo(px, py);
					}
					ctx.VG.Stroke(.(255, 220, 100, 255), 1.5f);
				}
			}
		}
	}

	protected override void OnMeasure(BoxConstraints constraints)
	{
		MeasuredSize = .(
			constraints.ConstrainWidth(200),
			constraints.ConstrainHeight(120));
	}
}
