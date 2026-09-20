using System;
using System.Collections;
using Sedulous.UI;
using Sedulous.Pipeline.Importer;

namespace Sedulous.Editor.App;

/// The pre-import review for one file: dropping a file on the asset browser pops this up
/// when the routed importer has options. Shows the source file, the destination group, the
/// importer's resource plan when it provides one (a per-kind list with a check box and an
/// editable target name per resource), and one check box per option toggle, then Import or
/// Cancel. TakePlan hands the edited plan back to the caller, who stores it as the options'
/// selection so the importer's fan-out skips deselected resources and honours renames.
class ImportOptionsDialog : Dialog
{
	/// Fired when the user confirms; the options carry their check box edits. Owned.
	public delegate void() OnImport ~ delete _;
	/// Fired on Change... on the destination row; the caller pops a group chooser, then
	/// calls SetDestination. Owned.
	public delegate void() OnChangeDestination ~ delete _;

	/// Borrowed; the caller owns the options it will import with.
	private ImportOptions mOptions;
	/// Owned until TakePlan; edited in place.
	private ImportPlan mPlan ~ delete _;
	// Borrowed: the content owns them.
	private Label mDestinationText = null;
	private ImportPlanView mPlanView = null;

	/// Takes ownership of the plan.
	public this(StringView sourcePath, StringView destination, ImportOptions options, ImportPlan plan) : base("Import")
	{
		mOptions = options;
		mPlan = plan;
		let hasPlan = (mPlan != null) && !mPlan.IsEmpty;
		MaxWidth.Value = hasPlan ? 620.0f : 480.0f;
		MaxHeight.Value = hasPlan ? 700.0f : 420.0f;

		let column = new FlexLayout();
		column.Direction = .Vertical;
		column.Spacing = 6.0f;

		ImportDialogRows.AddInfoRow(column, "Source:", ImportPaths.FileNameOf(sourcePath));
		mDestinationText = ImportDialogRows.AddDestinationRow(column, destination, new () => { if (OnChangeDestination != null) OnChangeDestination(); });

		if (hasPlan)
		{
			mPlanView = new ImportPlanView(mPlan);
			let scroll = new ScrollView();
			scroll.VScrollBarPolicy.Value = .Auto;
			scroll.HScrollBarPolicy.Value = .Never;
			var match = LayoutStyle();
			match.Width = SizeSpec.Match();
			scroll.AddView(mPlanView, match);
			var grow = LayoutStyle();
			grow.Width = SizeSpec.Match();
			grow.FlexGrow = 1.0f;
			column.AddView(scroll, grow);
		}

		if (mOptions != null)
			ImportDialogRows.AddToggles(column, mOptions);

		SetContent(column);

		let import = AddButton("Import", .None);
		import.OnClick.Add(new (b) =>
			{
				if (OnImport != null)
					OnImport();
				Close(.OK);
			});
		AddButton("Cancel", .Cancel);
	}

	public ImportOptions Options => mOptions;

	/// The edited plan, the check boxes applied live and the names synced from their
	/// editors here. Once, on Import; the caller takes ownership.
	public ImportPlan TakePlan()
	{
		if (mPlanView != null)
			mPlanView.SyncNames();
		let plan = mPlan;
		mPlan = null;
		return plan;
	}

	/// Updates the shown destination after the caller's group chooser resolves.
	public void SetDestination(StringView destination)
	{
		if (mDestinationText != null)
			mDestinationText.SetText(destination);
	}
}
