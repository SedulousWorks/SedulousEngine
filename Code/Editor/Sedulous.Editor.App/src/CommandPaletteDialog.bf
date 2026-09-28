using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.UI;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.App;

/// Every action by name. A filter box over the registry's declarations (label, description,
/// id, case folded), the matches listed with their effective chord and menu path, Up and Down
/// to move, Enter to run the highlighted one over the active subject through the registry (a
/// disabled action stays listed greyed and refuses with a status line), Escape to close. The
/// palette is the registry, filtered.
class CommandPaletteDialog : Dialog
{
	// One row: label | menu path | chord, the label greyed when the action is disabled now.
	private class Row : FlexLayout
	{
		public Label Title;
		public Label Where;
		public Label Chord;

		public this()
		{
			Direction = .Horizontal;
			Spacing = 12;
			Title = new Label();
			Title.FontSize.Value = 13.0f;
			var grow = LayoutStyle();
			grow.FlexGrow = 1.0f;
			grow.AlignSelf = .Center;
			AddView(Title, grow);
			Where = new Label();
			Where.FontSize.Value = 11.0f;
			Where.TextColor.Value = Color(0.55f, 0.55f, 0.55f, 1.0f);
			var centre = LayoutStyle();
			centre.AlignSelf = .Center;
			AddView(Where, centre);
			Chord = new Label();
			Chord.FontSize.Value = 12.0f;
			Chord.TextColor.Value = Color(0.7f, 0.7f, 0.7f, 1.0f);
			var fixedWidth = LayoutStyle();
			fixedWidth.Width = SizeSpec.Fixed(Unit.Dp(110));
			fixedWidth.AlignSelf = .Center;
			AddView(Chord, fixedWidth);
		}
	}

	private class RowAdapter : ListAdapterBase
	{
		private CommandPaletteDialog mOwner;

		public this(CommandPaletteDialog owner) { mOwner = owner; }

		public override int32 ItemCount => (int32)mOwner.mRows.Count;

		public override View CreateView(int32 viewType) => new Row();

		public override void BindView(View view, int32 position)
		{
			let row = view as Row;
			if ((row == null) || (position < 0) || (position >= mOwner.mRows.Count))
				return;
			let action = mOwner.mRows[position];
			let enabled = mOwner.mActions.IsEnabled(action.Id);
			row.Title.SetText(action.Label);
			row.Title.TextColor.Value = enabled ? null : Color(0.5f, 0.5f, 0.5f, 1.0f);
			row.Where.SetText(action.MenuPath);
			row.Chord.SetText(mOwner.mActions.Shortcut(action.Id).ToString(.. scope .()));
		}
	}

	/// Borrowed.
	private EditorActionRegistry mActions;
	private String mFilter = new .() ~ delete _;
	private List<EditorActionDeclaration> mRows = new .() ~ delete _;
	private int32 mHighlight = -1;
	// Borrowed: the content owns them.
	private EditText mFilterEdit;
	private ListView mList;
	private Label mStatus;
	private RowAdapter mAdapter ~ delete _;

	public this(EditorActionRegistry actions) : base("Command Palette")
	{
		mActions = actions;
		MinWidth.Value = 520.0f;
		MinHeight.Value = 360.0f;
		MaxWidth.Value = 720.0f;
		MaxHeight.Value = 520.0f;

		let column = new FlexLayout();
		column.Direction = .Vertical;
		column.Spacing = 6;

		// The filter first, so Show focuses it (the first focusable child) and typing starts at
		// once; Enter on it runs the highlighted row.
		mFilterEdit = new EditText();
		mFilterEdit.SetPlaceholder("Type an action's name...");
		mFilterEdit.OnTextChanged.Add(new (edit) => { SetFilter(edit.Text); });
		mFilterEdit.OnSubmit.Add(new (edit) => { ExecuteHighlighted().IgnoreError(); });
		var match = LayoutStyle();
		match.Width = SizeSpec.Match();
		column.AddView(mFilterEdit, match);

		mAdapter = new RowAdapter(this);
		mList = new ListView();
		mList.ItemHeight.Value = 26.0f;
		mList.SetAdapter(mAdapter);
		// A click highlights; a double click runs.
		mList.OnItemClicked.Add(new (position, clickCount, x, y) =>
			{
				Highlight(position);
				if (clickCount >= 2)
					ExecuteHighlighted().IgnoreError();
			});
		var grow = LayoutStyle();
		grow.Width = SizeSpec.Match();
		grow.FlexGrow = 1.0f;
		column.AddView(mList, grow);

		mStatus = new Label();
		mStatus.FontSize.Value = 11.0f;
		mStatus.TextColor.Value = Color(0.55f, 0.55f, 0.55f, 1.0f);
		column.AddView(mStatus);

		SetContent(column);
		Rebuild();
	}

	public ~this()
	{
		mList.SetAdapter(null);
	}

	// ---- the model (what a test drives; the views follow) -----------------------------------

	/// The rows for `filter`: every action whose label, description or id contains it (case
	/// folded), label matches first (a label starting with the filter before one merely
	/// containing it), then the rest, each group in registration order. An empty filter lists
	/// everything. The highlight goes back to the first row.
	public void SetFilter(StringView filter)
	{
		mFilter.Set(filter);
		Rebuild();
	}

	public StringView Filter => mFilter;
	public List<EditorActionDeclaration> Rows => mRows;
	/// The highlighted row (-1 with no rows).
	public int32 Highlighted => mHighlight;

	public void Highlight(int32 row)
	{
		if (mRows.IsEmpty)
		{
			mHighlight = -1;
			return;
		}
		mHighlight = Math.Clamp(row, 0, (int32)mRows.Count - 1);
		mList.Selection.Select(mHighlight);
		mList.ScrollToPosition(mHighlight);
	}

	/// Up and Down move the highlight, clamped at the ends.
	public void MoveHighlight(int32 delta) => Highlight(mHighlight + delta);

	/// Runs the highlighted action over the active subject: the dialog closes on success; a
	/// refused one (disabled over the active page, or no row) says so in the status line and
	/// keeps the palette open. Returns the registry's answer.
	public Result<void, ErrorCode> ExecuteHighlighted()
	{
		if ((mHighlight < 0) || (mHighlight >= mRows.Count))
		{
			mStatus.SetText("Nothing matches.");
			return .Err(.NotFound);
		}
		let action = mRows[mHighlight];
		if (mActions.Execute(action.Id) case .Err(let error))
		{
			mStatus.SetText(scope $"'{action.Label}' is not available over the active page.");
			return .Err(error);
		}
		Close(.OK);
		return .Ok;
	}

	// ---- keys: before the filter box sees them (it handles every key itself) ----------------

	public override void OnKeyDownCapture(KeyEventArgs e)
	{
		switch (e.Key)
		{
		case .Down:
			MoveHighlight(1);
			e.Handled = true;
		case .Up:
			MoveHighlight(-1);
			e.Handled = true;
		case .Return, .KeypadEnter:
			ExecuteHighlighted().IgnoreError();
			e.Handled = true;
		default:
			// Escape: the dialog's own OnKeyDown closes it.
		}
	}

	private void Rebuild()
	{
		mRows.Clear();
		let contains = scope List<EditorActionDeclaration>();
		let elsewhere = scope List<EditorActionDeclaration>();
		for (let action in mActions.Actions)
		{
			if (action.Label.Contains(mFilter, true))
			{
				if (mFilter.IsEmpty || action.Label.StartsWith(mFilter, .OrdinalIgnoreCase))
					mRows.Add(action); // a label starting with the filter
				else
					contains.Add(action);
			}
			else if (action.Description.Contains(mFilter, true) || action.Id.Contains(mFilter, true))
			{
				elsewhere.Add(action);
			}
		}
		mRows.AddRange(contains);
		mRows.AddRange(elsewhere);
		mList.NotifyDataChanged();
		mStatus.SetText(mRows.IsEmpty ? "Nothing matches." : "");
		Highlight(0);
	}
}
