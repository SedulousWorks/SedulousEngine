namespace Sedulous.Editor.App;

using System;
using System.Collections;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Core.Mathematics;
using Sedulous.Resources;
using Sedulous.Shell;

/// Property editor for a List<ResourceRef>.
/// Shows per-slot ResourceRef rows with path, browse, and clear buttons.
class ResourceRefListEditor : PropertyEditor
{
	private delegate int32() mCountGetter;
	private delegate ResourceRef(int32) mGetter;
	private delegate void(int32, ResourceRef) mSetter;
	private IDialogService mDialogs;
	private Sedulous.Editor.Core.EditorContext mEditorContext;
	private String mExtensionFilter ~ delete _;
	private FlexLayout mContainer;
	private bool mOwnsCallbacks;

	public this(StringView name, delegate int32() countGetter,
		delegate ResourceRef(int32) getter, delegate void(int32, ResourceRef) setter,
		IDialogService dialogs = null, Sedulous.Editor.Core.EditorContext editorContext = null,
		StringView extensionFilter = default,
		bool ownsCallbacks = true, StringView category = default)
		: base(name, category)
	{
		mCountGetter = countGetter;
		mGetter = getter;
		mSetter = setter;
		mDialogs = dialogs;
		mEditorContext = editorContext;
		if (extensionFilter.Length > 0)
			mExtensionFilter = new String(extensionFilter);
		mOwnsCallbacks = ownsCallbacks;
	}

	public ~this()
	{
		if (mOwnsCallbacks)
		{
			delete mCountGetter;
			delete mGetter;
			delete mSetter;
		}
	}

	protected override View CreateEditorView()
	{
		mContainer = new FlexLayout();
		mContainer.Direction = .Vertical;
		mContainer.Spacing = 2;
		RebuildSlots();
		return mContainer;
	}

	private void RebuildSlots()
	{
		if (mContainer == null) return;

		// Remove all children
		while (mContainer.ChildCount > 0)
			mContainer.RemoveView(mContainer.GetChildAt(0), true);

		let count = mCountGetter();

		for (int32 i = 0; i < count; i++)
		{
			let slot = i;
			let row = new FlexLayout();
			row.Direction = .Horizontal;
			row.Spacing = 2;

			// Slot label
			let label = new Label();
			label.SetText(scope $"[{i}]");
			label.FontSize.Value = 10;
			label.TextColor.Value = .(140, 145, 160, 255);
			row.AddView(label, new FlexLayout.LayoutParams() {
				Width = .Fixed(.Px(24)), Height = .Match
			});

			// Path display
			let pathLabel = new Label();
			pathLabel.FontSize.Value = 11;
			pathLabel.TextColor.Value = .(180, 185, 200, 255);
			let @ref = mGetter(i);
			if (@ref.HasPath)
			{
				let fileName = scope String();
				System.IO.Path.GetFileName(@ref.Path, fileName);
				pathLabel.SetText(fileName);
			}
			else if (@ref.HasId)
			{
				let idStr = scope String();
				@ref.Id.ToString(idStr);
				pathLabel.SetText(idStr);
			}
			else
				pathLabel.SetText("(none)");

			row.AddView(pathLabel, new FlexLayout.LayoutParams() {
				Height = .Match, Grow = 1
			});

			// Browse
			let browseBtn = new Button("...");
			browseBtn.OnClick.Add(new (btn) =>
			{
				// Use asset picker when EditorContext is available
				if (mEditorContext != null)
				{
					let ctx = mContainer?.Context;
					if (ctx == null) return;

					let picker = new AssetPickerDialog(mEditorContext, mExtensionFilter ?? "",
						new (protocolPath, guid) => {
							var newRef = ResourceRef(guid, protocolPath);
							BeginEdit();
							mSetter(slot, newRef);
							NotifyValueChanged();
							EndEdit();
							newRef.Dispose();
							RebuildSlots();
						});
					picker.Show(ctx);
				}
				else if (mDialogs != null)
				{
					// Fallback: OS file dialog
					mDialogs.ShowOpenFileDialog(
						new (paths) => {
							if (paths.Length > 0)
							{
								var newRef = ResourceRef(.(), paths[0]);
								BeginEdit();
								mSetter(slot, newRef);
								NotifyValueChanged();
								EndEdit();
								newRef.Dispose();
								RebuildSlots();
							}
						},
						default, default, false, null);
				}
			});
			row.AddView(browseBtn, new FlexLayout.LayoutParams() {
				Width = .Fixed(.Px(28)), Height = .Match
			});

			// Clear
			let clearBtn = new Button("X");
			clearBtn.OnClick.Add(new (btn) =>
			{
				mContainer.Context?.MutationQueue.QueueAction(new () =>
				{
					BeginEdit();
					mSetter(slot, .());
					NotifyValueChanged();
					EndEdit();
					RebuildSlots();
				});
			});
			row.AddView(clearBtn, new FlexLayout.LayoutParams() {
				Width = .Fixed(.Px(24)), Height = .Match
			});

			mContainer.AddView(row, new FlexLayout.LayoutParams() {
				Width = .Match, Height = .Fixed(.Px(20))
			});
		}

		// Add [+] button to add a new slot
		let addBtn = new Button("+");
		addBtn.OnClick.Add(new (btn) =>
		{
			// Defer mutation - this button will be deleted by RebuildSlots
			mContainer.Context?.MutationQueue.QueueAction(new () =>
			{
				BeginEdit();
				mSetter(mCountGetter(), .());
				NotifyValueChanged();
				EndEdit();
				RebuildSlots();
			});
		});
		mContainer.AddView(addBtn, new FlexLayout.LayoutParams() {
			Width = .Fixed(.Px(24)), Height = .Fixed(.Px(20))
		});
	}

	public override void RefreshView()
	{
		RebuildSlots();
	}
}
