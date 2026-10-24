using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.VG;
using internal Sedulous.GUI;

namespace Sedulous.GUI;

// The curve view: a source's curves on one canvas, time across on a shared TimeAxis and value up on a
// range of its own, drawn with Core's EvaluateCurve so what is edited is what plays. Mouse first, as
// ezEngine's:
//   - a click selects a key (Shift or Ctrl adds or takes it away), a drag from nothing selects by a box;
//   - a drag moves the selected keys (Shift locks it to the axis it moved along most), their times on
//     frames with a frame rate, their values in a curve's range, the keys sorted again as they pass
//     and their tangents set by their modes, so auto and smooth keys follow;
//   - a selected key's handles (where a cubic segment meets it) set its tangents; dragging an auto or
//     a flat key's handle makes it smooth;
//   - a double click on a curve adds a key there, on the curve;
//   - a key's menu sets the interpolation and the tangent mode of the selected keys, or deletes them
//     (Delete does too); the menu over nothing frames every curve or the selection;
//   - the wheel zooms about the pointer (Ctrl only time, Shift only value), a middle drag pans.
// Each gesture is one edit through the source (one undo entry, the application's).

/// What is under a point of a curve view.
struct CurveHit
{
	public enum Kind : uint8
	{
		None,
		Key,
		TangentIn,
		TangentOut,
		Curve,
	}

	public Kind What = .None;
	/// A key's, a handle's key; a curve's index in Key.Curve.
	public CurveKeyRef Key = .();

	public this() { }

	public this(Kind what, CurveKeyRef key)
	{
		What = what;
		Key = key;
	}
}

[GuiReflect(true)]
class CurveView : UIWidget, ITimeAxisClient, ICurveSourceClient
{
	public const float cHitRadius = 6.0f;
	public const float cHandleLength = 40.0f;
	public const float cDragThreshold = 3.0f;

	private enum Drag : uint8
	{
		None,
		/// Pressed on a key, not moved past the threshold.
		Pending,
		Keys,
		Handle,
		Box,
		Pan,
	}

	private Sedulous.GUI.TimeAxis mAxis = null;
	// Not owned: the source outlives the view or is set to null first.
	private ICurveSource mSource = null;
	private float mValueLow = 0.0f;
	private float mValueHigh = 1.0f;
	private List<CurveKeyRef> mSelection = new .() ~ delete _;

	private Drag mDrag = .None;
	// Where the gesture began, its own space.
	private Float2 mPressAt = .(0.0f, 0.0f);
	// The key pressed (a move's or a handle's).
	private CurveKeyRef mPressed = .();
	private bool mHandleOut = false;
	// Shift or Ctrl held at the press.
	private bool mAdditive = false;
	// Each curve's keys at the gesture's start.
	private List<List<CurveKey>> mOriginal = new .() ~ DeleteContainerAndItems!(_);
	private List<CurveKeyRef> mOriginalSelection = new .() ~ delete _;
	private float mPanTime = 0.0f;
	private float mPanLow = 0.0f;
	private float mPanHigh = 1.0f;
	private Float2 mBoxTo = .(0.0f, 0.0f);
	private Sedulous.GUI.Menu mMenu ~ _?.ReleaseRef();
	// Each value label in turn.
	private Sedulous.GUI.Text mText = new .() ~ delete _;

	public this()
	{
		Tag = "curveview";
		TabFocusable = true;
	}

	public ~this()
	{
		if (mAxis != null)
		{
			mAxis.Leave(this);
			mAxis.ReleaseRef();
		}
		if (mSource != null)
			mSource.RemoveClient(this);
	}

	// === What it shows ===

	/// The axis it reads its time from. It takes a reference of its own: the caller keeps its.
	public Sedulous.GUI.TimeAxis TimeAxis
	{
		get => mAxis;
		set
		{
			if (value != null)
				value.AddRef();
			if (mAxis != null)
			{
				mAxis.Leave(this);
				mAxis.ReleaseRef();
			}
			mAxis = value;
			if (mAxis != null)
				mAxis.Join(this);
			Invalidate();
		}
	}

	/// The curves it edits (not owned: the source outlives the view or is set to null first).
	public ICurveSource Source
	{
		get => mSource;
		set
		{
			if (mSource != null)
				mSource.RemoveClient(this);
			mSource = value;
			if (mSource != null)
				mSource.AddClient(this);
			mSelection.Clear();
			Invalidate();
		}
	}

	/// The values from its bottom to its top.
	public void SetValueRange(float low, float high)
	{
		var high;
		if (high - low < 1e-6f)
			high = low + 1e-6f;
		mValueLow = low;
		mValueHigh = high;
		Invalidate();
	}

	public float ValueLow => mValueLow;
	public float ValueHigh => mValueHigh;

	/// Fits the time axis and the values to every curve's keys (and its range, where it has one).
	public void FrameAll() => Frame(false);
	/// Fits them to the selected keys; to every curve with none selected.
	public void FrameSelection() => Frame(!mSelection.IsEmpty);

	// === The selection ===

	public Span<CurveKeyRef> Selection => mSelection;

	public void SetSelection(Span<CurveKeyRef> keys)
	{
		mSelection.Clear();
		for (let key in keys)
			Select(key, true);
		Invalidate();
	}

	public bool IsSelected(CurveKeyRef key)
	{
		for (let at in mSelection)
		{
			if (at == key)
				return true;
		}
		return false;
	}

	// === Edits of the selection (one each, through the source) ===

	public void SetInterpolation(CurveKeyInterpolation interpolation)
	{
		EditSelected(scope (key) => { key.Interpolation = interpolation; });
	}

	public void SetTangentMode(CurveTangentMode mode)
	{
		EditSelected(scope (key) => { key.TangentMode = mode; });
	}

	/// Deletes the selected keys; false when none were.
	public bool DeleteSelected()
	{
		if ((mSource == null) || mSelection.IsEmpty)
			return false;
		mSource.BeginKeysEdit();
		for (int c = 0; c < mSource.CurveCount; ++c)
		{
			if (!HasSelectedOn(c))
				continue;
			let keys = scope List<CurveKey>();
			let from = mSource.GetKeys(c);
			for (int i = 0; i < from.Length; ++i)
			{
				if (!IsSelected(CurveKeyRef(c, i)))
					keys.Add(from[i]);
			}
			ApplyCurveTangentModes(keys);
			mSource.PreviewKeys(c, keys);
		}
		mSource.CommitKeysEdit();
		mSelection.Clear();
		Invalidate();
		return true;
	}

	/// Adds a key to `curve` at `time`, on the curve (its interpolation the segment's it splits);
	/// false when the curve is full or locked.
	public bool InsertKey(int curve, float time)
	{
		var time;
		if ((mSource == null) || (curve < 0) || (curve >= mSource.CurveCount))
			return false;
		let info = scope CurveInfo();
		mSource.GetCurveInfo(curve, info);
		let from = mSource.GetKeys(curve);
		if (info.Locked || ((info.MaxKeys != 0) && (from.Length >= (int)info.MaxKeys)))
			return false;
		if (mAxis != null)
			time = Clamp(mAxis.Snap(time), 0.0f, mAxis.Duration);
		var key = CurveKey();
		key.Time = time;
		key.Value = EvaluateCurve(from, time);
		key.Interpolation = .Cubic;
		key.TangentMode = .Auto;
		int at = 0;
		while ((at < from.Length) && (from[at].Time <= time))
			++at;
		if (at > 0)
			key.Interpolation = from[at - 1].Interpolation;
		let keys = scope List<CurveKey>();
		for (int i = 0; i < from.Length; ++i)
		{
			if (i == at)
				keys.Add(key);
			keys.Add(from[i]);
		}
		if (at == from.Length)
			keys.Add(key);
		ApplyCurveTangentModes(keys);
		mSource.BeginKeysEdit();
		mSource.PreviewKeys(curve, keys);
		mSource.CommitKeysEdit();
		mSelection.Clear();
		mSelection.Add(CurveKeyRef(curve, at));
		Invalidate();
		return true;
	}

	// === Where things are (in its own space) ===

	public Float2 KeyPoint(float time, float value)
	{
		let @box = ContentBounds;
		let x = @box.X + ((mAxis != null) ? mAxis.TimeToOffset(time) : 0.0f);
		let y = @box.Bottom - (value - mValueLow) / (mValueHigh - mValueLow) * @box.Height;
		return .(x, y);
	}

	public float TimeAtX(float x) => (mAxis != null) ? mAxis.OffsetToTime(x - ContentBounds.X) : 0.0f;

	public float ValueAtY(float y)
	{
		let @box = ContentBounds;
		return (@box.Height > 0.0f) ? mValueLow + (@box.Bottom - y) / @box.Height * (mValueHigh - mValueLow) : mValueLow;
	}

	/// Where a key's handle is drawn (`out`: the one leaving it).
	public Float2 HandlePoint(CurveKey key, bool @out)
	{
		let @box = ContentBounds;
		let pixelsPerSecond = (mAxis != null) ? mAxis.PixelsPerSecond : 1.0f;
		let pixelsPerValue = @box.Height / (mValueHigh - mValueLow);
		let slope = @out ? key.TangentOut : key.TangentIn;
		let direction = Float2(pixelsPerSecond, -slope * pixelsPerValue);
		let length = Sqrt(direction.X * direction.X + direction.Y * direction.Y);
		if (length <= 0.0f)
			return KeyPoint(key.Time, key.Value);
		let sign = @out ? 1.0f : -1.0f;
		let at = KeyPoint(key.Time, key.Value);
		return .(at.X + sign * direction.X / length * cHandleLength, at.Y + sign * direction.Y / length * cHandleLength);
	}

	/// What is at `local` (its own space): a selected key's handle first, then a key, then a curve.
	public CurveHit HitTest(Float2 local)
	{
		var hit = CurveHit();
		if (mSource == null)
			return hit;
		let info = scope CurveInfo();
		for (let @ref in mSelection)
		{
			let keys = mSource.GetKeys(@ref.Curve);
			mSource.GetCurveInfo(@ref.Curve, info);
			if ((@ref.Index >= keys.Length) || info.Locked)
				continue;
			if (HasHandle(keys, @ref.Index, true) && Near(HandlePoint(keys[@ref.Index], true), local))
				return CurveHit(.TangentOut, @ref);
			if (HasHandle(keys, @ref.Index, false) && Near(HandlePoint(keys[@ref.Index], false), local))
				return CurveHit(.TangentIn, @ref);
		}
		for (int c = mSource.CurveCount - 1; c >= 0; c--)
		{
			mSource.GetCurveInfo(c, info);
			if (info.Locked)
				continue;
			let keys = mSource.GetKeys(c);
			for (int i = keys.Length - 1; i >= 0; i--)
			{
				if (Near(KeyPoint(keys[i].Time, keys[i].Value), local))
					return CurveHit(.Key, CurveKeyRef(c, i));
			}
		}
		let time = TimeAtX(local.X);
		for (int c = mSource.CurveCount - 1; c >= 0; c--)
		{
			mSource.GetCurveInfo(c, info);
			if (info.Locked)
				continue;
			let y = KeyPoint(time, EvaluateCurve(mSource.GetKeys(c), time)).Y;
			if (Abs(y - local.Y) <= cHitRadius)
				return CurveHit(.Curve, CurveKeyRef(c, 0));
		}
		return hit;
	}

	/// Whether a key shows a handle on that side: a cubic segment meets it there.
	public static bool HasHandle(Span<CurveKey> keys, int index, bool @out)
	{
		if (@out)
			return (index + 1 < keys.Length) && (keys[index].Interpolation == .Cubic);
		return (index > 0) && (index < keys.Length) && (keys[index - 1].Interpolation == .Cubic);
	}

	public Sedulous.GUI.Menu KeyMenu => ((mMenu != null) && mMenu.IsOpen) ? mMenu : null;

	public void OnTimeAxisChanged()
	{
		Invalidate();
	}

	public void OnCurvesChanged()
	{
		if (mSource == null)
			return;
		for (int i = mSelection.Count - 1; i >= 0; i--) // an undo may take keys away
		{
			if ((mSelection[i].Curve >= mSource.CurveCount) || (mSelection[i].Index >= mSource.GetKeys(mSelection[i].Curve).Length))
				mSelection.RemoveAt(i);
		}
		Invalidate();
	}

	// === Gestures ===

	protected override void OnMouseDown(MouseEvent e)
	{
		if ((mSource == null) || (mAxis == null))
			return;
		let local = ConvertToNodeSpace(e.Position); // events come in screen space
		if (e.Button == .Middle)
		{
			e.Handled = true;
			mDrag = .Pan;
			mPressAt = local;
			mPanTime = mAxis.Scroll;
			mPanLow = mValueLow;
			mPanHigh = mValueHigh;
			return;
		}
		if (e.Button != .Left)
			return;
		e.Handled = true;
		RequestFocus();
		mPressAt = local;
		mBoxTo = local;
		mAdditive = (e.Modifiers & (KeyModShift | KeyModCtrl)) != 0;
		let hit = HitTest(local);
		// A double click on the curve adds a key; on a key it is a click (a Shift+click soon after
		// selecting a key takes it away again).
		if ((e.ClickCount == 2) && (hit.What == .Curve))
		{
			InsertKey(hit.Key.Curve, TimeAtX(local.X));
			mDrag = .None;
			return;
		}
		switch (hit.What)
		{
		case .TangentIn, .TangentOut:
			mPressed = hit.Key;
			mHandleOut = hit.What == .TangentOut;
			mDrag = .Handle;
			BeginMove();
		case .Key:
			mPressed = hit.Key;
			if (mAdditive)
				Select(hit.Key, !IsSelected(hit.Key));
			else if (!IsSelected(hit.Key))
			{
				mSelection.Clear();
				mSelection.Add(hit.Key);
			}
			mDrag = IsSelected(hit.Key) ? .Pending : .None;
		default:
			if (!mAdditive)
				mSelection.Clear();
			mDrag = .Box;
		}
		Invalidate();
	}

	protected override void OnMouseMove(MouseEvent e)
	{
		if ((mDrag == .None) || (mSource == null) || (mAxis == null))
			return;
		let local = ConvertToNodeSpace(e.Position);
		switch (mDrag)
		{
		case .Pending:
			if ((Abs(local.X - mPressAt.X) < cDragThreshold) && (Abs(local.Y - mPressAt.Y) < cDragThreshold))
				return;
			mDrag = .Keys;
			BeginMove();
			MoveTo(local, (e.Modifiers & KeyModShift) != 0);
		case .Keys:
			MoveTo(local, (e.Modifiers & KeyModShift) != 0);
		case .Handle:
			DragHandle(local);
		case .Box:
			mBoxTo = local;
			Invalidate();
		case .Pan:
			let @box = ContentBounds;
			let perPixel = (@box.Height > 0.0f) ? (mPanHigh - mPanLow) / @box.Height : 0.0f;
			let shift = (local.Y - mPressAt.Y) * perPixel;
			mValueLow = mPanLow + shift;
			mValueHigh = mPanHigh + shift;
			mAxis.Scroll = mPanTime - (local.X - mPressAt.X) / mAxis.PixelsPerSecond;
			Invalidate();
		default:
		}
	}

	protected override void OnMouseUp(MouseEvent e)
	{
		if (mDrag == .Pan)
		{
			if (e.Button == .Middle)
				mDrag = .None;
			return;
		}
		if (e.Button != .Left)
			return;
		if ((mDrag == .Box) && (mSource != null))
		{
			let to = ConvertToNodeSpace(e.Position);
			let left = Min(mPressAt.X, to.X);
			let right = Max(mPressAt.X, to.X);
			let top = Min(mPressAt.Y, to.Y);
			let bottom = Max(mPressAt.Y, to.Y);
			let info = scope CurveInfo();
			for (int c = 0; c < mSource.CurveCount; ++c)
			{
				mSource.GetCurveInfo(c, info);
				if (info.Locked)
					continue;
				let keys = mSource.GetKeys(c);
				for (int i = 0; i < keys.Length; ++i)
				{
					let at = KeyPoint(keys[i].Time, keys[i].Value);
					if ((at.X >= left) && (at.X <= right) && (at.Y >= top) && (at.Y <= bottom))
						Select(CurveKeyRef(c, i), true);
				}
			}
			mDrag = .None;
			Invalidate();
			return;
		}
		if ((mDrag == .Pending) && !mAdditive)
		{
			// A click on a key of several selected selects it alone.
			mSelection.Clear();
			mSelection.Add(mPressed);
			Invalidate();
		}
		EndDrag(true);
	}

	protected override void OnPointerCancel(MouseEvent e)
	{
		EndDrag(false);
	}

	protected override void OnKeyDown(KeyEvent e)
	{
		let key = (KeyCode)e.KeyCode;
		if ((key == .Escape) && ((mDrag == .Keys) || (mDrag == .Handle)))
		{
			e.Handled = true;
			EndDrag(false);
			return;
		}
		if ((e.Modifiers == 0) && ((key == .Delete) || (key == .Backspace)) && (mDrag == .None))
			e.Handled = DeleteSelected();
	}

	protected override void OnMouseWheel(WheelEvent e)
	{
		if (mAxis == null)
			return;
		let steps = (e.Delta.Y != 0.0f) ? e.Delta.Y : e.Delta.X; // Shift may turn the wheel sideways
		if (steps == 0.0f)
			return;
		e.Handled = true;
		let local = ConvertToNodeSpace(e.Position);
		let factor = Pow(1.2f, steps);
		let timeOnly = (e.Modifiers & KeyModCtrl) != 0;
		let valueOnly = (e.Modifiers & KeyModShift) != 0;
		if (!valueOnly)
			mAxis.ZoomAbout(TimeAtX(local.X), factor);
		if (!timeOnly)
		{
			let value = ValueAtY(local.Y);
			SetValueRange(value - (value - mValueLow) / factor, value + (mValueHigh - value) / factor);
		}
		Invalidate();
	}

	protected override void OnContextMenu(MouseEvent e)
	{
		if (mSource == null)
			return;
		e.Handled = true;
		OpenMenu(ConvertToNodeSpace(e.Position), e.Position);
	}

	protected override void OnTextStyleChange()
	{
		mText.Font = Font;
		mText.SetFontSelection(FontService, GetTextStyle().FontFamily, GetTextStyle().Selection);
		mText.Color = TextColor;
		mText.SetAlignment(.Start, .Top);
	}

	public override Sedulous.GUI.Cursor CursorNow => (mDrag == .Pan) ? .Grabbing : base.CursorNow;

	// === Drawing ===

	public override void OnDraw(DrawContext ctx, Rect localBounds)
	{
		base.OnDraw(ctx, localBounds);
		if (mAxis == null)
			return;
		let @box = ContentBounds;
		ctx.PushClip(@box);
		Color PartColor(StringView name, Color fallback)
		{
			let part = GetPartStyle(name);
			var color = part.HasBackground ? part.Box.BackgroundColor : fallback;
			color.A *= part.Opacity;
			return color;
		}
		// The grid: a line at each labelled time, and at each value step, labelled.
		let grid = PartColor("grid", .(1.0f, 1.0f, 1.0f, 0.08f));
		let timeStep = mAxis.TickStep(TimeRuler.cMinLabelSpacing);
		for (int64 i = (int64)Ceil(mAxis.Scroll / timeStep);; ++i)
		{
			let offset = mAxis.TimeToOffset((float)i * timeStep);
			if (offset > @box.Width)
				break;
			ctx.VG.FillRect(.(Floor(@box.X + offset), @box.Y, 1.0f, @box.Height), grid);
		}
		let range = mValueHigh - mValueLow;
		float valueStep = 1.0f;
		if (@box.Height > 0.0f)
		{
			let least = range * 30.0f / @box.Height; // labels 30 px apart at least
			let magnitude = Pow(10.0f, Floor(Log(least) / Log(10.0f)));
			valueStep = 10.0f * magnitude;
			float[3] multiples = .(1.0f, 2.0f, 5.0f);
			for (let m in multiples)
			{
				if (m * magnitude >= least * 0.9999f)
				{
					valueStep = m * magnitude;
					break;
				}
			}
		}
		let label = scope String();
		for (int64 i = (int64)Ceil(mValueLow / valueStep); (float)i * valueStep <= mValueHigh; ++i)
		{
			let value = (float)i * valueStep;
			let y = KeyPoint(0.0f, value).Y;
			ctx.VG.FillRect(.(@box.X, Floor(y), @box.Width, 1.0f), grid);
			if (mText.HasFont)
			{
				label.Clear();
				FormatStepped(value, valueStep, label);
				mText.SetString(label);
				mText.Draw(ctx, Float2(@box.X + 3.0f, y + 1.0f));
			}
		}
		if (mSource != null)
		{
			let selected = PartColor("selected", .(1.0f, 1.0f, 1.0f, 1.0f));
			let info = scope CurveInfo();
			for (int c = 0; c < mSource.CurveCount; ++c)
			{
				mSource.GetCurveInfo(c, info);
				let keys = mSource.GetKeys(c);
				var stroke = info.StrokeColor;
				if (info.Locked)
					stroke.A *= 0.45f;
				if (!keys.IsEmpty)
				{
					let line = scope PathBuilder();
					for (float x = 0.0f; x <= @box.Width + 2.0f; x += 2.0f)
					{
						let t = mAxis.OffsetToTime(x);
						let at = KeyPoint(t, EvaluateCurve(keys, t));
						if (x == 0.0f)
							line.MoveTo(at.X, at.Y);
						else
							line.LineTo(at.X, at.Y);
					}
					let path = line.ToPath();
					ctx.VG.StrokePath(path, stroke, StrokeStyle(1.5f));
					delete path;
				}
				for (int i = 0; i < keys.Length; ++i)
				{
					let on = IsSelected(CurveKeyRef(c, i));
					let at = KeyPoint(keys[i].Time, keys[i].Value);
					bool[2] sides = .(false, true);
					if (on)
					{
						for (let @out in sides)
						{
							if (!HasHandle(keys, i, @out))
								continue;
							let handle = HandlePoint(keys[i], @out);
							let arm = scope PathBuilder();
							arm.MoveTo(at.X, at.Y);
							arm.LineTo(handle.X, handle.Y);
							let armPath = arm.ToPath();
							ctx.VG.StrokePath(armPath, selected, StrokeStyle(1.0f));
							delete armPath;
							let knob = scope PathBuilder();
							ShapeBuilder.BuildCircle(handle, 3.0f, knob);
							let knobPath = knob.ToPath();
							ctx.VG.FillPath(knobPath, selected);
							delete knobPath;
						}
					}
					let diamond = scope PathBuilder();
					let r = on ? 5.0f : 4.0f;
					diamond.MoveTo(at.X, at.Y - r);
					diamond.LineTo(at.X + r, at.Y);
					diamond.LineTo(at.X, at.Y + r);
					diamond.LineTo(at.X - r, at.Y);
					diamond.Close();
					let diamondPath = diamond.ToPath();
					ctx.VG.FillPath(diamondPath, on ? selected : stroke);
					delete diamondPath;
				}
			}
		}
		let playhead = PartColor("playhead", .(0.31f, 0.61f, 1.0f, 1.0f));
		ctx.VG.FillRect(.(Floor(@box.X + mAxis.TimeToOffset(mAxis.Playhead)), @box.Y, 1.0f, @box.Height), playhead);
		if (mDrag == .Box)
		{
			let fill = PartColor("selection-box", .(0.31f, 0.61f, 1.0f, 0.2f));
			let area = Rect(Min(mPressAt.X, mBoxTo.X), Min(mPressAt.Y, mBoxTo.Y), Abs(mBoxTo.X - mPressAt.X), Abs(mBoxTo.Y - mPressAt.Y));
			ctx.VG.FillRect(area.ToRectangle(), fill);
		}
		ctx.PopClip();
	}

	private static bool Near(Float2 a, Float2 b) => (Abs(a.X - b.X) <= cHitRadius) && (Abs(a.Y - b.Y) <= cHitRadius);

	private bool HasSelectedOn(int curve)
	{
		for (let @ref in mSelection)
		{
			if (@ref.Curve == curve)
				return true;
		}
		return false;
	}

	private void Select(CurveKeyRef key, bool on)
	{
		for (int i = 0; i < mSelection.Count; ++i)
		{
			if (mSelection[i] == key)
			{
				if (!on)
					mSelection.RemoveAt(i);
				return;
			}
		}
		if (on)
			mSelection.Add(key);
	}

	private void EditSelected(delegate void(ref CurveKey key) change)
	{
		if ((mSource == null) || mSelection.IsEmpty)
			return;
		mSource.BeginKeysEdit();
		for (int c = 0; c < mSource.CurveCount; ++c)
		{
			if (!HasSelectedOn(c))
				continue;
			let keys = scope List<CurveKey>();
			for (let key in mSource.GetKeys(c))
				keys.Add(key);
			for (let @ref in mSelection)
			{
				if ((@ref.Curve == c) && (@ref.Index < keys.Count))
					change(ref keys[@ref.Index]);
			}
			ApplyCurveTangentModes(keys);
			mSource.PreviewKeys(c, keys);
		}
		mSource.CommitKeysEdit();
	}

	private void BeginMove()
	{
		ClearAndDeleteItems!(mOriginal);
		for (int c = 0; c < mSource.CurveCount; ++c)
		{
			let keys = new List<CurveKey>();
			for (let key in mSource.GetKeys(c))
				keys.Add(key);
			mOriginal.Add(keys);
		}
		mOriginalSelection.Clear();
		for (let @ref in mSelection)
			mOriginalSelection.Add(@ref);
		mSource.BeginKeysEdit();
	}

	private void MoveTo(Float2 local, bool lockAxis)
	{
		if ((mPressed.Curve >= mOriginal.Count) || (mPressed.Index >= mOriginal[mPressed.Curve].Count))
			return;
		let anchor = mOriginal[mPressed.Curve][mPressed.Index];
		var dt = TimeAtX(local.X) - TimeAtX(mPressAt.X);
		var dv = ValueAtY(local.Y) - ValueAtY(mPressAt.Y);
		if (lockAxis)
		{
			if (Abs(local.X - mPressAt.X) >= Abs(local.Y - mPressAt.Y))
				dv = 0.0f;
			else
				dt = 0.0f;
		}
		dt = mAxis.Snap(anchor.Time + dt) - anchor.Time; // the pressed key lands on a frame; the rest keep their spacing
		let selection = scope List<CurveKeyRef>();
		let info = scope CurveInfo();
		for (int c = 0; c < mOriginal.Count; ++c)
		{
			bool any = false;
			for (let @ref in mOriginalSelection)
				any = any || (@ref.Curve == c);
			if (!any)
				continue;
			mSource.GetCurveInfo(c, info);
			let keys = scope List<CurveKey>();
			let moved = scope List<bool>();
			for (int i = 0; i < mOriginal[c].Count; ++i)
			{
				var key = mOriginal[c][i];
				bool selected = false;
				for (let @ref in mOriginalSelection)
					selected = selected || ((@ref.Curve == c) && (@ref.Index == i));
				if (selected)
				{
					key.Time = Clamp(key.Time + dt, 0.0f, mAxis.Duration);
					key.Value += dv;
					if (info.HasRange)
						key.Value = Clamp(key.Value, info.Min, info.Max);
				}
				keys.Add(key);
				moved.Add(selected);
			}
			// Sorted by time again, stably: a moved key passes the others, ties keep their order.
			for (int i = 1; i < keys.Count; ++i)
			{
				for (int j = i; (j > 0) && (keys[j].Time < keys[j - 1].Time); --j)
				{
					let swap = keys[j];
					keys[j] = keys[j - 1];
					keys[j - 1] = swap;
					let m = moved[j];
					moved[j] = moved[j - 1];
					moved[j - 1] = m;
				}
			}
			ApplyCurveTangentModes(keys);
			mSource.PreviewKeys(c, keys);
			for (int n = 0; n < keys.Count; ++n)
			{
				if (!moved[n])
					continue;
				selection.Add(CurveKeyRef(c, n));
			}
		}
		// The selection follows its keys to their places; each step starts again from the originals.
		mSelection.Clear();
		mSelection.AddRange(selection);
		Invalidate();
	}

	private void DragHandle(Float2 local)
	{
		if ((mPressed.Curve >= mOriginal.Count) || (mPressed.Index >= mOriginal[mPressed.Curve].Count))
			return;
		let keys = scope List<CurveKey>();
		for (let key in mOriginal[mPressed.Curve])
			keys.Add(key);
		ref CurveKey key = ref keys[mPressed.Index];
		var dt = TimeAtX(local.X) - key.Time;
		let dv = ValueAtY(local.Y) - key.Value;
		// A handle stays on its side of its key: past it, nearly upright.
		let least = 1e-4f;
		if (mHandleOut)
			dt = Max(dt, least);
		else
			dt = Min(dt, -least);
		let slope = dv / dt;
		if ((key.TangentMode == .Auto) || (key.TangentMode == .Flat))
			key.TangentMode = .Smooth;
		if (key.TangentMode == .Smooth)
		{
			key.TangentIn = slope;
			key.TangentOut = slope;
		}
		else if (mHandleOut)
			key.TangentOut = slope;
		else
			key.TangentIn = slope;
		ApplyCurveTangentModes(keys);
		mSource.PreviewKeys(mPressed.Curve, keys);
		Invalidate();
	}

	private void EndDrag(bool commit)
	{
		let drag = mDrag;
		mDrag = .None;
		if ((drag != .Keys) && (drag != .Handle))
			return;
		if (mSource == null)
			return;
		if (commit)
			mSource.CommitKeysEdit();
		else
		{
			mSource.CancelKeysEdit();
			mSelection.Clear();
			mSelection.AddRange(mOriginalSelection);
			mOriginalSelection.Clear();
		}
		ClearAndDeleteItems!(mOriginal);
		Invalidate();
	}

	private void Frame(bool selectionOnly)
	{
		if ((mSource == null) || (mAxis == null))
			return;
		bool any = false;
		float t0 = 0.0f;
		float t1 = 0.0f;
		float v0 = 0.0f;
		float v1 = 0.0f;
		bool rangedAny = false;
		float ranged = 0.0f;
		float rangedHigh = 0.0f;
		void Take(float t, float v)
		{
			if (!any)
			{
				t0 = t1 = t;
				v0 = v1 = v;
				any = true;
				return;
			}
			t0 = Min(t0, t);
			t1 = Max(t1, t);
			v0 = Min(v0, v);
			v1 = Max(v1, v);
		}
		let info = scope CurveInfo();
		for (int c = 0; c < mSource.CurveCount; ++c)
		{
			let keys = mSource.GetKeys(c);
			if (selectionOnly)
			{
				for (let @ref in mSelection)
				{
					if ((@ref.Curve == c) && (@ref.Index < keys.Length))
						Take(keys[@ref.Index].Time, keys[@ref.Index].Value);
				}
				continue;
			}
			mSource.GetCurveInfo(c, info);
			for (let key in keys)
				Take(key.Time, key.Value);
			if (keys.Length > 1) // the curve between its keys, an overshoot seen
			{
				for (int32 s = 0; s <= 64; ++s)
				{
					let t = keys[0].Time + (keys[keys.Length - 1].Time - keys[0].Time) * (float)s / 64.0f;
					Take(t, EvaluateCurve(keys, t));
				}
			}
			if (info.HasRange)
			{
				ranged = !rangedAny ? info.Min : Min(ranged, info.Min);
				rangedHigh = !rangedAny ? info.Max : Max(rangedHigh, info.Max);
				rangedAny = true;
			}
		}
		if (!any)
			return;
		if (rangedAny) // a framing shows at least the ranges
		{
			v0 = Min(v0, ranged);
			v1 = Max(v1, rangedHigh);
		}
		if (t1 - t0 < 1e-4f)
		{
			t0 -= 0.5f;
			t1 += 0.5f;
		}
		if (v1 - v0 < 1e-4f)
		{
			v0 -= 1.0f;
			v1 += 1.0f;
		}
		let timeMargin = (t1 - t0) * 0.05f;
		let valueMargin = (v1 - v0) * 0.1f;
		mAxis.Frame(t0 - timeMargin, t1 + timeMargin, ContentBounds.Width);
		SetValueRange(v0 - valueMargin, v1 + valueMargin);
	}

	private void OpenMenu(Float2 local, Float2 screen)
	{
		let top = RootNode;
		if (top == null)
			return;
		let hit = HitTest(local);
		if ((hit.What == .Key) && !IsSelected(hit.Key))
		{
			mSelection.Clear();
			mSelection.Add(hit.Key);
			Invalidate();
		}
		if (mMenu != null)
			mMenu.ReleaseRef();
		mMenu = new Sedulous.GUI.Menu();
		ShareTextStyle(mMenu, false);
		mMenu.SetAutoWidth(true);
		if (hit.What == .Key)
		{
			// Checked where every selected key agrees.
			bool sameInterp = true;
			bool sameMode = true;
			CurveKeyInterpolation interp = .Cubic;
			CurveTangentMode mode = .Auto;
			for (int n = 0; n < mSelection.Count; ++n)
			{
				let key = mSource.GetKeys(mSelection[n].Curve)[mSelection[n].Index];
				if (n == 0)
				{
					interp = key.Interpolation;
					mode = key.TangentMode;
				}
				sameInterp = sameInterp && (key.Interpolation == interp);
				sameMode = sameMode && (key.TangentMode == mode);
			}
			StringView[3] interpNames = .("Constant", "Linear", "Cubic");
			CurveKeyInterpolation[3] interps = .(.Constant, .Linear, .Cubic);
			for (int i = 0; i < 3; ++i)
			{
				let value = interps[i];
				mMenu.AddCheckItem(interpNames[i], sameInterp && (interp == value), new (on) => { SetInterpolation(value); });
			}
			mMenu.AddSeparator();
			StringView[4] modeNames = .("Auto", "Smooth", "Flat", "Broken");
			CurveTangentMode[4] modes = .(.Auto, .Smooth, .Flat, .Broken);
			for (int i = 0; i < 4; ++i)
			{
				let value = modes[i];
				mMenu.AddCheckItem(modeNames[i], sameMode && (mode == value), new (on) => { SetTangentMode(value); });
			}
			mMenu.AddSeparator();
			mMenu.AddItem("Delete", new () => { DeleteSelected(); });
		}
		else
		{
			mMenu.AddItem("Frame all", new () => { FrameAll(); });
			let selected = mMenu.AddItem("Frame selection", new () => { FrameSelection(); });
			selected.Enabled = !mSelection.IsEmpty;
		}
		mMenu.Open(this, top.ConvertToNodeSpace(screen));
	}
}
