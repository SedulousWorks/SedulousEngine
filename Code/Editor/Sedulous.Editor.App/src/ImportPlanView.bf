using System;
using System.Collections;
using Sedulous.UI;
using Sedulous.Pipeline.Importer;

namespace Sedulous.Editor.App;

/// The per-kind resource list of an import plan: a check-all header per kind, then one row
/// per resource with an enable check box and a target-name editor. Edits an external plan
/// in place: the check boxes are live, and SyncNames writes the editors back before the
/// plan is read, since the batch dialog switches files without tearing this down. The plan
/// and its entries must outlive the view.
class ImportPlanView : FlexLayout
{
	private static readonly ImportResourceKind[6] cKinds = .(.Mesh, .Material, .Texture, .Skeleton, .AnimationClip, .Collision);

	/// Borrowed; outlives the view.
	private ImportPlan mPlan;
	/// Parallel to the plan entries; borrowed, the rows own them.
	private List<EditText> mNameEditors = new .() ~ delete _;

	public this(ImportPlan plan)
	{
		mPlan = plan;
		Direction = .Vertical;
		Spacing = 2.0f;
		mNameEditors.Resize(plan.Entries.Count);
		for (let kind in cKinds)
		{
			let indices = new List<int>();
			for (int i < plan.Entries.Count)
			{
				if (plan.Entries[i].Kind == kind)
					indices.Add(i);
			}
			if (indices.IsEmpty)
			{
				delete indices;
				continue;
			}

			let rowChecks = new List<CheckBox>();
			let header = new CheckBox(kind.Label, true);
			header.FontSize.Value = 12.0f;
			AddView(header, RowStyle(24.0f));
			for (let i in indices)
			{
				let entry = plan.Entries[i];
				let row = new FlexLayout();
				row.Direction = .Horizontal;
				row.Spacing = 6.0f;
				let check = new CheckBox("", entry.Enabled);
				check.OnCheckedChanged.Add(new [=entry](c, on) => { entry.Enabled = on; });
				var checkStyle = LayoutStyle();
				checkStyle.Width = SizeSpec.Fixed(Unit.Dp(38.0f));
				checkStyle.Height = SizeSpec.Match();
				row.AddView(check, checkStyle);
				rowChecks.Add(check);
				let name = new EditText();
				name.SetText(entry.TargetName);
				var grow = LayoutStyle();
				grow.FlexGrow = 1.0f;
				grow.Height = SizeSpec.Match();
				row.AddView(name, grow);
				mNameEditors[i] = name;
				AddView(row, RowStyle(24.0f));
			}
			header.OnCheckedChanged.Add(new [=indices, =rowChecks, =plan](c, on) =>
				{
					for (let i in indices)
						plan.Entries[i].Enabled = on;
					for (let rowCheck in rowChecks)
						rowCheck.IsChecked.Value = on;
				} ~ { delete indices; delete rowChecks; });
		}
	}

	/// Writes the name editors' current text back into the plan entries.
	public void SyncNames()
	{
		for (int i = 0; (i < mNameEditors.Count) && (i < mPlan.Entries.Count); i++)
		{
			let editor = mNameEditors[i];
			if ((editor != null) && !editor.Text.IsEmpty)
				mPlan.Entries[i].TargetName.Set(editor.Text);
		}
	}

	private static LayoutStyle RowStyle(float height)
	{
		var style = LayoutStyle();
		style.Width = SizeSpec.Match();
		style.Height = SizeSpec.Fixed(Unit.Dp(height));
		return style;
	}
}
