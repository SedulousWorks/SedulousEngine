using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.GUI;

namespace Sedulous.Editor.Scene;

// The physics block's collision groups as a grid (Raptor's editor-gui spec, 5.6: the user's ruling,
// the old editor's matrix): a row per group and a column per group, the column headers the groups'
// numbers (each named in its tooltip), the rows the numbers and names, and a check box where row and
// column meet on and below the diagonal, so each pair has one: whether the two collide. A click is
// the pair's write through the groups' source (both ways, one undo step). The grid's row for it is
// the source's `matrix` (hinted "CollisionMatrix"), beside its `groups` list, whose rows give each
// group's name; it reads the masks from the list's rows.

class CollisionMatrixEditor : PropertyEditor
{
	public const String cHint = "CollisionMatrix";
	public const float cCell = 20.0f;
	public const float cNameWidth = 120.0f;

	/// The groups, as last built.
	private List<String> mNames = new .() ~ DeleteContainerAndItems!(_);
	/// Its children's (each row's holds them), row by row, the lower triangle.
	private List<CheckBox> mBoxes = new .() ~ delete _;
	/// Showing the masks, not the user's click.
	private bool mBinding = false;

	public this()
	{
		AddClass("collision-matrix");
		using (StyleWriteScope(this))
		{
			EditLayoutStyle(scope (s) =>
				{
					s.Direction = .Column;
					s.RowGap = 2.0f;
				});
		}
	}

	public static void Register(PropertyEditorRegistry registry)
	{
		registry.RegisterHint(cHint, new () => new CollisionMatrixEditor(), true);
	}

	/// How many groups it shows.
	public int Count => mNames.Count;

	/// The box for the pair (`row`, `column`), `column` <= `row`; null: none.
	public CheckBox Box(int row, int column)
	{
		if ((column > row) || (row >= mNames.Count))
			return null;
		return mBoxes[row * (row + 1) / 2 + column];
	}

	protected override void OnBind(PropertyInfo info, PropertyValue value)
	{
		let count = (int)Math.Max(value.Value.AsInt, 0);
		let names = scope List<String>();
		defer { ClearAndDeleteItems!(names); }
		for (int i < count)
		{
			var read = Read(scope $"{i}.name", .String);
			names.Add(new String(read.Value.AsString));
			read.Dispose();
		}
		var same = names.Count == mNames.Count;
		for (int i = 0; same && (i < names.Count); i++)
			same = names[i] == mNames[i];
		if (!same)
			Build(names);
		// Each box as its pair is now (a row's mask, as the source keeps it both ways).
		mBinding = true;
		defer { mBinding = false; }
		for (int row < count)
		{
			var read = Read(scope $"{row}.collides", .Flags);
			let mask = (uint64)read.Value.AsInt;
			read.Dispose();
			for (int column = 0; column <= row; column++)
			{
				if (let @box = Box(row, column))
				{
					let on = (mask & (1UL << column)) != 0;
					if (@box.Checked != on)
						@box.Checked = on;
					@box.Enabled = !IsReadOnly;
				}
			}
		}
	}

	// The groups list's path beside its own: "…/matrix" reads "…/groups.<i>.<row>".
	private void GroupPath(StringView rest, String outPath)
	{
		let own = Path;
		let slash = own.LastIndexOf('/');
		if (slash >= 0)
			outPath.Append(own.Substring(0, slash + 1));
		outPath.AppendF("groups.{}", rest);
	}

	private PropertyValue Read(StringView rest, PropertyKind kind)
	{
		if (Host == null)
			return .();
		return Host.ReadPropertyValue(GroupPath(rest, .. scope .()), kind);
	}

	// The pair's write, through the row's `collides` (the source writes both ways).
	private void Write(int row, int column, bool collides)
	{
		if (mBinding || (Host == null) || IsReadOnly)
			return;
		let path = GroupPath(scope $"{row}.collides", .. scope .());
		var write = PropertyWrite(Sedulous.GUI.Variant((int64)(collides ? (1UL << column) : 0)));
		write.Mask = 1UL << column;
		Host.BeginPropertyEdit(path);
		Host.CommitPropertyEdit(path, write);
	}

	private static void Cell(UIWidget widget, float width)
	{
		widget.EditLayoutStyle(scope (s) =>
			{
				s.Width = LayoutLength.Px(width);
				s.Shrink = 0.0f;
			});
	}

	// A line of the grid, added.
	private UIWidget AddLine()
	{
		let line = new UIWidget();
		line.AddClass("collision-matrix-row");
		line.EditLayoutStyle(scope (s) =>
			{
				s.Direction = .Row;
				s.AlignItems = .Center;
				s.Height = LayoutLength.Px(cCell);
			});
		AddChild(line);
		line.ReleaseRef(); // the editor's keeps it
		return line;
	}

	// The headers and a row a group, a box at each pair on and below the diagonal.
	private void Build(List<String> names)
	{
		while (ChildCount > 0)
			RemoveChild(GetChildAt(ChildCount - 1));
		mBoxes.Clear();
		ClearAndDeleteItems!(mNames);
		for (let name in names)
			mNames.Add(new String(name));
		let count = mNames.Count;

		let header = AddLine();
		let corner = new Label();
		Cell(corner, cNameWidth);
		header.AddChild(corner);
		corner.ReleaseRef();
		for (int column < count)
		{
			let number = new Label();
			number.AddClass("collision-matrix-column");
			number.Text = scope $"{column}";
			number.Tooltip = mNames[column];
			Cell(number, cCell);
			header.AddChild(number);
			number.ReleaseRef();
		}
		for (int r < count)
		{
			let line = AddLine();
			let name = new Label();
			name.AddClass("collision-matrix-name");
			name.Text = scope $"{r} {mNames[r]}";
			Cell(name, cNameWidth);
			line.AddChild(name);
			name.ReleaseRef();
			for (int column = 0; column <= r; column++)
			{
				let @box = new CheckBox();
				@box.Tooltip = scope $"{mNames[r]} and {mNames[column]} collide";
				@box.SetOnToggled(new [=this, =r, =column] (on) => { Write(r, column, on); });
				Cell(@box, cCell);
				line.AddChild(@box);
				mBoxes.Add(@box);
				@box.ReleaseRef(); // its line's keeps it
			}
		}
	}
}
