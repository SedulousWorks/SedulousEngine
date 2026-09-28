using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Editor.Core;
using Sedulous.UI;
using Sedulous.UI.Toolkit;

namespace Sedulous.Editor.App;

/// THE editable list of the editor: every list a user adds to, reorders and removes from is
/// one of these, whatever its elements are, so every list looks and behaves the same.
///
/// One property grid row whose editor view is a header (the add icon, top right) over a row
/// per element. Two element shapes:
/// - SLOT elements (the default): each row an AssetPickerSlot that fills, plus move up, move
///   down and remove icon buttons. The mesh's materials, a list of entity references.
/// - SECTION elements (ElementsAsSections): an element with several fields of its own (a
///   script behaviour, a clip event) is a collapsible grid section of its own, like a
///   component, and its move and remove icons sit in that section's header (ElementActions).
///   This row is then the list's header alone: the count and the add icon.
///
/// Adding is the add icon, or its menu when OnAddMenu is set (add by kind). With accepted types
/// set, a slot takes a dropped asset of those types (OnAssignSlot), and the header, or an empty
/// list, takes one to APPEND (OnAppendDropped): dragging three materials in fills three slots.
///
/// Fully callback driven, no reflection or component coupling: the consumer wires the callbacks
/// and sets SlotNames before the row builds.
class ContainerListEditor : PropertyEditor
{
	/// Pick or assign the asset in slot i. Owned.
	public delegate void(int index) OnPickSlot ~ delete _;
	/// Remove slot i. Owned.
	public delegate void(int index) OnRemoveSlot ~ delete _;
	/// Reorder slot i; true is up. Owned.
	public delegate void(int index, bool up) OnMoveSlot ~ delete _;
	/// Append a new, empty element. Owned.
	public delegate void() OnAdd ~ delete _;
	/// When set, the add icon opens a menu this fills (add by kind) instead of calling OnAdd.
	/// Owned.
	public delegate void(ContextMenu menu) OnAddMenu ~ delete _;
	/// A dropped asset of an accepted type landed on slot i. Owned.
	public delegate void(int index, Guid id) OnAssignSlot ~ delete _;
	/// A dropped asset of an accepted type landed on the header or the empty list: append it.
	/// Owned.
	public delegate void(Guid id) OnAppendDropped ~ delete _;
	/// A dropped asset of another type: its display name and type name. Owned.
	public delegate void(StringView assetName, StringView typeName) OnRejectedDrop ~ delete _;
	/// Per element display text, set before the row builds: a slot's value, or a section
	/// element's summary.
	public List<String> SlotNames = new .() ~ DeleteContainerAndItems!(_);
	/// The elements are grid sections of their own; this row is the list's header alone.
	public bool ElementsAsSections = false;

	/// The asset types a slot or an append drop accepts; empty is no drop target.
	private List<String> mAcceptedTypes = new .() ~ DeleteContainerAndItems!(_);

	public this(StringView name, StringView category) : base(name, category) {}

	public Span<String> AcceptedTypes => mAcceptedTypes;

	/// The asset types the slots and an append drop accept (AssetPickerSlot.cAnyAsset for any).
	public void SetAcceptedTypes(Span<StringView> types)
	{
		ClearAndDeleteItems(mAcceptedTypes);
		for (let type in types)
			mAcceptedTypes.Add(new String(type));
	}

	public override void RefreshView() {}

	/// The move up, move down and remove icons for a SECTION element's header: element `index`
	/// of `count`. Hand the view to PropertyGrid.SetCategoryHeaderActions for the element's
	/// section. A null `onMove` is a list whose order means nothing (timed events): remove
	/// alone. The callbacks are CONSUMED.
	public static View ElementActions(int index, int count, delegate void(int index, bool up) onMove,
		delegate void(int index) onRemove) => new ElementActionsView(index, count, onMove, onRemove);

	protected override View CreateEditorView()
	{
		let column = new AppendDropZone(this);
		column.Direction = .Vertical;
		column.Spacing = 2.0f;

		// The header: the count for a section list, a spacer that grows, the add icon on the
		// right.
		{
			let header = new FlexLayout();
			header.Direction = .Horizontal;
			var grow = LayoutStyle();
			grow.FlexGrow = 1.0f;
			grow.AlignSelf = .Center;
			if (ElementsAsSections)
			{
				let count = new Label(scope $"{SlotNames.Count} {(SlotNames.Count == 1) ? "item" : "items"}");
				count.FontSize.Value = 11.0f;
				header.AddView(count, grow);
			}
			else
			{
				header.AddView(new FlexLayout(), grow);
			}
			let add = new IconButton(EditorIcons.Add);
			add.TooltipText.Set("Add");
			add.OnClick.Add(new [=this, =add](b) => { AddClicked(add); });
			header.AddView(add);
			column.AddView(header, RowStyle());
		}

		if (ElementsAsSections)
			return column;

		// The slot rows: a picker slot that fills plus move up, move down and remove.
		let types = scope List<StringView>();
		for (let t in mAcceptedTypes)
			types.Add(t);
		for (int i < SlotNames.Count)
		{
			let row = new FlexLayout();
			row.Direction = .Horizontal;
			row.Spacing = 4.0f;

			let slot = new AssetPickerSlot(SlotNames[i]);
			slot.SetFontSize(12.0f);
			slot.OnPick = new [=i, =this]() => { if (OnPickSlot != null) OnPickSlot(i); };
			slot.SetAcceptedTypes(types);
			slot.OnAssignDropped = new [=i, =this](id) => { if (OnAssignSlot != null) OnAssignSlot(i, id); };
			slot.OnRejectedDrop = new [=this](name, typeName) => { if (OnRejectedDrop != null) OnRejectedDrop(name, typeName); };
			var grow = LayoutStyle();
			grow.FlexGrow = 1.0f;
			row.AddView(slot, grow);

			let up = new IconButton(EditorIcons.MoveUp);
			up.TooltipText.Set("Move up");
			up.IsEnabled = i > 0;
			up.OnClick.Add(new [=i, =this](b) => { if (OnMoveSlot != null) OnMoveSlot(i, true); });
			row.AddView(up);
			let down = new IconButton(EditorIcons.MoveDown);
			down.TooltipText.Set("Move down");
			down.IsEnabled = i + 1 < SlotNames.Count;
			down.OnClick.Add(new [=i, =this](b) => { if (OnMoveSlot != null) OnMoveSlot(i, false); });
			row.AddView(down);
			let remove = new IconButton(EditorIcons.Remove);
			remove.TooltipText.Set("Remove");
			remove.OnClick.Add(new [=i, =this](b) => { if (OnRemoveSlot != null) OnRemoveSlot(i); });
			row.AddView(remove);

			column.AddView(row, RowStyle());
		}
		return column;
	}

	/// The add icon: the add menu when there is one, else a plain append.
	private void AddClicked(IconButton add)
	{
		if (OnAddMenu == null)
		{
			if (OnAdd != null)
				OnAdd();
			return;
		}
		let ui = add.Context;
		if (ui == null)
			return;
		let menu = new ContextMenu();
		OnAddMenu(menu);
		let at = add.LocalToScreen(.(0.0f, add.Height));
		menu.Show(ui, at.X, at.Y);
		menu.ReleaseRef();
	}

	/// Whether a dropped asset of `typeName` (or an entity, AssetPickerSlot.cEntity) is one this
	/// list takes.
	private bool Accepts(StringView typeName) => AssetPickerSlot.Accepts(mAcceptedTypes, typeName);

	private static LayoutStyle RowStyle()
	{
		var style = LayoutStyle();
		style.Width = SizeSpec.Match();
		style.Height = SizeSpec.Fixed(Unit.Dp(22.0f));
		return style;
	}

	/// The list's column: a drop anywhere on it outside a slot (the header, the gaps, an empty
	/// list) appends. A slot is the deeper target and takes its own drops first.
	private class AppendDropZone : FlexLayout, IDropTarget
	{
		private ContainerListEditor mOwner;
		private bool mHover = false;
		private bool mMatches = false;

		public this(ContainerListEditor owner) { mOwner = owner; }

		public override IDropTarget AsDropTarget() =>
			((mOwner.OnAppendDropped != null) && !mOwner.mAcceptedTypes.IsEmpty) ? this : null;

		public DragDropEffects CanAcceptDrop(DragData data, float localX, float localY)
		{
			Guid id;
			return AssetPickerSlot.DescribeDrag(data, out id, scope .(), scope .()) ? .Link : .None;
		}

		public void OnDragEnter(DragData data, float localX, float localY)
		{
			Guid id;
			let typeName = scope String();
			mHover = AssetPickerSlot.DescribeDrag(data, out id, typeName, scope .());
			mMatches = mHover && mOwner.Accepts(typeName);
			Invalidate();
		}

		public void OnDragOver(DragData data, float localX, float localY) {}

		public void OnDragLeave(DragData data)
		{
			mHover = false;
			Invalidate();
		}

		public DragDropEffects OnDrop(DragData data, float localX, float localY)
		{
			mHover = false;
			Invalidate();
			Guid id;
			let typeName = scope String();
			let name = scope String();
			if (!AssetPickerSlot.DescribeDrag(data, out id, typeName, name))
				return .None;
			if (!mOwner.Accepts(typeName))
			{
				GlobalLog(.Warning, "Assets: '{}' is a {}, this list does not accept it", name, typeName);
				if (mOwner.OnRejectedDrop != null)
					mOwner.OnRejectedDrop(name, typeName);
				return .None;
			}
			mOwner.OnAppendDropped(id);
			return .Link;
		}

		public override void OnDraw(UIDrawContext ctx)
		{
			base.OnDraw(ctx);
			if (mHover)
			{
				let ring = mMatches
					? ResolveStyleColor(.AccentColor, Color(80.0f / 255.0f, 150.0f / 255.0f, 240.0f / 255.0f, 1.0f))
					: ResolveStyleColor(.ErrorColor, Color(210.0f / 255.0f, 60.0f / 255.0f, 60.0f / 255.0f, 1.0f));
				ctx.VG.StrokeRect(.(0, 0, Width, Height), ring, 2.0f);
			}
		}
	}

	/// A section element's header icons. OWNS the two callbacks its three buttons share.
	private class ElementActionsView : FlexLayout
	{
		private delegate void(int index, bool up) mOnMove ~ delete _;
		private delegate void(int index) mOnRemove ~ delete _;

		public this(int index, int count, delegate void(int index, bool up) onMove, delegate void(int index) onRemove)
		{
			mOnMove = onMove;
			mOnRemove = onRemove;
			Direction = .Horizontal;
			Spacing = 2.0f;
			if (onMove != null)
			{
				let up = new IconButton(EditorIcons.MoveUp);
				up.TooltipText.Set("Move up");
				up.IsEnabled = index > 0;
				up.OnClick.Add(new [=this, =index](b) => { mOnMove(index, true); });
				AddView(up);
				let down = new IconButton(EditorIcons.MoveDown);
				down.TooltipText.Set("Move down");
				down.IsEnabled = index + 1 < count;
				down.OnClick.Add(new [=this, =index](b) => { mOnMove(index, false); });
				AddView(down);
			}
			let remove = new IconButton(EditorIcons.Remove);
			remove.TooltipText.Set("Remove");
			remove.OnClick.Add(new [=this, =index](b) => { mOnRemove(index); });
			AddView(remove);
		}
	}
}
