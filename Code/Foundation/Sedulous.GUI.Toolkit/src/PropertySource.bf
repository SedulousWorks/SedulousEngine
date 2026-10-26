using System;
using System.Collections;
using Sedulous.Core;
using internal Sedulous.GUI;

namespace Sedulous.GUI;

// What a property grid reads: a source of properties over one object or several. A property is one
// value (a bool, an integer, a float, a string, an enum or flags) at a path; a group (a vector's
// parts, a nested object) is a property whose children are the paths under it (`position.x`), so
// values that differ between the objects differ per part. The source says what is there and what
// each object holds; the grid edits through it as gestures: begun, previewed live on every object,
// then committed (the originals put back and the edit applied once, one undo entry) or cancelled
// (the originals put back). The undo is the source's (an application's, as ezEngine's and Zero's),
// never the grid's.
//
// A source may say each object's default for a path: the grid marks what differs from it, and a
// revert puts each object's own back, one undo entry.
//
// Copying and pasting go through the source as edits do: it writes a path and what is under it as
// text and reads it back, one undo entry; the grid has the menu and the keys, and no format.
//
// A list's elements are its children by index, and a change to one (an insert, a removal, a move)
// is one call, one undo entry, made in each object.
//
// PropertyBag is a source of its own values in memory: what tests and a page without objects of
// its own edit, its commits told to whoever keeps the undo.
//
// Values cross the source as the GUI's model Variant: what a source hands out (GetValue,
// GetDefault) the caller disposes; what it is given (a write's value) the caller keeps, and the
// source copies what it keeps.

enum PropertyKind : uint8
{
	/// No value of its own: its children are the paths under it.
	Group,
	Bool,
	Integer,
	Float,
	String,
	/// An integer, one of its choices.
	Enum,
	/// An integer, any of its choices' bits.
	Flags,
	/// Its elements are its children by index (`tags.0`); its value is their count.
	List,
	/// A colour, its sRGB values.
	Color,
	/// Core's curve keys, one value; MaxCount its most keys, a range its values'.
	Curve,
	/// A ColorGradient, one value; MaxCount its most stops of each kind.
	Gradient,
	/// What something kept elsewhere is known by (an asset, an entity): its Guid as text, empty for
	/// none; ReferenceType is what it points at.
	Reference,
}

static
{
	// What a list allows (PropertyInfo.ListOps).
	public const uint8 PropertyListAdd = 1 << 0;
	public const uint8 PropertyListRemove = 1 << 1;
	public const uint8 PropertyListMove = 1 << 2;
}

/// An enum's value or a flag's bit, and what it is called. A class: it owns its name.
class PropertyChoice
{
	public String Name = new .() ~ delete _;
	public int64 Value = 0;

	public this() { }

	public this(StringView name, int64 value)
	{
		Name.Set(name);
		Value = value;
	}

	public void Set(PropertyChoice other)
	{
		Name.Set(other.Name);
		Value = other.Value;
	}
}

/// What a source says of one property. Read afresh each time the grid asks, so whether it shows or
/// may be edited can follow other values (`visibleWhen`). A class: it owns its text and its lists;
/// Set copies another into it.
class PropertyInfo
{
	/// Its segment of the path.
	public String Name = new .() ~ delete _;
	/// What its row says; empty: its name.
	public String DisplayName = new .() ~ delete _;
	/// A top-level property's group in the grid; empty: none.
	public String Category = new .() ~ delete _;
	/// Its row's tooltip.
	public String Description = new .() ~ delete _;
	public PropertyKind Kind = .String;
	/// An editor asked for by name ("slider"), before its kind's.
	public String Hint = new .() ~ delete _;
	/// A number kept between Min and Max; else unbounded.
	public bool HasRange = false;
	public double Min = 0.0;
	public double Max = 0.0;
	/// A number's step; 0: the editor's own.
	public double Step = 0.0;
	/// An enum's values, flags' bits.
	public List<PropertyChoice> Choices = new .() ~ DeleteContainerAndItems!(_);
	public bool ReadOnly = false;
	public bool Visible = true;
	/// A colour's alpha is edited (not an HDR colour's, nor one with `noAlpha`).
	public bool ShowsAlpha = true;
	/// A list's: the PropertyList* bits.
	public uint8 ListOps = 0;
	/// A list's most elements (a BoundedArray's), a curve's most keys, a gradient's most stops; 0:
	/// no limit.
	public uint32 MaxCount = 0;
	/// A list's types an add chooses from; empty: its one.
	public List<String> ElementTypes = new .() ~ DeleteContainerAndItems!(_);
	/// A reference's: the type it points at (an application finds what may fill it); null when it
	/// says not.
	public System.Type ReferenceType = null;

	public StringView ShownName => (DisplayName.Length != 0) ? (StringView)DisplayName : (StringView)Name;

	/// Adds a choice (an enum's value, a flag's bit).
	public void AddChoice(StringView name, int64 value)
	{
		Choices.Add(new PropertyChoice(name, value));
	}

	/// Makes this a copy of `other`.
	public void Set(PropertyInfo other)
	{
		if (other === this)
			return;
		Name.Set(other.Name);
		DisplayName.Set(other.DisplayName);
		Category.Set(other.Category);
		Description.Set(other.Description);
		Kind = other.Kind;
		Hint.Set(other.Hint);
		HasRange = other.HasRange;
		Min = other.Min;
		Max = other.Max;
		Step = other.Step;
		ClearAndDeleteItems!(Choices);
		for (let choice in other.Choices)
		{
			let copy = new PropertyChoice();
			copy.Set(choice);
			Choices.Add(copy);
		}
		ReadOnly = other.ReadOnly;
		Visible = other.Visible;
		ShowsAlpha = other.ShowsAlpha;
		ListOps = other.ListOps;
		MaxCount = other.MaxCount;
		ClearAndDeleteItems!(ElementTypes);
		for (let type in other.ElementTypes)
			ElementTypes.Add(new String(type));
		ReferenceType = other.ReferenceType;
	}
}

/// A value written by an edit. For flags only `Mask`'s bits change, each object keeping its others,
/// so a flag set on several objects leaves the flags they differ in as they were. Its value is a
/// view the writer keeps.
struct PropertyWrite
{
	public Sedulous.GUI.Variant Value = .();
	public uint64 Mask = ~(uint64)0;

	public this() { }

	public this(Sedulous.GUI.Variant value)
	{
		Value = value;
	}

	public this(Sedulous.GUI.Variant value, uint64 mask)
	{
		Value = value;
		Mask = mask;
	}
}

/// A change to a list: an element inserted at Index (of ElementType, for a list of several), the
/// one at Index removed, or moved to To (its place after the move). A class: it owns its text.
class ListEdit
{
	public enum Op : uint8
	{
		Insert,
		Remove,
		Move,
	}

	public Op Kind = .Insert;
	public int Index = 0;
	public int To = 0;
	public String ElementType = new .() ~ delete _;

	public this() { }

	public this(Op kind, int index, int to = 0)
	{
		Kind = kind;
		Index = index;
		To = to;
	}

	public void Set(ListEdit other)
	{
		Kind = other.Kind;
		Index = other.Index;
		To = other.To;
		ElementType.Set(other.ElementType);
	}
}

/// What a source tells its grid.
interface IPropertySourceClient
{
	/// Which properties there are, or what they say of themselves, changed: read them again.
	void OnPropertiesChanged();
	/// Values changed (an undo, another editor, the objects themselves): show them again.
	void OnValuesChanged();
}

abstract class IPropertySource
{
	// Not owned: the grid that reads it.
	private IPropertySourceClient mClient = null;

	/// How many objects it stands for; their values differing is a row's mixed state.
	public abstract int ObjectCount { get; }
	/// The properties under `parent` (empty: the top level), in their order, appended to `outInfos`
	/// (the caller deletes them).
	public abstract void GetProperties(StringView parent, List<PropertyInfo> outInfos);
	/// The value at `path` of object `object`; the caller disposes it.
	public abstract Sedulous.GUI.Variant GetValue(StringView path, int object);

	/// An edit of `path` begins: what each object holds now is what a cancel puts back.
	public abstract void BeginEdit(StringView path);
	/// The edit as it goes (a scrub, a picker open): written to every object, live.
	public abstract void PreviewEdit(StringView path, PropertyWrite write);
	/// The edit ends with `write`: the originals put back, then `write` applied as one change.
	public abstract void CommitEdit(StringView path, PropertyWrite write);
	/// The edit is given up: the originals put back.
	public abstract void CancelEdit(StringView path);
	/// Changes the list `path` in each object, one undo entry; false when nothing changed.
	public abstract bool EditList(StringView path, ListEdit edit);

	/// What object `object` would hold at `path` by default (the type's, a prefab's: the source's to
	/// say); empty when it has none. The caller disposes it.
	public abstract Sedulous.GUI.Variant GetDefault(StringView path, int object);
	/// Puts each object's own default back at `path` and under it, one undo entry; false when
	/// nothing changed.
	public abstract bool Revert(StringView path);
	/// What a revert of `path` is called ("Revert to default", "Revert to prefab"), appended.
	public abstract void GetRevertText(StringView path, String outText);

	/// `path` and what is under it as text for the clipboard (the engine's serialization is a
	/// source's to use), appended; nothing when it cannot be copied.
	public abstract void CopyValue(StringView path, String outText);
	/// Reads `text` (CopyValue's) into `path` in each object, one undo entry; false, with `reason`
	/// filled, when it does not fit.
	public abstract bool PasteValue(StringView path, StringView text, String reason);

	public IPropertySourceClient Client
	{
		get => mClient;
		set => mClient = value;
	}

	protected void NotifyPropertiesChanged()
	{
		if (mClient != null)
			mClient.OnPropertiesChanged();
	}

	protected void NotifyValuesChanged()
	{
		if (mClient != null)
			mClient.OnValuesChanged();
	}
}

/// A property's value over every object: the first object's, whether any differs, and for flags
/// which bits differ. It owns its value: the caller disposes it.
struct PropertyValue : IDisposable
{
	public Sedulous.GUI.Variant Value = .();
	public bool Mixed = false;
	public uint64 MixedBits = 0;

	public this() { }

	public void Dispose() mut
	{
		Value.Dispose();
	}
}

static
{
	/// `path` joined under `parent` ("position" and "x": "position.x"), appended to `outPath`.
	public static void JoinPropertyPath(StringView parent, StringView name, String outPath)
	{
		outPath.Append(parent);
		if (outPath.Length != 0)
			outPath.Append(".");
		outPath.Append(name);
	}

	/// The path `path` is under ("" for a top-level property).
	public static StringView ParentPropertyPath(StringView path)
	{
		for (int i = path.Length; i > 0; --i)
		{
			if (path[i - 1] == '.')
				return path.Substring(0, i - 1);
		}
		return default;
	}

	/// `write` applied to `old`: flags keep the bits outside its mask. It may be a view of the
	/// write's value: a caller that keeps it copies it.
	public static Sedulous.GUI.Variant ApplyPropertyWrite(Sedulous.GUI.Variant old, PropertyWrite write)
	{
		if (write.Mask == ~(uint64)0)
			return write.Value.View();
		let bits = ((uint64)old.AsInt & ~write.Mask) | ((uint64)write.Value.AsInt & write.Mask);
		return Sedulous.GUI.Variant((int64)bits);
	}

	public static PropertyValue ReadPropertyValue(IPropertySource source, StringView path, PropertyKind kind)
	{
		var result = PropertyValue();
		let count = source.ObjectCount;
		if (count == 0)
			return result;
		result.Value = source.GetValue(path, 0);
		for (int i = 1; i < count; ++i)
		{
			var other = source.GetValue(path, i);
			defer other.Dispose();
			if (kind == .Flags)
				result.MixedBits |= (uint64)result.Value.AsInt ^ (uint64)other.AsInt;
			else if ((result.Value.Kind != other.Kind) || (result.Value.Compare(other) != 0))
				result.Mixed = true;
		}
		if (result.MixedBits != 0)
			result.Mixed = true;
		return result;
	}
}

/// A source of its own values in memory: properties declared by path, each object's values kept
/// here, and lists of values (each object's elements its own), or of groups whose fields a list
/// declares (AddElementField). A commit is told (path, each object's value before, each after) to
/// whoever keeps the undo, which puts values back with SetValue; a list's change is told as it was
/// asked.
class PropertyBag : IPropertySource
{
	/// One commit: the path, and each object's value before and after (owned).
	public class Commit
	{
		public String Path = new .() ~ delete _;
		public List<Sedulous.GUI.Variant> Before = new .() ~ PropertyBagDetail.DisposeAll(_);
		public List<Sedulous.GUI.Variant> After = new .() ~ PropertyBagDetail.DisposeAll(_);
	}

	/// Every object's default (SetDefault).
	public const int cAllObjects = -1;

	// A group element's field: its info (name, kind, what else it says) and a new element's value.
	private class ElementField
	{
		public PropertyInfo Info = new .() ~ delete _;
		public Sedulous.GUI.Variant Value = .() ~ _.Dispose();
	}

	private class Entry
	{
		public String Path = new .() ~ delete _;
		public PropertyInfo Info = new .() ~ delete _;
		// Each object's.
		public List<Sedulous.GUI.Variant> Values = new .() ~ PropertyBagDetail.DisposeAll(_);
		// A list's: each object's elements, a group's fields one after another.
		public List<List<Sedulous.GUI.Variant>> Elements = new .() ~ { for (let e in _) PropertyBagDetail.DisposeAll(e); delete _; };
		public PropertyKind ElementKind = .Float;
		public Sedulous.GUI.Variant ElementDefault = .() ~ _.Dispose();
		// A list's: what each element says beyond its name and kind.
		public PropertyInfo ElementInfo = new .() ~ delete _;
		// A list of groups: each element's fields, in order.
		public List<ElementField> Fields = new .() ~ DeleteContainerAndItems!(_);

		/// How many values an element is: one, or its group's fields.
		public int Stride => Fields.IsEmpty ? 1 : Fields.Count;

		/// A new element's values onto `elements`, copies they own.
		public void AppendElement(List<Sedulous.GUI.Variant> elements)
		{
			if (Fields.IsEmpty)
				elements.Add(ElementDefault.Copy());
			for (let field in Fields)
				elements.Add(field.Value.Copy());
		}
	}

	private class Original
	{
		public String Path = new .() ~ delete _;
		public List<Sedulous.GUI.Variant> Values = new .() ~ PropertyBagDetail.DisposeAll(_);
	}

	private class Default
	{
		public String Path = new .() ~ delete _;
		public int Object = 0;
		public Sedulous.GUI.Variant Value = .() ~ _.Dispose();
	}

	private List<Entry> mProperties = new .() ~ DeleteContainerAndItems!(_);
	private List<Original> mOriginals = new .() ~ DeleteContainerAndItems!(_);
	private List<Default> mDefaults = new .() ~ DeleteContainerAndItems!(_);
	private int mObjects;
	private delegate void(Commit commit) mOnCommit ~ delete _;
	private delegate void(StringView path) mOnPreview ~ delete _;
	private delegate void(StringView path) mOnCancel ~ delete _;
	private delegate void(StringView path, ListEdit edit) mOnListEdited ~ delete _;
	private delegate void(StringView path) mOnReverted ~ delete _;

	public this(int objects = 1)
	{
		mObjects = objects;
	}

	/// Declares the property `path` (its name the last segment, under its parent's path), empty for
	/// every object; returns its info to fill in.
	public PropertyInfo Add(StringView path, PropertyKind kind) => Add(path, kind, .());

	/// Declares the property `path` with `value` for every object (the bag keeps its own copies);
	/// returns its info to fill in.
	public PropertyInfo Add(StringView path, PropertyKind kind, Sedulous.GUI.Variant value)
	{
		let entry = new Entry();
		entry.Path.Set(path);
		let parent = ParentPropertyPath(path).Length;
		entry.Info.Name.Set((parent == 0) ? path : path.Substring(parent + 1, path.Length - parent - 1));
		entry.Info.Kind = kind;
		for (int i = 0; i < mObjects; ++i)
		{
			entry.Values.Add(value.Copy());
			entry.Elements.Add(new List<Sedulous.GUI.Variant>());
		}
		mProperties.Add(entry);
		NotifyPropertiesChanged();
		return entry.Info;
	}

	/// Declares the list `path` of values of `elementKind` (a new element `element`), with `count`
	/// elements in every object; returns its info to fill in (by default it may add, remove and move
	/// its elements).
	public PropertyInfo AddList(StringView path, PropertyKind elementKind, Sedulous.GUI.Variant element, int count = 0)
	{
		let info = Add(path, .List);
		info.ListOps = PropertyListAdd | PropertyListRemove | PropertyListMove;
		let entry = mProperties.Back;
		entry.ElementKind = elementKind;
		entry.ElementDefault.Dispose();
		entry.ElementDefault = element.Copy();
		for (let elements in entry.Elements)
		{
			for (int i = 0; i < count; ++i)
				elements.Add(element.Copy());
		}
		return info;
	}

	/// The info of `path`, to change; PropertiesChanged after.
	public PropertyInfo FindInfo(StringView path)
	{
		let entry = Find(path);
		return (entry != null) ? entry.Info : null;
	}

	/// What every element of the list `path` says beyond its name, kind and read-only state (a
	/// range, a reference's type), to fill in; null when `path` is no list.
	public PropertyInfo FindElementInfo(StringView path)
	{
		let entry = Find(path);
		return ((entry != null) && (entry.Info.Kind == .List)) ? entry.ElementInfo : null;
	}

	/// Gives every element of the list `path` a field `name` of `kind` (new elements `value`, the bag
	/// keeping its own copy): its elements are groups of their fields from then on (`path.N.name`),
	/// as a reflected list's struct elements are. Declared before the list has elements; returns the
	/// field's info to fill in (a range, a reference's type), null when `path` is no list.
	public PropertyInfo AddElementField(StringView path, StringView name, PropertyKind kind, Sedulous.GUI.Variant value)
	{
		let list = Find(path);
		if ((list == null) || (list.Info.Kind != .List))
			return null;
		list.ElementKind = .Group;
		let field = new ElementField();
		field.Info.Name.Set(name);
		field.Info.Kind = kind;
		field.Value = value.Copy();
		list.Fields.Add(field);
		NotifyPropertiesChanged();
		return field.Info;
	}

	/// A field with no value of its own for new elements.
	public PropertyInfo AddElementField(StringView path, StringView name, PropertyKind kind) => AddElementField(path, name, kind, .());

	/// Tells the grid what FindInfo's changes were.
	public void PropertiesChanged() => NotifyPropertiesChanged();

	/// Sets object `object`'s value at `path` (a property's or an element's) from code; the bag
	/// keeps its own copy.
	public void SetValue(StringView path, int object, Sedulous.GUI.Variant value)
	{
		if (let slot = Slot(path, object))
		{
			PropertyBagDetail.Store(slot, value);
			NotifyValuesChanged();
		}
	}

	/// Gives object `object`'s list `path` `count` elements from code (new ones its default).
	public void ResizeList(StringView path, int object, int count)
	{
		let list = Find(path);
		if ((list == null) || (list.Info.Kind != .List) || (object < 0) || (object >= list.Elements.Count))
			return;
		let elements = list.Elements[object];
		while (elements.Count > count * list.Stride)
		{
			elements.Back.Dispose();
			elements.PopBack();
		}
		while (elements.Count < count * list.Stride)
			list.AppendElement(elements);
		NotifyPropertiesChanged();
	}

	/// How many elements object `object`'s list `path` has.
	public int ElementCount(StringView path, int object)
	{
		let entry = Find(path);
		return ((entry != null) && (object >= 0) && (object < entry.Elements.Count)) ? entry.Elements[object].Count / entry.Stride : 0;
	}

	/// Object `object`'s default at `path` (a property's or an element's); every object's with
	/// cAllObjects.
	public void SetDefault(StringView path, Sedulous.GUI.Variant value, int object = cAllObjects)
	{
		for (let known in mDefaults)
		{
			if ((known.Path == path) && ((object == cAllObjects) || (known.Object == object)))
				PropertyBagDetail.Store(&known.Value, value);
		}
		for (int i = 0; i < mObjects; ++i)
		{
			if ((object == cAllObjects) || (object == i))
			{
				bool found = false;
				for (let known in mDefaults)
					found = found || ((known.Path == path) && (known.Object == i));
				if (!found)
				{
					let made = new Default();
					made.Path.Set(path);
					made.Object = i;
					made.Value = value.Copy();
					mDefaults.Add(made);
				}
			}
		}
		NotifyValuesChanged();
	}

	/// Told each revert (the path), to keep it for undo. OWNERSHIP of `onReverted` transfers.
	public void SetOnReverted(delegate void(StringView path) onReverted)
	{
		delete mOnReverted;
		mOnReverted = onReverted;
	}

	/// Told each commit, to keep it for undo. OWNERSHIP of `onCommit` transfers.
	public void SetOnCommit(delegate void(Commit commit) onCommit)
	{
		delete mOnCommit;
		mOnCommit = onCommit;
	}

	/// Told of each preview of a gesture (a drag, a scrub, a picker open) as it goes, the values
	/// in the bag by then: an owner that shows them live (a preview) reads them; the gesture ends
	/// in a commit or a cancel. OWNERSHIP of `onPreview` transfers.
	public void SetOnPreview(delegate void(StringView path) onPreview)
	{
		delete mOnPreview;
		mOnPreview = onPreview;
	}

	/// Told of a gesture given up (Escape): the values are back as they were before it.
	/// OWNERSHIP of `onCancel` transfers.
	public void SetOnCancel(delegate void(StringView path) onCancel)
	{
		delete mOnCancel;
		mOnCancel = onCancel;
	}

	/// Told each list change made. OWNERSHIP of `onEdited` transfers.
	public void SetOnListEdited(delegate void(StringView path, ListEdit edit) onEdited)
	{
		delete mOnListEdited;
		mOnListEdited = onEdited;
	}

	/// The edits begun and not yet ended.
	public int OpenEdits => mOriginals.Count;

	public override int ObjectCount => mObjects;

	public override void GetProperties(StringView parent, List<PropertyInfo> outInfos)
	{
		// A list's elements: as many as the fewest any object has.
		let list = Find(parent);
		if ((list != null) && (list.Info.Kind == .List))
		{
			int count = int.MaxValue;
			for (let elements in list.Elements)
				count = Math.Min(count, elements.Count / list.Stride);
			for (int i = 0; (i < count) && (count != int.MaxValue); ++i)
			{
				let info = new PropertyInfo();
				info.Set(list.ElementInfo);
				info.Name.Clear();
				i.ToString(info.Name);
				info.Kind = list.ElementKind;
				info.ReadOnly = list.Info.ReadOnly;
				outInfos.Add(info);
			}
			return;
		}
		// A group element's fields ("variants.2": its clip, its weight).
		let outer = Find(ParentPropertyPath(parent));
		if ((outer != null) && (outer.Info.Kind == .List) && !outer.Fields.IsEmpty)
		{
			for (let field in outer.Fields)
			{
				let info = new PropertyInfo();
				info.Set(field.Info);
				info.ReadOnly = info.ReadOnly || outer.Info.ReadOnly;
				outInfos.Add(info);
			}
			return;
		}
		for (let entry in mProperties)
		{
			if (ParentPropertyPath(entry.Path) == parent)
			{
				let info = new PropertyInfo();
				info.Set(entry.Info);
				outInfos.Add(info);
			}
		}
	}

	public override Sedulous.GUI.Variant GetValue(StringView path, int object)
	{
		let list = Find(path);
		if ((list != null) && (list.Info.Kind == .List))
			return ((object >= 0) && (object < list.Elements.Count)) ? Sedulous.GUI.Variant((int64)(list.Elements[object].Count / list.Stride)) : Sedulous.GUI.Variant();
		let slot = Slot(path, object);
		return (slot != null) ? slot.Copy() : Sedulous.GUI.Variant();
	}

	public override void BeginEdit(StringView path)
	{
		if ((FindOriginal(path) != null) || (Slot(path, 0) == null))
			return;
		let original = new Original();
		original.Path.Set(path);
		for (int i = 0; i < mObjects; ++i)
			original.Values.Add(GetValue(path, i));
		mOriginals.Add(original);
	}

	public override void PreviewEdit(StringView path, PropertyWrite write)
	{
		if (IsReadOnly(path))
			return;
		for (int i = 0; i < mObjects; ++i)
		{
			if (let slot = Slot(path, i))
				PropertyBagDetail.Store(slot, ApplyPropertyWrite(*slot, write));
		}
		NotifyValuesChanged();
		if (mOnPreview != null)
			mOnPreview(path);
	}

	public override void CommitEdit(StringView path, PropertyWrite write)
	{
		if (IsReadOnly(path) || (Slot(path, 0) == null))
		{
			EndEdit(path);
			return;
		}
		let commit = scope Commit();
		commit.Path.Set(path);
		let original = FindOriginal(path);
		for (int i = 0; i < mObjects; ++i)
		{
			let slot = Slot(path, i);
			let before = ((original != null) && (i < original.Values.Count)) ? original.Values[i].Copy() : ((slot != null) ? slot.Copy() : Sedulous.GUI.Variant());
			commit.Before.Add(before);
			if (slot != null)
				PropertyBagDetail.Store(slot, ApplyPropertyWrite(before, write)); // from the original, not the previews
			commit.After.Add((slot != null) ? slot.Copy() : Sedulous.GUI.Variant());
		}
		EndEdit(path);
		NotifyValuesChanged();
		if (mOnCommit != null)
			mOnCommit(commit);
	}

	public override void CancelEdit(StringView path)
	{
		if (let original = FindOriginal(path))
		{
			for (int i = 0; (i < mObjects) && (i < original.Values.Count); ++i)
			{
				if (let slot = Slot(path, i))
					PropertyBagDetail.Store(slot, original.Values[i]);
			}
		}
		EndEdit(path);
		NotifyValuesChanged();
		if (mOnCancel != null)
			mOnCancel(path);
	}

	public override Sedulous.GUI.Variant GetDefault(StringView path, int object)
	{
		for (let known in mDefaults)
		{
			if ((known.Object == object) && (known.Path == path))
				return known.Value.Copy();
		}
		return .();
	}

	public override bool Revert(StringView path)
	{
		bool changed = false;
		for (let known in mDefaults)
		{
			let at = StringView(known.Path);
			let under = (at == path) || ((at.Length > path.Length) && (at.Substring(0, path.Length) == path) && (at[path.Length] == '.'));
			let slot = under ? Slot(at, known.Object) : null;
			if ((slot != null) && ((slot.Kind != known.Value.Kind) || (slot.Compare(known.Value) != 0)))
			{
				PropertyBagDetail.Store(slot, known.Value);
				changed = true;
			}
		}
		if (!changed)
			return false;
		NotifyValuesChanged();
		if (mOnReverted != null)
			mOnReverted(path);
		return true;
	}

	public override void GetRevertText(StringView path, String outText)
	{
		outText.Append("Revert to default");
	}

	// A single value as its text, the first object's; a group or a list is not copied here.
	public override void CopyValue(StringView path, String outText)
	{
		let slot = Slot(path, 0);
		if (slot != null)
			slot.ToString(outText);
	}

	public override bool PasteValue(StringView path, StringView text, String reason)
	{
		let kind = KindAt(path);
		var value = Sedulous.GUI.Variant();
		switch (kind)
		{
		case .Bool:
			if ((text == "true") || (text == "false"))
				value = Sedulous.GUI.Variant(text == "true");
		case .Integer, .Enum, .Flags:
			if (int64.Parse(ParseUtil.Trim(text)) case .Ok(let number))
				value = Sedulous.GUI.Variant(number);
		case .Float:
			if (double.Parse(ParseUtil.Trim(text)) case .Ok(let real))
				value = Sedulous.GUI.Variant(real);
		case .String:
			value = Sedulous.GUI.Variant(text);
		case .Reference:
			// A Guid's text, or nothing (cleared).
			let trimmed = ParseUtil.Trim(text);
			if (trimmed.IsEmpty || (Guid.Parse(trimmed) case .Ok))
				value = Sedulous.GUI.Variant(trimmed);
		case .Color:
			let color = ParseColor(ParseUtil.Trim(text));
			if (color.HasValue)
				value = Sedulous.GUI.Variant(color.Value);
		default:
		}
		if (value.IsEmpty || IsReadOnly(path) || (Slot(path, 0) == null))
		{
			reason.Clear();
			reason.AppendF("\"{}\" is no {}", text, PropertyKindLabel(kind));
			return false;
		}
		BeginEdit(path);
		CommitEdit(path, PropertyWrite(value));
		return true;
	}

	public override bool EditList(StringView path, ListEdit edit)
	{
		let list = Find(path);
		if ((list == null) || (list.Info.Kind != .List) || list.Info.ReadOnly)
			return false;
		let needs = (edit.Kind == .Insert) ? PropertyListAdd : ((edit.Kind == .Remove) ? PropertyListRemove : PropertyListMove);
		if ((list.Info.ListOps & needs) == 0)
			return false;
		bool changed = false;
		// An element's values: one, or a group's fields, added, removed and moved whole.
		let stride = list.Stride;
		for (let elements in list.Elements)
		{
			let count = elements.Count / stride;
			switch (edit.Kind)
			{
			case .Insert:
				if ((list.Info.MaxCount == 0) || (count < (int)list.Info.MaxCount))
				{
					let element = scope List<Sedulous.GUI.Variant>();
					list.AppendElement(element); // the copies move into the list
					let at = Math.Min(edit.Index, count) * stride;
					for (int f = 0; f < stride; ++f)
						elements.Insert(at + f, element[f]);
					changed = true;
				}
			case .Remove:
				if ((edit.Index >= 0) && (edit.Index < count))
				{
					for (int f = 0; f < stride; ++f)
					{
						elements[edit.Index * stride].Dispose();
						elements.RemoveAt(edit.Index * stride);
					}
					changed = true;
				}
			case .Move:
				if ((edit.Index >= 0) && (edit.Index < count) && (edit.To >= 0) && (edit.To < count) && (edit.Index != edit.To))
				{
					let moved = scope List<Sedulous.GUI.Variant>();
					for (int f = 0; f < stride; ++f)
						moved.Add(elements[edit.Index * stride + f]);
					for (int f = 0; f < stride; ++f)
						elements.RemoveAt(edit.Index * stride);
					for (int f = 0; f < stride; ++f)
						elements.Insert(edit.To * stride + f, moved[f]);
					changed = true;
				}
			}
		}
		if (!changed)
			return false;
		NotifyPropertiesChanged();
		if (mOnListEdited != null)
			mOnListEdited(path, edit);
		return true;
	}

	private Entry Find(StringView path)
	{
		for (let entry in mProperties)
		{
			if (entry.Path == path)
				return entry;
		}
		return null;
	}

	// Object `object`'s value at `path`: a property's, an element of a list ("tags.2"), or a field of
	// a group element ("variants.2.weight").
	private Sedulous.GUI.Variant* Slot(StringView path, int object)
	{
		if ((object < 0) || (object >= mObjects))
			return null;
		if (let entry = Find(path))
			return (entry.Info.Kind == .List) ? null : &entry.Values[object];
		let parent = ParentPropertyPath(path);
		var list = (parent.Length != 0) ? Find(parent) : null;
		if ((list != null) && (list.Info.Kind == .List))
		{
			if (!list.Fields.IsEmpty)
				return null; // a group element has no value of its own: its fields do
			let index = int64.Parse(path.Substring(parent.Length + 1, path.Length - parent.Length - 1));
			let elements = list.Elements[object];
			if (index case .Ok(let i))
			{
				if ((i >= 0) && (i < elements.Count))
					return &elements[(int)i];
			}
			return null;
		}
		// A group element's field.
		let element = parent;
		let listPath = ParentPropertyPath(element);
		list = (listPath.Length != 0) ? Find(listPath) : null;
		if ((list == null) || (list.Info.Kind != .List) || list.Fields.IsEmpty)
			return null;
		let number = int64.Parse(element.Substring(listPath.Length + 1, element.Length - listPath.Length - 1));
		let name = path.Substring(element.Length + 1, path.Length - element.Length - 1);
		for (int f = 0; f < list.Fields.Count; ++f)
		{
			if (list.Fields[f].Info.Name != name)
				continue;
			let values = list.Elements[object];
			if (number case .Ok(let n))
			{
				let at = (n >= 0) ? (int)n * list.Stride + f : values.Count;
				if (at < values.Count)
					return &values[at];
			}
			return null;
		}
		return null;
	}

	private PropertyKind KindAt(StringView path)
	{
		if (let entry = Find(path))
			return entry.Info.Kind;
		let list = Find(ParentPropertyPath(path));
		if ((list != null) && (list.Info.Kind == .List))
			return list.ElementKind;
		// A group element's field: its own kind.
		let element = ParentPropertyPath(path);
		let outer = (element.Length != 0) ? Find(ParentPropertyPath(element)) : null;
		if ((outer != null) && (outer.Info.Kind == .List))
		{
			let name = path.Substring(element.Length + 1, path.Length - element.Length - 1);
			for (let field in outer.Fields)
			{
				if (field.Info.Name == name)
					return field.Info.Kind;
			}
		}
		return .Group;
	}

	private static StringView PropertyKindLabel(PropertyKind kind)
	{
		switch (kind)
		{
		case .Bool:
			return "bool";
		case .Integer, .Enum, .Flags:
			return "integer";
		case .Float:
			return "number";
		case .String:
			return "text";
		case .Color:
			return "colour";
		case .Reference:
			return "guid";
		default:
			return "value it can take";
		}
	}

	private bool IsReadOnly(StringView path)
	{
		if (let entry = Find(path))
			return entry.Info.ReadOnly;
		let list = Find(ParentPropertyPath(path));
		if (list != null)
			return list.Info.ReadOnly;
		let outer = Find(ParentPropertyPath(ParentPropertyPath(path))); // a group element's field
		return (outer != null) && (outer.Info.Kind == .List) && outer.Info.ReadOnly;
	}

	private Original FindOriginal(StringView path)
	{
		for (let original in mOriginals)
		{
			if (original.Path == path)
				return original;
		}
		return null;
	}

	private void EndEdit(StringView path)
	{
		for (int i = 0; i < mOriginals.Count; ++i)
		{
			if (mOriginals[i].Path == path)
			{
				delete mOriginals[i];
				mOriginals.RemoveAt(i);
				return;
			}
		}
	}
}

/// What PropertySource.bf keeps out of the public surface.
internal static class PropertyBagDetail
{
	/// Disposes each value and deletes the list.
	public static void DisposeAll(List<Sedulous.GUI.Variant> values)
	{
		if (values == null)
			return;
		for (int i = 0; i < values.Count; i++)
			values[i].Dispose();
		delete values;
	}

	/// Keeps a copy of `value` in `slot`, letting go of what it held (copied first: `value` may be a
	/// view of it).
	public static void Store(Sedulous.GUI.Variant* slot, Sedulous.GUI.Variant value)
	{
		let copy = value.Copy();
		slot.Dispose();
		*slot = copy;
	}
}
