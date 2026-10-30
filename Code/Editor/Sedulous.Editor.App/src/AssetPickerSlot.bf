using System;
using System.Collections;
using Sedulous.GUI;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.App;

// The asset slot (Raptor's editor-gui spec, 5.2, layer 3), as the kit draws it: the referenced
// asset's type glyph (its category's tint), its name, and its verbs: pick (the target; a click on
// the name picks too), open, reveal (in the assets browser), clear. An empty slot says "Not set" and
// keeps only pick. A verb shows only when its owner wired it; open, reveal and clear need something
// referenced. It is a drop target for an asset of a type it takes, naming why not over one it does
// not: a drop and a pick are the same assignment.

/// A reference to an asset, picked, dropped on, opened, revealed and cleared. Its looks are the sheet's
/// (`.slot`, `.slot-glyph`, `.slot-name`, `button.slot-button`, `.slot.empty`).
class AssetPickerSlot : UIWidget
{
	/// The accepted type that means any asset: a field that is genuinely untyped. An empty list
	/// takes any too; a caller that names its types spells "any" as this.
	public const String cAnyAsset = "*";

	// Owned by the tree: the slot holds its children and never lets one go.
	private Sedulous.GUI.Image mGlyph;
	private Sedulous.GUI.Label mName;
	private Sedulous.GUI.Button mPick;
	private Sedulous.GUI.Button mOpen;
	private Sedulous.GUI.Button mReveal;
	private Sedulous.GUI.Button mClear;

	private delegate void() mOnPick ~ delete _;
	private delegate void() mOnOpen ~ delete _;
	private delegate void() mOnReveal ~ delete _;
	private delegate void() mOnClear ~ delete _;
	private delegate void(Guid id) mOnDropped ~ delete _;
	private List<String> mTypes = new .() ~ DeleteContainerAndItems!(_);
	/// The category class on the glyph now, taken off when the glyph changes.
	private String mGlyphClass = new .() ~ delete _;
	private bool mHasValue = false;
	private bool mHasGlyph = false;

	public this()
	{
		Tag = "assetslot";
		AddClass("slot");
		mGlyph = new Sedulous.GUI.Image();
		mGlyph.AddClass("slot-glyph");
		mGlyph.HitTestVisible = false;
		mName = new Sedulous.GUI.Label();
		mName.AddClass("slot-name");
		mName.HitTestVisible = false; // a click on it is the slot's: pick
		AddChild(mGlyph);
		mGlyph.ReleaseRef();
		AddChild(mName);
		mName.ReleaseRef();
		mPick = Verb("Editor/Icons/target.svg", "Pick (or drop an asset here)", new [=this] () => { Pick(); });
		mOpen = Verb("Editor/Icons/open.svg", "Open", new [=this] () =>
			{
				if (mOnOpen != null)
					mOnOpen();
			});
		mReveal = Verb("Editor/Icons/folder-open.svg", "Show in Assets", new [=this] () =>
			{
				if (mOnReveal != null)
					mOnReveal();
			});
		mClear = Verb("Editor/Icons/close.svg", "Clear", new [=this] () =>
			{
				if (mOnClear != null)
					mOnClear();
			});
		SetValue("");
	}

	// The verbs, each shown once wired. OWNERSHIP of each callback transfers (one set before is
	// deleted).

	public void SetOnPick(delegate void() pick)
	{
		delete mOnPick;
		mOnPick = pick;
		Show();
	}

	public void SetOnOpen(delegate void() open)
	{
		delete mOnOpen;
		mOnOpen = open;
		Show();
	}

	public void SetOnReveal(delegate void() reveal)
	{
		delete mOnReveal;
		mOnReveal = reveal;
		Show();
	}

	public void SetOnClear(delegate void() clear)
	{
		delete mOnClear;
		mOnClear = clear;
		Show();
	}

	/// An asset of a type it takes was dropped on it: assign it (the pick's write). Unwired, it
	/// is no drop target. OWNERSHIP transfers.
	public void SetOnDropped(delegate void(Guid id) dropped)
	{
		delete mOnDropped;
		mOnDropped = dropped;
	}

	/// The asset types it takes, by name, full or short (AssetTypeNames.Matches); empty, or
	/// cAnyAsset among them: any.
	public void SetAcceptedTypes(Span<StringView> types)
	{
		ClearAndDeleteItems(mTypes);
		for (let type in types)
			mTypes.Add(new String(type));
	}

	/// The asset types that may fill a reference to `target`, asked of `refs` (the builders': a
	/// texture's and a render texture's for a Texture), as the ones it takes; none when `refs` cannot
	/// say.
	public void AcceptTypesOf(ResourceRefServices refs, Type target)
	{
		ClearAndDeleteItems(mTypes);
		if ((refs != null) && (refs.AcceptedTypes != null))
			refs.AcceptedTypes(target, mTypes);
	}

	public Span<String> AcceptedTypes => mTypes;

	/// What it references: the asset's name, or nothing (`name` empty).
	public void SetValue(StringView name)
	{
		mHasValue = !name.IsEmpty;
		mName.Text = mHasValue ? name : StringView("Not set");
		Show();
	}

	public bool HasValue => mHasValue;
	public StringView ShownName => mName.Text;

	/// The referenced asset type's glyph, and its category's class (a tint); empty: none.
	public void SetGlyph(StringView path, StringView categoryClass = default)
	{
		if (!mGlyphClass.IsEmpty)
			mGlyph.RemoveClass(mGlyphClass);
		mGlyphClass.Set(categoryClass);
		if (!mGlyphClass.IsEmpty)
			mGlyph.AddClass(mGlyphClass);
		mGlyph.Source = path;
		mHasGlyph = !path.IsEmpty;
		Show();
	}

	/// The glyph of a type, as EditorIcons found it (its icon and its category's class); null:
	/// none.
	public void SetGlyph(TypeIcon icon)
	{
		if (icon == null)
			SetGlyph("", "");
		else
			SetGlyph(icon.Source, icon.Class);
	}

	/// Picks, as its target button does.
	public void Pick()
	{
		if (mOnPick != null)
			mOnPick();
	}

	public Sedulous.GUI.Button PickButton => mPick;
	public Sedulous.GUI.Button OpenButton => mOpen;
	public Sedulous.GUI.Button RevealButton => mReveal;
	public Sedulous.GUI.Button ClearButton => mClear;
	public Sedulous.GUI.Image GlyphImage => mGlyph;

	/// Whether `typeName`, a dragged asset's type, is one of `accepted` (by AssetTypeNames.Matches,
	/// or cAnyAsset). For an owner that checks a type itself, as a list editor's append does.
	public static bool Accepts(Span<String> accepted, StringView typeName)
	{
		for (let a in accepted)
		{
			if ((a == cAnyAsset) || AssetTypeNames.Matches(typeName, a))
				return true;
		}
		return false;
	}

	/// A refused drop's warning, naming every type the refuser takes, for an owner's toast:
	/// "brick is a TextureAsset - this field takes StaticMeshAsset or SkinnedMeshAsset". The
	/// any-asset wildcard reads as words. `noun` is what refused it ("field", "list").
	public static void RejectionText(StringView assetName, StringView typeName, Span<String> accepted,
		StringView noun, String outText)
	{
		let label = TypeLabel(typeName);
		outText.AppendF("{} is {} {} - this {} takes ", assetName, Article(label), label, noun);
		if (accepted.IsEmpty)
		{
			outText.Append("no asset");
			return;
		}
		for (int i < accepted.Length)
		{
			if (i > 0)
				outText.Append((i + 1 == accepted.Length) ? " or " : ", ");
			outText.Append(TypeLabel(accepted[i]));
		}
	}

	protected override void OnMouseClick(MouseEvent e)
	{
		if ((e.Button != .Left) || (mOnPick == null))
			return;
		e.Handled = true;
		Pick();
	}

	protected override void OnDragQuery(DropQuery query)
	{
		if (mOnDropped == null)
			return;
		let dragged = scope AssetDrag();
		let why = scope String();
		if (Takes(query.Payload, dragged, why))
		{
			query.Accept(.Link);
			query.Reason.Clear();
			query.Reason.AppendF("Use {}", dragged.Name);
		}
		else if (dragged.Id != Guid.Empty) // an asset it does not take, or several; another payload is not ours to refuse
			query.Refuse(why);
	}

	protected override void OnDrop(DragEvent e)
	{
		let dropped = scope AssetDrag();
		let why = scope String();
		if ((mOnDropped != null) && Takes(e.Payload, dropped, why))
			mOnDropped(dropped.Id);
	}

	/// Whether it takes what `payload` carries (read into `outAsset`), and why not when not.
	private bool Takes(DragPayload payload, AssetDrag outAsset, String outWhy)
	{
		// cAnyAsset takes any, as no types at all do.
		Span<String> types = mTypes;
		for (let type in mTypes)
		{
			if (type == cAnyAsset)
				types = .();
		}
		return AssetDrag.Takes(payload, types, outAsset, outWhy);
	}

	/// A verb's button, added to the row. Borrowed: the slot holds it. OWNERSHIP of `click`
	/// transfers.
	private Sedulous.GUI.Button Verb(StringView icon, StringView tooltip, delegate void() click)
	{
		let button = new Sedulous.GUI.Button();
		button.AddClass("slot-button");
		button.Icon = icon;
		button.Tooltip = tooltip;
		button.SetOnClick(click);
		AddChild(button);
		button.ReleaseRef();
		return button;
	}

	/// The verbs it has, the empty look.
	private void Show()
	{
		if (mHasValue)
			RemoveClass("empty");
		else
			AddClass("empty");
		mGlyph.Displayed = mHasValue && mHasGlyph;
		mPick.Displayed = mOnPick != null;
		mOpen.Displayed = (mOnOpen != null) && mHasValue;
		mReveal.Displayed = (mOnReveal != null) && mHasValue;
		mClear.Displayed = (mOnClear != null) && mHasValue;
	}

	/// "an" before a vowel, "a" otherwise: the rejection text's article.
	private static StringView Article(StringView word)
	{
		let first = word.IsEmpty ? 'x' : word[0];
		return "AEIOUaeiou".Contains(first) ? "an" : "a";
	}

	/// A type as the rejection text names it: the wildcard as words.
	private static StringView TypeLabel(StringView typeName)
	{
		if (typeName == cAnyAsset)
			return "any asset";
		return typeName;
	}
}
