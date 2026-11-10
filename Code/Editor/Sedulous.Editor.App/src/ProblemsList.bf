using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.GUI;

namespace Sedulous.Editor.App;

// What a code page's check found, under its code: a
// line saying how many errors and warnings there are ("No problems" when none), then a row each, its
// severity's icon, its place ("12:4", the file before it when the problem is in another, a shader's
// include) and its message, errors first. Choosing a row, by a click or the arrow keys, tells the
// page, which takes its code there. It replaces the old pages' error boxes, inert text, and the GUI
// page's one-line status. The editor's, as a part of its kit, until something outside the editor
// needs it. It fills a panel of the page's markup.

/// One thing a check found.
class CodeProblem
{
	public CodeSeverity Severity = .Error;
	public String Message = new .() ~ delete _;
	/// Empty: the page's own code; else the file it is in (an include).
	public String File = new .() ~ delete _;
	/// From 0.
	public uint32 Line = 0;
	/// From 0.
	public uint32 Column = 0;
	/// False: the check named the line alone (the whole of it is marked).
	public bool AtColumn = true;

	public this() { }

	public this(CodeSeverity severity, StringView message, StringView file, uint32 line, uint32 column, bool atColumn = true)
	{
		Severity = severity;
		Message.Set(message);
		File.Set(file);
		Line = line;
		Column = column;
		AtColumn = atColumn;
	}

	/// The problems a code editor's diagnostics are (its own code's), appended; the caller deletes
	/// them.
	public static void Of(Span<CodeDiagnostic> diagnostics, List<CodeProblem> outProblems)
	{
		for (let d in diagnostics)
			outProblems.Add(new CodeProblem(d.Severity, d.Message, "", d.Range.Start.Line, d.Range.Start.Column));
	}
}

class ProblemsList
{
	// The problems as the list's rows.
	private class Model : IModel
	{
		private ProblemsList mList;

		public this(ProblemsList list)
		{
			mList = list;
		}

		public override int RowCount(ModelIndex parent) => parent.IsValid ? 0 : mList.mProblems.Count;
		public override int ColumnCount() => 1;

		public override Sedulous.GUI.Variant Data(ModelIndex index, ModelRole role = .Display)
		{
			if ((role != .Display) || (index.Row < 0) || (index.Row >= mList.mProblems.Count))
				return .();
			return .(mList.mProblems[index.Row].Message);
		}

		public void Reset() => NotifyReset();
	}

	private List<CodeProblem> mProblems = new .() ~ DeleteContainerAndItems!(_);
	private String mClean = new .() ~ delete _; // SetClean's
	private Model mModel ~ delete _;
	/// One reference each, the list's: the host holds its own.
	private Sedulous.GUI.Label mSummary ~ _.ReleaseRef();
	private ListView mList ~ _.ReleaseRef();
	private delegate void(CodeProblem problem) mOnChoose ~ delete _;
	private uint32 mClickListener = 0;

	/// Fills `host` (a panel of the page's markup): its summary, then its list.
	public this(UIWidget host)
	{
		mModel = new .(this);
		host.AddClass("problems");
		mSummary = new Sedulous.GUI.Label();
		mSummary.AddClass("problems-summary");
		host.AddChild(mSummary);
		mList = new ListView();
		mList.AddClass("problems-list");
		let rows = new RowFactory();
		rows.Create = new [=this] (type) => MakeRow();
		rows.Bind = new [=this] (row, index) => { BindRow(row, index); };
		mList.SetRowFactory(rows);
		mList.Model = mModel;
		// A row chosen by the keys or a click goes there; a click on the chosen one again too.
		mList.SetOnSelectionChanged(new [=this] (index) => { Choose(index); });
		mList.SetOnActivated(new [=this] (index) => { Choose(index); });
		mClickListener = mList.AddEventListener(.MouseClick, new [=this] (e) => { Choose(.(mList.CurrentItem, 0, -1)); });
		host.AddChild(mList);
		Show(.());
	}

	public ~this()
	{
		mList.RemoveEventListener(mClickListener);
		mList.Model = null;
	}

	/// Shows `problems` (copied), errors first, each kind in its place's order.
	public void Show(Span<CodeProblem> problems)
	{
		ClearAndDeleteItems!(mProblems);
		for (let p in problems)
			mProblems.Add(new CodeProblem(p.Severity, p.Message, p.File, p.Line, p.Column, p.AtColumn));
		// Errors, then warnings, then the rest; by file (its own first), line and column.
		for (int i = 1; i < mProblems.Count; i++)
		{
			for (int j = i; (j > 0) && Before(mProblems[j], mProblems[j - 1]); j--)
				Swap!(mProblems[j], mProblems[j - 1]);
		}
		mSummary.Text = Summary(.. scope String());
		mModel.Reset();
	}

	/// Told of the problem chosen, to take its code there. OWNERSHIP of `onChoose` transfers.
	public void SetOnChoose(delegate void(CodeProblem problem) onChoose)
	{
		delete mOnChoose;
		mOnChoose = onChoose;
	}

	/// What the summary says with no problems (empty: "No problems"): what a page's check
	/// found good (the class a script compiles). Said at the next Show.
	public void SetClean(StringView text)
	{
		mClean.Set(text);
	}

	/// "No problems" (or what SetClean said), "1 error", "2 errors, 1 warning", appended.
	public void Summary(String outText)
	{
		if (mProblems.IsEmpty)
		{
			outText.Append(mClean.IsEmpty ? "No problems" : mClean);
			return;
		}
		int errors = 0;
		int warnings = 0;
		int others = 0;
		for (let p in mProblems)
		{
			if (p.Severity == .Error)
				errors++;
			else if (p.Severity == .Warning)
				warnings++;
			else
				others++;
		}
		let start = outText.Length;
		Count(outText, start, errors, "error", "errors");
		Count(outText, start, warnings, "warning", "warnings");
		Count(outText, start, others, "note", "notes");
	}

	// === For tests ===

	public Span<CodeProblem> Problems => mProblems;
	public ListView List => mList;

	/// What a row says where it is ("12:4", "Common.hlsli 3:1", "12" for a line alone), appended.
	public static void PlaceOf(CodeProblem p, String outText)
	{
		if (!p.File.IsEmpty)
			outText.AppendF("{} ", System.IO.Path.GetFileName(p.File, .. scope String()));
		if (p.AtColumn)
			outText.AppendF("{}:{}", p.Line + 1, p.Column + 1);
		else
			outText.AppendF("{}", p.Line + 1);
	}

	public void Choose(ModelIndex index)
	{
		if ((index.Row < 0) || (index.Row >= mProblems.Count) || (mOnChoose == null))
			return;
		mOnChoose(mProblems[index.Row]);
	}

	private static void Count(String outText, int start, int count, StringView one, StringView many)
	{
		if (count == 0)
			return;
		if (outText.Length > start)
			outText.Append(", ");
		outText.AppendF("{} {}", count, (count == 1) ? one : many);
	}

	private static int Rank(CodeSeverity severity) => (severity == .Error) ? 0 : ((severity == .Warning) ? 1 : 2);

	private static bool Before(CodeProblem a, CodeProblem b)
	{
		if (Rank(a.Severity) != Rank(b.Severity))
			return Rank(a.Severity) < Rank(b.Severity);
		if (a.File.IsEmpty != b.File.IsEmpty)
			return a.File.IsEmpty;
		if (a.File != b.File)
			return String.Compare(a.File, b.File, false) < 0;
		return (a.Line != b.Line) ? (a.Line < b.Line) : (a.Column < b.Column);
	}

	private Node MakeRow()
	{
		let row = new Panel();
		row.AddClass("problem-row");
		let icon = new Sedulous.GUI.Image();
		icon.AddClass("problem-icon");
		let place = new Sedulous.GUI.Label();
		place.AddClass("problem-place");
		place.AddClass("mono");
		let message = new Sedulous.GUI.Label();
		message.AddClass("problem-message");
		row.AddChild(icon);
		row.AddChild(place);
		row.AddChild(message);
		// The row holds them now.
		icon.ReleaseRef();
		place.ReleaseRef();
		message.ReleaseRef();
		return row;
	}

	private void BindRow(Node node, ModelIndex index)
	{
		let row = node as UIWidget;
		if ((row == null) || (index.Row < 0) || (index.Row >= mProblems.Count) || (row.ChildCount < 3))
			return;
		let p = mProblems[index.Row];
		if (let icon = row.GetChildAt(0) as Sedulous.GUI.Image)
			icon.Source = scope String()..AppendF("Editor/Icons/{}.svg", (p.Severity == .Error) ? "error" : ((p.Severity == .Warning) ? "warning" : "info"));
		if (let place = row.GetChildAt(1) as Sedulous.GUI.Label)
			place.Text = PlaceOf(p, .. scope String());
		if (let message = row.GetChildAt(2) as Sedulous.GUI.Label)
		{
			message.Text = p.Message;
			message.Tooltip = p.Message; // a long one is cut where the row ends
		}
		for (let s in StringView[?]("error", "warning", "info", "hint"))
			row.RemoveClass(s);
		row.AddClass(CodeSeverityName(p.Severity));
	}
}
