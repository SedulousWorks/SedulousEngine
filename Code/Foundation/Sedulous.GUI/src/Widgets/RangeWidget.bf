using System;

namespace Sedulous.GUI;

// RangeWidget: what a slider, a scroll bar, a progress bar and a number field share: a RangeValue
// and the reflected properties over it (value, min, max, step, exponential, allow-greater,
// allow-lesser). The page is protected: the controls a page means something to (a scroll bar's
// visible part, a slider's and a number field's page keys) expose it; a progress bar does not. A
// value set from code reports nothing (a binding follows it); the user's changes report `input`
// as they go and `change` when committed (a drag's release, a key, a typed value's commit), as a
// text field's do.

[GuiReflect]
class RangeWidget : UIWidget
{
	private RangeValue mRange = .();
	// The value last committed (a change reports once).
	private double mCommitted = 0.0;
	private Observable mValueChanged = new .() ~ delete _;
	private delegate void(double value) mOnChanging ~ delete _;
	private delegate void(double value) mOnChanged ~ delete _;

	protected this()
	{
	}

	/// The value (a read a binding records). Set from code: constrained, reported to bindings, no
	/// events.
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
			if (Apply(value))
				mCommitted = mRange.Value;
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
			Edit(r);
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
			Edit(r);
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
			Edit(r);
		}
	}

	[GuiProperty("exponential")]
	public bool Exponential
	{
		get => mRange.Exponential;
		set
		{
			var r = mRange;
			r.Exponential = value;
			Edit(r);
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
			Edit(r);
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
			Edit(r);
		}
	}

	public RangeValue Range => mRange;

	/// The value's place along the range, 0 to 1.
	public double Ratio => mRange.Ratio;

	/// Each change the user makes, as it goes (the `input` event). OWNERSHIP of `callback`
	/// transfers.
	public void SetOnValueChanging(delegate void(double value) callback)
	{
		delete mOnChanging;
		mOnChanging = callback;
	}

	/// A change the user committed (the `change` event). OWNERSHIP of `callback` transfers.
	public void SetOnValueChanged(delegate void(double value) callback)
	{
		delete mOnChanged;
		mOnChanged = callback;
	}

	protected double PageSize
	{
		get => mRange.Page;
		set
		{
			var r = mRange;
			r.Page = (value < 0.0) ? 0.0 : value;
			Edit(r);
		}
	}

	/// The page is a visible part (a scroll bar's): the value stops short of the maximum by it.
	protected void SetPageShown(bool shown)
	{
		var r = mRange;
		r.PageShown = shown;
		Edit(r);
	}

	/// The user moved it to `value`: reported as `input`, and committed (`change`) now or later.
	protected void ChangeByUser(double value, bool commit)
	{
		if (Apply(value))
		{
			if (mOnChanging != null)
				mOnChanging(mRange.Value);
			SendEvent(scope Event(.Input, this));
		}
		if (commit)
			Commit();
	}

	/// A gesture ended (a drag released): its change, if any, is committed.
	protected void Commit()
	{
		if (mRange.Value == mCommitted)
			return;
		mCommitted = mRange.Value;
		if (mOnChanged != null)
			mOnChanged(mRange.Value);
		SendEvent(scope Event(.Changed, this));
	}

	/// The range or the value changed: redraw (a control with parts of its own does more).
	protected virtual void OnRangeChange()
	{
		Invalidate();
	}

	private bool Apply(double value)
	{
		let constrained = mRange.Constrain(value);
		if (constrained == mRange.Value)
			return false;
		mRange.Value = constrained;
		OnRangeChange();
		mValueChanged.Notify();
		return true;
	}

	// `next` is the range edited: its value constrained by its new bounds, it takes the range's
	// place, and a value it moved counts as committed.
	private void Edit(RangeValue next)
	{
		var next;
		next.Value = next.Constrain(next.Value);
		if (next == mRange)
			return;
		let moved = next.Value != mRange.Value;
		mRange = next;
		OnRangeChange();
		if (moved)
		{
			mCommitted = mRange.Value;
			mValueChanged.Notify();
		}
	}
}
