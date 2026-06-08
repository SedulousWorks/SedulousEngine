namespace Sedulous.Editor.App;

using System;
using System.Collections;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Editor.Core;
using Sedulous.Engine.Animation;

/// Phase-3 property picker for the `.propanim` editor. Lists every path
/// the `PropertyBinderRegistry` knows about, grouped by value type, and
/// hands the chosen `(path, kind)` to the callback.
///
/// Usage:
///   let picker = new PropertyPickerDialog(animSub.PropertyBinderRegistry,
///       new (path, kind) => { clip.AddVector3Track(path); ... });
///   picker.Show(ctx);
///
/// The picker doesn't filter by the target entity yet - it's a flat
/// view of the registry. The roadmap notes a future "doesn't resolve
/// on this entity" warning; that lands once the registry / inspector
/// has reflection metadata for component-bound paths (Phase 3+).
class PropertyPickerDialog : Dialog
{
	private PropertyBinderRegistry mRegistry;
	private delegate void(StringView, PropTrackKind) mOnSelected ~ delete _;

	// Strings the button closures capture by value. Each Button stores
	// the closure in its OnClick event; the strings must outlive the
	// dialog's content, so this dialog owns them and frees them with
	// the dialog itself.
	private List<String> mOwnedStrings = new .() ~ DeleteContainerAndItems!(_);

	public this(PropertyBinderRegistry registry,
		delegate void(StringView path, PropTrackKind kind) onSelected)
		: base("Add Track")
	{
		mRegistry = registry;
		mOnSelected = onSelected;

		MinWidth.Value = 360;
		MinHeight.Value = 360;
		MaxWidth.Value = 480;
		MaxHeight.Value = 560;

		BuildContent();
		AddButton("Cancel", .Cancel);
	}

	private void BuildContent()
	{
		let scroll = new ScrollView();
		let list = new FlexLayout();
		list.Direction = .Vertical;
		list.Spacing = 2;
		list.Padding = .(6);
		scroll.AddView(list, new LayoutParams() { Width = .Match, Height = .Wrap });

		int totalAdded = 0;
		if (mRegistry != null)
		{
			totalAdded += AppendFloatSection(list);
			totalAdded += AppendVector2Section(list);
			totalAdded += AppendVector3Section(list);
			totalAdded += AppendVector4Section(list);
			totalAdded += AppendQuaternionSection(list);
		}

		if (totalAdded == 0)
		{
			let empty = new Label();
			empty.SetText("(no animatable properties registered)");
			empty.TextColor.Value = .(160, 160, 170, 255);
			list.AddView(empty, new FlexLayout.LayoutParams() {
				Width = .Match, Height = .Fixed(.Px(20))
			});
		}

		SetContent(scroll);
	}

	private int AppendFloatSection(FlexLayout list)
	{
		let collected = scope List<StringView>();
		for (let p in mRegistry.FloatPaths) collected.Add(p);
		return EmitSection(list, "Float", .Float, collected);
	}

	private int AppendVector2Section(FlexLayout list)
	{
		let collected = scope List<StringView>();
		for (let p in mRegistry.Vector2Paths) collected.Add(p);
		return EmitSection(list, "Vector2", .Vector2, collected);
	}

	private int AppendVector3Section(FlexLayout list)
	{
		let collected = scope List<StringView>();
		for (let p in mRegistry.Vector3Paths) collected.Add(p);
		return EmitSection(list, "Vector3", .Vector3, collected);
	}

	private int AppendVector4Section(FlexLayout list)
	{
		let collected = scope List<StringView>();
		for (let p in mRegistry.Vector4Paths) collected.Add(p);
		return EmitSection(list, "Vector4", .Vector4, collected);
	}

	private int AppendQuaternionSection(FlexLayout list)
	{
		let collected = scope List<StringView>();
		for (let p in mRegistry.QuaternionPaths) collected.Add(p);
		return EmitSection(list, "Quaternion", .Quaternion, collected);
	}

	private int EmitSection(FlexLayout list, StringView label, PropTrackKind kind, List<StringView> paths)
	{
		if (paths.Count == 0) return 0;

		let header = new Label();
		header.SetText(scope $"{label} ({paths.Count})");
		header.TextColor.Value = .(220, 220, 230, 255);
		header.FontSize.Value = 12;
		list.AddView(header, new FlexLayout.LayoutParams() {
			Width = .Match, Height = .Fixed(.Px(22))
		});

		// Hoist the instance refs the click closure needs - capture lists
		// can only reference locals, not 'this'.
		let dlg = this;
		for (let path in paths)
		{
			let ownedPath = new String(path);
			mOwnedStrings.Add(ownedPath);

			let kindCopy = kind;
			let btn = new Button(ownedPath);
			btn.OnClick.Add(new [=ownedPath, =kindCopy, =dlg] (b) =>
			{
				if (dlg.mOnSelected != null)
					dlg.mOnSelected(ownedPath, kindCopy);
				dlg.Close(.OK);
			});
			list.AddView(btn, new FlexLayout.LayoutParams() {
				Width = .Match, Height = .Fixed(.Px(24))
			});
		}
		return paths.Count;
	}
}
