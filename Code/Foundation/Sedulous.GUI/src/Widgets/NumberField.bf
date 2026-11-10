using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.VG;
using internal Sedulous.GUI;

namespace Sedulous.GUI;

// NumberField: a number typed, stepped or scrubbed, on the text field's core with a RangeValue,
// after Godot's SpinBox and LunarSong's drag fields.
//
// - Its text is its value, written with the step's decimals (none for an `integer` field), between
//   its `prefix` and `suffix`.
// - Typed, the text is read as an expression when it commits (Return, or focus leaving): numbers,
//   + - * /, parentheses; then snapped to the step and kept in the range (unless allowed past it).
//   Text that is no number goes back to the value it had.
// - Not yet being edited, a press and a drag across scrubs it (past a few pixels; Shift fine, Ctrl
//   coarse), reporting `input` as it goes and `change` on release; a press let go without a drag
//   starts editing, all of it selected.
// - Its arrows (repeat buttons, the button core's) step it, as do Up and Down (Page Up and Down a
//   page) and the wheel while it is focused.
// - A value set from code reports nothing but to bindings, as a range's does.
// - Mixed (several objects' values differing, a property grid's): no number shows, its placeholder
//   does, and whatever the user does next sets one, even the value it holds.
// - Escape during a scrub puts the value back as it was before the press and reports the cancel.

static
{
	/// `text` read as arithmetic: numbers (with a decimal point), + - * /, unary minus and
	/// parentheses; none when it is not one (or divides by zero).
	public static double? EvaluateExpression(StringView text)
	{
		var p = NumberFieldDetail.ExpressionParser(text);
		let v = p.Sum();
		p.Skip();
		if (!p.Ok || (p.At != text.Length) || (text.Length == 0))
			return null;
		return v;
	}
}

/// What NumberField.bf keeps out of the public surface.
internal static class NumberFieldDetail
{
	/// A recursive descent over sums of products of primaries.
	public struct ExpressionParser
	{
		public StringView Text;
		public int At = 0;
		public bool Ok = true;

		public this(StringView text)
		{
			Text = text;
		}

		public void Skip() mut
		{
			while ((At < Text.Length) && ((Text[At] == ' ') || (Text[At] == '\t')))
				++At;
		}

		public double Primary() mut
		{
			Skip();
			if ((At < Text.Length) && ((Text[At] == '-') || (Text[At] == '+')))
			{
				let negative = Text[At++] == '-';
				let v = Primary();
				return negative ? -v : v;
			}
			if ((At < Text.Length) && (Text[At] == '('))
			{
				++At;
				let v = Sum();
				Skip();
				if ((At < Text.Length) && (Text[At] == ')'))
					++At;
				else
					Ok = false;
				return v;
			}
			let start = At;
			while ((At < Text.Length) && (((Text[At] >= '0') && (Text[At] <= '9')) || (Text[At] == '.')))
				++At;
			let v = (At > start) ? TextRunsDetail.ParseFloat(Text.Substring(start, At - start)) : (double?)null;
			if (!v.HasValue)
			{
				Ok = false;
				return 0.0;
			}
			return v.Value;
		}

		public double Product() mut
		{
			var v = Primary();
			while (true)
			{
				Skip();
				if ((At >= Text.Length) || ((Text[At] != '*') && (Text[At] != '/')))
					return v;
				let divide = Text[At++] == '/';
				let r = Primary();
				if (divide && (r == 0.0))
					Ok = false;
				v = divide ? ((r != 0.0) ? v / r : 0.0) : v * r;
			}
		}

		public double Sum() mut
		{
			var v = Product();
			while (true)
			{
				Skip();
				if ((At >= Text.Length) || ((Text[At] != '+') && (Text[At] != '-')))
					return v;
				let minus = Text[At++] == '-';
				let r = Product();
				v = minus ? v - r : v + r;
			}
		}
	}
}

/// A number field's arrow: a repeat button acting on the press, its triangle the
/// `spinbutton::arrow` part's background colour.
[GuiReflect]
class SpinButton : ButtonBase
{
	private bool mUp;

	public this(bool up)
	{
		mUp = up;
		Tag = "spinbutton";
		AddClass(up ? "up" : "down");
		TabFocusable = false; // the field keeps the focus
		Repeat = true;
		RepeatDelay = 0.4f;
		RepeatInterval = 0.06f;
	}

	public bool IsUp => mUp;

	public override void CollectStyleParts(List<StringView> outParts)
	{
		outParts.Add("arrow");
	}

	public override void OnDraw(DrawContext ctx, Rect localBounds)
	{
		let b = ContentBounds;
		let arrow = GetPartStyle("arrow");
		var color = arrow.HasBackground ? arrow.Box.BackgroundColor : Color(0.70f, 0.74f, 0.80f, 1.0f);
		color.A *= arrow.Opacity;
		let w = Math.Min(8.0f, b.Width * 0.6f);
		let h = w * 0.55f;
		let x = b.X + (b.Width - w) * 0.5f;
		let y = b.Y + (b.Height - h) * 0.5f;
		let pb = scope PathBuilder();
		if (mUp)
		{
			pb.MoveTo(x, y + h);
			pb.LineTo(x + w, y + h);
			pb.LineTo(x + w * 0.5f, y);
		}
		else
		{
			pb.MoveTo(x, y);
			pb.LineTo(x + w, y);
			pb.LineTo(x + w * 0.5f, y + h);
		}
		pb.Close();
		let path = pb.ToPath();
		ctx.VG.FillPath(path, color);
		delete path;
	}
}

[GuiReflect(true)]
class NumberField : TextField
{
	private const float cSpinWidth = 16.0f;
	/// Between its text and its arrows.
	private const float cSpinGap = 2.0f;
	/// The least room its number keeps beside its arrows.
	private const float cNumberRoom = 32.0f;
	/// Pixels a press moves before it scrubs.
	private const float cScrubThreshold = 4.0f;
	private const float cPixelsPerStep = 4.0f;

	private RangeValue mRange = .();
	private double mCommittedValue = 0.0;
	private bool mInteger = false;
	private bool mEditing = false;
	// A press not yet a click or a scrub.
	private bool mPressing = false;
	private bool mScrubbing = false;
	private bool mMixed = false;
	private bool mScrubFromMixed = false;
	// A mixed field's first change commits whatever its value.
	private bool mCommitAlways = false;
	private bool mStepsOnWheel = true;
	private float mPressX = 0.0f;
	private double mScrubFrom = 0.0;
	private String mPrefix = new .() ~ delete _;
	private String mSuffix = new .() ~ delete _;
	private Observable mValueChanged = new .() ~ delete _;
	private SpinButton mUp = null ~ _?.ReleaseRef();
	private SpinButton mDown = null ~ _?.ReleaseRef();
	private delegate void(double value) mOnValueChanging ~ delete _;
	private delegate void(double value) mOnValueChanged ~ delete _;
	private delegate void() mOnValueCancelled ~ delete _;

	public this()
	{
		Tag = "numberfield";
		AccessRoleName = "spinbutton"; // what a screen reader takes it for
		mUp = new SpinButton(true);
		mDown = new SpinButton(false);
		mUp.SetOnClick(new () => { StepBy(1.0); });
		mDown.SetOnClick(new () => { StepBy(-1.0); });
		AddChild(mUp);
		AddChild(mDown);
		mRange.Max = 100.0;
		mRange.Step = 1.0;
		ShowValue();
	}

	// === Value ===

	/// The value (a read a binding records). Set from code: constrained, shown, reported to
	/// bindings, no events.
	[GuiProperty("value", .TwoWay, "value")]
	public double Value
	{
		get
		{
			mValueChanged.Track();
			return mRange.Value;
		}
		set
		{
			mMixed = false;
			mCommitAlways = false;
			if (Apply(value))
				mCommittedValue = mRange.Value;
			ShowValue();
		}
	}

	[GuiProperty("min", .None, "min")]
	public double Min
	{
		get => mRange.Min;
		set
		{
			var r = mRange;
			r.Min = value;
			EditRange(r);
		}
	}

	[GuiProperty("max", .None, "max")]
	public double Max
	{
		get => mRange.Max;
		set
		{
			var r = mRange;
			r.Max = value;
			EditRange(r);
		}
	}

	[GuiProperty("step", .None, "step")]
	public double Step
	{
		get => mRange.Step;
		set
		{
			var r = mRange;
			r.Step = (value < 0.0) ? 0.0 : value;
			EditRange(r);
		}
	}

	/// Page Up and Down's step (0: a tenth of the range).
	[GuiProperty("page")]
	public double Page
	{
		get => mRange.Page;
		set
		{
			var r = mRange;
			r.Page = (value < 0.0) ? 0.0 : value;
			EditRange(r);
		}
	}

	[GuiProperty("allow-greater")]
	public bool AllowGreater
	{
		get => mRange.AllowGreater;
		set
		{
			var r = mRange;
			r.AllowGreater = value;
			EditRange(r);
		}
	}

	[GuiProperty("allow-lesser")]
	public bool AllowLesser
	{
		get => mRange.AllowLesser;
		set
		{
			var r = mRange;
			r.AllowLesser = value;
			EditRange(r);
		}
	}

	/// Whole numbers only: snapped to them and written without decimals.
	[GuiProperty("integer")]
	public bool IsInteger
	{
		get => mInteger;
		set
		{
			mInteger = value;
			Value = mRange.Value;
		}
	}

	public RangeValue Range => mRange;

	/// Text before and after the number ("$", " px").
	[GuiProperty("prefix")]
	public StringView Prefix
	{
		get => mPrefix;
		set
		{
			mPrefix.Set(value);
			ShowValue();
		}
	}

	[GuiProperty("suffix")]
	public StringView Suffix
	{
		get => mSuffix;
		set
		{
			mSuffix.Set(value);
			ShowValue();
		}
	}

	// Markup's prefix and suffix as written: a suffix's leading space is part of it.
	public override bool SetMarkupAttribute(StringView name, StringView value)
	{
		if (name == "prefix")
			Prefix = value;
		else if (name == "suffix")
			Suffix = value;
		else
			return base.SetMarkupAttribute(name, value);
		return true;
	}

	/// Each change the user makes, as it goes (a scrub's steps). OWNERSHIP of `callback`
	/// transfers.
	public void SetOnValueChanging(delegate void(double value) callback)
	{
		delete mOnValueChanging;
		mOnValueChanging = callback;
	}

	/// A change the user committed (a typed value, a step, a scrub's release). OWNERSHIP of
	/// `callback` transfers.
	public void SetOnValueChanged(delegate void(double value) callback)
	{
		delete mOnValueChanged;
		mOnValueChanged = callback;
	}

	/// Neither value shown: the values it stands for differ. Set after Value, which clears it.
	public bool IsMixed
	{
		get => mMixed;
		set
		{
			if (mMixed == value)
				return;
			mMixed = value;
			mCommitAlways = false;
			mCommittedValue = mRange.Value;
			ShowValue();
		}
	}

	/// Whether the wheel steps it while it is focused (on); off, the wheel goes on to what scrolls.
	public bool StepsOnWheel
	{
		get => mStepsOnWheel;
		set => mStepsOnWheel = value;
	}

	/// A scrub given up with Escape: the value is back as it was before it. OWNERSHIP of `callback`
	/// transfers.
	public void SetOnValueCancelled(delegate void() callback)
	{
		delete mOnValueCancelled;
		mOnValueCancelled = callback;
	}

	/// Being edited as text (typed into, or a press let go on it); otherwise a press scrubs.
	public bool IsEditing => mEditing;
	/// Whether its arrows show: only while its number keeps room beside them. A field too narrow
	/// for both (a vector's part in a narrow inspector) gives the arrows' room to the number; a drag
	/// still scrubs it and the arrow keys still step it.
	public bool ShowsArrows
	{
		get
		{
			let b = BorderThickness;
			let p = Padding;
			let text = Size.X - b.TotalHorizontal - p.TotalHorizontal - cSpinWidth - cSpinGap;
			return text >= cNumberRoom;
		}
	}

	public SpinButton UpButton => mUp;
	public SpinButton DownButton => mDown;

	/// The value as it is written: the step's decimals, between the prefix and the suffix, appended
	/// to `outText`.
	public void FormatValue(double value, String outText)
	{
		let decimals = mInteger ? 0 : mRange.Decimals;
		double scale = 1.0;
		for (int32 d = 0; d < decimals; ++d)
			scale *= 10.0;
		let rounded = (double)(int64)(value * scale + ((value < 0.0) ? -0.5 : 0.5)) / scale;
		outText.Append(mPrefix);
		if (decimals == 0)
			((int64)rounded).ToString(outText);
		else if ((Math.Abs(rounded) < 1e15) && (rounded == (double)(int64)rounded))
			((int64)rounded).ToString(outText); // a whole number without a fraction
		else
			rounded.ToString(outText); // the shortest form that reads back as the same number
		outText.Append(mSuffix);
	}

	// The text read as an expression; a number committed, else the old value back.
	protected override void OnCommitting()
	{
		var text = ParseUtil.Trim(Model.Text);
		if ((mPrefix.Length != 0) && (text.Length >= mPrefix.Length) && (text.Substring(0, mPrefix.Length) == mPrefix))
			text = ParseUtil.Trim(text.Substring(mPrefix.Length, text.Length - mPrefix.Length));
		if ((mSuffix.Length != 0) && (text.Length >= mSuffix.Length) &&
			(text.Substring(text.Length - mSuffix.Length, mSuffix.Length) == mSuffix))
			text = ParseUtil.Trim(text.Substring(0, text.Length - mSuffix.Length));
		let v = EvaluateExpression(text);
		if (v.HasValue)
			ChangeByUser(v.Value, false);
		else if (mMixed)
			return; // nothing typed into a mixed field: still mixed
		ShowValue();
		CommitValue();
	}

	protected override void OnKeyDown(KeyEvent e)
	{
		if ((e.Target == this) && (e.Modifiers == 0) && IsTreeEnabled)
		{
			let key = (KeyCode)e.KeyCode;
			if ((key == .Escape) && mPressing)
			{
				CancelScrub();
				e.Handled = true;
				return;
			}
			double by = 0.0;
			if (key == .Up)
				by = mRange.KeyStep;
			else if (key == .Down)
				by = -mRange.KeyStep;
			else if (key == .PageUp)
				by = mRange.PageStep;
			else if (key == .PageDown)
				by = -mRange.PageStep;
			if (by != 0.0)
			{
				StepValue(by);
				e.Handled = true;
				return;
			}
			if ((key == .Space) || ((key >= .A) && (key <= .Num9)))
				mEditing = true; // typing into it
		}
		base.OnKeyDown(e);
	}

	protected override void OnTextInput(TextInputEvent e)
	{
		mEditing = true;
		base.OnTextInput(e);
	}

	protected override void OnMouseWheel(WheelEvent e)
	{
		if (!mStepsOnWheel || !IsFocused || (e.Delta.Y == 0.0f))
			return;
		StepValue(mRange.KeyStep * (double)e.Delta.Y);
		e.Handled = true;
	}

	protected override void OnMouseDown(MouseEvent e)
	{
		if (mEditing || (e.Button != .Left))
		{
			base.OnMouseDown(e);
			return;
		}
		// Not editing: a press may become a scrub, or a click that starts editing.
		RequestFocus();
		e.Handled = true;
		mPressing = true;
		mScrubbing = false;
		mPressX = e.Position.X;
		mScrubFrom = mRange.Value;
		mScrubFromMixed = mMixed;
	}

	protected override void OnMouseMove(MouseEvent e)
	{
		if (!mPressing)
		{
			base.OnMouseMove(e);
			return;
		}
		// Toward the inline end raises it, as a slider's does.
		let dx = (e.Position.X - mPressX) * (IsRightToLeft ? -1.0f : 1.0f);
		if (!mScrubbing && (Math.Abs(dx) < cScrubThreshold))
			return;
		mScrubbing = true;
		// A step per few pixels; Shift a tenth as fast, Ctrl ten times.
		double rate = ((mRange.Step > 0.0) ? mRange.Step : (mRange.Max - mRange.Min) / 200.0) / cPixelsPerStep;
		if ((e.Modifiers & KeyModShift) != 0)
			rate *= 0.1;
		if ((e.Modifiers & KeyModCtrl) != 0)
			rate *= 10.0;
		ChangeByUser(mScrubFrom + (double)dx * rate, true);
		ShowValue();
	}

	protected override void OnMouseUp(MouseEvent e)
	{
		if (!mPressing)
		{
			base.OnMouseUp(e);
			return;
		}
		mPressing = false;
		if (mScrubbing)
		{
			mScrubbing = false;
			CommitValue();
			return;
		}
		// A click: editing, all of it selected.
		mEditing = true;
		Model.SelectAll();
		Synced();
	}

	protected override void OnPointerCancel(MouseEvent e)
	{
		if (mScrubbing)
			CommitValue();
		mPressing = false;
		mScrubbing = false;
		base.OnPointerCancel(e);
	}

	protected override void OnFocusLost()
	{
		base.OnFocusLost(); // commits
		mEditing = false;
	}

	// Its text kept clear of its arrows, at its inline end.
	protected override Rect EditBounds()
	{
		let content = ContentBounds;
		let b = BorderThickness;
		if (!ShowsArrows)
			return content;
		if (IsRightToLeft)
		{
			let left = Math.Max(content.X, b.Left + cSpinWidth + cSpinGap);
			return .(left, content.Y, Math.Max(0.0f, content.Right - left), content.Height);
		}
		let right = Math.Min(content.Right, Size.X - b.Right - cSpinWidth - cSpinGap);
		return .(content.X, content.Y, Math.Max(0.0f, right - content.X), content.Height);
	}

	// Its arrows stacked at its inline end, inside its border.
	public override void OnLayout()
	{
		let b = BorderThickness;
		let size = Size;
		let h = Math.Max(0.0f, size.Y - b.TotalVertical);
		let x = IsRightToLeft ? b.Left : size.X - b.Right - cSpinWidth;
		let arrows = ShowsArrows;
		mUp.Visible = arrows;
		mDown.Visible = arrows;
		mUp.Arrange(.(x, b.Top, cSpinWidth, h * 0.5f));
		mDown.Arrange(.(x, b.Top + h * 0.5f, cSpinWidth, h - h * 0.5f));
	}

	private bool Apply(double value)
	{
		var value;
		if (mInteger)
			value = (double)(int64)(value + ((value < 0.0) ? -0.5 : 0.5));
		value = mRange.Constrain(value);
		if ((value == mRange.Value) && !mMixed)
			return false;
		mMixed = false; // the user set one value, whatever it is
		mRange.Value = value;
		mValueChanged.Notify();
		return true;
	}

	// `next` is the range edited: its value constrained by its new bounds, a value it moved counting
	// as committed.
	private void EditRange(RangeValue next)
	{
		mRange = next;
		let before = mRange.Value;
		mRange.Value = mRange.Constrain(mRange.Value);
		if (mRange.Value != before)
		{
			mCommittedValue = mRange.Value;
			mValueChanged.Notify();
		}
		ShowValue();
	}

	// The user moved it: `input`, and `change` now or at the gesture's end.
	private void ChangeByUser(double value, bool reportInput)
	{
		let wasMixed = mMixed;
		if (!Apply(value))
			return;
		if (wasMixed)
			mCommitAlways = true; // committed even at the value it held
		if (reportInput)
		{
			if (mOnValueChanging != null)
				mOnValueChanging(mRange.Value);
			SendEvent(scope Event(.Input, this));
		}
	}

	private void CommitValue()
	{
		if ((mRange.Value == mCommittedValue) && !mCommitAlways)
			return;
		mCommitAlways = false;
		mCommittedValue = mRange.Value;
		if (mOnValueChanged != null)
			mOnValueChanged(mRange.Value);
		SendEvent(scope Event(.Changed, this));
	}

	// A step from an arrow, a key or the wheel: committed at once, any typing dropped.
	private void StepBy(double steps)
	{
		StepValue(mRange.KeyStep * steps);
	}

	private void StepValue(double by)
	{
		if (!IsTreeEnabled)
			return;
		ChangeByUser(mRange.Value + by, true);
		mEditing = false;
		ShowValue();
		CommitValue();
	}

	// The text shows the value (and is the committed text, so the field reports no edit); mixed,
	// it is empty and the placeholder shows.
	private void ShowValue()
	{
		if (mMixed)
		{
			Text = default;
			return;
		}
		let text = scope String();
		FormatValue(mRange.Value, text);
		Text = text;
	}

	// Escape mid-scrub: the value and the mixed state back, the press over, the cancel told.
	private void CancelScrub()
	{
		let scrubbed = mScrubbing;
		mPressing = false;
		mScrubbing = false;
		let dispatcher = EventDispatcher;
		if (dispatcher != null)
			dispatcher.ReleasePointer(this);
		if (!scrubbed)
			return;
		Apply(mScrubFrom);
		mMixed = mScrubFromMixed;
		mCommitAlways = false;
		mCommittedValue = mRange.Value;
		ShowValue();
		if (mOnValueCancelled != null)
			mOnValueCancelled();
	}
}
