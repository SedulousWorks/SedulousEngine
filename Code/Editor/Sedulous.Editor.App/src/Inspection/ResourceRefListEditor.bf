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
	private LinearLayout mContainer;
	private bool mOwnsCallbacks;

	public this(StringView name, delegate int32() countGetter,
		delegate ResourceRef(int32) getter, delegate void(int32, ResourceRef) setter,
		IDialogService dialogs = null, bool ownsCallbacks = true, StringView category = default)
		: base(name, category)
	{
		mCountGetter = countGetter;
		mGetter = getter;
		mSetter = setter;
		mDialogs = dialogs;
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
		mContainer = new LinearLayout();
		mContainer.Orientation = .Vertical;
		mContainer.Spacing = 2;
		RebuildSlots();
		return mContainer;
	}

	private void RebuildSlots()
	{
		if (mContainer == null) return;

		// Remove all children
		while (mContainer.ChildCount > 0)
			mContainer.RemoveView(mContainer.GetChildAt(0));

		let count = mCountGetter();

		for (int32 i = 0; i < count; i++)
		{
			let slot = i;
			let row = new LinearLayout();
			row.Orientation = .Horizontal;
			row.Spacing = 2;

			// Slot label
			let label = new Label();
			label.SetText(scope $"[{i}]");
			label.FontSize = 10;
			label.TextColor = .(140, 145, 160, 255);
			row.AddView(label, new LinearLayout.LayoutParams() {
				Width = 24, Height = LayoutParams.MatchParent
			});

			// Path display
			let pathLabel = new Label();
			pathLabel.FontSize = 11;
			pathLabel.TextColor = .(180, 185, 200, 255);
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

			row.AddView(pathLabel, new LinearLayout.LayoutParams() {
				Width = 0, Height = LayoutParams.MatchParent, Weight = 1
			});

			// Browse
			let browseBtn = new Button();
			browseBtn.SetText("...");
			browseBtn.OnClick.Add(new  (btn) =>
			{
				if (mDialogs != null)
				{
					mDialogs.ShowOpenFileDialog(
						new (paths) => {
							if (paths.Length > 0)
							{
								var newRef = ResourceRef(.(), paths[0]);
								mSetter(slot, newRef);
								newRef.Dispose();
								RebuildSlots();
							}
						},
						default, default, false, null);
				}
			});
			row.AddView(browseBtn, new LinearLayout.LayoutParams() {
				Width = 28, Height = LayoutParams.MatchParent
			});

			// Clear
			let clearBtn = new Button();
			clearBtn.SetText("X");
			clearBtn.OnClick.Add(new (btn) =>
			{
				mContainer.Context?.MutationQueue.QueueAction(new () =>
				{
					mSetter(slot, .());
					RebuildSlots();
				});
			});
			row.AddView(clearBtn, new LinearLayout.LayoutParams() {
				Width = 24, Height = LayoutParams.MatchParent
			});

			mContainer.AddView(row, new LinearLayout.LayoutParams() {
				Width = LayoutParams.MatchParent, Height = 20
			});
		}

		// Add [+] button to add a new slot
		let addBtn = new Button();
		addBtn.SetText("+");
		addBtn.OnClick.Add(new (btn) =>
		{
			// Defer mutation - this button will be deleted by RebuildSlots
			mContainer.Context?.MutationQueue.QueueAction(new () =>
			{
				mSetter(mCountGetter(), .());
				RebuildSlots();
			});
		});
		mContainer.AddView(addBtn, new LinearLayout.LayoutParams() {
			Width = 24, Height = 20
		});
	}

	public override void RefreshView()
	{
		RebuildSlots();
	}
}
