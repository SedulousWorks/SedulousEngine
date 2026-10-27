using System;
using Sedulous.Core;

namespace Sedulous.GUI;

// TextField: a single-line, editable text control, over the editing model and keys TextEditBase
// gives it. Modeled on eepp's UITextInput (role only). Its text sits on one line, centred down its
// height, and scrolls across to keep the caret in view; Return submits it (the `submit` event, its
// value committing as `change`). It may mask its text as a password: a bullet for each character,
// copying and cutting taking nothing out, no IME composition.

[GuiReflect(true), Scriptable]
class TextField : TextEditBase
{
	private float mScrollX = 0.0f;
	private bool mPassword = false;

	public this()
	{
		Tag = "textfield";
		AccessRoleName = "textbox"; // what a screen reader takes it for
		ShownText.WhiteSpace = .Pre; // its spaces as typed, on one line
		ShownText.SetAlignment(.Start, .Middle);
		HintText.SetAlignment(.Start, .Middle);
		using (StyleWriteScope(this))
		{
			SetTextAlignment(.Start, .Middle);
		}
		OnCommand(cTextSubmitCommand, new (e) => { Submit(); });
	}

	/// A password field draws a bullet for each character and lets nothing out by copy or cut. Its
	/// value is not read out.
	[GuiProperty("password", .None, "secret"), Scriptable]
	public bool IsPassword
	{
		get => mPassword;
		set
		{
			if (value == mPassword)
				return;
			mPassword = value;
			Model.CopyAllowed = !value;
			Synced();
		}
	}

	/// How far its text is scrolled across from its inline start (to keep the caret in view): from
	/// the left in a left-to-right line, from the right in a right-to-left one.
	public float ScrollX => mScrollX;

	/// One line of its font, a field's usual width, when nothing sizes it.
	public override Float2 MeasureContent(Float2 available)
	{
		return .(160.0f, (ShownText.Font != null) ? ShownText.LineHeight : 20.0f);
	}

	/// Its line's baseline, where it draws its value (and its placeholder, in the same font).
	public override float BaselineAt(Float2 size)
	{
		let c = Chrome;
		return ShownText.FirstBaseline(.(c.Left, c.Top, Math.Max(0.0f, size.X - c.TotalHorizontal), Math.Max(0.0f, size.Y - c.TotalVertical)));
	}

	protected override bool IsMasked => mPassword;

	// One line, unbounded.
	protected override TextLayout EditLayout() => ShownText.LayoutFor(Rect());

	// The layout's origin: a line shorter than the field where its alignment puts it, resolved
	// against the line's own direction (start is the right in a right-to-left one); a longer one
	// scrolled from its inline start. Its line is centred down it.
	protected override Float2 TextOrigin(Rect content)
	{
		let origin = ShownText.Origin(.(content.X, content.Y, 0.0f, content.Height));
		let layout = EditLayout();
		let view = View(content);
		if (layout.Width <= view)
			return .(origin.X + Slack(layout, view - layout.Width), origin.Y);
		return .(origin.X - ScrollFromLeft(layout, view), origin.Y);
	}

	// Scrolls by the least that shows the caret, and no further than the text needs. Not focused,
	// a line too long for the field rests on its start: a value shows its beginning (-9.81, not
	// 81), wherever its caret was left.
	protected override void KeepCaretInView()
	{
		if (!IsFocused)
		{
			if (mScrollX != 0.0f)
			{
				mScrollX = 0.0f;
				Invalidate();
			}
			return;
		}
		let layout = EditLayout();
		let view = View(EditBounds());
		let caret = layout.CaretX(DisplayCaret());
		let before = mScrollX;
		float left = ScrollFromLeft(layout, view);
		if (caret - left > view)
			left = caret - view;
		if (caret < left)
			left = caret;
		let range = Math.Max(0.0f, layout.Width - view);
		left = Math.Clamp(left, 0.0f, range);
		mScrollX = RunsRightToLeft(layout) ? range - left : left;
		if (mScrollX != before)
			Invalidate();
	}

	private static float View(Rect content) => Math.Max(0.0f, content.Width - cCaretWidth);

	// The line's paragraph runs right to left (the field's own way while it is empty).
	private bool RunsRightToLeft(TextLayout layout)
	{
		return layout.Lines.IsEmpty ? IsRightToLeft : layout.Lines[0].RightToLeft;
	}

	// The scroll as the layout moves left, from the inline-start scroll it keeps.
	private float ScrollFromLeft(TextLayout layout, float view)
	{
		let range = Math.Max(0.0f, layout.Width - view);
		let fromStart = Math.Clamp(mScrollX, 0.0f, range);
		return RunsRightToLeft(layout) ? range - fromStart : fromStart;
	}

	// How far a short line sits from the left, of the `slack` it leaves.
	private float Slack(TextLayout layout, float slack)
	{
		var align = ShownText.HAlign;
		if (align == .Start)
			align = RunsRightToLeft(layout) ? TextHAlign.Right : TextHAlign.Left;
		else if (align == .End)
			align = RunsRightToLeft(layout) ? TextHAlign.Left : TextHAlign.Right;
		return (align == .Center) ? slack * 0.5f : (align == .Right) ? slack : 0.0f;
	}
}
