using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.VG;
using internal Sedulous.GUI;

namespace Sedulous.GUI;

// The property grid's curve and gradient editors, and the default editors registered with a grid
// (they are the last of them, so the registration lives here). A curve or a gradient is one value
// (PropertyKind.Curve, .Gradient; a Variant of Core's keys or a ColorGradient), mixed when the
// objects' differ:
//   - a row shows a preview (the curve drawn, the gradient's bar), hatched when mixed;
//   - a click on it opens the full view as a popup (a ruler and a curve view, or a gradient view),
//     every edit in it previewed on each object; closing it commits once (one undo entry, as a
//     colour's picker does), Escape gives the whole of it up.
// Which runtime types are curves or gradients is the source's to say; these editors know only the
// values.

/// A popup's panel holding an editor's full view.
[GuiReflect]
class PropertyViewPopup : UIWidget
{
	public this()
	{
		Tag = "propertyviewpopup";
		Padding = Thickness(8.0f, 8.0f, 8.0f, 8.0f);
		EditLayoutStyle(scope (s) =>
			{
				s.Direction = .Column;
				s.RowGap = 2.0f;
			});
	}

	public override void OnDraw(DrawContext ctx, Rect localBounds)
	{
		if (!BoxFills)
			ctx.VG.FillRect(localBounds.ToRectangle(), .(0.18f, 0.20f, 0.25f, 1.0f));
		base.OnDraw(ctx, localBounds);
	}
}

/// What CurveEditors.bf keeps out of the public surface.
internal static class CurveEditorsDetail
{
	// Diagonal lines over `box`: a row's mixed state, as a mixed swatch shows it.
	public static void DrawHatched(DrawContext ctx, Rect @box, Color line)
	{
		ctx.VG.FillRect(@box.ToRectangle(), .(0.3f, 0.32f, 0.36f, 1.0f));
		ctx.PushClip(@box);
		let lines = scope PathBuilder();
		for (float x = -@box.Height; x < @box.Width; x += 6.0f)
		{
			lines.MoveTo(@box.X + x, @box.Bottom);
			lines.LineTo(@box.X + x + @box.Height, @box.Y);
		}
		let path = lines.ToPath();
		ctx.VG.StrokePath(path, line, StrokeStyle(1.0f));
		delete path;
		ctx.PopClip();
	}
}

/// A row's picture of a curve or a gradient; a click on it reports.
[GuiReflect]
class PropertyValuePreview : UIWidget
{
	// Its own copy.
	private Sedulous.GUI.Variant mValue = .() ~ _.Dispose();
	private bool mMixed = false;
	private float mLow = 0.0f;
	private float mHigh = 0.0f;
	private delegate void() mOnClick ~ delete _;

	public this()
	{
		Tag = "propertypreview";
		TabFocusable = true;
	}

	/// Shows `value` (it keeps its own copy: the caller keeps its).
	public void SetValue(Sedulous.GUI.Variant value, bool mixed)
	{
		let copy = value.Copy();
		mValue.Dispose();
		mValue = copy;
		mMixed = mixed;
		Invalidate();
	}

	/// A curve's values from the bottom to the top (low == high: its keys' own).
	public void SetValueRange(float low, float high)
	{
		mLow = low;
		mHigh = high;
		Invalidate();
	}

	/// OWNERSHIP of `callback` transfers.
	public void SetOnClick(delegate void() callback)
	{
		delete mOnClick;
		mOnClick = callback;
	}

	/// What it shows (a view of its own copy).
	public Sedulous.GUI.Variant Value => mValue.View();
	public bool IsMixed => mMixed;

	protected override void OnMouseClick(MouseEvent e)
	{
		if (e.Button != .Left)
			return;
		e.Handled = true;
		if ((mOnClick != null) && IsTreeEnabled)
			mOnClick();
	}

	protected override void OnKeyDown(KeyEvent e)
	{
		let key = (KeyCode)e.KeyCode;
		if ((e.Target == this) && (e.Modifiers == 0) && ((key == .Return) || (key == .Space)) && (mOnClick != null) && IsTreeEnabled)
		{
			e.Handled = true;
			mOnClick();
		}
	}

	public override void OnDraw(DrawContext ctx, Rect localBounds)
	{
		base.OnDraw(ctx, localBounds);
		let @box = ContentBounds;
		if ((@box.Width <= 0.0f) || (@box.Height <= 0.0f))
			return;
		if (mMixed)
		{
			CurveEditorsDetail.DrawHatched(ctx, @box, TextColor);
			return;
		}
		if (mValue.Kind == .Gradient)
		{
			let gradient = mValue.AsGradient;
			ColorPickerDetail.DrawChecker(ctx, @box);
			for (float x = 0.0f; x < @box.Width; x += 2.0f)
				ctx.VG.FillRect(.(@box.X + x, @box.Y, Min(2.0f, @box.Width - x), @box.Height), gradient.Evaluate((x + 1.0f) / @box.Width));
			return;
		}
		let keys = mValue.AsCurve;
		if (keys.IsEmpty)
			return;
		// Across the keys' times (from 0), up the range or the values the curve reaches, found at the
		// points it is drawn through (a steep tangent's overshoot included); held in its box.
		let end = Max(keys[keys.Length - 1].Time, 1e-3f);
		var low = mLow;
		var high = mHigh;
		if (high <= low)
		{
			low = high = keys[0].Value;
			for (float x = 0.0f; x <= @box.Width; x += 2.0f)
			{
				let v = EvaluateCurve(keys, end * x / @box.Width);
				low = Min(low, v);
				high = Max(high, v);
			}
			if (high - low < 1e-4f)
			{
				low -= 0.5f;
				high += 0.5f;
			}
		}
		ctx.PushClip(@box);
		let inset = 2.0f;
		let line = scope PathBuilder();
		for (float x = 0.0f; x <= @box.Width; x += 2.0f)
		{
			let v = EvaluateCurve(keys, end * x / @box.Width);
			let y = @box.Bottom - inset - (v - low) / (high - low) * (@box.Height - 2.0f * inset);
			if (x == 0.0f)
				line.MoveTo(@box.X + x, y);
			else
				line.LineTo(@box.X + x, y);
		}
		let part = GetPartStyle("curve");
		var stroke = part.HasBackground ? part.Box.BackgroundColor : Color(0.31f, 0.61f, 1.0f, 1.0f);
		stroke.A *= part.Opacity;
		let path = line.ToPath();
		ctx.VG.StrokePath(path, stroke, StrokeStyle(1.5f));
		delete path;
		ctx.PopClip();
	}
}

/// A curve's editor: its preview on the row, a ruler and a curve view in a popup.
[GuiReflect]
class CurvePropertyEditor : PropertyEditor, ICurveSourceClient
{
	public const float cViewWidth = 420.0f;
	public const float cViewHeight = 220.0f;

	private PropertyValuePreview mPreview ~ _.ReleaseRef();
	private PropertyViewPopup mPopup ~ _.ReleaseRef();
	private Sedulous.GUI.TimeAxis mAxis ~ _.ReleaseRef();
	private TimeRuler mRuler ~ _.ReleaseRef();
	private CurveView mView ~ _.ReleaseRef();
	// The popup's own: the curve as it is edited.
	private CurveSet mCurves = new .() ~ delete _;
	private PropertyInfo mInfo = new .() ~ delete _;
	// The value bound.
	private List<CurveKey> mKeys = new .() ~ delete _;
	// What the edit last previewed.
	private List<CurveKey> mPreviewed = new .() ~ delete _;
	private bool mLoading = false;
	// The edit begun, its popup open.
	private bool mEditing = false;

	public this()
	{
		AddClass("curve");
		mPreview = new PropertyValuePreview();
		mPreview.EditLayoutStyle(scope (s) => { s.Grow = 1.0f; });
		mPreview.SetOnClick(new () => { OpenView(); });
		AddChild(mPreview);

		mAxis = new Sedulous.GUI.TimeAxis();
		mPopup = new PropertyViewPopup();
		mRuler = new TimeRuler();
		mRuler.EditLayoutStyle(scope (s) => { s.Width = LayoutLength.Px(cViewWidth); });
		mRuler.TimeAxis = mAxis;
		mPopup.AddChild(mRuler);
		mView = new CurveView();
		mView.EditLayoutStyle(scope (s) =>
			{
				s.Width = LayoutLength.Px(cViewWidth);
				s.Height = LayoutLength.Px(cViewHeight);
			});
		mView.TimeAxis = mAxis;
		mCurves.AddCurve(scope CurveInfo());
		mView.Source = mCurves;
		mCurves.AddClient(this);
		mPopup.AddChild(mView);
	}

	public ~this()
	{
		mView.Source = null;
		mCurves.RemoveClient(this);
	}

	public PropertyValuePreview Preview => mPreview;
	public CurveView View => mView;
	public Sedulous.GUI.TimeAxis TimeAxis => mAxis;

	/// Whether the popup is open.
	public bool IsViewOpen
	{
		get
		{
			let dispatcher = mPopup.EventDispatcher;
			return (dispatcher != null) && dispatcher.IsPopupOpen(mPopup);
		}
	}

	/// Opens the view on the curve shown; its edits preview, its closing commits.
	public void OpenView()
	{
		let dispatcher = EventDispatcher;
		if ((dispatcher == null) || IsReadOnly || IsViewOpen)
			return;
		ShareTextStyle(mPopup, false);
		mLoading = true;
		mCurves.SetKeys(0, mKeys);
		mLoading = false;
		mEditing = false;
		mView.SetSelection(default);
		// Its time across the view (at least a second, a particle curve's 0 to 1), its values up the
		// range or what the curve reaches.
		let end = mKeys.IsEmpty ? 1.0f : Max(1.0f, mKeys.Back.Time);
		mAxis.Duration = end;
		mAxis.Scroll = 0.0f;
		mAxis.PixelsPerSecond = cViewWidth / end;
		var low = mInfo.HasRange ? (float)mInfo.Min : 0.0f;
		var high = mInfo.HasRange ? (float)mInfo.Max : 1.0f;
		for (let key in mKeys)
		{
			low = Min(low, key.Value);
			high = Max(high, key.Value);
		}
		let margin = (high - low) * 0.1f + 1e-3f;
		mView.SetValueRange(low - margin, high + margin);
		let options = new PopupOptions();
		options.Anchor = mPreview;
		options.Placement.Side = .Below;
		options.Placement.Align = .Start;
		options.Placement.Gap = 2.0f;
		options.Placement.Shrink = true;
		options.TakesFocus = true;
		options.FitContent = true;
		options.OnClosed = new (reason) => { Closed(reason == .Escape); };
		dispatcher.OpenPopup(this, mPopup, options);
	}

	// The view's edits (each a gesture of the popup's own set): previewed on the objects, the edit
	// begun at the first.
	public void OnCurvesChanged()
	{
		if (mLoading)
			return;
		let keys = mCurves.GetKeys(0);
		if (!mEditing)
		{
			if (CurveSet.Same(keys, mKeys))
				return;
			mEditing = true;
			BeginEdit();
		}
		else if (CurveSet.Same(keys, mPreviewed))
			return; // told again (a commit after its preview): nothing new
		mPreviewed.Clear();
		for (let key in keys)
			mPreviewed.Add(key);
		mPreview.SetValue(Sedulous.GUI.Variant.FromCurve(keys), false);
		PreviewEdit(PropertyWrite(Sedulous.GUI.Variant.FromCurve(keys)));
	}

	protected override void OnBind(PropertyInfo info, PropertyValue value)
	{
		mInfo.Set(info);
		mKeys.Clear();
		for (let key in value.Value.AsCurve)
			mKeys.Add(key);
		mPreview.SetValue(value.Value, value.Mixed);
		mPreview.SetValueRange(info.HasRange ? (float)info.Min : 0.0f, info.HasRange ? (float)info.Max : 0.0f);
		mPreview.Enabled = !IsReadOnly;
		let curve = scope CurveInfo();
		curve.Name.Set(info.Name);
		curve.HasRange = info.HasRange;
		curve.Min = (float)info.Min;
		curve.Max = (float)info.Max;
		curve.MaxKeys = info.MaxCount;
		curve.StrokeColor = .(0.31f, 0.61f, 1.0f, 1.0f);
		mCurves.Info(0).Set(curve);
		mLoading = true; // telling the view is not an edit
		mCurves.InfoChanged();
		mLoading = false;
	}

	protected override void OnTextStyleChange()
	{
		ShareTextStyle(mPreview);
	}

	private void Closed(bool escaped)
	{
		if (!mEditing)
			return;
		mEditing = false;
		if (escaped)
			CancelEdit();
		else
			CommitEdit(PropertyWrite(Sedulous.GUI.Variant.FromCurve(mCurves.GetKeys(0))));
	}
}

/// A gradient's editor: its bar on the row, a gradient view in a popup.
[GuiReflect]
class GradientPropertyEditor : PropertyEditor
{
	private PropertyValuePreview mPreview ~ _.ReleaseRef();
	private PropertyViewPopup mPopup ~ _.ReleaseRef();
	private GradientView mView ~ _.ReleaseRef();
	// The value bound.
	private ColorGradient mGradient = new .() ~ delete _;
	private bool mEditing = false;

	public this()
	{
		AddClass("gradient");
		mPreview = new PropertyValuePreview();
		mPreview.EditLayoutStyle(scope (s) => { s.Grow = 1.0f; });
		mPreview.SetOnClick(new () => { OpenView(); });
		AddChild(mPreview);
		mPopup = new PropertyViewPopup();
		mView = new GradientView();
		mView.EditLayoutStyle(scope (s) => { s.Width = LayoutLength.Px(360.0f); });
		mView.SetOnGradientChanging(new (value) => { Edited(value); });
		mView.SetOnGradientChanged(new (value) => { Edited(value); });
		mView.SetOnGradientCancelled(new () => { Edited(mView.Value); });
		mPopup.AddChild(mView);
	}

	public PropertyValuePreview Preview => mPreview;
	public GradientView View => mView;

	public bool IsViewOpen
	{
		get
		{
			let dispatcher = mPopup.EventDispatcher;
			return (dispatcher != null) && dispatcher.IsPopupOpen(mPopup);
		}
	}

	public void OpenView()
	{
		let dispatcher = EventDispatcher;
		if ((dispatcher == null) || IsReadOnly || IsViewOpen)
			return;
		ShareTextStyle(mPopup, false);
		mView.Value = mGradient;
		mView.Select(GradientStopRef());
		mEditing = false;
		let options = new PopupOptions();
		options.Anchor = mPreview;
		options.Placement.Side = .Below;
		options.Placement.Align = .Start;
		options.Placement.Gap = 2.0f;
		options.Placement.Shrink = true;
		options.TakesFocus = true;
		options.FitContent = true;
		options.OnClosed = new (reason) => { Closed(reason == .Escape); };
		dispatcher.OpenPopup(this, mPopup, options);
	}

	protected override void OnBind(PropertyInfo info, PropertyValue value)
	{
		mGradient.Set(value.Value.AsGradient);
		mPreview.SetValue(value.Value, value.Mixed);
		mPreview.Enabled = !IsReadOnly;
		mView.MaxStops = info.MaxCount;
	}

	protected override void OnTextStyleChange()
	{
		ShareTextStyle(mPreview);
	}

	private void Edited(ColorGradient value)
	{
		if (!mEditing)
		{
			if (value.Equals(mGradient))
				return;
			mEditing = true;
			BeginEdit();
		}
		mPreview.SetValue(Sedulous.GUI.Variant(value), false);
		PreviewEdit(PropertyWrite(Sedulous.GUI.Variant(value)));
	}

	private void Closed(bool escaped)
	{
		if (!mEditing)
			return;
		mEditing = false;
		if (escaped)
			CancelEdit();
		else
			CommitEdit(PropertyWrite(Sedulous.GUI.Variant(mView.Value)));
	}
}

static
{
	/// Registers the default editors with `registry`: bool, integer, float, string, enum and flags
	/// by kind; lists by kind, Float2, Float3 and Float4 by hint; colours by kind, stops and HDR
	/// colours by hint; curves and gradients by kind.
	public static void RegisterDefaultPropertyEditors(PropertyEditorRegistry registry)
	{
		StringView[3] floats = .("Float2", "Float3", "Float4");
		for (let hint in floats)
			registry.RegisterHint(hint, new () => new FloatsPropertyEditor(), true);
		registry.RegisterKind(.Bool, new () => new BoolPropertyEditor());
		registry.RegisterKind(.Integer, new () => new NumberPropertyEditor());
		registry.RegisterKind(.Float, new () => new NumberPropertyEditor());
		registry.RegisterKind(.String, new () => new StringPropertyEditor());
		registry.RegisterKind(.Enum, new () => new EnumPropertyEditor());
		registry.RegisterKind(.Color, new () => new ColorPropertyEditor());
		registry.RegisterHint("stops", new () => new StopsPropertyEditor());
		registry.RegisterHint("ColorHdr", new () => new HdrColorPropertyEditor(), true);
		registry.RegisterKind(.List, new () => new ListPropertyEditor());
		registry.RegisterKind(.Flags, new () => new FlagsPropertyEditor());
		registry.RegisterKind(.Curve, new () => new CurvePropertyEditor());
		registry.RegisterKind(.Gradient, new () => new GradientPropertyEditor());
	}
}
