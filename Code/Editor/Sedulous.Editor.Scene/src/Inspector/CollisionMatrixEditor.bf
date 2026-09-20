using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Physics;

namespace Sedulous.Editor.Scene;

/// The physics collision matrix as a property row: a name column, one narrow column per
/// group with its name rotated into the header, a check box per pair, remove on the last
/// group and an add button while there is room.
class CollisionMatrixEditor : PropertyEditor
{
	/// The display names, indexed by group, and the parallel collide masks.
	public List<String> Names = new .() ~ DeleteContainerAndItems!(_);
	public List<uint32> Matrix = new .() ~ delete _;
	/// The names as last built, so an edit box only commits a real change.
	public List<String> CommittedNames = new .() ~ DeleteContainerAndItems!(_);

	public delegate void(int index, StringView name) OnRename ~ delete _;
	/// (row group, column group).
	public delegate void(int i, int j) OnToggle ~ delete _;
	public delegate void() OnAddGroup ~ delete _;
	/// Only the last group is offered.
	public delegate void(int index) OnRemoveGroup ~ delete _;

	private FlexLayout mColumn = null;

	public this(StringView name, StringView category) : base(name, category) {}

	public override void RefreshView() {}

	protected override View CreateEditorView()
	{
		mColumn = new FlexLayout();
		mColumn.Direction = .Vertical;
		mColumn.Spacing = 2.0f;
		BuildGrid(mColumn);
		return mColumn;
	}

	/// Repopulates the grid, deferred through the context's mutation queue when there is
	/// one, since a rebuild from inside a click handler would tear down the clicked view.
	public void RequestRebuild()
	{
		if (mColumn == null)
			return;
		delegate void() rebuild = new [=this]() =>
		{
			mColumn.RemoveAllViews();
			BuildGrid(mColumn);
			mColumn.Invalidate();
		};
		if (let ctx = mColumn.Context)
		{
			ctx.MutationQueue.QueueAction(rebuild);
		}
		else
		{
			rebuild();
			delete rebuild;
		}
	}

	private void BuildGrid(FlexLayout column)
	{
		let count = Names.Count;
		ClearAndDeleteItems(CommittedNames);
		for (let n in Names)
			CommittedNames.Add(new String(n));

		const float cNameColW = 104.0f; // the left name column
		const float cCellW = 26.0f; // each group column, narrow under a vertical header
		const float cRowH = 22.0f;
		const float cHeaderH = 88.0f; // room for the rotated names
		const float cQuarterTurn = -1.5707963f; // -90 degrees: header names read bottom to top

		{
			let header = new FlexLayout();
			header.Direction = .Horizontal;
			header.Spacing = 2.0f;
			header.AddView(new Label(""), FixedCell(cNameColW));
			for (int j < count)
			{
				let slot = CenteredSlot();
				let head = new Label(Names[j]);
				head.FontSize.Value = 11.0f;
				head.TooltipText.Set(Names[j]);
				head.Transform.Rotation = cQuarterTurn;
				head.Transform.Origin = .(0.5f, 0.5f);
				slot.AddView(head);
				header.AddView(slot, FixedCell(cCellW));
			}
			var lp = LayoutStyle();
			lp.Width = SizeSpec.Match();
			lp.Height = SizeSpec.Fixed(Unit.Dp(cHeaderH));
			column.AddView(header, lp);
		}

		for (int i < count)
		{
			let row = new FlexLayout();
			row.Direction = .Horizontal;
			row.Spacing = 2.0f;

			let name = new EditText();
			name.SetText(Names[i]);
			name.OnSubmit.Add(new [=this, =i, =name](e) =>
			{
				if (OnRename != null)
					OnRename(i, name.Text);
			});
			name.OnEditingFinished.Add(new [=this, =i, =name](e) =>
			{
				if ((i >= CommittedNames.Count) || (OnRename == null))
					return;
				if (name.Text != CommittedNames[i])
					OnRename(i, name.Text);
			});
			row.AddView(name, FixedCell(cNameColW));

			for (int j < count)
			{
				let collides = (i < Matrix.Count) && ((Matrix[i] & (1u << j)) != 0);
				let slot = CenteredSlot();
				let check = new CheckBox("", collides);
				check.TooltipText.Set(scope $"{Names[i]} vs {Names[j]}");
				check.OnCheckedChanged.Add(new [=this, =i, =j](b, on) =>
				{
					if (OnToggle != null)
						OnToggle(i, j);
				});
				slot.AddView(check);
				row.AddView(slot, FixedCell(cCellW));
			}

			if ((i + 1 == count) && (count > 1))
			{
				let del = new Button("x");
				del.FontSize.Value = 12.0f;
				del.TooltipText.Set("Remove this group (the last one)");
				del.OnClick.Add(new [=this, =i](b) =>
				{
					if (OnRemoveGroup != null)
						OnRemoveGroup(i);
				});
				row.AddView(del, FixedCell(20.0f));
			}

			var lp = LayoutStyle();
			lp.Width = SizeSpec.Match();
			lp.Height = SizeSpec.Fixed(Unit.Dp(cRowH));
			column.AddView(row, lp);
		}

		if (count < PhysicsWorldSettings.CollisionGroupCount)
		{
			let add = new Button("+ Add Group");
			add.FontSize.Value = 12.0f;
			add.OnClick.Add(new [=this](b) =>
			{
				if (OnAddGroup != null)
					OnAddGroup();
			});
			var lp = LayoutStyle();
			lp.Width = SizeSpec.Match();
			lp.Height = SizeSpec.Fixed(Unit.Dp(cRowH));
			column.AddView(add, lp);
		}
	}

	private static LayoutStyle FixedCell(float width)
	{
		var lp = LayoutStyle();
		lp.Width = SizeSpec.Fixed(Unit.Dp(width));
		return lp;
	}

	private static FlexLayout CenteredSlot()
	{
		let slot = new FlexLayout();
		slot.Direction = .Horizontal;
		slot.JustifyContent = .Center;
		slot.AlignItems = .Center;
		return slot;
	}
}
