using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Fonts;
using internal Sedulous.GUI;

namespace Sedulous.GUI;

// The language service: what the editor asks its host for, so the widget stays language-neutral
// (Godot's and Zero's): completions at a place, and what to say about the word under the pointer.
// The host answers from its compiler (a script module's API, the markup registry); the library
// ships none, as it ships no language.
//
// The completion list: a core popup that never takes the focus (the editor keeps the keys, its
// "completing" key context sending Up, Down, Return, Tab and Escape to the list), filtered fuzzily
// as the word grows (zed's and VS Code's: the letters in order, a match at the start or at a word's
// start, and a run of them, scoring higher), each row its kind, its label with the matched letters
// marked, and its detail.

/// What a completion is, for its mark and its colour (the list's part of the kind's name).
enum CodeCompletionKind : uint8
{
	Text,
	Keyword,
	Variable,
	Function,
	Method,
	Property,
	Field,
	Type,
	Enum,
	EnumMember,
	Constant,
	Module,
	Snippet,
	Count,
}

static
{
	public static StringView CodeCompletionKindName(CodeCompletionKind kind)
	{
		let i = (int)kind;
		return CodeCompletionDetail.sKindNames[(i < (int)CodeCompletionKind.Count) ? i : 0];
	}

	/// The letter a row marks its kind with (in the kind's colour).
	public static StringView CodeCompletionKindMark(CodeCompletionKind kind)
	{
		let i = (int)kind;
		return CodeCompletionDetail.sKindMarks[(i < (int)CodeCompletionKind.Count) ? i : 0];
	}

	/// How well `pattern` matches `label` fuzzily: below 0 none, else higher better. Its letters must
	/// come in order, case aside, the first at the label's start or a word's (after `_`, `-` or `.`,
	/// or a capital after a small letter); each scores, more at the start, at a word's start (the
	/// first letter most), right after the letter before it, and in the pattern's case. `positions`,
	/// when given, gets the byte of each matched letter.
	public static int32 CodeFuzzyMatch(StringView pattern, StringView label, List<uint32> positions = null)
	{
		if (positions != null)
			positions.Clear();
		let m = pattern.Length;
		let n = label.Length;
		if (m == 0)
			return 0;
		if (m > n)
			return -1;
		char8 Lower(char8 c) => ((c >= 'A') && (c <= 'Z')) ? (char8)((uint8)c + 32) : c;
		bool IsUpper(char8 c) => (c >= 'A') && (c <= 'Z');
		bool IsLower(char8 c) => (c >= 'a') && (c <= 'z');
		bool WordStart(int j)
		{
			if (j == 0)
				return true;
			let before = label[j - 1];
			return (before == '_') || (before == '-') || (before == '.') || (before == ' ') || (IsLower(before) && IsUpper(label[j]));
		}
		const int cPattern = 32;
		const int cLabel = 128;
		if ((m > cPattern) || (n > cLabel))
		{
			// Too long to weigh: a prefix, case aside, or nothing.
			for (int i < m)
			{
				if (Lower(pattern[i]) != Lower(label[i]))
					return -1;
			}
			if (positions != null)
			{
				for (int i < m)
					positions.Add((uint32)i);
			}
			return (int32)m;
		}
		const int16 cNone = -32000;
		int16[cPattern * cLabel] score = ?;
		uint8[cPattern * cLabel] from = ?;
		int16 Letter(int i, int j)
		{
			// A later letter at a word's start counts less, so a run ("pos" in position) beats an
			// acronym's letters scattered over words ("pOrderSet").
			return (int16)(1 + ((j == 0) ? 8 : WordStart(j) ? ((i == 0) ? 6 : 3) : 0) + ((pattern[i] == label[j]) ? 1 : 0));
		}
		for (int j < n)
		{
			score[j] = ((Lower(pattern[0]) == Lower(label[j])) && WordStart(j)) ? Letter(0, j) : cNone;
			from[j] = 0;
		}
		for (int i = 1; i < m; ++i)
		{
			int16 best = cNone; // the best of row i - 1 before j - 1
			uint8 bestAt = 0;
			for (int j < n)
			{
				score[i * cLabel + j] = cNone;
				from[i * cLabel + j] = 0;
				if ((j >= 2) && (score[(i - 1) * cLabel + j - 2] > best))
				{
					best = score[(i - 1) * cLabel + j - 2];
					bestAt = (uint8)(j - 2);
				}
				if ((j == 0) || (Lower(pattern[i]) != Lower(label[j])))
					continue;
				let run = (score[(i - 1) * cLabel + j - 1] > cNone) ? (int16)(score[(i - 1) * cLabel + j - 1] + 5) : cNone;
				if ((run == cNone) && (best == cNone))
					continue;
				if (run >= best)
				{
					score[i * cLabel + j] = (int16)(run + Letter(i, j));
					from[i * cLabel + j] = (uint8)(j - 1);
				}
				else
				{
					score[i * cLabel + j] = (int16)(best + Letter(i, j));
					from[i * cLabel + j] = bestAt;
				}
			}
		}
		int16 total = cNone;
		int end = 0;
		for (int j < n)
		{
			if (score[(m - 1) * cLabel + j] > total)
			{
				total = score[(m - 1) * cLabel + j];
				end = j;
			}
		}
		if (total == cNone)
			return -1;
		if (positions != null)
		{
			positions.Resize(m);
			int j = end;
			for (int i = m - 1; i >= 0; i--)
			{
				positions[i] = (uint32)j;
				j = from[i * cLabel + j];
			}
		}
		return total;
	}
}

/// A completion the service offers. A class: it owns its texts; Set copies another.
class CodeCompletionItem
{
	/// What the list shows and the typed word is matched against.
	public String Label = new .() ~ delete _;
	public CodeCompletionKind Kind = .Text;
	/// Shown dim at the row's end (a type, a signature).
	public String Detail = new .() ~ delete _;
	/// What accepting puts in place of the typed word; empty: the label.
	public String Insert = new .() ~ delete _;

	/// Makes this a copy of `other`.
	public void Set(CodeCompletionItem other)
	{
		if (other === this)
			return;
		Label.Set(other.Label);
		Kind = other.Kind;
		Detail.Set(other.Detail);
		Insert.Set(other.Insert);
	}
}

/// What the editor asks completions for.
struct CodeCompletionRequest
{
	/// The primary caret.
	public CodePosition At = .();
	/// Where the word being typed begins (At when none is).
	public CodePosition WordStart = .();
	/// Asked for (Ctrl+Space) rather than opened by typing.
	public bool Invoked = false;
	/// The trigger character just typed (a `.`), else 0.
	public char8 Trigger = 0;

	public this() { }
}

/// The host's: completions and hover for its language. Asked on the GUI's thread, at once.
interface ICodeLanguageService
{
	/// The characters that open the list when typed (`.` and `:`), with an empty word.
	StringView CompletionTriggers { get; }
	/// Every completion that may apply at `request.At`, each new (the caller owns them), added to
	/// `out`; the editor filters them by the word as it is typed, asking again only when the list
	/// opens or a trigger is typed.
	void Complete(CodeDocument document, CodeCompletionRequest request, List<CodeCompletionItem> @out);
	/// What to say of what is at `at` (a declaration, a value while debugging), appended to `out`;
	/// false: nothing.
	bool Hover(CodeDocument document, CodePosition at, String @out);
}

/// The editor's completion list (`codecompletion`): the service's completions filtered by the word
/// typed, best first, one selected. It never takes the focus, and a press in it leaves the focus in
/// the editor; a click picks a row.
[GuiReflect]
class CodeCompletionList : UIWidget
{
	public const int cRowsShown = 10;
	public const float cMinWidth = 200.0f;
	public const float cMaxWidth = 560.0f;

	private const float cPad = 6.0f;

	private struct Shown
	{
		public uint32 Item = 0;
		public int32 Score = 0;

		public this(uint32 item, int32 score)
		{
			Item = item;
			Score = score;
		}
	}

	private class Row
	{
		public Sedulous.GUI.Text Mark = new .() ~ delete _;
		public Sedulous.GUI.Text Label = new .() ~ delete _;
		public Sedulous.GUI.Text Detail = new .() ~ delete _;
		public float MarkWidth = 0.0f;
		public float LabelWidth = 0.0f;
		public float DetailWidth = 0.0f;
		/// The whole row's, padded.
		public float Width = 0.0f;
	}

	private List<CodeCompletionItem> mItems = new .() ~ DeleteContainerAndItems!(_);
	private List<Shown> mShown = new .() ~ delete _;
	// By shown index, made as each is first drawn or measured (null until then).
	private List<Row> mRows = new .() ~ DeleteContainerAndItems!(_);
	private String mPrefix = new .() ~ delete _;
	private int mSelected = 0;
	// One wide letter: the kind's column.
	private Sedulous.GUI.Text mMeasure = new .() ~ delete _;
	private delegate void(Sedulous.GUI.Text text) mStyleText ~ delete _;
	private delegate void(int index) mOnPicked ~ delete _;
	private delegate void(int index) mOnSelected ~ delete _;

	public this()
	{
		Tag = "codecompletion";
		KeepsFocus = true;
		ClipChildren = true;
		using (StyleWriteScope(this))
		{
			EditLayoutStyle(scope (s) => { s.OverflowY = .Auto; });
		}
	}

	/// The service's completions, filtered by the word typed. The items move to the list (OWNERSHIP
	/// of each transfers; `items` is left empty).
	public void SetItems(List<CodeCompletionItem> items, StringView prefix)
	{
		ClearAndDeleteItems!(mItems);
		mItems.AddRange(items);
		items.Clear();
		Filter(prefix);
	}

	public int ItemCount => mItems.Count;

	/// Shows those `prefix` matches, best first (in the service's order while it is empty), the first
	/// selected; how many.
	public int Filter(StringView prefix)
	{
		mPrefix.Set(prefix);
		mShown.Clear();
		for (int i < mItems.Count)
		{
			let score = CodeFuzzyMatch(prefix, mItems[i].Label);
			if (score >= 0)
				mShown.Add(.((uint32)i, score));
		}
		if (prefix.Length != 0)
		{
			// Stable: at a tie of score and length, the service's order.
			for (int i = 1; i < mShown.Count; i++)
			{
				let key = mShown[i];
				int j = i;
				while ((j > 0) && Before(key, mShown[j - 1]))
				{
					mShown[j] = mShown[j - 1];
					--j;
				}
				mShown[j] = key;
			}
		}
		ClearAndDeleteItems!(mRows);
		mSelected = 0;
		ScrollOffset = .(0.0f, 0.0f);
		RequestLayout();
		Invalidate();
		return mShown.Count;
	}

	public StringView Prefix => mPrefix;
	public int ShownCount => mShown.Count;
	public CodeCompletionItem ShownItem(int index) => mItems[(int)mShown[index].Item];

	/// The selected completion; null when none shows.
	public CodeCompletionItem SelectedItem => (mSelected < mShown.Count) ? ShownItem(mSelected) : null;

	public int Selected
	{
		get => mSelected;
		set
		{
			if (mShown.IsEmpty)
				return;
			let index = Math.Min(value, mShown.Count - 1);
			if (index == mSelected)
				return;
			mSelected = index;
			ScrollToSelected();
			Invalidate();
			if (mOnSelected != null)
				mOnSelected(mSelected);
		}
	}

	/// Up and Down (`wrap`: past an end to the other), the pages (stopping at the ends).
	public void MoveSelection(int32 delta, bool wrap)
	{
		if (mShown.IsEmpty)
			return;
		let count = (int64)mShown.Count;
		var to = (int64)mSelected + delta;
		if (wrap && ((delta == 1) || (delta == -1)))
			to = (to % count + count) % count;
		Selected = (int)Math.Clamp(to, (int64)0, count - 1);
	}

	/// The page a Page Up or Down moves.
	public static int32 PageRows => (int32)cRowsShown - 1;

	/// How far across a row its label begins: the editor lines it up with the word.
	public float LabelInset => Chrome.Left + cPad + mMeasure.LayoutFor(.()).Width + cPad;

	public float RowHeight
	{
		get
		{
			let line = mMeasure.LineHeight;
			return ((line > 0.0f) ? line : 16.0f) + 4.0f;
		}
	}

	/// OWNERSHIP of `callback` transfers.
	public void SetOnPicked(delegate void(int index) callback)
	{
		delete mOnPicked;
		mOnPicked = callback;
	}

	/// OWNERSHIP of `callback` transfers.
	public void SetOnSelected(delegate void(int index) callback)
	{
		delete mOnSelected;
		mOnSelected = callback;
	}

	public override void CollectStyleParts(List<StringView> outParts)
	{
		outParts.Add("selected");
		outParts.Add("match");
		outParts.Add("detail");
		for (int i < (int)CodeCompletionKind.Count)
			outParts.Add(CodeCompletionKindName((CodeCompletionKind)i));
	}

	public override Float2 MeasureContent(Float2 available)
	{
		// As wide as its widest rows (of the first few), within bounds; as tall as ten rows.
		float widest = 0.0f;
		let measured = Math.Min(mShown.Count, 50);
		for (int i < measured)
			widest = Math.Max(widest, RowFor(i).Width);
		let rows = (float)Math.Min(mShown.Count, cRowsShown);
		return .(Math.Clamp(widest, cMinWidth, cMaxWidth), rows * RowHeight);
	}

	public override void OnLayout()
	{
		// Not the base's: it has no children; what it scrolls over is its rows.
		let content = ContentBounds;
		SetScrollExtent(.(content.Width, (float)mShown.Count * RowHeight));
	}

	protected override void OnTextStyleChange()
	{
		delete mStyleText;
		mStyleText = new (text) =>
			{
				text.Font = Font;
				text.SetFontSelection(FontService, GetTextStyle().FontFamily, GetTextStyle().Selection);
				text.Color = TextColor;
				text.WhiteSpace = .Pre;
				text.Direction = ParagraphDirection(.LeftToRight, false);
			};
		mStyleText(mMeasure);
		mMeasure.SetString("M");
		ClearAndDeleteItems!(mRows);
		RequestLayout();
		Invalidate();
	}

	protected override void OnPartStyleChange(StringView part)
	{
		base.OnPartStyleChange(part);
		ClearAndDeleteItems!(mRows);
		Invalidate();
	}

	public override void OnDraw(DrawContext ctx, Rect localBounds)
	{
		base.OnDraw(ctx, localBounds);
		if (mShown.IsEmpty)
			return;
		let content = ContentBounds;
		let rh = RowHeight;
		let top = ScrollShift.Y;
		let first = (int)Math.Max(0.0f, top / rh);
		let last = Math.Min(mShown.Count - 1, (int)Math.Max(0.0f, (top + content.Height) / rh));
		let selected = GetPartStyle("selected");
		var selectedColor = selected.HasBackground ? selected.Box.BackgroundColor : Color(0.17f, 0.24f, 0.36f, 1.0f);
		selectedColor.A *= selected.Opacity;
		ctx.PushClip(content);
		for (int i = first; i <= last; ++i)
		{
			let y = content.Y + (float)i * rh - top;
			if (i == mSelected)
				ctx.VG.FillRect(.(content.X, y, content.Width, rh), selectedColor);
			let row = RowFor(i);
			DrawAt(ctx, row.Mark, content.X + cPad, y, rh);
			DrawAt(ctx, row.Label, content.X + cPad + row.MarkWidth + cPad, y, rh);
			// The detail at the end, where it clears the label.
			let labelEnd = content.X + cPad + row.MarkWidth + cPad + row.LabelWidth;
			let detailX = content.X + content.Width - cPad - row.DetailWidth;
			if ((row.DetailWidth > 0.0f) && (detailX >= labelEnd + cPad * 2.0f))
				DrawAt(ctx, row.Detail, detailX, y, rh);
		}
		ctx.PopClip();
	}

	protected override void OnMouseDown(MouseEvent e)
	{
		if ((e.Button != .Left) || mShown.IsEmpty)
			return;
		e.Handled = true;
		let local = ConvertToNodeSpace(e.Position);
		let row = (local.Y - ContentBounds.Y + ScrollShift.Y) / RowHeight;
		if ((row < 0.0f) || ((int)row >= mShown.Count))
			return;
		Selected = (int)row;
		if (mOnPicked != null)
			mOnPicked(mSelected);
	}

	// A row's text at `x`, in the middle of its row at `y`, `rh` tall.
	private static void DrawAt(DrawContext ctx, Sedulous.GUI.Text text, float x, float y, float rh)
	{
		let layout = text.LayoutFor(.());
		text.DrawLayout(ctx, layout, .(x, y + (rh - layout.Height) * 0.5f));
	}

	// Whether `a` shows before `b`: the higher score, the shorter label at a tie.
	private bool Before(Shown a, Shown b)
	{
		if (a.Score != b.Score)
			return a.Score > b.Score;
		return mItems[(int)a.Item].Label.Length < mItems[(int)b.Item].Label.Length;
	}

	// The rich text tag that colours what follows `c`, appended to `outText`.
	private static void ColorTag(Color c, String outText)
	{
		const String cHex = "0123456789abcdef";
		float[4] channels = .(c.R, c.G, c.B, c.A);
		outText.Append("[color=#");
		for (int k < 4)
		{
			let v = (uint32)(Math.Clamp(channels[k], 0.0f, 1.0f) * 255.0f + 0.5f);
			outText.Append(cHex[(int)(v >> 4)]);
			outText.Append(cHex[(int)(v & 15)]);
		}
		outText.Append("]");
	}

	private Color PartText(StringView part, Color fallback)
	{
		let style = GetPartStyle(part);
		return style.HasColor ? style.TextColor : fallback;
	}

	// Its shown row `index`, made as it is first drawn or measured.
	private Row RowFor(int index)
	{
		while (mRows.Count < mShown.Count)
			mRows.Add(null);
		if (mRows[index] != null)
			return mRows[index];
		let row = new Row();
		mRows[index] = row;
		let item = ShownItem(index);
		if (mStyleText != null)
		{
			mStyleText(row.Mark);
			mStyleText(row.Label);
			mStyleText(row.Detail);
		}
		row.Mark.Color = PartText(CodeCompletionKindName(item.Kind), TextColor);
		row.Mark.SetString(CodeCompletionKindMark(item.Kind));
		// The label, its matched letters in the match part's colour ("[[" a "[").
		let matched = scope List<uint32>();
		CodeFuzzyMatch(mPrefix, item.Label, matched);
		let open = ColorTag(PartText("match", TextColor), .. scope String());
		let markup = scope String();
		StringView label = item.Label;
		int next = 0;
		for (int i < label.Length)
		{
			let hit = (next < matched.Count) && (matched[next] == (uint32)i);
			if (hit)
			{
				markup.Append(open);
				++next;
			}
			if (label[i] == '[')
				markup.Append("[[");
			else
				markup.Append(label[i]);
			if (hit)
				markup.Append("[/color]");
		}
		row.Label.SetMarkup(markup);
		row.Detail.Color = PartText("detail", TextColor);
		row.Detail.SetString(item.Detail);
		row.MarkWidth = Math.Max(row.Mark.LayoutFor(.()).Width, mMeasure.LayoutFor(.()).Width);
		row.LabelWidth = row.Label.LayoutFor(.()).Width;
		row.DetailWidth = item.Detail.IsEmpty ? 0.0f : row.Detail.LayoutFor(.()).Width;
		row.Width = cPad + row.MarkWidth + cPad + row.LabelWidth + ((row.DetailWidth > 0.0f) ? cPad * 3.0f + row.DetailWidth : 0.0f) + cPad;
		return row;
	}

	private void ScrollToSelected()
	{
		let rh = RowHeight;
		let top = (float)mSelected * rh;
		let view = ContentBounds.Height;
		let offset = ScrollOffset;
		if (top < offset.Y)
			ScrollOffset = .(offset.X, top);
		else if (top + rh > offset.Y + view)
			ScrollOffset = .(offset.X, top + rh - view);
	}
}

/// What CodeCompletion.bf keeps out of the public surface: the kinds' names and marks.
internal static class CodeCompletionDetail
{
	public static String[(int)CodeCompletionKind.Count] sKindNames = .(
		"text", "keyword", "variable", "function", "method", "property", "field", "type", "enum", "enum-member",
		"constant", "module", "snippet");

	public static String[(int)CodeCompletionKind.Count] sKindMarks = .(
		"t", "k", "v", "f", "m", "p", "d", "T", "E", "e", "c", "M", "s");
}
