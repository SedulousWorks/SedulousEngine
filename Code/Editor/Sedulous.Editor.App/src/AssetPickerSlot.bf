using System;
using Sedulous.Editor.Core;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.UI;

namespace Sedulous.Editor.App;

/// The asset reference slot: a horizontal composite of the asset name (grows, click picks),
/// the preview/reveal, Edit and Clear. The name button is the picker affordance, and the
/// three trailing buttons share one chrome: a ContentButton hosting a 14px drawable. Used by
/// every resource-ref inspector row and the material list-slot rows. Affordances render
/// only when their callback is wired (the entity-ref twin wires OnPick alone and degrades
/// to a plain name button), and Edit, Clear and preview disable while the slot is empty.
/// A type-filtered drop target for asset-browser drags; the preview icon is the asset type
/// glyph until a real thumbnail exists.
///
/// Wiring order: set the callbacks first, then SetValue, which synchronises the affordances
/// (visibility from wiring, enabled state from has-value).
class AssetPickerSlot : FlexLayout, IDropTarget
{
	/// Click the name body: (re)assign via the picker dialog. Owned.
	public delegate void() OnPick ~ delete _;
	/// Open the referenced asset for editing. Owned.
	public delegate void() OnEdit ~ delete _;
	/// Clear the reference; must route the consumer's undoable command. Owned.
	public delegate void() OnClear ~ delete _;
	/// Reveal the referenced asset in the asset browser. Owned.
	public delegate void() OnReveal ~ delete _;
	/// A type-matching asset was dropped on the slot: assign it, the consumer's undoable
	/// command, the same write the picker takes. Owned.
	public delegate void(Guid id) OnAssignDropped ~ delete _;
	/// A wrong-type asset was dropped: the asset display name and its type name. The slot
	/// already logs a warning; wire this for the toast. Owned.
	public delegate void(StringView displayName, StringView typeName) OnRejectedDrop ~ delete _;

	// Owned by the children.
	private ContentButton mPreview = null;
	/// Owned by the preview button.
	private DrawableView mPreviewDrawable = null;
	private Button mBody = null;
	private ContentButton mEdit = null;
	private ContentButton mClear = null;
	/// Borrowed from EditorIcons.
	private SVGDrawable mPreviewIcon = null;
	/// The drop filter; empty means not a drop target.
	private List<String> mAcceptedTypes = new .() ~ DeleteContainerAndItems!(_);
	/// An asset drag is over the slot...
	private bool mDropHover = false;
	/// ...and its type is accepted.
	private bool mDropMatches = false;
	/// Owned; wins over the icon while set.
	private Drawable mPreviewThumbnail = null ~ { if (_ != null) _.ReleaseRef(); };
	private bool mHasValue = false;

	public this(StringView name = "")
	{
		Direction = .Horizontal;
		Spacing = 2.0f;

		mBody = new Button(name.Length > 0 ? name : "(none)");
		mBody.TooltipText.Set("Choose asset");
		mBody.OnClick.Add(new (b) => { if (OnPick != null) OnPick(); });
		var grow = LayoutStyle();
		grow.FlexGrow = 1.0f;
		AddView(mBody, grow);

		// The preview/reveal is a clickable drawable host: the asset type glyph now, swapped
		// for the real thumbnail once one exists; the icon stays the fallback.
		mPreview = MakeActionButton(null, "Reveal in asset browser", out mPreviewDrawable);
		mPreview.OnClick.Add(new (b) => { if (OnReveal != null) OnReveal(); });

		// The icons are null before EditorIcons.Initialize (tests).
		mEdit = MakeActionButton(Retained(EditorIcons.Edit), "Edit asset", ?);
		mEdit.OnClick.Add(new (b) => { if (OnEdit != null) OnEdit(); });

		mClear = MakeActionButton(Retained(EditorIcons.Close), "Clear reference", ?);
		mClear.OnClick.Add(new (b) => { if (OnClear != null) OnClear(); });

		SyncAffordances(false);
	}

	/// The current reference display: the name text and whether a real asset is
	/// referenced. Also synchronises the affordances; call after wiring the callbacks.
	public void SetValue(StringView name, bool hasValue)
	{
		mHasValue = hasValue;
		mBody.SetText((hasValue && (name.Length > 0)) ? name : "(none)");
		SyncAffordances(hasValue);
	}

	/// The asset type glyph for the preview (EditorIcons.ForAssetType): the fallback layer,
	/// shown whenever no thumbnail is set. Borrowed.
	public void SetPreviewIcon(SVGDrawable icon)
	{
		mPreviewIcon = icon;
		ApplyPreview();
		SyncAffordances(mHasValue);
	}

	/// A generated thumbnail, any drawable; wins over the type icon while set. Null falls
	/// back to the icon. Consumes the reference.
	public void SetPreviewThumbnail(Drawable thumbnail)
	{
		if (mPreviewThumbnail != null)
			mPreviewThumbnail.ReleaseRef();
		mPreviewThumbnail = thumbnail;
		ApplyPreview();
		SyncAffordances(mHasValue);
	}

	/// The body text size; list-slot rows run compact chrome.
	public void SetFontSize(float size) => mBody.FontSize.Value = size;

	/// The asset type names this slot accepts, the picker's filter list. Non-empty makes
	/// the slot a drop target for asset-browser drags.
	public void SetAcceptedTypes(Span<StringView> types)
	{
		ClearAndDeleteItems(mAcceptedTypes);
		for (let type in types)
			mAcceptedTypes.Add(new String(type));
	}

	// ---- IDropTarget (asset-browser drags) ----
	// Any asset drag is accepted at hover level so OnDrop can warn on a type mismatch (the
	// manager never calls OnDrop for a None effect); the hover cue distinguishes a match
	// (accent ring) from a mismatch (error ring).

	public override IDropTarget AsDropTarget() => mAcceptedTypes.Count > 0 ? this : null;

	public DragDropEffects CanAcceptDrop(DragData data, float localX, float localY)
	{
		return ((data as AssetDragData) != null) ? .Link : .None;
	}

	public void OnDragEnter(DragData data, float localX, float localY)
	{
		let asset = data as AssetDragData;
		mDropHover = asset != null;
		mDropMatches = (asset != null) && TypeAccepted(asset.AssetTypeName);
		Invalidate();
	}

	public void OnDragOver(DragData data, float localX, float localY) {}

	public void OnDragLeave(DragData data)
	{
		mDropHover = false;
		Invalidate();
	}

	public DragDropEffects OnDrop(DragData data, float localX, float localY)
	{
		mDropHover = false;
		Invalidate();
		let asset = data as AssetDragData;
		if (asset == null)
			return .None;
		if (!TypeAccepted(asset.AssetTypeName))
		{
			GlobalLog(.Warning, "Assets: '{}' is a {}, this slot does not accept it", asset.DisplayName, asset.AssetTypeName);
			if (OnRejectedDrop != null)
				OnRejectedDrop(asset.DisplayName, asset.AssetTypeName);
			return .None;
		}
		if (OnAssignDropped != null)
			OnAssignDropped(asset.Id);
		return .Link;
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		base.OnDraw(ctx);
		if (mDropHover)
		{
			// A match is the accent ring, a mismatch the error ring; themed, the literals
			// are fallbacks.
			let ring = mDropMatches
				? ResolveStyleColor(.AccentColor, Color(80.0f / 255.0f, 150.0f / 255.0f, 240.0f / 255.0f, 1.0f))
				: ResolveStyleColor(.ErrorColor, Color(210.0f / 255.0f, 60.0f / 255.0f, 60.0f / 255.0f, 1.0f));
			ctx.VG.StrokeRect(.(0, 0, Width, Height), ring, 2.0f);
		}
	}

	public bool HasValue => mHasValue;
	public Button BodyButton => mBody;
	public ContentButton EditButton => mEdit;
	public ContentButton ClearButton => mClear;
	public ContentButton PreviewButton => mPreview;

	/// One chrome for every trailing action: a ContentButton hosting a 14px drawable view.
	/// Adds the button to the row and answers it, with the drawable host. Consumes the icon
	/// reference.
	private ContentButton MakeActionButton(Drawable icon, StringView tooltip, out DrawableView outDrawable)
	{
		let content = new DrawableView(icon, 14.0f, 14.0f);
		outDrawable = content;
		let button = new ContentButton(content);
		button.TooltipText.Set(tooltip);
		AddView(button);
		return button;
	}

	/// A shared icon, with a reference taken for the view that will hold it; null stays null.
	private static Drawable Retained(Drawable icon)
	{
		if (icon != null)
			icon.AddRef();
		return icon;
	}

	private bool TypeAccepted(StringView typeName)
	{
		for (let accepted in mAcceptedTypes)
		{
			if (AssetTypeNames.Matches(typeName, accepted))
				return true;
		}
		return false;
	}

	/// The thumbnail wins; the type icon is the fallback layer.
	private void ApplyPreview()
	{
		let drawable = (mPreviewThumbnail != null) ? mPreviewThumbnail : mPreviewIcon;
		mPreviewDrawable.SetDrawable(Retained(drawable));
	}

	/// Visibility follows wiring (unwired affordances take no space); the enabled state
	/// follows the value (Edit, Clear and reveal are inert on an empty slot).
	private void SyncAffordances(bool hasValue)
	{
		let preview = (OnReveal != null) || (mPreviewIcon != null) || (mPreviewThumbnail != null);
		mPreview.Visibility = preview ? .Visible : .Gone;
		mPreview.IsEnabled = hasValue && (OnReveal != null);
		mEdit.Visibility = (OnEdit != null) ? .Visible : .Gone;
		mEdit.IsEnabled = hasValue;
		mClear.Visibility = (OnClear != null) ? .Visible : .Gone;
		mClear.IsEnabled = hasValue;
	}
}
