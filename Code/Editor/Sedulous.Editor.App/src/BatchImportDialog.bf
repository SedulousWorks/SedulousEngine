using System;
using System.Collections;
using Sedulous.UI;
using Sedulous.Pipeline.Importer;

namespace Sedulous.Editor.App;

/// One review session for a whole drop: one dialog per drop, always. Left, the source files
/// with an enable check box, the name, and an importer dropdown where more than one importer
/// claims the extension. Right, the selected file's resource plan and option toggles.
/// Worker-prepared plans stream in through OnFilePrepared; Import stays disabled until every
/// enabled file is described. The caller reads Files back on OnImport and commits each
/// enabled entry.
class BatchImportDialog : Dialog
{
	/// Read Files for the final decisions. Owned.
	public delegate void() OnImport ~ delete _;
	/// Owned.
	public delegate void() OnChangeDestination ~ delete _;
	/// (Re)describes one entry; the owner owns the describe policy, inline for light
	/// importers, the worker path landing through OnFilePrepared instead. Owned.
	public delegate void(BatchImportFile file) DescribeFile ~ delete _;

	private List<BatchImportFile> mFiles ~ DeleteContainerAndItems!(_);
	private int mSelected = 0;
	// Borrowed: the content owns them.
	private Label mDestinationText = null;
	private FlexLayout mDetail = null;
	/// The selected file's plan view.
	private ImportPlanView mPlanView = null;
	/// Parallel to mFiles, for the selection highlight.
	private List<BatchFileRow> mFileRows = new .() ~ delete _;
	private Button mImportButton = null;

	/// Takes ownership of the file list.
	public this(StringView destination, List<BatchImportFile> files) : base("Import Files")
	{
		mFiles = files;
		MaxWidth.Value = 860.0f;
		MaxHeight.Value = 700.0f;

		let column = new FlexLayout();
		column.Direction = .Vertical;
		column.Spacing = 6.0f;

		// The destination row, shared by the whole batch.
		mDestinationText = ImportDialogRows.AddDestinationRow(column, destination, new () => { if (OnChangeDestination != null) OnChangeDestination(); });

		// The split: the file list left, the per-file detail right.
		let split = new FlexLayout();
		split.Direction = .Horizontal;
		split.Spacing = 8.0f;
		BuildFileList(split);
		mDetail = new FlexLayout();
		mDetail.Direction = .Vertical;
		mDetail.Spacing = 4.0f;
		{
			let scroll = new ScrollView();
			scroll.VScrollBarPolicy.Value = .Auto;
			scroll.HScrollBarPolicy.Value = .Never;
			var match = LayoutStyle();
			match.Width = SizeSpec.Match();
			scroll.AddView(mDetail, match);
			var grow = LayoutStyle();
			grow.FlexGrow = 1.0f;
			grow.Height = SizeSpec.Match();
			split.AddView(scroll, grow);
		}
		var fill = LayoutStyle();
		fill.Width = SizeSpec.Match();
		fill.FlexGrow = 1.0f;
		column.AddView(split, fill);
		SetContent(column);

		mImportButton = AddButton("Import", .None);
		mImportButton.OnClick.Add(new (b) =>
			{
				SyncSelectedNames();
				if (OnImport != null)
					OnImport();
				Close(.OK);
			});
		AddButton("Cancel", .Cancel);

		RebuildDetail();
		SyncImportEnabled();
	}

	public List<BatchImportFile> Files => mFiles;

	public void SetDestination(StringView destination)
	{
		if (mDestinationText != null)
			mDestinationText.SetText(destination);
	}

	/// A worker prepare landed for the index; the owner filled Prepared, Plan and Described.
	/// Refreshes the detail, if that file is selected, and the Import gate.
	public void OnFilePrepared(int index)
	{
		if (index == mSelected)
			QueueRebuildDetail();
		SyncImportEnabled();
	}

	private void BuildFileList(FlexLayout split)
	{
		let list = new FlexLayout();
		list.Direction = .Vertical;
		list.Spacing = 2.0f;
		for (int i < mFiles.Count)
		{
			let entry = mFiles[i];
			let row = new BatchFileRow();
			row.OnSelect = new [=i, =this]() => { SelectFile(i); };
			row.SetSelected(i == mSelected);
			mFileRows.Add(row);
			let check = new CheckBox("", entry.Enabled);
			check.OnCheckedChanged.Add(new [=entry, =this](c, on) =>
				{
					entry.Enabled = on;
					SyncImportEnabled();
				});
			var checkStyle = LayoutStyle();
			checkStyle.Width = SizeSpec.Fixed(Unit.Dp(30.0f));
			checkStyle.Height = SizeSpec.Match();
			row.AddView(check, checkStyle);
			let name = new Label(ImportPaths.FileNameOf(entry.Path));
			name.FontSize.Value = 12.0f;
			name.Ellipsis.Value = true;
			var grow = LayoutStyle();
			grow.FlexGrow = 1.0f;
			grow.Height = SizeSpec.Match();
			row.AddView(name, grow);
			if (entry.Candidates.Count > 1)
			{
				// Several importers claim the extension: the per-row dropdown replaces the
				// old modal-per-file chooser.
				let combo = new ComboBox();
				for (let importer in entry.Candidates)
					combo.AddItem(importer.Label);
				combo.SetSelectedIndex((int32)entry.ImporterIndex);
				combo.OnSelectionChanged.Add(new [=i, =this](c, index) => { ChangeImporter(i, Math.Max(0, index)); });
				var comboStyle = LayoutStyle();
				comboStyle.Width = SizeSpec.Fixed(Unit.Dp(110.0f));
				comboStyle.Height = SizeSpec.Match();
				row.AddView(combo, comboStyle);
			}
			list.AddView(row, ImportDialogRows.RowStyle(26.0f));
		}
		let scroll = new ScrollView();
		scroll.VScrollBarPolicy.Value = .Auto;
		scroll.HScrollBarPolicy.Value = .Never;
		var match = LayoutStyle();
		match.Width = SizeSpec.Match();
		scroll.AddView(list, match);
		var side = LayoutStyle();
		side.Width = SizeSpec.Fixed(Unit.Dp(300.0f));
		side.Height = SizeSpec.Match();
		split.AddView(scroll, side);
	}

	private void SelectFile(int index)
	{
		if ((index == mSelected) || (index >= mFiles.Count))
			return;
		SyncSelectedNames(); // this file's rename edits survive the switch
		if (mSelected < mFileRows.Count)
			mFileRows[mSelected].SetSelected(false);
		mSelected = index;
		if (mSelected < mFileRows.Count)
			mFileRows[mSelected].SetSelected(true);
		QueueRebuildDetail();
	}

	private void ChangeImporter(int fileIndex, int importerIndex)
	{
		let entry = mFiles[fileIndex];
		if ((importerIndex >= entry.Candidates.Count) || (importerIndex == entry.ImporterIndex))
			return;
		entry.ImporterIndex = importerIndex;
		delete entry.Options;
		entry.Options = entry.Candidates[importerIndex].CreateOptions();
		if (entry.Options == null)
			entry.Options = new ImportOptions(); // a bare selection carrier; option-less importers still honour renames
		DeleteAndNullify!(entry.Prepared); // payloads are importer-specific
		delete entry.Plan;
		entry.Plan = new ImportPlan();
		entry.Described = false;
		if (DescribeFile != null)
			DescribeFile(entry);
		if (fileIndex == mSelected)
			QueueRebuildDetail();
		SyncImportEnabled();
	}

	/// Detail rebuilds destroy views: never inline from a click handler.
	private void QueueRebuildDetail()
	{
		if (Context == null)
		{
			RebuildDetail();
			return;
		}
		AddRef();
		Context.MutationQueue.QueueAction(new () =>
			{
				RebuildDetail();
				ReleaseRef();
			});
	}

	private void RebuildDetail()
	{
		mDetail.RemoveAllViews();
		mPlanView = null;
		if (mSelected >= mFiles.Count)
			return;
		let entry = mFiles[mSelected];

		let title = new Label(ImportPaths.FileNameOf(entry.Path));
		title.FontSize.Value = 13.0f;
		mDetail.AddView(title, ImportDialogRows.RowStyle(22.0f));

		if (!entry.Described)
		{
			let reading = new Label("Reading file...");
			reading.FontSize.Value = 12.0f;
			mDetail.AddView(reading, ImportDialogRows.RowStyle(22.0f));
			return;
		}

		if (!entry.Plan.IsEmpty)
		{
			mPlanView = new ImportPlanView(entry.Plan);
			var match = LayoutStyle();
			match.Width = SizeSpec.Match();
			mDetail.AddView(mPlanView, match);
		}
		if (entry.Options != null)
			ImportDialogRows.AddToggles(mDetail, entry.Options);
	}

	private void SyncSelectedNames()
	{
		if (mPlanView != null)
			mPlanView.SyncNames();
	}

	/// Import waits for every enabled file to be described, as worker prepares stream in.
	private void SyncImportEnabled()
	{
		if (mImportButton == null)
			return;
		bool ready = true;
		for (let f in mFiles)
			ready = ready && (!f.Enabled || f.Described);
		mImportButton.IsEnabled = ready;
		mImportButton.Invalidate();
	}
}
