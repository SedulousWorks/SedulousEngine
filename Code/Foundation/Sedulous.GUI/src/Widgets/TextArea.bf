using System;
using Sedulous.Core;

namespace Sedulous.GUI;

// TextArea: the multiline text field, over the same editing model and keys as TextField
// (TextEditBase). Its text wraps at its width, its spaces and line breaks as typed (white-space:
// pre-wrap); Return breaks a line; up and down move by the lines it shows, keeping the column they
// started from, and page up and down by as many as fit; Home and End go to a shown line's ends. It
// is `rows` lines tall unless something sizes it, and scrolls down to keep the caret in view (the
// wheel scrolls it too). It declares "textinput multiline", the context the multiline keys are
// bound in; Ctrl+Return submits it.

[GuiReflect(true), Scriptable]
class TextArea : TextEditBase
{
	private ShownLines mLines ~ delete _;
	private int32 mRows = 3;
	private float mScrollY = 0.0f;

	public this()
	{
		mLines = new ShownLines(this);
		Tag = "textarea";
		AccessRoleName = "textarea"; // what a screen reader takes it for
		KeyContext = "textinput multiline";
		ShownText.WhiteSpace = .PreWrap;
		HintText.WhiteSpace = .Normal;
		Model.Multiline = true;
		Model.SetLines(mLines);
		OnCommand(cTextSubmitCommand, new (e) => { Submit(); });
	}

	/// How many lines tall it is when nothing sizes it.
	[GuiProperty("rows"), Scriptable]
	public int32 Rows
	{
		get => mRows;
		set
		{
			mRows = Math.Max(1, value);
			RequestLayout();
		}
	}

	/// How far its text is scrolled down (to keep the caret in view).
	public float ScrollY => mScrollY;

	/// A text area's usual width, `rows` lines tall.
	public override Float2 MeasureContent(Float2 available)
	{
		let line = (ShownText.Font != null) ? ShownText.LineHeight : 20.0f;
		return .(240.0f, line * (float)mRows);
	}

	/// The size its text takes wrapped at `width` (widest line by total height), at least a line
	/// tall: what a box that grows with what is typed measures (an editable label editing).
	public Float2 MeasureText(float width)
	{
		let line = (ShownText.Font != null) ? ShownText.LineHeight : 20.0f;
		if ((Text.Length == 0) || (ShownText.Font == null))
			return .(0.0f, line);
		let size = ShownText.MeasureWrapped(width);
		return .(size.X, Math.Max(size.Y, line));
	}

	/// Its first line's baseline.
	public override float BaselineAt(Float2 size)
	{
		let c = Chrome;
		let layout = ShownText.LayoutFor(.(0.0f, 0.0f, Math.Max(0.0f, size.X - c.TotalHorizontal), 0.0f));
		let first = layout.Lines.IsEmpty ? 0.0f : layout.Lines[0].Baseline;
		return c.Top + first - mScrollY;
	}

	protected override TextLayout EditLayout()
	{
		return ShownText.LayoutFor(.(0.0f, 0.0f, ContentBounds.Width, 0.0f));
	}

	protected override Float2 TextOrigin(Rect content)
	{
		return .(content.X, content.Y - mScrollY);
	}

	// Scrolls by the least that shows the caret's line, and no further than the text needs.
	protected override void KeepCaretInView()
	{
		let view = ContentBounds.Height;
		let layout = EditLayout();
		let line = LineAt(layout, DisplayCaret());
		let before = mScrollY;
		if (line.Top + line.Height - mScrollY > view)
			mScrollY = line.Top + line.Height - view;
		if (line.Top < mScrollY)
			mScrollY = line.Top;
		mScrollY = Math.Max(0.0f, Math.Min(mScrollY, layout.Height - view));
		if (mScrollY != before)
			Invalidate();
	}

	// The wheel scrolls it, a few lines a notch; at an end the wheel goes on to what holds it.
	protected override void OnMouseWheel(WheelEvent e)
	{
		let view = ContentBounds.Height;
		let most = Math.Max(0.0f, EditLayout().Height - view);
		let before = mScrollY;
		mScrollY = Math.Max(0.0f, Math.Min(most, mScrollY - e.Delta.Y * ShownText.LineHeight * 3.0f));
		if (mScrollY != before)
		{
			e.Handled = true;
			Invalidate();
		}
	}

	// The lines it shows, which vertical movement and a line's ends follow.
	private class ShownLines : ITextLines
	{
		// Its area, which owns it.
		private TextArea mArea;

		public this(TextArea area)
		{
			mArea = area;
		}

		public TextRange LineAt(int offset)
		{
			let layout = mArea.EditLayout();
			if (layout.Lines.IsEmpty)
				return .();
			let index = layout.LineOf(mArea.DisplayOffset(offset));
			let line = layout.Lines[index];
			// A wrapped line's end is its next line's start: End stops before the space it broke at.
			let end = layout.OffsetOnLine(index, 1.0e9f);
			return .(mArea.ModelOffset(line.Start), mArea.ModelOffset(Math.Max(line.Start, end)));
		}

		public int OffsetByLines(int offset, int32 lines, ref float goalX)
		{
			let layout = mArea.EditLayout();
			if (layout.Lines.IsEmpty)
				return 0;
			let display = mArea.DisplayOffset(offset);
			if (goalX < 0.0f)
				goalX = layout.CaretX(display);
			let target = (int32)layout.LineOf(display) + lines;
			if (target < 0)
				return 0;
			if (target >= (int32)layout.Lines.Count)
				return mArea.Model.Text.Length;
			return mArea.ModelOffset(layout.OffsetOnLine((int)target, goalX));
		}

		public int32 LinesPerPage
		{
			get
			{
				let line = mArea.[Friend]ShownText.LineHeight;
				return (line > 0.0f) ? Math.Max(1, (int32)(mArea.ContentBounds.Height / line)) : 1;
			}
		}
	}
}
