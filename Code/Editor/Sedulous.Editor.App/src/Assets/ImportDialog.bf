namespace Sedulous.Editor.App;

using System;
using System.Collections;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Core.Mathematics;
using Sedulous.Editor.Core;
using Sedulous.Resources;
using Sedulous.Serialization;
using Sedulous.VFS;
using System.IO;

/// Modal dialog for asset import.
/// Shows a preview of items to be imported with checkboxes, output location,
/// and Import/Cancel buttons.
///
/// Usage:
///   let dialog = new ImportDialog(preview, importer, mount, baseLocator,
///                                 index, uriPrefix, indexLocator, serializer, panel);
///   dialog.Show(ctx);
///   // Dialog owns itself - deleted on close via PopupLayer.
class ImportDialog : Dialog
{
	private ImportPreview mPreview ~ delete _;
	private IAssetImporter mImporter;
	private IWritableMount mMount;
	private String mBaseLocator = new .() ~ delete _;
	private IResourceIndex mIndex;
	private String mUriPrefix = new .() ~ delete _;
	private String mIndexLocator = new .() ~ delete _; // locator the index is persisted to
	private ISerializerProvider mSerializer;
	private AssetBrowserPanel mPanel;
	private Sedulous.Core.Logging.Abstractions.ILogger mLogger;
	private Sedulous.Editor.Core.EditorContext mEditorContext;

	// Item checkboxes (parallel to mPreview.Items)
	private List<CheckBox> mItemChecks = new .() ~ delete _;

	// Inline warning label for duplicate (Name, Extension) pairs across
	// selected items. Refreshed after each EditableLabel commit; visible
	// only when at least one duplicate exists. The Import button stays
	// enabled regardless (per the "allow + warn" UX), but a final log
	// warning fires in ExecuteImport so the issue is captured for the
	// post-import session record.
	private Label mDupWarningLabel;

	public this(ImportPreview preview, IAssetImporter importer,
		IWritableMount mount, StringView baseLocator,
		IResourceIndex index, StringView uriPrefix, StringView indexLocator,
		ISerializerProvider serializer, AssetBrowserPanel panel,
		Sedulous.Core.Logging.Abstractions.ILogger logger = null,
		Sedulous.Editor.Core.EditorContext editorContext = null)
		: base("Import Assets")
	{
		mPreview = preview;
		mImporter = importer;
		mMount = mount;
		mBaseLocator.Set(baseLocator);
		mIndex = index;
		mUriPrefix.Set(uriPrefix);
		mIndexLocator.Set(indexLocator);
		mSerializer = serializer;
		mPanel = panel;
		mLogger = logger;
		mEditorContext = editorContext;

		MaxWidth = 550;
		MaxHeight = 500;

		BuildContent();

		AddButton("Import", .OK);
		AddButton("Cancel", .Cancel);

		OnClosed.Add(new (dialog, result) => {
			if (result == .OK)
				ExecuteImport();
		});
	}

	private void BuildContent()
	{
		let content = new FlexLayout();
		content.Direction = .Vertical;
		content.Spacing = 6;

		// Source file path
		let sourceRow = new FlexLayout();
		sourceRow.Direction = .Horizontal;
		sourceRow.Spacing = 6;

		let sourceLabel = new Label();
		sourceLabel.SetText("Source:");
		sourceLabel.FontSize = 11;
		sourceLabel.TextColor = .(140, 145, 165, 255);
		sourceRow.AddView(sourceLabel, new FlexLayout.LayoutParams() { Width = .Fixed(.Px(50)), Height = .Match });

		let sourcePath = new Label();
		sourcePath.SetText(mPreview.SourcePath);
		sourcePath.FontSize = 11;
		sourcePath.Ellipsis = true;
		sourceRow.AddView(sourcePath, new FlexLayout.LayoutParams() { Height = .Match, Grow = 1 });

		content.AddView(sourceRow, new FlexLayout.LayoutParams() { Width = .Match, Height = .Fixed(.Px(18)) });

		// Output directory
		let outputRow = new FlexLayout();
		outputRow.Direction = .Horizontal;
		outputRow.Spacing = 6;

		let outputLabel = new Label();
		outputLabel.SetText("Output:");
		outputLabel.FontSize = 11;
		outputLabel.TextColor = .(140, 145, 165, 255);
		outputRow.AddView(outputLabel, new FlexLayout.LayoutParams() { Width = .Fixed(.Px(50)), Height = .Match });

		let outputPath = new Label();
		// mUriPrefix is constructed as "{scheme}://{baseLocator}" by the
		// caller (AssetBrowserBuilder), so it already includes the folder.
		// Don't append mBaseLocator again - that would double-count and
		// show "project://Fox/Fox/" when saving to "project://Fox/".
		outputPath.SetText(mUriPrefix);
		outputPath.FontSize = 11;
		outputPath.Ellipsis = true;
		outputRow.AddView(outputPath, new FlexLayout.LayoutParams() { Height = .Match, Grow = 1 });

		content.AddView(outputRow, new FlexLayout.LayoutParams() { Width = .Match, Height = .Fixed(.Px(18)) });

		// Separator
		let sep = new Panel();
		sep.Background = new ColorDrawable(.(60, 65, 80, 255));
		content.AddView(sep, new FlexLayout.LayoutParams() { Width = .Match, Height = .Fixed(.Px(1)) });

		// Import options (importer-specific)
		BuildOptionsUI(content);

		// Items header
		let headerRow = new FlexLayout();
		headerRow.Direction = .Horizontal;
		headerRow.Spacing = 6;

		let selectAllCheck = new CheckBox("Select All", true);
		selectAllCheck.FontSize = 11;
		selectAllCheck.OnCheckedChanged.Add(new (cb, val) => {
			for (let check in mItemChecks)
				check.IsChecked = val;
			RefreshDupWarning();
		});
		headerRow.AddView(selectAllCheck, new FlexLayout.LayoutParams() { Width = .Wrap, Height = .Match });

		let countLabel = new Label();
		let countText = scope String();
		countText.AppendF("{} items", mPreview.Items.Count);
		countLabel.SetText(countText);
		countLabel.FontSize = 10;
		countLabel.TextColor = .(120, 125, 140, 255);
		countLabel.HAlign = .Right;
		headerRow.AddView(countLabel, new FlexLayout.LayoutParams() { Height = .Match, Grow = 1 });

		content.AddView(headerRow, new FlexLayout.LayoutParams() { Width = .Match, Height = .Fixed(.Px(22)) });

		// Duplicate-name warning - hidden until a dup exists. Sits between
		// the items header and the list so it's adjacent to what the user
		// is editing.
		mDupWarningLabel = new Label();
		mDupWarningLabel.FontSize = 10;
		mDupWarningLabel.TextColor = .(230, 170, 80, 255);
		mDupWarningLabel.Visibility = .Gone;
		content.AddView(mDupWarningLabel, new FlexLayout.LayoutParams() { Width = .Match, Height = .Wrap });

		// Item list (scrollable)
		let itemList = new FlexLayout();
		itemList.Direction = .Vertical;
		itemList.Spacing = 2;

		for (let item in mPreview.Items)
		{
			let itemRow = new FlexLayout();
			itemRow.Direction = .Horizontal;
			itemRow.Spacing = 8;

			let check = new CheckBox();
			check.IsChecked = item.Selected;
			check.OnCheckedChanged.Add(new (cb, val) => { RefreshDupWarning(); });
			mItemChecks.Add(check);
			itemRow.AddView(check, new FlexLayout.LayoutParams() { Width = .Fixed(.Px(20)), Height = .Match });

			// Type label. Ellipsis-truncate if the importer hands us a label
			// that's longer than the 90px column (e.g., audio importer
			// stuffs sample-rate / channel / duration into TypeLabel).
			let typeLabel = new Label();
			typeLabel.SetText(item.TypeLabel);
			typeLabel.FontSize = 10;
			typeLabel.TextColor = .(140, 160, 200, 255);
			typeLabel.Ellipsis = true;
			itemRow.AddView(typeLabel, new FlexLayout.LayoutParams() { Width = .Fixed(.Px(90)), Height = .Match });

			// Editable name (slow-click or double-click to rename) + read-only
			// extension. Stash OriginalName at preview-build time so the
			// importer can find this resource by its source-authored name
			// post-conversion. The user is free to edit Name without losing
			// the link to the converted resource.
			if (item.OriginalName == null)
			{
				item.OriginalName = new String();
				item.OriginalName.Set(item.Name);
			}

			let nameField = new EditableLabel();
			nameField.SetText(item.Name);
			nameField.FontSize = 11;
			nameField.Ellipsis = true;
			let capturedItem = item;
			nameField.OnRenameCommitted.Add(new (label, newName) => {
				capturedItem.Name.Set(newName);
				RefreshDupWarning();
			});
			itemRow.AddView(nameField, new FlexLayout.LayoutParams() { Height = .Match, Grow = 1 });

			let extLabel = new Label();
			extLabel.SetText(item.Extension);
			extLabel.FontSize = 11;
			extLabel.TextColor = .(140, 145, 165, 255);
			itemRow.AddView(extLabel, new FlexLayout.LayoutParams() { Width = .Wrap, Height = .Match });

			itemList.AddView(itemRow, new FlexLayout.LayoutParams() { Width = .Match, Height = .Fixed(.Px(22)) });
		}

		// Wrap item list in a ScrollView for many items
		let scrollView = new ScrollView();
		scrollView.AddView(itemList, new LayoutParams() { Width = .Match, Height = .Wrap });
		content.AddView(scrollView, new FlexLayout.LayoutParams() { Width = .Match, Grow = 1 });

		SetContent(content);

		// In case the source data has natural duplicates before the user
		// has edited anything, show the warning immediately.
		RefreshDupWarning();
	}

	/// Walks the selected preview items and flags duplicate (Name, Extension)
	/// pairs in the inline warning label. Called after every EditableLabel
	/// commit and once at dialog build time.
	private void RefreshDupWarning()
	{
		if (mDupWarningLabel == null) return;

		// Count occurrences of each (Name, Extension) pair among selected
		// items. Selection check matches mItemChecks position-by-position
		// against mPreview.Items.
		let counts = scope Dictionary<String, int>();
		defer { for (let kv in counts) delete kv.key; }

		for (int i = 0; i < mPreview.Items.Count; i++)
		{
			if (i < mItemChecks.Count && !mItemChecks[i].IsChecked) continue;
			let item = mPreview.Items[i];
			let key = new String();
			key.AppendF("{}{}", item.Name, item.Extension);
			if (counts.TryGetValue(key, let prev))
			{
				counts[key] = prev + 1;
				delete key;
			}
			else
			{
				counts[key] = 1;
			}
		}

		let conflicts = scope List<String>();
		for (let kv in counts)
		{
			if (kv.value > 1)
				conflicts.Add(kv.key);
		}

		if (conflicts.Count == 0)
		{
			mDupWarningLabel.Visibility = .Gone;
			return;
		}

		let msg = scope String();
		msg.AppendF("⚠ {} duplicate name(s) — importing will overwrite: ", conflicts.Count);
		for (int i = 0; i < conflicts.Count; i++)
		{
			if (i > 0) msg.Append(", ");
			msg.Append(conflicts[i]);
		}
		mDupWarningLabel.SetText(msg);
		mDupWarningLabel.Visibility = .Visible;
	}

	/// Builds importer-specific options UI if the preview has options.
	private void BuildOptionsUI(FlexLayout content)
	{
		if (let texOptions = mPreview.Options as TextureImportOptions)
		{
			let optionsRow = new FlexLayout();
			optionsRow.Direction = .Horizontal;
			optionsRow.Spacing = 6;

			let presetLabel = new Label();
			presetLabel.SetText("Preset:");
			presetLabel.FontSize = 11;
			presetLabel.TextColor = .(140, 145, 165, 255);
			optionsRow.AddView(presetLabel, new FlexLayout.LayoutParams() { Width = .Fixed(.Px(50)), Height = .Match });

			let combo = new ComboBox();
			combo.AddItem("3D Texture");
			combo.AddItem("Sprite");
			combo.AddItem("UI");
			combo.AddItem("Equirectangular Sky");

			int cubemapIndex = -1;
			if (texOptions.CubemapDetected)
			{
				cubemapIndex = combo.AddItem("Cubemap Sky");
			}

			// Set initial selection from options
			switch (texOptions.Preset)
			{
			case .Texture3D:         combo.SelectedIndex = 0;
			case .Sprite:            combo.SelectedIndex = 1;
			case .UI:                combo.SelectedIndex = 2;
			case .EquirectangularSky: combo.SelectedIndex = 3;
			case .CubemapSky:        combo.SelectedIndex = (cubemapIndex >= 0) ? cubemapIndex : 3;
			}

			combo.OnSelectionChanged.Add(new [=texOptions, =cubemapIndex] (cb, idx) => {
				switch (idx)
				{
				case 0: texOptions.Preset = .Texture3D;
				case 1: texOptions.Preset = .Sprite;
				case 2: texOptions.Preset = .UI;
				case 3: texOptions.Preset = .EquirectangularSky;
				default:
					if (idx == cubemapIndex)
						texOptions.Preset = .CubemapSky;
				}
			});

			optionsRow.AddView(combo, new FlexLayout.LayoutParams() { Grow = 1, Height = .Match });

			content.AddView(optionsRow, new FlexLayout.LayoutParams() { Width = .Match, Height = .Fixed(.Px(24)) });

			// Separator after options
			let optSep = new Panel();
			optSep.Background = new ColorDrawable(.(60, 65, 80, 255));
			content.AddView(optSep, new FlexLayout.LayoutParams() { Width = .Match, Height = .Fixed(.Px(1)) });
		}

		if (let modelOptions = mPreview.Options as ModelImportDialogOptions)
		{
			let skelRow = new FlexLayout();
			skelRow.Direction = .Horizontal;
			skelRow.Spacing = 6;

			let skelLabel = new Label();
			skelLabel.SetText("Skeleton:");
			skelLabel.FontSize = 11;
			skelLabel.TextColor = .(140, 145, 165, 255);
			skelRow.AddView(skelLabel, new FlexLayout.LayoutParams() { Width = .Fixed(.Px(60)), Height = .Match });

			let skelPathLabel = new Label();
			skelPathLabel.SetText("(none)");
			skelPathLabel.FontSize = 11;
			skelPathLabel.Ellipsis = true;
			skelRow.AddView(skelPathLabel, new FlexLayout.LayoutParams() { Height = .Match, Grow = 1 });

			let browseBtn = new Button("...");
			browseBtn.FontSize = 10;
			let editorCtx = mEditorContext;
			browseBtn.OnClick.Add(new [=modelOptions, =skelPathLabel, =editorCtx] (btn) => {
				if (editorCtx != null)
				{
					let ctx = skelPathLabel.Context;
					if (ctx == null) return;
					let picker = new AssetPickerDialog(editorCtx, ".skeleton",
						new [=modelOptions, =skelPathLabel] (protocolPath, guid) => {
							skelPathLabel.SetText(protocolPath);
							modelOptions.SkeletonRef.Dispose();
							modelOptions.SkeletonRef = ResourceRef(guid, protocolPath);
						});
					picker.Show(ctx);
				}
			});
			skelRow.AddView(browseBtn, new FlexLayout.LayoutParams() { Width = .Fixed(.Px(30)), Height = .Match });

			let clearBtn = new Button("X");
			clearBtn.FontSize = 10;
			clearBtn.OnClick.Add(new [=modelOptions, =skelPathLabel] (btn) => {
				skelPathLabel.SetText("(none)");
				modelOptions.SkeletonRef.Dispose();
				modelOptions.SkeletonRef = ResourceRef();
			});
			skelRow.AddView(clearBtn, new FlexLayout.LayoutParams() { Width = .Fixed(.Px(22)), Height = .Match });

			content.AddView(skelRow, new FlexLayout.LayoutParams() { Width = .Match, Height = .Fixed(.Px(24)) });

			// Separator after model options
			let modelSep = new Panel();
			modelSep.Background = new ColorDrawable(.(60, 65, 80, 255));
			content.AddView(modelSep, new FlexLayout.LayoutParams() { Width = .Match, Height = .Fixed(.Px(1)) });
		}
	}

	/// Logs a warning naming every duplicate (Name, Extension) among the
	/// selected items. Called from ExecuteImport just before invoking the
	/// importer so the conflict is captured even though we proceed anyway.
	private void LogDuplicatesIfAny()
	{
		if (mLogger == null) return;

		let counts = scope Dictionary<String, int>();
		defer { for (let kv in counts) delete kv.key; }

		for (let item in mPreview.Items)
		{
			if (!item.Selected) continue;
			let key = new String();
			key.AppendF("{}{}", item.Name, item.Extension);
			if (counts.TryGetValue(key, let prev))
			{
				counts[key] = prev + 1;
				delete key;
			}
			else
			{
				counts[key] = 1;
			}
		}

		for (let kv in counts)
		{
			if (kv.value > 1)
				mLogger.LogWarning("Import contains duplicate name '{}' x{} - earlier writes will be overwritten", kv.key, kv.value);
		}
	}

	/// Runs the import with only the checked items.
	private void ExecuteImport()
	{
		// Sync checkbox states to preview items
		for (int i = 0; i < mPreview.Items.Count && i < mItemChecks.Count; i++)
			mPreview.Items[i].Selected = mItemChecks[i].IsChecked;

		// Check if anything is selected
		bool anySelected = false;
		for (let item in mPreview.Items)
		{
			if (item.Selected)
			{
				anySelected = true;
				break;
			}
		}

		if (!anySelected)
			return;

		// Final warning: any duplicate (Name, Extension) among selected
		// items will cause one to overwrite another. The dialog already
		// flagged this inline; this is the record-for-posterity log.
		LogDuplicatesIfAny();

		AssetImportContext ctx = .()
		{
			Mount = mMount,
			BaseLocator = mBaseLocator,
			Index = mIndex,
			UriPrefix = mUriPrefix,
			Serializer = mSerializer,
			Logger = mLogger,
		};

		if (mImporter.Import(mPreview, ctx) case .Ok)
		{
			mLogger?.LogInformation("Imported: {} ({} items selected)", mPreview.SourcePath, mItemChecks.Count);

			// Persist the index back through the mount so subsequent loads
			// pick up the new GUID -> URI mappings.
			if (mIndexLocator.Length > 0)
			{
				let indexStream = scope MemoryStream();
				if (mIndex.SerializeTo(indexStream) case .Ok)
				{
					indexStream.Position = 0;
					mMount.Save(mIndexLocator, indexStream);
				}
			}
		}
		else
			mLogger?.LogError("Import failed: {}", mPreview.SourcePath);

		mPanel.RefreshContent();
	}
}
