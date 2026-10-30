using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.VG;
using internal Sedulous.GUI;

namespace Sedulous.GUI;

// The gradient view edits one of Core's gradients as a value: its colour stops (sRGB) and alpha stops
// apart, and the space they blend in, drawn with Core's EvaluateGradient so what is edited is what
// plays (no gradient model of the toolkit's).
//   - A strip: alpha stops above a bar of the gradient over a checkerboard, colour stops below it.
//   - A click on the strip adds a stop there (an alpha stop on its upper half, a colour stop on its
//     lower), of the gradient's colour or alpha at that place, and a drag moves it; a press on a stop
//     selects it and a drag moves it, the stops sorted again as it passes; a drag off the strip takes
//     it away (back on, it returns), though never a kind's last stop. Escape gives a drag up.
//   - A double click on a colour stop, or a click on its swatch, opens the colour picker as a popup
//     (its drags preview, closing it is the change, Escape gives it up); an alpha stop has a number
//     field; the selected stop's place has one too; the interpolation is a drop-down.
// The value is the GUI's ColorGradient, as a property grid's gradient row carries it. It reports each
// step of a gesture (changing), its end (changed) and a gesture given up (cancelled, the value back as
// it was); whoever holds the gradient writes it.

/// A stop of a gradient: which kind, and its place among that kind's stops.
struct GradientStopRef : IEquatable<GradientStopRef>
{
	public bool Alpha = false;
	/// -1: none.
	public int32 Index = -1;

	public this() { }

	public this(bool alpha, int32 index)
	{
		Alpha = alpha;
		Index = index;
	}

	public bool IsValid => Index >= 0;

	public bool Equals(GradientStopRef other) => this == other;

	[Commutable]
	public static bool operator==(GradientStopRef a, GradientStopRef b) => (a.Alpha == b.Alpha) && (a.Index == b.Index);
}

/// A gradient view's strip: the bar and the stops either side of it, and their gestures.
[GuiReflect]
class GradientStrip : UIWidget
{
	/// The parts it draws: a sheet reaches only the parts named here.
	public override void CollectStyleParts(List<StringView> outParts)
	{
		outParts.Add("selected");
	}

	// Each stop lane's height.
	public const float cLane = 12.0f;
	public const float cHitRadius = 6.0f;
	// Past the strip by this much, a dragged stop goes.
	public const float cPullOff = 24.0f;

	// The view it is a part of, which holds it.
	private GradientView mView;
	private bool mDragging = false;

	public this(GradientView view)
	{
		mView = view;
		Tag = "gradientstrip";
		EditLayoutStyle(scope (s) => { s.Height = LayoutLength.Px(48.0f); });
	}

	/// Where a time is across it, and back (its own space).
	public float XAt(float time)
	{
		let @box = ContentBounds;
		return @box.X + Clamp(time, 0.0f, 1.0f) * @box.Width;
	}

	public float TimeAt(float x)
	{
		let @box = ContentBounds;
		return (@box.Width > 0.0f) ? Clamp((x - @box.X) / @box.Width, 0.0f, 1.0f) : 0.0f;
	}

	/// The bar between the lanes.
	public Rect BarBounds
	{
		get
		{
			let @box = ContentBounds;
			return .(@box.X, @box.Y + cLane, @box.Width, Max(0.0f, @box.Height - 2.0f * cLane));
		}
	}

	/// The stop under `local`, if any.
	public GradientStopRef StopAt(Float2 local)
	{
		let @box = ContentBounds;
		let value = mView.[Friend]mValue;
		let alphaLane = local.Y < @box.Y + cLane + 2.0f;
		let colorLane = local.Y > @box.Bottom - cLane - 2.0f;
		var best = GradientStopRef();
		var bestDistance = cHitRadius + 1.0f;
		if (alphaLane)
		{
			for (int i = 0; i < value.Alphas.Count; ++i)
			{
				let d = Abs(XAt(value.Alphas[i].Time) - local.X);
				if ((d <= cHitRadius) && (d < bestDistance))
				{
					best = GradientStopRef(true, (int32)i);
					bestDistance = d;
				}
			}
		}
		if (colorLane)
		{
			for (int i = 0; i < value.Colors.Count; ++i)
			{
				let d = Abs(XAt(value.Colors[i].Time) - local.X);
				if ((d <= cHitRadius) && (d < bestDistance))
				{
					best = GradientStopRef(false, (int32)i);
					bestDistance = d;
				}
			}
		}
		return best;
	}

	protected override void OnMouseDown(MouseEvent e)
	{
		if (e.Button != .Left)
			return;
		e.Handled = true;
		mView.RequestFocus();
		let local = ConvertToNodeSpace(e.Position); // events come in screen space
		var stop = StopAt(local);
		if ((e.ClickCount == 2) && stop.IsValid)
		{
			mView.Select(stop);
			if (!stop.Alpha)
				mView.OpenPicker();
			return;
		}
		mView.[Friend]BeginGesture();
		if (!stop.IsValid)
		{
			// A click on nothing adds a stop there, and the drag goes on with it.
			let @box = ContentBounds;
			let alpha = local.Y < @box.Y + @box.Height * 0.5f;
			if ((mView.[Friend]mMaxStops != 0) && (mView.[Friend]Count(alpha) >= (int)mView.[Friend]mMaxStops))
			{
				mView.[Friend]mGesture = false;
				return;
			}
			stop = mView.[Friend]Insert(alpha, TimeAt(local.X));
		}
		mView.[Friend]mSelected = stop;
		mView.[Friend]mDragStop = stop;
		mView.[Friend]mDragBase.Set(mView.[Friend]mValue);
		mView.[Friend]ShowSelection();
		mView.Invalidate();
		mDragging = true;
	}

	protected override void OnMouseMove(MouseEvent e)
	{
		if (!mDragging)
			return;
		let local = ConvertToNodeSpace(e.Position);
		let @box = ContentBounds;
		let off = (local.Y < @box.Y - cPullOff) || (local.Y > @box.Bottom + cPullOff);
		mView.[Friend]DragStop(TimeAt(local.X), off);
	}

	protected override void OnMouseUp(MouseEvent e)
	{
		if (!mDragging || (e.Button != .Left))
			return;
		mDragging = false;
		mView.[Friend]EndStopDrag();
	}

	protected override void OnPointerCancel(MouseEvent e)
	{
		if (!mDragging)
			return;
		mDragging = false;
		mView.[Friend]CancelGesture();
	}

	public override void OnDraw(DrawContext ctx, Rect localBounds)
	{
		base.OnDraw(ctx, localBounds);
		let value = mView.[Friend]mValue;
		let bar = BarBounds;
		if ((bar.Width <= 0.0f) || (bar.Height <= 0.0f))
			return;
		// The bar: the gradient over a checkerboard, a column a pixel or two wide at a time.
		ColorPickerDetail.DrawChecker(ctx, bar);
		for (float x = 0.0f; x < bar.Width; x += 2.0f)
		{
			let color = value.Evaluate((x + 1.0f) / bar.Width);
			ctx.VG.FillRect(.(bar.X + x, bar.Y, Min(2.0f, bar.Width - x), bar.Height), color);
		}
		let selectedPart = GetPartStyle("selected");
		let selected = selectedPart.HasBackground ? selectedPart.Box.BackgroundColor : Color(1.0f, 1.0f, 1.0f, 1.0f);
		let edge = TextColor;
		let chosen = mView.[Friend]mSelected;
		// A stop: a triangle pointing at the bar, filled with its colour or its alpha as grey.
		void Marker(float time, bool above, Color fill, bool on)
		{
			let x = XAt(time);
			let tip = above ? bar.Y : bar.Bottom;
			let @base = above ? bar.Y - cLane : bar.Bottom + cLane;
			let shape = scope PathBuilder();
			shape.MoveTo(x, tip);
			shape.LineTo(x + 5.0f, @base);
			shape.LineTo(x - 5.0f, @base);
			shape.Close();
			let path = shape.ToPath();
			ctx.VG.FillPath(path, fill);
			ctx.VG.StrokePath(path, on ? selected : edge, StrokeStyle(on ? 2.0f : 1.0f));
			delete path;
		}
		for (int i = 0; i < value.Alphas.Count; ++i)
		{
			let a = value.Alphas[i].Alpha;
			Marker(value.Alphas[i].Time, true, .(a, a, a, 1.0f), chosen.Alpha && (chosen.Index == (int32)i));
		}
		for (int i = 0; i < value.Colors.Count; ++i)
		{
			var c = value.Colors[i].Color;
			c.A = 1.0f;
			Marker(value.Colors[i].Time, false, c, !chosen.Alpha && (chosen.Index == (int32)i));
		}
	}
}

[GuiReflect(true)]
class GradientView : UIWidget
{
	private GradientStrip mStrip ~ _.ReleaseRef();
	private UIWidget mControls ~ _.ReleaseRef();
	private ComboBox mInterpolation ~ _.ReleaseRef();
	private Label mTimeLabel ~ _.ReleaseRef();
	private NumberField mTime ~ _.ReleaseRef();
	private Label mAlphaLabel ~ _.ReleaseRef();
	private NumberField mAlpha ~ _.ReleaseRef();
	private ColorSwatch mSwatch ~ _.ReleaseRef();
	private PropertyColorPopup mPopup ~ _.ReleaseRef();

	private ColorGradient mValue = new .() ~ delete _;
	private GradientStopRef mSelected = .();
	private uint32 mMaxStops = 0;
	// The controls are being set from the value.
	private bool mShowing = false;
	// A gesture under way.
	private bool mGesture = false;
	// The open picker has changed the colour.
	private bool mPicking = false;
	// The value when the gesture began.
	private ColorGradient mBefore = new .() ~ delete _;
	private GradientStopRef mBeforeSelected = .();
	// The stop the strip drags, in mDragBase.
	private GradientStopRef mDragStop = .();
	// The value the drag works from.
	private ColorGradient mDragBase = new .() ~ delete _;
	private bool mPulledOff = false;
	private delegate void(ColorGradient gradient) mOnChanging ~ delete _;
	private delegate void(ColorGradient gradient) mOnChanged ~ delete _;
	private delegate void() mOnCancelled ~ delete _;

	public this()
	{
		Tag = "gradientview";
		TabFocusable = true;
		EditLayoutStyle(scope (s) =>
			{
				s.Direction = .Column;
				s.RowGap = 6.0f;
			});
		mStrip = new GradientStrip(this);
		AddChild(mStrip);

		mControls = new UIWidget();
		mControls.EditLayoutStyle(scope (s) =>
			{
				s.Direction = .Row;
				s.ColumnGap = 6.0f;
				s.AlignItems = .Center;
			});
		AddChild(mControls);
		mInterpolation = new ComboBox();
		StringView[4] spaces = .("sRGB", "Linear light", "OKLab", "Constant"); // GradientInterpolation's order
		for (let name in spaces)
			mInterpolation.AddItem(name);
		mInterpolation.EditLayoutStyle(scope (s) => { s.Width = LayoutLength.Px(110.0f); });
		mInterpolation.SetOnSelectionChanged(new (index) => { PickedInterpolation(index); });
		mControls.AddChild(mInterpolation);

		mTimeLabel = MakeLabel("At");
		mTime = MakeField(0.0, 1.0, 0.01);
		mTime.SetOnValueChanging(new (value) => { TypedTime(value, false); });
		mTime.SetOnValueChanged(new (value) => { TypedTime(value, true); });
		mTime.SetOnValueCancelled(new () => { CancelGesture(); });

		mAlphaLabel = MakeLabel("Alpha");
		mAlpha = MakeField(0.0, 1.0, 0.01);
		mAlpha.SetOnValueChanging(new (value) => { TypedAlpha(value, false); });
		mAlpha.SetOnValueChanged(new (value) => { TypedAlpha(value, true); });
		mAlpha.SetOnValueCancelled(new () => { CancelGesture(); });

		mSwatch = new ColorSwatch();
		mSwatch.EditLayoutStyle(scope (s) =>
			{
				s.Width = LayoutLength.Px(40.0f);
				s.Height = LayoutLength.Px(20.0f);
				s.Shrink = 0.0f;
			});
		mSwatch.ShowsAlpha = false;
		mSwatch.SetOnClick(new () => { OpenPicker(); });
		mControls.AddChild(mSwatch);

		mPopup = new PropertyColorPopup();
		mPopup.Picker.ShowsAlpha = false; // a gradient's alpha is its alpha stops'
		mPopup.Picker.SetOnColorChanging(new (color) => { PickedColor(color); });
		mPopup.Picker.SetOnColorChanged(new (color) => { PickedColor(color); });
		ShowSelection();
	}

	// === The value ===

	/// The gradient (borrowed: read it, never change it). Set from code it is copied, shown, and
	/// nothing is reported.
	public ColorGradient Value
	{
		get => mValue;
		set
		{
			mValue.Set(value);
			if (mSelected.IsValid && (mSelected.Index >= (int32)Count(mSelected.Alpha)))
				mSelected = .();
			ShowSelection();
			Invalidate();
		}
	}

	/// The most stops of each kind (a particle gradient's eight); 0: no limit.
	public uint32 MaxStops
	{
		get => mMaxStops;
		set => mMaxStops = value;
	}

	/// OWNERSHIP of `callback` transfers.
	public void SetOnGradientChanging(delegate void(ColorGradient gradient) callback)
	{
		delete mOnChanging;
		mOnChanging = callback;
	}

	/// OWNERSHIP of `callback` transfers.
	public void SetOnGradientChanged(delegate void(ColorGradient gradient) callback)
	{
		delete mOnChanged;
		mOnChanged = callback;
	}

	/// A gesture given up: the value is as it was before it. OWNERSHIP of `callback` transfers.
	public void SetOnGradientCancelled(delegate void() callback)
	{
		delete mOnCancelled;
		mOnCancelled = callback;
	}

	// === The selection ===

	public GradientStopRef Selected => mSelected;

	public void Select(GradientStopRef stop)
	{
		var stop;
		if (stop.IsValid && (stop.Index >= (int32)Count(stop.Alpha)))
			stop = .();
		mSelected = stop;
		ShowSelection();
		Invalidate();
	}

	// === Edits (each one change) ===

	/// Adds a stop at `time` of the gradient's colour or alpha there; false when the kind is full.
	public bool AddStop(bool alpha, float time)
	{
		if ((mMaxStops != 0) && (Count(alpha) >= (int)mMaxStops))
			return false;
		let stop = Insert(alpha, time);
		Select(stop);
		Changed(true);
		return true;
	}

	/// Takes the selected stop away; false when there is none, or it is its kind's last.
	public bool RemoveSelected()
	{
		if (!mSelected.IsValid || (Count(mSelected.Alpha) <= 1))
			return false;
		Erase(mSelected);
		mSelected = .();
		ShowSelection();
		Changed(true);
		return true;
	}

	// === Parts ===

	public GradientStrip Strip => mStrip;
	public ComboBox InterpolationBox => mInterpolation;
	public NumberField TimeField => mTime;
	public NumberField AlphaField => mAlpha;
	public ColorSwatch Swatch => mSwatch;

	/// The picker, while it is open.
	public ColorPicker Picker
	{
		get
		{
			let dispatcher = mPopup.EventDispatcher;
			return ((dispatcher != null) && dispatcher.IsPopupOpen(mPopup)) ? mPopup.Picker : null;
		}
	}

	/// Opens the picker on the selected colour stop.
	public void OpenPicker()
	{
		let dispatcher = EventDispatcher;
		if ((dispatcher == null) || !mSelected.IsValid || mSelected.Alpha || (Picker != null))
			return;
		ShareTextStyle(mPopup, false);
		var color = mValue.Colors[mSelected.Index].Color;
		color.A = 1.0f;
		mPopup.Picker.ColorValue = color;
		mPicking = false;
		let options = new PopupOptions();
		options.Anchor = mSwatch;
		options.Placement.Side = .Below;
		options.Placement.Align = .Start;
		options.Placement.Gap = 2.0f;
		options.Placement.Shrink = true;
		options.TakesFocus = true;
		options.FitContent = true;
		options.OnClosed = new (reason) => { PickerClosed(reason == .Escape); };
		dispatcher.OpenPopup(this, mPopup, options);
	}

	protected override void OnKeyDown(KeyEvent e)
	{
		let key = (KeyCode)e.KeyCode;
		if ((key == .Escape) && mStrip.[Friend]mDragging)
		{
			e.Handled = true;
			mStrip.[Friend]mDragging = false;
			CancelGesture();
			return;
		}
		if ((e.Modifiers == 0) && ((key == .Delete) || (key == .Backspace)) && !mStrip.[Friend]mDragging && (e.Target == this))
			e.Handled = RemoveSelected();
	}

	protected override void OnTextStyleChange()
	{
		ShareTextStyle(mInterpolation);
		ShareTextStyle(mTime);
		ShareTextStyle(mAlpha);
		ShareTextStyle(mTimeLabel);
		ShareTextStyle(mAlphaLabel);
	}

	private Label MakeLabel(StringView text)
	{
		let label = new Label();
		label.Text = text;
		label.HitTestVisible = false;
		mControls.AddChild(label);
		return label;
	}

	private NumberField MakeField(double low, double high, double step)
	{
		let field = new NumberField();
		field.Min = low;
		field.Max = high;
		field.Step = step;
		field.EditLayoutStyle(scope (s) => { s.Width = LayoutLength.Px(72.0f); });
		mControls.AddChild(field);
		return field;
	}

	private int Count(bool alpha) => alpha ? mValue.Alphas.Count : mValue.Colors.Count;

	private float TimeOf(GradientStopRef stop) => stop.Alpha ? mValue.Alphas[stop.Index].Time : mValue.Colors[stop.Index].Time;

	// Puts a stop at `time` of what the gradient has there; where it went.
	private GradientStopRef Insert(bool alpha, float time)
	{
		let here = mValue.Evaluate(time);
		if (alpha)
		{
			int alphaAt = 0;
			while ((alphaAt < mValue.Alphas.Count) && (mValue.Alphas[alphaAt].Time <= time))
				++alphaAt;
			mValue.Alphas.Insert(alphaAt, GradientAlphaStop(time, here.A));
			return GradientStopRef(true, (int32)alphaAt);
		}
		int at = 0;
		while ((at < mValue.Colors.Count) && (mValue.Colors[at].Time <= time))
			++at;
		mValue.Colors.Insert(at, GradientColorStop(time, Color(here.R, here.G, here.B, 1.0f)));
		return GradientStopRef(false, (int32)at);
	}

	private void Erase(GradientStopRef stop)
	{
		if (stop.Alpha)
			mValue.Alphas.RemoveAt(stop.Index);
		else
			mValue.Colors.RemoveAt(stop.Index);
	}

	// Moves a stop to `time`, sorted again; where it went.
	private GradientStopRef MoveStop(GradientStopRef stop, float time)
	{
		let to = Clamp(time, 0.0f, 1.0f);
		if (stop.Alpha)
		{
			var movedAlpha = mValue.Alphas[stop.Index];
			movedAlpha.Time = to;
			mValue.Alphas.RemoveAt(stop.Index);
			int alphaAt = 0;
			while ((alphaAt < mValue.Alphas.Count) && (mValue.Alphas[alphaAt].Time <= to))
				++alphaAt;
			mValue.Alphas.Insert(alphaAt, movedAlpha);
			return GradientStopRef(true, (int32)alphaAt);
		}
		var moved = mValue.Colors[stop.Index];
		moved.Time = to;
		mValue.Colors.RemoveAt(stop.Index);
		int at = 0;
		while ((at < mValue.Colors.Count) && (mValue.Colors[at].Time <= to))
			++at;
		mValue.Colors.Insert(at, moved);
		return GradientStopRef(false, (int32)at);
	}

	// A gesture's start: what a cancel puts back.
	private void BeginGesture()
	{
		if (mGesture)
			return;
		mGesture = true;
		mBefore.Set(mValue);
		mBeforeSelected = mSelected;
	}

	private void Changed(bool done)
	{
		Invalidate();
		if (done)
		{
			mGesture = false;
			if (mOnChanged != null)
				mOnChanged(mValue);
		}
		else if (mOnChanging != null)
			mOnChanging(mValue);
	}

	private void CancelGesture()
	{
		if (!mGesture)
			return;
		mGesture = false;
		mValue.Set(mBefore);
		mSelected = mBeforeSelected;
		mPulledOff = false;
		ShowSelection();
		Invalidate();
		if (mOnCancelled != null)
			mOnCancelled();
	}

	// The strip's drag: the stop to `time`, or off the strip (gone while it stays off).
	private void DragStop(float time, bool off)
	{
		if (!mDragStop.IsValid)
			return;
		mValue.Set(mDragBase);
		mPulledOff = off && (Count(mDragStop.Alpha) > 1);
		if (mPulledOff)
		{
			Erase(mDragStop);
			mSelected = .();
		}
		else
			mSelected = MoveStop(mDragStop, time);
		ShowSelection();
		Changed(false);
	}

	private void EndStopDrag()
	{
		mDragStop = .();
		mPulledOff = false;
		if (mGesture)
		{
			if (mValue.Equals(mBefore))
				mGesture = false; // a click on a stop: nothing changed
			else
				Changed(true);
		}
	}

	private void ShowSelection()
	{
		mShowing = true;
		mInterpolation.SelectedIndex = (int32)mValue.Interpolation;
		let any = mSelected.IsValid;
		let alpha = any && mSelected.Alpha;
		mTimeLabel.Displayed = any;
		mTime.Displayed = any;
		mAlphaLabel.Displayed = alpha;
		mAlpha.Displayed = alpha;
		mSwatch.Displayed = any && !alpha;
		if (any)
		{
			mTime.Value = TimeOf(mSelected);
			if (alpha)
				mAlpha.Value = mValue.Alphas[mSelected.Index].Alpha;
			else
				mSwatch.ColorValue = mValue.Colors[mSelected.Index].Color;
		}
		mShowing = false;
	}

	private void PickedInterpolation(int32 index)
	{
		if (mShowing || (index < 0) || (index > (int32)GradientInterpolation.Constant))
			return;
		mValue.Interpolation = (GradientInterpolation)index;
		Changed(true);
	}

	private void TypedTime(double value, bool done)
	{
		if (mShowing || !mSelected.IsValid)
			return;
		BeginGesture();
		mSelected = MoveStop(mSelected, (float)value);
		Changed(done);
	}

	private void TypedAlpha(double value, bool done)
	{
		if (mShowing || !mSelected.IsValid || !mSelected.Alpha)
			return;
		BeginGesture();
		mValue.Alphas[mSelected.Index].Alpha = Clamp((float)value, 0.0f, 1.0f);
		Changed(done);
	}

	private void PickedColor(Color picked)
	{
		if (!mSelected.IsValid || mSelected.Alpha)
			return;
		if (!mPicking)
		{
			mPicking = true;
			BeginGesture();
		}
		var color = picked;
		color.A = 1.0f;
		mValue.Colors[mSelected.Index].Color = color;
		mSwatch.ColorValue = color;
		Changed(false);
	}

	private void PickerClosed(bool escaped)
	{
		if (!mPicking)
			return;
		mPicking = false;
		if (escaped)
			CancelGesture();
		else
			Changed(true);
	}
}
