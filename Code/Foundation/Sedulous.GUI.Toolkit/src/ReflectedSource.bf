using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using internal Sedulous.GUI;

namespace Sedulous.GUI;

// The property source over the GUI's reflection: one reflected object or several of one type, their
// properties as the grid's paths. A type is reflected by its [GuiReflect] table (GuiTypeInfo): its
// [GuiProperty] properties, its base's after its own, each read and written through its table's
// get and set, with what an inspector reads of each beside it.
//   - bool, every integer width, float, double and text are values; an enum is choices from its
//     cases, or flags with GuiPropertyFlags.BitFlags (read and written as an integer); a property
//     without a setter is read only (but a list, changed in place, needs none).
//   - A Color is a colour, its alpha hidden with NoAlpha; a Float4 with HdrColor (sRGB rgb, a
//     linear intensity in w) is an HDR colour, hinted "ColorHdr", its parts `color` and
//     `intensity` (shown in stops); a Float4 with Color is a colour as a Color is (four floats a
//     runtime keeps its tints in), NoAlpha hiding its alpha.
//   - Float2, Float3 and Float4 are groups hinted with their names, their parts x, y, z, w; a
//     Quaternion is a Float3 group of Euler degrees (pitch, yaw, roll) the source converts, as the
//     editor's Transform row does; a node held by a property is a group of its own table's
//     properties, and a value struct (its [GuiProperty] fields) a group of its fields, read from a
//     copy and written back whole through what holds it.
//   - A List<T> is a list (its [GuiList] most, a bounded array's), its elements by index; a list of
//     objects adds by type, the [GuiReflect] types its [GuiList] names, by their [DisplayName].
//   - Core's Curve is one value of kind Curve, its keys whole; the GUI's ColorGradient is one value
//     of kind Gradient. A value struct the application registers as a curve (its List<CurveKey>)
//     or a gradient (its lists of stops and its blend) is one value of that kind too: the toolkit
//     names no runtime type, the application says which of its types these are and where their
//     parts are.
//   - A reference is one value of kind Reference, its Guid as text (empty: none), naming the type
//     it points at: a type the application's reference shape takes (an engine's Ref<T>), a write
//     dropping its binding so the next resolve binds the new id; a value struct the application
//     registers as a reference (its Guid field, by name), naming itself and hinted with its name,
//     so the application's editor for it (an editor's entity reference) is chosen before the one
//     for asset references; and a bare Guid, naming the type its member's [GuiReference] names,
//     else nothing in particular; a list of bare Guids names its elements' by its own member's. The toolkit has no slot: by default a reference shows as its
//     Guid's text, and the application registers its editor for the kind.
//   - Any other type is a group hinted with its type's name, for an application's editor; with no
//     editor, the grid's row saying no editor fits.
//   - A row says its [DisplayName], else its property's name made readable; its [Description], its
//     [Range] (min, max, step; a ranged float hinted "slider", as the old inspector showed it) and
//     its [VisibleWhen] ("Kind", or "Kind=1,2" of its raw integer, a sibling's; shown when it holds
//     for every object).
// Defaults: the type's, read from an instance its creator makes, under any an application stacks
// over it (a prefab's, by path and object); a revert puts each object's own back, a list whole from
// the type's instance.
// Writes go through the property's setter (a value struct's field into a copy written back whole, a
// list's element into the list). Each commit is told to the application as one change: what, where,
// and each object's value there before and after as text, written with the text format the
// application gives (its serializer), which Restore reads back for an undo; the undo is the
// application's.

/// What the application gives a reflected source to write text with: its serializer (the engine's
/// XmlSerializer, say), so the toolkit takes on no format.
interface IPropertyTextFormat
{
	/// Text written by `write`, appended to `outText`; nothing when it failed.
	void Write(delegate void(ISerializer ar) write, String outText);
	/// Reads `text` with `read`; false when it is not the format's or the read failed.
	bool Read(StringView text, delegate void(ISerializer ar) read);
}

/// What the application gives a reflected source to know its references by (an engine's Ref<T>,
/// read through Resource's ReferenceShape), so the toolkit names no runtime type and depends on
/// no engine module. Each call takes the value's type and the address of a copy of it the source
/// writes back whole through what holds it.
interface IPropertyReferenceShape
{
	/// Whether a value of `type` is a reference.
	bool Is(System.Type type);
	/// The type a reference of `type` points at (what may fill it); null when it says not.
	System.Type Target(System.Type type);
	/// The Guid inside the reference of `type` at `value`.
	Result<Guid> Id(System.Type type, void* value);
	/// Points the reference of `type` at `value` at `id` and drops its binding, so the next resolve
	/// binds the new id; false when it cannot.
	bool Assign(System.Type type, void* value, Guid id);
}

/// A change a reflected source made: what (in words), where, and each object's value there before
/// and after as the text format's text (empty without one). A class: it owns its text; Set copies
/// another into it.
class ReflectedChange
{
	public String Words = new .() ~ delete _;
	public String Path = new .() ~ delete _;
	public List<String> Before = new .() ~ DeleteContainerAndItems!(_);
	public List<String> After = new .() ~ DeleteContainerAndItems!(_);

	public void Set(ReflectedChange other)
	{
		Words.Set(other.Words);
		Path.Set(other.Path);
		ClearAndDeleteItems!(Before);
		for (let text in other.Before)
			Before.Add(new String(text));
		ClearAndDeleteItems!(After);
		for (let text in other.After)
			After.Add(new String(text));
	}
}

/// Where a value struct registered as a reference keeps what it is known by: its Guid field, by
/// name.
struct ReflectedReferenceParts
{
	public StringView Id;

	public this(StringView id)
	{
		Id = id;
	}
}

/// Where a value struct registered as a curve keeps its keys: its List<CurveKey> field, by name
/// (the most it holds is the list's [GuiList] most).
struct ReflectedCurveParts
{
	public StringView Keys;

	public this(StringView keys)
	{
		Keys = keys;
	}
}

/// Where a value struct registered as a gradient keeps its parts: its List<GradientColorStop> and
/// List<GradientAlphaStop> fields and its GradientInterpolation field, by name (the most stops of a
/// kind is the smaller list's most).
struct ReflectedGradientParts
{
	public StringView Colors;
	public StringView Alphas;
	public StringView Interpolation;

	public this(StringView colors, StringView alphas, StringView interpolation)
	{
		Colors = colors;
		Alphas = alphas;
		Interpolation = interpolation;
	}
}

static
{
	/// "castsShadows" -> "Casts Shadows", "fovYRadians" -> "Fov Y Radians", "IBL" -> "IBL": a
	/// reflected name as a row says it (the editor's convention), appended to `outText`.
	public static void ReadablePropertyName(StringView name, String outText)
	{
		bool prevLower = false;
		bool prevUpper = false;
		for (int i = 0; i < name.Length; ++i)
		{
			var c = name[i];
			let upper = (c >= 'A') && (c <= 'Z');
			let lower = (c >= 'a') && (c <= 'z');
			if ((i == 0) && lower)
				c = (char8)((uint8)c - ((uint8)'a' - (uint8)'A'));
			else if (upper)
			{
				let nextLower = (i + 1 < name.Length) && (name[i + 1] >= 'a') && (name[i + 1] <= 'z');
				if (prevLower || (prevUpper && nextLower))
					outText.Append(" ");
			}
			outText.Append(c);
			prevLower = lower;
			prevUpper = upper;
		}
	}
}

class ReflectedPropertySource : IPropertySource
{
	/// A default for a path and an object (empty: it has none there), over the type's own; the
	/// caller disposes what it gives.
	public typealias DefaultProvider = delegate Sedulous.GUI.Variant(StringView path, int object);

	// What reflection holds, as the grid sees it.
	protected enum Shape : uint8
	{
		Bool,
		Integer,
		Float,
		String,
		Enum,
		Float2,
		Float3,
		Float4,
		Quaternion,
		Color,
		/// Core's Curve, or a value struct registered as a curve.
		Curve,
		/// The GUI's ColorGradient, or a value struct registered as a gradient.
		Gradient,
		/// A type the reference shape takes, a value struct registered as a reference, or a bare
		/// Guid: its Guid.
		Reference,
		/// An object with a table of its own (the root, a node a property holds, an object in a
		/// list), or a value struct.
		Group,
		/// A List<T>.
		List,
		Other,
	}

	// One step below a property's value: a field of the value struct above, or an element of the
	// list above.
	protected struct Link
	{
		public GuiFieldInfo Field;
		public GuiListInfo Elements;
		public int Index;

		public this(GuiFieldInfo field)
		{
			Field = field;
			Elements = null;
			Index = 0;
		}

		public this(GuiListInfo elements, int index)
		{
			Field = null;
			Elements = elements;
			Index = index;
		}
	}

	// How far below a property a path reaches (a struct's field of a list's element of...).
	protected const int cMostLinks = 8;

	// A place a path names in one object: a property of an owner and the links below its value (a
	// field, an element), a part of a Float or a Quaternion, or an object with a table (the root, a
	// node a property holds, an object in a list).
	protected struct Target
	{
		// A group's: its table and its object.
		public GuiTypeInfo Table = null;
		public Object Instance = null;
		// A value's: its owner, its property, and the links from the property's value to it.
		public Object Owner = null;
		public GuiPropertyInfo Property = null;
		public Link[cMostLinks] Links = default;
		public int32 Depth = 0;
		// A part of the Float or Quaternion above (or an HDR colour's).
		public int32 Part = -1;
		// A Float4 that is an HDR colour: its parts `color` and `intensity`.
		public bool Hdr = false;
		// A Float4 that is a colour (Color): one value, not its parts.
		public bool AsColor = false;
		public bool ReadOnly = false;

		public this() { }
	}

	// An HDR colour's colour part (its rgb); its intensity is part 3 (w).
	protected const int32 cHdrColorPart = 10;

	private class Original
	{
		public String Path = new .() ~ delete _;
		// Each object's, for a cancel.
		public List<Sedulous.GUI.Variant> Values = new .() ~ PropertyBagDetail.DisposeAll(_);
		// Each object's text, for the change.
		public List<String> States = new .() ~ DeleteContainerAndItems!(_);
	}

	private class Provider
	{
		public DefaultProvider Default ~ delete _;
		public String RevertText = new .() ~ delete _;
	}

	private class CurveType
	{
		public String Name = new .() ~ delete _;
		public String Keys = new .() ~ delete _;
	}

	private class ReferenceType
	{
		public String Name = new .() ~ delete _;
		public String Id = new .() ~ delete _;
	}

	private class GradientType
	{
		public String Name = new .() ~ delete _;
		public String Colors = new .() ~ delete _;
		public String Alphas = new .() ~ delete _;
		public String Interpolation = new .() ~ delete _;
	}

	// Not owned: the application's.
	private List<Object> mObjects = new .() ~ delete _;
	private GuiTypeInfo mType = null;
	private List<Original> mOriginals = new .() ~ DeleteContainerAndItems!(_);
	// Not owned.
	private IPropertyTextFormat mFormat = null;
	private List<Provider> mProviders = new .() ~ DeleteContainerAndItems!(_);
	// The type's defaults, made by its creator.
	private Object mTypeDefault = null;
	private List<CurveType> mCurveTypes = new .() ~ DeleteContainerAndItems!(_);
	private List<ReferenceType> mReferenceTypes = new .() ~ DeleteContainerAndItems!(_);
	// Not owned.
	private IPropertyReferenceShape mReferenceShape = null;
	private List<GradientType> mGradientTypes = new .() ~ DeleteContainerAndItems!(_);
	private delegate void(ReflectedChange change) mOnChange ~ delete _;
	/// SetOnDescribe's.
	private delegate void(StringView path, PropertyInfo info) mOnDescribe ~ delete _;

	public ~this()
	{
		ReleaseTypeDefault();
	}

	/// The objects it stands for, all of the type `type` (several components: several objects).
	/// Borrowed: they outlive the source, or are replaced first.
	public void SetObjects(Span<Object> objects, GuiTypeInfo type)
	{
		mObjects.Clear();
		for (let object in objects)
		{
			if (object != null)
				mObjects.Add(object);
		}
		mType = type;
		ClearAndDeleteItems!(mOriginals);
		// The type's defaults: an instance its creator makes (none for a type without one).
		ReleaseTypeDefault();
		if (!mObjects.IsEmpty && (mType != null))
			mTypeDefault = mType.Create();
		NotifyPropertiesChanged();
	}

	public Span<Object> Objects => mObjects;
	public GuiTypeInfo ObjectType => mType;

	/// The text format changes and copies are written in (not owned; null: none).
	public IPropertyTextFormat TextFormat
	{
		get => mFormat;
		set => mFormat = value;
	}

	/// What tells the application's references (not owned; null: none, only a value struct
	/// registered as one and a bare Guid are references).
	public IPropertyReferenceShape ReferenceShape
	{
		get => mReferenceShape;
		set
		{
			mReferenceShape = value;
			NotifyPropertiesChanged();
		}
	}

	/// Told each change made, to keep for undo. OWNERSHIP of `onChange` transfers.
	public void SetOnChange(delegate void(ReflectedChange change) onChange)
	{
		delete mOnChange;
		mOnChange = onChange;
	}

	/// Puts `change`'s values back, those before it (an undo) or after it (a redo); false without a
	/// text format or when the objects no longer take it.
	public bool Restore(ReflectedChange change, bool before)
	{
		let states = before ? change.Before : change.After;
		if ((mFormat == null) || (states.Count != mObjects.Count))
			return false;
		bool ok = true;
		for (int i = 0; i < mObjects.Count; ++i)
			ok = ReadState(change.Path, i, states[i]) && ok;
		NotifyPropertiesChanged(); // a list's count may have changed back
		return ok;
	}

	/// Stacks `provider` over the defaults (the last stacked asks first); a revert is then called
	/// `revertText` ("Revert to prefab"). OWNERSHIP of `provider` transfers.
	public void PushDefaults(DefaultProvider provider, StringView revertText)
	{
		let made = new Provider();
		made.Default = provider;
		made.RevertText.Set(revertText);
		mProviders.Add(made);
		NotifyValuesChanged();
	}

	public void ClearDefaults()
	{
		ClearAndDeleteItems!(mProviders);
		NotifyValuesChanged();
	}

	/// Tells the grid the objects changed from outside it (an undo the application made).
	public void Refresh() => NotifyPropertiesChanged();

	/// Takes the value struct named `typeName` as a reference: one value, its Guid at `parts.Id`, the
	/// struct itself what it points at.
	public void RegisterReferenceType(StringView typeName, ReflectedReferenceParts parts)
	{
		let entry = new ReferenceType();
		entry.Name.Set(typeName);
		entry.Id.Set(parts.Id);
		mReferenceTypes.Add(entry);
		NotifyPropertiesChanged();
	}

	/// Takes the value struct named `typeName` as a curve: one value, its keys at `parts.Keys`.
	public void RegisterCurveType(StringView typeName, ReflectedCurveParts parts)
	{
		let entry = new CurveType();
		entry.Name.Set(typeName);
		entry.Keys.Set(parts.Keys);
		mCurveTypes.Add(entry);
		NotifyPropertiesChanged();
	}

	/// Takes the value struct named `typeName` as a gradient: one value of its stops and blend.
	public void RegisterGradientType(StringView typeName, ReflectedGradientParts parts)
	{
		let entry = new GradientType();
		entry.Name.Set(typeName);
		entry.Colors.Set(parts.Colors);
		entry.Alphas.Set(parts.Alphas);
		entry.Interpolation.Set(parts.Interpolation);
		mGradientTypes.Add(entry);
		NotifyPropertiesChanged();
	}

	// === IPropertySource ===

	public override int ObjectCount => mObjects.Count;

	public override void GetProperties(StringView parent, List<PropertyInfo> outInfos)
	{
		let first = outInfos.Count;
		ListProperties(parent, outInfos);
		// What the application says of each (a list element named by a field of its own, a group's
		// line, a row shown only when another holds): its describe hook, last.
		if (mOnDescribe != null)
		{
			let path = scope String();
			for (int i = first; i < outInfos.Count; ++i)
			{
				path.Clear();
				JoinPropertyPath(parent, outInfos[i].Name, path);
				mOnDescribe(path, outInfos[i]);
			}
		}
	}

	/// Told of each row as it is described, its info to change: what reflection cannot say of it (an
	/// element's name from a field of its own, a closed group's line, a row shown or not by another's
	/// value). The hook reads the objects through GetValue. OWNERSHIP of `onDescribe` transfers.
	public void SetOnDescribe(delegate void(StringView path, PropertyInfo info) onDescribe)
	{
		delete mOnDescribe;
		mOnDescribe = onDescribe;
	}

	private void ListProperties(StringView parent, List<PropertyInfo> outInfos)
	{
		if (mObjects.IsEmpty)
			return;
		Target target = .();
		if (!Resolve(0, parent, out target))
			return;
		if ((parent.Length == 0) || IsGroup(target))
		{
			ListPropertiesOf(parent, target, outInfos);
			return;
		}
		if (target.Part >= 0)
			return;
		let shape = ShapeOf(target);
		if (shape == .Group)
			ListFieldsOf(parent, target, outInfos);
		else if (shape == .List)
			ListElements(parent, outInfos);
		else if (target.Hdr)
			ListHdrParts(outInfos);
		else if (!target.AsColor && ((shape == .Float2) || (shape == .Float3) || (shape == .Float4) || (shape == .Quaternion)))
			ListParts(shape, outInfos);
	}

	public override Sedulous.GUI.Variant GetValue(StringView path, int object)
	{
		Target target = .();
		return Resolve(object, path, out target) ? Read(target) : Sedulous.GUI.Variant();
	}

	public override void BeginEdit(StringView path)
	{
		let original = new Original();
		original.Path.Set(path);
		for (int i = 0; i < mObjects.Count; ++i)
		{
			original.Values.Add(GetValue(path, i));
			original.States.Add(WriteState(path, i, .. new String()));
		}
		mOriginals.Add(original);
	}

	public override void PreviewEdit(StringView path, PropertyWrite write)
	{
		for (int i = 0; i < mObjects.Count; ++i)
			WriteValue(path, i, write);
		NotifyValuesChanged();
	}

	public override void CommitEdit(StringView path, PropertyWrite write)
	{
		let change = scope ReflectedChange();
		change.Words.AppendF("Set {}", path);
		change.Path.Set(path);
		let original = FindOriginal(path);
		for (int i = 0; i < mObjects.Count; ++i)
		{
			if ((original != null) && (i < original.Values.Count))
			{
				Target target = .();
				if (Resolve(i, path, out target))
					WriteTarget(target, original.Values[i]); // the original back, then the one change
				change.Before.Add(new String(original.States[i]));
			}
			else
				change.Before.Add(WriteState(path, i, .. new String()));
			WriteValue(path, i, write);
			change.After.Add(WriteState(path, i, .. new String()));
		}
		DropOriginal(path);
		Changed(path);
		if (mOnChange != null)
			mOnChange(change);
	}

	public override void CancelEdit(StringView path)
	{
		if (let original = FindOriginal(path))
		{
			for (int i = 0; (i < mObjects.Count) && (i < original.Values.Count); ++i)
			{
				Target target = .();
				if (Resolve(i, path, out target))
					WriteTarget(target, original.Values[i]);
			}
		}
		DropOriginal(path);
		NotifyValuesChanged();
	}

	public override bool EditList(StringView path, ListEdit edit)
	{
		let change = scope ReflectedChange();
		ListWords(path, edit, change.Words);
		change.Path.Set(path);
		bool changed = false;
		for (int o = 0; o < mObjects.Count; ++o)
		{
			change.Before.Add(WriteState(path, o, .. new String()));
			Target target = .();
			if (Resolve(o, path, out target) && (target.Part < 0) && (ShapeOf(target) == .List) && !target.ReadOnly)
				changed = ChangeList(target, edit) || changed;
			change.After.Add(WriteState(path, o, .. new String()));
		}
		if (!changed)
			return false;
		NotifyPropertiesChanged();
		if (mOnChange != null)
			mOnChange(change);
		return true;
	}

	public override Sedulous.GUI.Variant GetDefault(StringView path, int object)
	{
		Target target = .();
		if (!Resolve(object, path, out target) || target.ReadOnly)
			return .(); // nothing to put back where nothing is written
		for (int i = mProviders.Count; i > 0; --i)
		{
			var value = mProviders[i - 1].Default(path, object);
			if (!value.IsEmpty)
				return value;
			value.Dispose();
		}
		Target byDefault = .();
		return ((mTypeDefault != null) && ResolveIn(mTypeDefault, mType, path, out byDefault)) ? Read(byDefault) : Sedulous.GUI.Variant();
	}

	public override bool Revert(StringView path)
	{
		let change = scope ReflectedChange();
		change.Words.AppendF("Reverted {}", path);
		change.Path.Set(path);
		bool changed = false;
		for (int o = 0; o < mObjects.Count; ++o)
		{
			change.Before.Add(WriteState(path, o, .. new String()));
			changed = RevertUnder(path, o) || changed;
			change.After.Add(WriteState(path, o, .. new String()));
		}
		if (!changed)
			return false;
		NotifyPropertiesChanged();
		if (mOnChange != null)
			mOnChange(change);
		return true;
	}

	public override void GetRevertText(StringView path, String outText)
	{
		outText.Append(mProviders.IsEmpty ? "Revert to default" : (StringView)mProviders.Back.RevertText);
	}

	// The first object's value at `path` in the text format: its shape, then the value.
	public override void CopyValue(StringView path, String outText)
	{
		Target target = .();
		if ((mFormat == null) || !Resolve(0, path, out target) || ((target.Property == null) && (target.Table == null)))
			return;
		let shape = ShapeTag(target, .. scope String());
		if (shape.Length == 0)
			return;
		mFormat.Write(scope (ar) =>
			{
				Serialize(ar, "shape", shape);
				SerializeTarget(ar, "value", target);
			}, outText);
	}

	// Into each object, one change; refused when the shape differs or nothing can be written.
	public override bool PasteValue(StringView path, StringView text, String reason)
	{
		Target target = .();
		if ((mFormat == null) || !Resolve(0, path, out target) || ((target.Property == null) && (target.Table == null)))
		{
			reason.Set("Nothing to paste into");
			return false;
		}
		if (target.ReadOnly)
		{
			reason.Clear();
			reason.AppendF("{} is read only", path);
			return false;
		}
		let copied = scope String();
		let read = mFormat.Read(text, scope (ar) => { Serialize(ar, "shape", copied); });
		if (!read || (copied.Length == 0))
		{
			reason.Set("The clipboard holds no copied property");
			return false;
		}
		let expected = ShapeTag(target, .. scope String());
		if (copied != expected)
		{
			reason.Clear();
			reason.AppendF("A {} does not paste onto a {}", copied, expected);
			return false;
		}
		let change = scope ReflectedChange();
		change.Words.AppendF("Pasted {}", path);
		change.Path.Set(path);
		for (int o = 0; o < mObjects.Count; ++o)
		{
			change.Before.Add(WriteState(path, o, .. new String()));
			Target into;
			if (Resolve(o, path, out into))
			{
				mFormat.Read(text, scope (ar) =>
					{
						let shape = scope String();
						Serialize(ar, "shape", shape);
						SerializeTarget(ar, "value", into);
					});
			}
			change.After.Add(WriteState(path, o, .. new String()));
		}
		NotifyPropertiesChanged();
		if (mOnChange != null)
			mOnChange(change);
		return true;
	}

	// === Shapes ===

	// A type's shape: one the application registered (a curve, a gradient), else what it is, a
	// value's description (a list, a value struct) deciding what the type alone does not.
	protected Shape ShapeOf(System.Type type, GuiValueInfo value)
	{
		if (type == null)
			return .Other;
		if (FindCurveType(type) != null)
			return .Curve;
		if (FindGradientType(type) != null)
			return .Gradient;
		if ((FindReferenceType(type) != null) || ((mReferenceShape != null) && mReferenceShape.Is(type)))
			return .Reference;
		let shape = BaseShapeOf(type);
		if (shape != .Other)
			return shape;
		if (value != null)
		{
			if (value.ListInfo != null)
				return .List;
			if (value.IsStruct)
				return .Group;
		}
		return .Other;
	}

	protected static Shape BaseShapeOf(System.Type type)
	{
		if (type == typeof(bool))
			return .Bool;
		if (type.IsInteger)
			return .Integer;
		if ((type == typeof(float)) || (type == typeof(double)))
			return .Float;
		if ((type == typeof(StringView)) || (type == typeof(String)))
			return .String;
		if (type == typeof(Float2))
			return .Float2;
		if (type == typeof(Float3))
			return .Float3;
		if (type == typeof(Float4))
			return .Float4;
		if (type == typeof(Quaternion))
			return .Quaternion;
		if (type == typeof(Color))
			return .Color;
		if (type == typeof(Guid))
			return .Reference; // what something is known by, as a Ref<T>'s id is
		if (type.IsEnum)
			return .Enum;
		if (type.IsSubtypeOf(typeof(Sedulous.Core.Curve)))
			return .Curve;
		if (type.IsSubtypeOf(typeof(ColorGradient)))
			return .Gradient;
		if (type.IsSubtypeOf(typeof(Node)))
			return .Group;
		return .Other;
	}

	// A place's shape: a group's (an object with a table), else its value's.
	protected Shape ShapeOf(Target target)
	{
		if ((target.Table != null) && (target.Instance != null))
			return .Group;
		if (target.Property == null)
			return .Other;
		return ShapeOf(TypeOf(target), ValueInfoOf(target));
	}

	protected static bool IsGroup(Target target) => (target.Part < 0) && (target.Table != null) && (target.Instance != null);

	// The type of the value at a place (a list's element type for an element).
	protected static System.Type TypeOf(Target target)
	{
		if (target.Property == null)
			return (target.Table != null) ? target.Table.Type : null;
		if (target.Depth == 0)
			return target.Property.ValueType;
		let link = target.Links[target.Depth - 1];
		return (link.Field != null) ? link.Field.ValueType : link.Elements.ElementType;
	}

	// What the value at a place is beyond its type; null when it is only its type.
	protected static GuiValueInfo ValueInfoOf(Target target)
	{
		if (target.Property == null)
			return null;
		if (target.Depth == 0)
			return target.Property.Value;
		let link = target.Links[target.Depth - 1];
		return (link.Field != null) ? link.Field.Value : link.Elements.Element;
	}

	// Whether a member is read only: a property without a setter, unless it is a list (changed in
	// place); a value struct's field is written into its copy.
	protected static bool IsReadOnlyMember(GuiMemberInfo member)
	{
		if (member.Value?.ListInfo != null)
			return false;
		if (let property = member as GuiPropertyInfo)
			return !property.CanWrite;
		return false;
	}

	// A member's HDR colour: a Float4 marked HdrColor.
	protected bool IsHdr(GuiMemberInfo member) =>
		member.Flags.HasFlag(.HdrColor) && (ShapeOf(member.ValueType, member.Value) == .Float4);

	// A member's four floats kept as a colour: a Float4 marked Color.
	protected bool IsColor(GuiMemberInfo member) =>
		member.Flags.HasFlag(.Color) && (ShapeOf(member.ValueType, member.Value) == .Float4);

	// === Paths ===

	// The place `path` names in object `object`.
	protected bool Resolve(int object, StringView path, out Target outTarget)
	{
		outTarget = .();
		return (object >= 0) && (object < mObjects.Count) && ResolveIn(mObjects[object], mType, path, out outTarget);
	}

	protected bool ResolveIn(Object root, GuiTypeInfo table, StringView path, out Target outTarget)
	{
		outTarget = .();
		var at = Target();
		at.Table = table;
		at.Instance = root;
		int start = 0;
		while (start < path.Length)
		{
			var end = start;
			while ((end < path.Length) && (path[end] != '.'))
				++end;
			let segment = path.Substring(start, end - start);
			start = end + 1;
			if (!Step(ref at, segment))
				return false;
		}
		outTarget = at;
		return true;
	}

	// One segment further from `at`: a property of an object, a field of a value struct, an
	// element of a list, or a part.
	protected bool Step(ref Target at, StringView segment)
	{
		if (at.Part >= 0)
			return false;
		if (IsGroup(at))
		{
			let property = at.Table.Find(segment);
			if (property == null)
				return false;
			var next = Target();
			next.Owner = at.Instance;
			next.Property = property;
			next.ReadOnly = at.ReadOnly || IsReadOnlyMember(property);
			next.Hdr = IsHdr(property);
			next.AsColor = IsColor(property);
			if (BaseShapeOf(property.ValueType) == .Group)
			{
				// A node it holds: a group of its own table.
				var value = property.Get(at.Instance);
				defer value.Dispose();
				if (let node = (value.HasValue && value.IsObject) ? (value.Get<Object>() as Node) : null)
				{
					next.Table = node.GuiType;
					next.Instance = node;
				}
			}
			at = next;
			return true;
		}
		if ((at.Property == null) || (at.Depth >= cMostLinks))
			return false;
		let shape = ShapeOf(at);
		if (shape == .Group)
		{
			// A value struct: one of its fields.
			let field = ValueInfoOf(at)?.FindField(segment);
			if (field == null)
				return false;
			at.Links[at.Depth] = Link(field);
			at.Depth++;
			at.Hdr = IsHdr(field);
			at.AsColor = IsColor(field);
			return true;
		}
		if (shape == .List)
		{
			let info = ValueInfoOf(at).ListInfo;
			int index = 0;
			if (int.Parse(segment) case .Ok(let parsed))
				index = parsed;
			else
				return false;
			var held = ReadLink(at, at.Depth);
			defer held.Dispose();
			let list = held.IsObject ? held.Get<Object>() : null;
			if ((list == null) || (index < 0) || (index >= info.Count(list)))
				return false;
			at.Links[at.Depth] = Link(info, index);
			at.Depth++;
			at.Hdr = false;
			at.AsColor = false;
			if (info.HoldsObjects)
			{
				// An object of its own: a group of its table, written in place.
				var element = info.GetAt(list, index);
				defer element.Dispose();
				let object = element.IsObject ? element.Get<Object>() : null;
				let table = (object != null) ? TableOf(info, object) : null;
				if (table == null)
					return false;
				at.Table = table;
				at.Instance = object;
			}
			return true;
		}
		if (at.AsColor)
			return false; // a colour is one value, not its parts
		let part = at.Hdr ? HdrPartIndex(segment) : PartIndex(shape, segment);
		if (part >= 0)
		{
			at.Part = part;
			return true;
		}
		return false;
	}

	// An object in a list: its own type's table (a node's, else the one of the types the list
	// makes that it is), else the list's element type's.
	protected static GuiTypeInfo TableOf(GuiListInfo info, Object element)
	{
		if (let node = element as Node)
			return node.GuiType;
		let types = scope List<GuiTypeInfo>();
		info.GetTypes(types);
		let type = element.GetType();
		for (let table in types)
		{
			if (table.Type == type)
				return table;
		}
		return info.ElementTable;
	}

	// An HDR colour's parts: its colour (rgb), its intensity (w).
	protected static int32 HdrPartIndex(StringView segment)
	{
		if (segment == "color")
			return cHdrColorPart;
		return (segment == "intensity") ? 3 : -1;
	}

	protected static int32 PartIndex(Shape shape, StringView segment)
	{
		if (shape == .Quaternion)
		{
			StringView[3] names = .("pitch", "yaw", "roll");
			for (int32 i = 0; i < 3; ++i)
			{
				if (segment == names[i])
					return i;
			}
			return -1;
		}
		int32 count = (shape == .Float2) ? 2 : ((shape == .Float3) ? 3 : ((shape == .Float4) ? 4 : 0));
		StringView[4] names = .("x", "y", "z", "w");
		for (int32 i = 0; i < count; ++i)
		{
			if (segment == names[i])
				return i;
		}
		return -1;
	}

	// === Rows ===

	// A group's properties, its type's bases first, as rows.
	protected void ListPropertiesOf(StringView path, Target group, List<PropertyInfo> outInfos)
	{
		if ((group.Table == null) || (group.Instance == null))
			return;
		let chain = scope List<GuiTypeInfo>();
		for (var t = group.Table; t != null; t = t.Base)
			chain.Insert(0, t);
		for (let t in chain)
		{
			for (let property in t.OwnProperties)
			{
				let info = new PropertyInfo();
				Describe(path, group, property, info);
				outInfos.Add(info);
			}
		}
	}

	// A value struct's fields, as rows.
	protected void ListFieldsOf(StringView path, Target group, List<PropertyInfo> outInfos)
	{
		let value = ValueInfoOf(group);
		if (value == null)
			return;
		for (let field in value.Fields)
		{
			let info = new PropertyInfo();
			Describe(path, group, field, info);
			outInfos.Add(info);
		}
	}

	// A member as a row: its kind, hint, names and what it carries for an inspector.
	protected void Describe(StringView path, Target group, GuiMemberInfo member, PropertyInfo info)
	{
		info.Name.Set(member.Name);
		if (member.DisplayName.Length != 0)
			info.DisplayName.Set(member.DisplayName);
		else
			ReadablePropertyName(member.Name, info.DisplayName);
		info.Description.Set(member.Description);
		info.ReadOnly = group.ReadOnly || IsReadOnlyMember(member);
		DescribeType(member.ValueType, member.Value, member.Flags.HasFlag(.BitFlags), info);
		if (info.Kind == .Color)
			info.ShowsAlpha = !member.Flags.HasFlag(.NoAlpha);
		if (IsHdr(member))
			info.Hint.Set("ColorHdr");
		else if (IsColor(member))
		{
			// Four floats kept as a colour (a particle's tint): one colour, as a Color is.
			info.Kind = .Color;
			info.Hint.Clear();
			info.ShowsAlpha = !member.Flags.HasFlag(.NoAlpha);
		}
		if (member.HasRange)
		{
			info.HasRange = true;
			info.Min = member.Min;
			info.Max = member.Max;
			info.Step = member.Step;
			// A ranged float slides over its range (an integer's range only bounds its field).
			if ((info.Kind == .Float) && (info.Hint.Length == 0))
				info.Hint.Set("slider");
		}
		// A bare Guid's member may name what it points at ([GuiReference]).
		if ((info.Kind == .Reference) && (info.ReferenceType == null))
			info.ReferenceType = member.ReferenceType;
		if (member.VisibleWhen.Length != 0)
			info.Visible = Holds(path, member.VisibleWhen);
	}

	// A type's kind as a row (`flags`: an enum read as flags), what a member or an element is.
	protected void DescribeType(System.Type type, GuiValueInfo value, bool flags, PropertyInfo info)
	{
		switch (ShapeOf(type, value))
		{
		case .Bool:
			info.Kind = .Bool;
		case .Integer:
			info.Kind = .Integer;
		case .Enum:
			info.Kind = flags ? .Flags : .Enum;
			if (value != null)
			{
				for (let c in value.Cases)
				{
					if (flags && (c.Value == 0))
						continue; // no bit: nothing to tick (a `None`)
					info.AddChoice(ReadablePropertyName(c.Name, .. scope String()), c.Value);
				}
			}
		case .Float:
			info.Kind = .Float;
		case .String:
			info.Kind = .String;
		case .Float2:
			info.Kind = .Group;
			info.Hint.Set("Float2");
		case .Float3:
			info.Kind = .Group;
			info.Hint.Set("Float3");
		case .Float4:
			info.Kind = .Group;
			info.Hint.Set("Float4");
		case .Quaternion:
			info.Kind = .Group;
			info.Hint.Set("Float3"); // Euler degrees
		case .Color:
			info.Kind = .Color;
		case .Curve:
			info.Kind = .Curve;
			if (let parts = FindCurveType(type))
				info.MaxCount = PartCapacity(value, parts.Keys);
		case .Gradient:
			info.Kind = .Gradient;
			if (let parts = FindGradientType(type))
			{
				let colors = PartCapacity(value, parts.Colors);
				let alphas = PartCapacity(value, parts.Alphas);
				info.MaxCount = (colors == 0) ? alphas : (((alphas == 0) || (colors < alphas)) ? colors : alphas); // one most for both kinds
			}
		case .Reference:
			info.Kind = .Reference;
			info.ReferenceType = ReferenceTargetOf(type);
			if (FindReferenceType(type) != null)
			{
				// A registered one: its type's name, for the application's editor.
				info.Hint.Clear();
				type.GetName(info.Hint);
			}
		case .List:
			info.Kind = .List;
			let list = value.ListInfo;
			let types = scope List<GuiTypeInfo>();
			if (list.HoldsObjects)
				CreatableTypes(list, types);
			if (!info.ReadOnly)
			{
				let adds = !list.HoldsObjects || !types.IsEmpty;
				info.ListOps = (uint8)((adds ? PropertyListAdd : 0) | PropertyListRemove | PropertyListMove);
			}
			for (let made in types)
				info.ElementTypes.Add(TypeShownName(made, .. new String()));
			info.MaxCount = (uint32)list.MaxCount; // a bounded array's most
		case .Group, .Other: // its type's name, for an editor of its own; else its rows
			info.Kind = .Group;
			info.Hint.Clear();
			type.GetName(info.Hint);
		}
	}

	// A list of objects' types an add makes: those it names that have a creator.
	protected static void CreatableTypes(GuiListInfo list, List<GuiTypeInfo> outTypes)
	{
		let named = scope List<GuiTypeInfo>();
		list.GetTypes(named);
		for (let type in named)
		{
			if (type.CanCreate)
				outTypes.Add(type);
		}
	}

	// What an add of a type is called: its [DisplayName], else its name.
	protected static void TypeShownName(GuiTypeInfo type, String outText)
	{
		if (type.DisplayName.Length != 0)
			outText.Append(type.DisplayName);
		else
			type.Type.GetName(outText);
	}

	// A list's elements, the fewest any object has, each named by its index (and an object's or a
	// struct's by its type's name).
	protected void ListElements(StringView path, List<PropertyInfo> outInfos)
	{
		if (mObjects.IsEmpty)
			return;
		// A list of bare ids names what its elements point at as a bare id does, by its own
		// member's [GuiReference].
		System.Type named = null;
		Target list = .();
		if (Resolve(0, path, out list))
		{
			if (list.Depth > 0)
				named = list.Links[list.Depth - 1].Field?.ReferenceType;
			else if (list.Property != null)
				named = list.Property.ReferenceType;
		}
		int64 count = int64.MaxValue;
		for (int o = 0; o < mObjects.Count; ++o)
		{
			var value = GetValue(path, o);
			count = Math.Min(count, value.AsInt);
			value.Dispose();
		}
		for (int64 i = 0; i < count; ++i)
		{
			let element = scope String();
			JoinPropertyPath(path, scope String()..AppendF("{}", i), element);
			Target target = .();
			if (!Resolve(0, element, out target))
				continue;
			let info = new PropertyInfo();
			info.Name.AppendF("{}", i);
			info.ReadOnly = target.ReadOnly;
			if (IsGroup(target))
			{
				info.Kind = .Group;
				target.Table.Type.GetName(info.Hint);
				TypeShownName(target.Table, info.DisplayName);
				info.DisplayName.AppendF(" {}", i + 1);
			}
			else
			{
				DescribeType(TypeOf(target), ValueInfoOf(target), false, info);
				if ((info.Kind == .Reference) && (info.ReferenceType == null))
					info.ReferenceType = named;
				if (ShapeOf(target) == .Group)
					info.DisplayName.AppendF("{} {}", info.Hint, i + 1);
				else
					info.DisplayName.AppendF("Element {}", i + 1);
			}
			outInfos.Add(info);
		}
	}

	// `visibleWhen` ("prop", or "prop=1,2" of its raw integer): a sibling's value, in every object.
	protected bool Holds(StringView group, StringView condition)
	{
		int eq = 0;
		while ((eq < condition.Length) && (condition[eq] != '='))
			++eq;
		if (eq == 0)
			return true;
		let sibling = JoinPropertyPath(group, condition.Substring(0, eq), .. scope String());
		for (int o = 0; o < mObjects.Count; ++o)
		{
			var value = GetValue(sibling, o);
			int64 held = value.AsInt;
			if (value.Kind == .Bool)
				held = value.AsBool ? 1 : 0;
			value.Dispose();
			if (!Matches(condition, eq, held))
				return false;
		}
		return true;
	}

	// Whether `value` meets the condition after its name (`eq` is where its `=` is, if any):
	// nonzero, or one of the integers listed.
	protected static bool Matches(StringView condition, int eq, int64 value)
	{
		if (eq == condition.Length)
			return value != 0;
		int start = eq + 1;
		while (start <= condition.Length)
		{
			var end = start;
			while ((end < condition.Length) && (condition[end] != ','))
				++end;
			var listed = condition.Substring(start, end - start);
			listed.Trim();
			if ((int64.Parse(listed) case .Ok(let number)) && (number == value))
				return true;
			start = end + 1;
		}
		return false;
	}

	protected static void ListHdrParts(List<PropertyInfo> outInfos)
	{
		let color = new PropertyInfo();
		color.Name.Set("color");
		color.DisplayName.Set("Color");
		color.Kind = .Color;
		color.ShowsAlpha = false;
		outInfos.Add(color);
		let intensity = new PropertyInfo();
		intensity.Name.Set("intensity");
		intensity.DisplayName.Set("Intensity");
		intensity.Kind = .Float;
		intensity.Hint.Set("stops");
		outInfos.Add(intensity);
	}

	protected static void ListParts(Shape shape, List<PropertyInfo> outInfos)
	{
		StringView[4] floats = .("x", "y", "z", "w");
		StringView[4] shownFloats = .("X", "Y", "Z", "W");
		StringView[3] angles = .("pitch", "yaw", "roll");
		// Shown as the axes they turn about (pitch about X, yaw about Y, roll about Z), so a
		// rotation reads like the position and scale beside it.
		StringView[3] shownAngles = .("X", "Y", "Z");
		let count = (shape == .Float2) ? 2 : ((shape == .Float4) ? 4 : 3);
		for (int i = 0; i < count; ++i)
		{
			let info = new PropertyInfo();
			let euler = shape == .Quaternion;
			info.Name.Set(euler ? angles[i] : floats[i]);
			info.DisplayName.Set(euler ? shownAngles[i] : shownFloats[i]);
			info.Kind = .Float;
			info.Step = euler ? 1.0 : 0.01;
			outInfos.Add(info);
		}
	}

	// === Values ===

	// The value `depth` links below a place's property (0: the property's own), read through the
	// thunks: a field from the struct above (a copy), an element from the list above. The caller
	// disposes it.
	protected System.Variant ReadLink(Target target, int32 depth)
	{
		if (target.Property == null)
			return default;
		if (depth == 0)
			return target.Property.Get(target.Owner);
		var above = ReadLink(target, depth - 1);
		defer above.Dispose();
		if (!above.HasValue)
			return default;
		let link = target.Links[depth - 1];
		if (link.Field != null)
		{
			if (above.IsObject)
				return default; // a field of a value struct only
			return link.Field.Get(above.DataPtr);
		}
		let list = above.IsObject ? above.Get<Object>() : null;
		if ((list == null) || (link.Index >= link.Elements.Count(list)))
			return default;
		return link.Elements.GetAt(list, link.Index);
	}

	// Writes `value` `depth` links below a place's property: a field into a copy of the struct
	// above, written back whole; an element into the list above (in place). The caller keeps
	// `value`.
	protected bool WriteLink(Target target, int32 depth, System.Variant value)
	{
		if (target.Property == null)
			return false;
		if (depth == 0)
			return target.Property.Set(target.Owner, value);
		var above = ReadLink(target, depth - 1);
		defer above.Dispose();
		if (!above.HasValue)
			return false;
		let link = target.Links[depth - 1];
		if (link.Field != null)
			return !above.IsObject && link.Field.Set(above.DataPtr, value) && WriteLink(target, depth - 1, above);
		let list = above.IsObject ? above.Get<Object>() : null;
		return (list != null) && (link.Index < link.Elements.Count(list)) && link.Elements.SetAt(list, link.Index, value);
	}

	// A value at a place, through its links; the caller disposes it.
	protected Sedulous.GUI.Variant Read(Target target)
	{
		if ((target.Property == null) || IsGroup(target))
			return .();
		let shape = ShapeOf(target);
		if (target.Part == cHdrColorPart)
		{
			Float4 parts;
			return ReadCompound(target, .Float4, out parts) ? Sedulous.GUI.Variant(Color(parts.X, parts.Y, parts.Z, 1.0f)) : Sedulous.GUI.Variant();
		}
		if (target.AsColor)
		{
			Float4 parts;
			return ReadCompound(target, .Float4, out parts) ? Sedulous.GUI.Variant(Color(parts.X, parts.Y, parts.Z, parts.W)) : Sedulous.GUI.Variant();
		}
		if (target.Part >= 0)
			return Sedulous.GUI.Variant(PartOf(target, shape));
		let type = TypeOf(target);
		switch (shape)
		{
		case .List:
			{
				var held = ReadLink(target, target.Depth);
				defer held.Dispose();
				let list = held.IsObject ? held.Get<Object>() : null;
				let info = ValueInfoOf(target)?.ListInfo;
				return ((list != null) && (info != null)) ? Sedulous.GUI.Variant((int64)info.Count(list)) : Sedulous.GUI.Variant();
			}
		case .Curve:
			if (FindCurveType(type) != null)
				return ReadCurve(target);
		case .Gradient:
			if (FindGradientType(type) != null)
				return ReadGradient(target);
		case .Reference:
			return ReadReference(target);
		default:
		}
		var value = ReadLink(target, target.Depth);
		defer value.Dispose();
		return FromCore(value, shape, type);
	}

	// Writes `value` to a place; false when it cannot be written.
	protected bool WriteTarget(Target target, Sedulous.GUI.Variant value)
	{
		if ((target.Property == null) || target.ReadOnly || value.IsEmpty || IsGroup(target))
			return false;
		let shape = ShapeOf(target);
		if (target.Part == cHdrColorPart)
		{
			// The colour's rgb, its intensity kept.
			Float4 parts;
			if (!ReadCompound(target, .Float4, out parts))
				return false;
			let color = value.AsColor;
			return WriteCompound(target, .Float4, .(color.R, color.G, color.B, parts.W));
		}
		if (target.AsColor)
		{
			let color = value.AsColor;
			return WriteCompound(target, .Float4, .(color.R, color.G, color.B, color.A));
		}
		if (target.Part >= 0)
			return SetPart(target, shape, value.AsFloat);
		let type = TypeOf(target);
		switch (shape)
		{
		case .Curve:
			{
				if (value.Kind != .Curve)
					return false;
				let keys = scope List<CurveKey>();
				keys.AddRange(value.AsCurve); // the value may be a view of the curve's own keys
				if (FindCurveType(type) != null)
					return WriteCurve(target, keys);
				// Written into the curve it holds.
				var held = ReadLink(target, target.Depth);
				defer held.Dispose();
				let curve = (held.HasValue && held.IsObject) ? (held.Get<Object>() as Sedulous.Core.Curve) : null;
				if (curve == null)
					return false;
				curve.Keys.Clear();
				curve.Keys.AddRange(keys);
				return true;
			}
		case .Gradient:
			{
				if (value.Kind != .Gradient)
					return false;
				if (FindGradientType(type) != null)
					return WriteGradient(target, value.AsGradient);
				var held = ReadLink(target, target.Depth);
				defer held.Dispose();
				let gradient = (held.HasValue && held.IsObject) ? (held.Get<Object>() as ColorGradient) : null;
				if (gradient == null)
					return false;
				gradient.Set(value.AsGradient);
				return true;
			}
		case .String:
			{
				if (type == typeof(String))
				{
					// Written into the text it holds: its setter would take the variant's own.
					var held = ReadLink(target, target.Depth);
					defer held.Dispose();
					let text = (held.HasValue && held.IsObject) ? (held.Get<Object>() as String) : null;
					if (text == null)
						return false;
					text.Set(scope String(value.AsString));
					return true;
				}
			}
		case .Reference:
			return (value.Kind == .String) && WriteReference(target, value.AsString);
		case .List, .Group, .Other:
			return false; // through its elements, fields or rows
		default:
		}
		var boxed = ToCore(value, shape, type);
		defer boxed.Dispose();
		return boxed.HasValue && WriteLink(target, target.Depth, boxed);
	}

	protected void WriteValue(StringView path, int object, PropertyWrite write)
	{
		Target target = .();
		if (Resolve(object, path, out target))
		{
			var old = Read(target);
			defer old.Dispose();
			WriteTarget(target, ApplyPropertyWrite(old, write));
		}
	}

	// A table's value as the grid's (the caller disposes it).
	protected static Sedulous.GUI.Variant FromCore(System.Variant value, Shape shape, System.Type type)
	{
		if (!value.HasValue)
			return .();
		switch (shape)
		{
		case .Bool:
			return Sedulous.GUI.Variant(value.Get<bool>());
		case .Integer, .Enum:
			return Sedulous.GUI.Variant(ReflectedSourceDetail.ReadInteger(value, type));
		case .Float:
			if (value.VariantType == typeof(float))
				return Sedulous.GUI.Variant((double)value.Get<float>());
			return Sedulous.GUI.Variant(value.Get<double>());
		case .String:
			return Sedulous.GUI.Variant(TextOf(value)).Copy();
		case .Color:
			return Sedulous.GUI.Variant(value.Get<Color>());
		case .Curve:
			let curve = value.IsObject ? (value.Get<Object>() as Sedulous.Core.Curve) : null;
			return (curve != null) ? Sedulous.GUI.Variant.FromCurve(curve.Keys).Copy() : Sedulous.GUI.Variant();
		case .Gradient:
			let gradient = value.IsObject ? (value.Get<Object>() as ColorGradient) : null;
			return (gradient != null) ? Sedulous.GUI.Variant(gradient).Copy() : Sedulous.GUI.Variant();
		default:
			return .();
		}
	}

	// The grid's value as the table's, of the member's own type (the caller disposes it).
	protected static System.Variant ToCore(Sedulous.GUI.Variant value, Shape shape, System.Type type)
	{
		switch (shape)
		{
		case .Bool:
			return System.Variant.Create(value.AsBool);
		case .Integer, .Enum:
			return ReflectedSourceDetail.IntegerOf(value.AsInt, type);
		case .Float:
			if (type == typeof(float))
				return System.Variant.Create((float)value.AsFloat);
			return System.Variant.Create(value.AsFloat);
		case .String:
			return TextVariant(value.AsString);
		case .Color:
			return System.Variant.Create(value.AsColor);
		default:
			return default; // a compound: through its parts
		}
	}

	// A Float's part, or a Quaternion's Euler angle in degrees.
	protected double PartOf(Target target, Shape shape)
	{
		Float4 parts;
		if (!ReadCompound(target, shape, out parts))
			return 0.0;
		float[4] values = .(parts.X, parts.Y, parts.Z, parts.W);
		return (double)values[target.Part];
	}

	protected bool SetPart(Target target, Shape shape, double value)
	{
		Float4 parts;
		if (!ReadCompound(target, shape, out parts))
			return false;
		switch (target.Part)
		{
		case 0: parts.X = (float)value;
		case 1: parts.Y = (float)value;
		case 2: parts.Z = (float)value;
		default: parts.W = (float)value;
		}
		return WriteCompound(target, shape, parts);
	}

	// A Float2/3/4 as x, y, z, w; a Quaternion as its Euler degrees (pitch, yaw, roll). The whole
	// value, whatever part the place names.
	protected bool ReadCompound(Target target, Shape shape, out Float4 outParts)
	{
		outParts = .(0.0f, 0.0f, 0.0f, 0.0f);
		if (target.Property == null)
			return false;
		var value = ReadLink(target, target.Depth);
		defer value.Dispose();
		if (!value.HasValue || value.IsObject)
			return false;
		switch (shape)
		{
		case .Float2:
			{
				let v = value.Get<Float2>();
				outParts = .(v.X, v.Y, 0.0f, 0.0f);
				return true;
			}
		case .Float3:
			{
				let v = value.Get<Float3>();
				outParts = .(v.X, v.Y, v.Z, 0.0f);
				return true;
			}
		case .Float4:
			{
				outParts = value.Get<Float4>();
				return true;
			}
		case .Quaternion:
			{
				float yaw = 0.0f;
				float pitch = 0.0f;
				float roll = 0.0f;
				ToYawPitchRoll(value.Get<Quaternion>(), out yaw, out pitch, out roll);
				outParts = .(RadiansToDegrees(pitch), RadiansToDegrees(yaw), RadiansToDegrees(roll), 0.0f);
				return true;
			}
		default:
			return false;
		}
	}

	protected bool WriteCompound(Target target, Shape shape, Float4 parts)
	{
		if ((target.Property == null) || target.ReadOnly)
			return false;
		System.Variant boxed;
		switch (shape)
		{
		case .Float2:
			boxed = System.Variant.Create(Float2(parts.X, parts.Y));
		case .Float3:
			boxed = System.Variant.Create(Float3(parts.X, parts.Y, parts.Z));
		case .Float4:
			boxed = System.Variant.Create(parts);
		case .Quaternion:
			boxed = System.Variant.Create(FromYawPitchRoll(DegreesToRadians(parts.Y), DegreesToRadians(parts.X), DegreesToRadians(parts.Z)));
		default:
			return false;
		}
		defer boxed.Dispose();
		return WriteLink(target, target.Depth, boxed);
	}

	// === Text: each object's value at a path, written and read with the text format ===

	protected void WriteState(StringView path, int object, String outText)
	{
		if (mFormat == null)
			return;
		Target target = .();
		if (!Resolve(object, path, out target))
			return;
		mFormat.Write(scope (ar) => { SerializeTarget(ar, "value", target); }, outText);
	}

	protected bool ReadState(StringView path, int object, StringView text)
	{
		Target target = .();
		if ((mFormat == null) || !Resolve(object, path, out target))
			return false;
		return mFormat.Read(text, scope (ar) => { SerializeTarget(ar, "value", target); });
	}

	// A place either way under `key`: a value as its type, a Float or a Quaternion as Core's own,
	// a curve as its keys and a gradient as its stops (a registered struct's too, read and written
	// whole), a list as its count and elements, an object or a value struct as an object of its
	// members by name.
	protected void SerializeTarget(ISerializer ar, StringView key, Target target)
	{
		if ((target.Property == null) && (target.Table == null))
			return;
		let reading = ar.Mode == .Read;
		if (IsGroup(target))
		{
			SerializeObject(ar, key, target);
			return;
		}
		let shape = ShapeOf(target);
		if ((target.Part == cHdrColorPart) || target.AsColor)
		{
			var read = Read(target);
			defer read.Dispose();
			var value = read.AsColor;
			ar.Key(key);
			Serialize(ar, ref value);
			if (reading)
				WriteTarget(target, Sedulous.GUI.Variant(value));
			return;
		}
		if (target.Part >= 0)
		{
			var value = PartOf(target, shape);
			ar.Key(key);
			Serialize(ar, ref value);
			if (reading)
				SetPart(target, shape, value);
			return;
		}
		switch (shape)
		{
		case .Bool:
			{
				var read = Read(target);
				defer read.Dispose();
				var value = read.AsBool;
				ar.Key(key);
				Serialize(ar, ref value);
				if (reading)
					WriteTarget(target, Sedulous.GUI.Variant(value));
			}
		case .Integer, .Enum:
			{
				var read = Read(target);
				defer read.Dispose();
				var value = read.AsInt;
				ar.Key(key);
				Serialize(ar, ref value);
				if (reading)
					WriteTarget(target, Sedulous.GUI.Variant(value));
			}
		case .Float:
			{
				var read = Read(target);
				defer read.Dispose();
				var value = read.AsFloat;
				ar.Key(key);
				Serialize(ar, ref value);
				if (reading)
					WriteTarget(target, Sedulous.GUI.Variant(value));
			}
		case .String, .Reference: // a reference as its Guid's text
			{
				var read = Read(target);
				defer read.Dispose();
				let value = scope String(read.AsString);
				Serialize(ar, key, value);
				if (reading)
					WriteTarget(target, Sedulous.GUI.Variant(value));
			}
		case .Color:
			{
				var read = Read(target);
				defer read.Dispose();
				var value = read.AsColor;
				ar.Key(key);
				Serialize(ar, ref value);
				if (reading)
					WriteTarget(target, Sedulous.GUI.Variant(value));
			}
		case .Float2, .Float3, .Float4, .Quaternion:
			{
				Float4 parts;
				ReadCompound(target, shape, out parts);
				ar.Key(key);
				if (shape == .Float2)
				{
					var value = Float2(parts.X, parts.Y);
					Serialize(ar, ref value);
					parts = .(value.X, value.Y, 0.0f, 0.0f);
				}
				else if (shape == .Float4)
					Serialize(ar, ref parts);
				else
				{
					var value = Float3(parts.X, parts.Y, parts.Z); // a Quaternion as its Euler degrees, as the grid shows it
					Serialize(ar, ref value);
					parts = .(value.X, value.Y, value.Z, 0.0f);
				}
				if (reading)
					WriteCompound(target, shape, parts);
			}
		case .Curve:
			{
				// Its keys whole, Core's or a registered struct's alike.
				var read = Read(target);
				defer read.Dispose();
				let keys = scope List<CurveKey>();
				keys.AddRange(read.AsCurve);
				ar.Key(key);
				ReflectedSourceDetail.SerializeKeys(ar, keys);
				if (reading)
					WriteTarget(target, Sedulous.GUI.Variant.FromCurve(keys));
			}
		case .Gradient:
			{
				var read = Read(target);
				defer read.Dispose();
				let gradient = scope ColorGradient();
				gradient.Set(read.AsGradient);
				ar.Key(key);
				ReflectedSourceDetail.SerializeGradient(ar, gradient);
				if (reading)
					WriteTarget(target, Sedulous.GUI.Variant(gradient));
			}
		case .Group:
			SerializeFields(ar, key, target);
		case .List:
			SerializeList(ar, key, target);
		default:
		}
	}

	// An object with a table either way: an object of its properties by name, its type's first.
	protected void SerializeObject(ISerializer ar, StringView key, Target target)
	{
		let reading = ar.Mode == .Read;
		ar.Key(key);
		ar.BeginObject();
		for (var t = target.Table; t != null; t = t.Base)
		{
			for (let property in t.OwnProperties)
			{
				var child = Target();
				child.Owner = target.Instance;
				child.Property = property;
				child.ReadOnly = target.ReadOnly || IsReadOnlyMember(property);
				child.Hdr = IsHdr(property);
				child.AsColor = IsColor(property);
				if (child.ReadOnly && reading)
					continue;
				if (reading && !ar.HasKey(property.Name))
					continue;
				if (BaseShapeOf(property.ValueType) == .Group)
					continue; // a node it holds is its own, not written with its holder
				SerializeTarget(ar, property.Name, child);
			}
		}
		ar.EndObject();
	}

	// A value struct either way: an object of its fields by name, each written into a copy of the
	// struct and the copy written back.
	protected void SerializeFields(ISerializer ar, StringView key, Target target)
	{
		let value = ValueInfoOf(target);
		if ((value == null) || (target.Depth >= cMostLinks))
			return;
		let reading = ar.Mode == .Read;
		ar.Key(key);
		ar.BeginObject();
		for (let field in value.Fields)
		{
			if (reading && !ar.HasKey(field.Name))
				continue;
			var child = target;
			child.Links[child.Depth] = Link(field);
			child.Depth++;
			child.Hdr = IsHdr(field);
			child.AsColor = IsColor(field);
			SerializeTarget(ar, field.Name, child);
		}
		ar.EndObject();
	}

	// A list either way: its count, each object's type (a list of objects), then each element.
	// Read, the list takes the count before its elements are read: a list of objects is rebuilt
	// from the types written, a list of values grown or cut at its end.
	protected void SerializeList(ISerializer ar, StringView key, Target target)
	{
		let info = ValueInfoOf(target)?.ListInfo;
		var held = ReadLink(target, target.Depth);
		defer held.Dispose();
		let list = held.IsObject ? held.Get<Object>() : null;
		if ((info == null) || (list == null) || (target.Depth >= cMostLinks))
			return;
		let reading = ar.Mode == .Read;
		ar.Key(key);
		ar.BeginObject();
		var count = (int64)info.Count(list);
		ar.Key("count");
		Serialize(ar, ref count);
		if (reading && !target.ReadOnly)
		{
			if (info.HoldsObjects)
			{
				while (info.Count(list) != 0)
					info.RemoveAt(list, info.Count(list) - 1);
				let creatable = scope List<GuiTypeInfo>();
				CreatableTypes(info, creatable);
				for (int64 i = 0; i < count; ++i)
				{
					let type = scope String();
					Serialize(ar, ElementKey(i, true, .. scope String()), type);
					for (let made in creatable)
					{
						if (made.Type.GetName(.. scope String()) != type)
							continue;
						let made = made.Create();
						if ((made != null) && !info.InsertObject(list, info.Count(list), made))
							GuiListInfo.ReleaseElement(made);
						break;
					}
				}
			}
			else
			{
				while ((info.Count(list) > count) && (count >= 0))
					info.RemoveAt(list, info.Count(list) - 1);
				while (info.Count(list) < count)
				{
					if (!info.Insert(list, info.Count(list)))
						break; // a bounded list at its most
				}
			}
		}
		else if (info.HoldsObjects)
		{
			// Written, each element's type; read into a list that is read only, passed over.
			for (int64 i = 0; i < count; ++i)
			{
				let type = scope String();
				if (i < info.Count(list))
				{
					var element = info.GetAt(list, (int)i);
					if (element.IsObject && (element.Get<Object>() != null))
						element.Get<Object>().GetType().GetName(type);
					element.Dispose();
				}
				Serialize(ar, ElementKey(i, true, .. scope String()), type);
			}
		}
		let size = info.Count(list);
		for (int i = 0; i < size; ++i)
		{
			let elementKey = ElementKey(i, false, .. scope String());
			if (reading && !ar.HasKey(elementKey))
				continue;
			var element = target;
			element.Links[element.Depth] = Link(info, i);
			element.Depth++;
			element.Hdr = false;
			element.AsColor = false;
			if (info.HoldsObjects)
			{
				var object = info.GetAt(list, i);
				let instance = object.IsObject ? object.Get<Object>() : null;
				object.Dispose();
				let table = (instance != null) ? TableOf(info, instance) : null;
				if (table == null)
					continue;
				element.Table = table;
				element.Instance = instance;
			}
			SerializeTarget(ar, elementKey, element);
		}
		ar.EndObject();
	}

	// "e3" for element 3, "t3" for its type, appended to `outKey`.
	protected static void ElementKey(int64 index, bool type, String outKey)
	{
		outKey.AppendF("{}{}", type ? "t" : "e", index);
	}

	// Each value at `path` and under it in object `object` given its default; a list whole, as the
	// type's instance has it. Whether anything changed.
	protected bool RevertUnder(StringView path, int object)
	{
		Target target = .();
		if (!Resolve(object, path, out target) || target.ReadOnly)
			return false;
		let shape = (target.Part >= 0) ? Shape.Float : ShapeOf(target);
		if (shape == .List)
		{
			if ((mTypeDefault == null) || (mFormat == null))
				return false;
			let before = WriteState(path, object, .. scope String());
			Target byDefault = .();
			if (!ResolveIn(mTypeDefault, mType, path, out byDefault))
				return false;
			let text = scope String();
			mFormat.Write(scope (ar) => { SerializeTarget(ar, "value", byDefault); }, text);
			ReadState(path, object, text);
			return WriteState(path, object, .. scope String()) != before;
		}
		if ((shape == .Group) || (shape == .Float2) || (shape == .Float3) || (shape == .Float4) || (shape == .Quaternion))
		{
			let children = scope List<PropertyInfo>();
			defer { ClearAndDeleteItems!(children); }
			GetProperties(path, children);
			bool changed = false;
			for (let child in children)
				changed = RevertUnder(JoinPropertyPath(path, child.Name, .. scope String()), object) || changed;
			return changed;
		}
		var byDefault = GetDefault(path, object);
		defer byDefault.Dispose();
		var now = Read(target);
		defer now.Dispose();
		if (byDefault.IsEmpty || (now.Compare(byDefault) == 0))
			return false;
		return WriteTarget(target, byDefault);
	}

	// What a copy is, so a paste takes only its like: a Float's name (a Quaternion's Euler degrees a
	// Float3, as the grid shows it), a struct's or an object's type, a list of its elements' type, a
	// value's kind; appended to `outText`.
	protected void ShapeTag(Target target, String outText)
	{
		if ((target.Part == cHdrColorPart) || target.AsColor)
		{
			outText.Append("Color");
			return;
		}
		if (target.Part >= 0)
		{
			outText.Append("number");
			return;
		}
		if (target.Hdr)
		{
			outText.Append("ColorHdr");
			return;
		}
		if (IsGroup(target))
		{
			target.Table.Type.GetName(outText);
			return;
		}
		switch (ShapeOf(target))
		{
		case .Bool: outText.Append("bool");
		case .Integer, .Enum: outText.Append("integer");
		case .Float: outText.Append("number");
		case .String: outText.Append("text");
		case .Float2: outText.Append("Float2");
		case .Float3, .Quaternion: outText.Append("Float3");
		case .Float4: outText.Append("Float4");
		case .Color: outText.Append("Color");
		case .Reference:
			// Only a reference to its like.
			outText.Append("reference to ");
			if (let to = ReferenceTargetOf(TypeOf(target)))
				to.GetName(outText);
			else
				outText.Append("?");
		case .Curve, .Gradient, .Group:
			TypeOf(target).GetName(outText);
		case .List:
			outText.Append("list of ");
			ValueInfoOf(target).ListInfo.ElementType.GetName(outText);
		default:
		}
	}

	// === Lists ===

	// One object's list changed as `edit` asks.
	protected bool ChangeList(Target target, ListEdit edit)
	{
		let info = ValueInfoOf(target)?.ListInfo;
		var held = ReadLink(target, target.Depth);
		defer held.Dispose();
		let list = held.IsObject ? held.Get<Object>() : null;
		if ((info == null) || (list == null))
			return false;
		let size = info.Count(list);
		switch (edit.Kind)
		{
		case .Insert:
			let at = Math.Min(Math.Max(edit.Index, 0), size);
			if (info.HoldsObjects)
			{
				let creatable = scope List<GuiTypeInfo>();
				CreatableTypes(info, creatable);
				for (let made in creatable)
				{
					if ((edit.ElementType.Length != 0) && (TypeShownName(made, .. scope String()) != edit.ElementType))
						continue;
					if (info.IsFull(list))
						return false;
					let made = made.Create();
					if (made == null)
						return false;
					if (info.InsertObject(list, at, made))
						return true;
					GuiListInfo.ReleaseElement(made);
					return false;
				}
				return false;
			}
			return info.Insert(list, at);
		case .Remove:
			if ((edit.Index < 0) || (edit.Index >= size))
				return false;
			info.RemoveAt(list, edit.Index);
			return true;
		default: // a move
			if ((edit.Index < 0) || (edit.Index >= size) || (edit.To < 0) || (edit.To >= size) || (edit.Index == edit.To))
				return false;
			info.Move(list, edit.Index, edit.To);
			return true;
		}
	}

	protected static void ListWords(StringView path, ListEdit edit, String outText)
	{
		switch (edit.Kind)
		{
		case .Insert: outText.AppendF("Added to {}", path);
		case .Remove: outText.AppendF("Removed from {}", path);
		case .Move: outText.AppendF("Moved in {}", path);
		}
	}

	// === References: a Guid's text, through the shape, a registered struct's field or the Guid itself ===

	private ReferenceType FindReferenceType(System.Type type)
	{
		if (mReferenceTypes.IsEmpty || (type == null))
			return null;
		let name = type.GetName(.. scope String());
		for (let entry in mReferenceTypes)
		{
			if (entry.Name == name)
				return entry;
		}
		return null;
	}

	// What a reference of `type` points at: a registered struct itself, nothing for a bare Guid (its
	// member may say), else what the application's shape says.
	protected System.Type ReferenceTargetOf(System.Type type)
	{
		if (FindReferenceType(type) != null)
			return type;
		if (type == typeof(Guid))
			return null;
		return (mReferenceShape != null) ? mReferenceShape.Target(type) : null;
	}

	// The Guid in `value`, the reference at `target` as read (a bare Guid, a registered struct's
	// field, or through the shape); false when it has none.
	protected bool ReferenceIdOf(Target target, System.Variant value, out Guid outId)
	{
		outId = .();
		if (!value.HasValue || value.IsObject)
			return false;
		let type = TypeOf(target);
		var held = value;
		if (type == typeof(Guid))
		{
			outId = held.Get<Guid>();
			return true;
		}
		if (let parts = FindReferenceType(type))
		{
			let field = ValueInfoOf(target)?.FindField(parts.Id);
			if ((field == null) || (field.ValueType != typeof(Guid)))
				return false;
			var read = field.Get(held.DataPtr);
			defer read.Dispose();
			if (!read.HasValue)
				return false;
			outId = read.Get<Guid>();
			return true;
		}
		if ((mReferenceShape == null) || !mReferenceShape.Is(type))
			return false;
		if (mReferenceShape.Id(type, held.DataPtr) case .Ok(let id))
		{
			outId = id;
			return true;
		}
		return false;
	}

	// A reference's Guid as text; empty when it names nothing (or has no Guid to read).
	protected Sedulous.GUI.Variant ReadReference(Target target)
	{
		var value = ReadLink(target, target.Depth);
		defer value.Dispose();
		Guid id = .();
		if (!ReferenceIdOf(target, value, out id) || id.IsNil)
			return Sedulous.GUI.Variant(StringView());
		return Sedulous.GUI.Variant(id.ToString(.. scope String())).Copy();
	}

	// Writes the Guid `text` names (empty: none) to the reference at `target`: a bare Guid through
	// its setter; a registered struct's field, or the shape's Assign (which drops the binding, so the
	// next resolve binds the new id), into a copy written back whole. False for text that is no Guid.
	protected bool WriteReference(Target target, StringView text)
	{
		var trimmed = text;
		trimmed.Trim();
		Guid id = .();
		if ((trimmed.Length != 0) && !(Guid.Parse(trimmed) case .Ok(out id)))
			return false;
		let type = TypeOf(target);
		if (type == typeof(Guid))
		{
			var boxed = System.Variant.Create(id);
			defer boxed.Dispose();
			return WriteLink(target, target.Depth, boxed);
		}
		var whole = ReadLink(target, target.Depth);
		defer whole.Dispose();
		if (!whole.HasValue || whole.IsObject)
			return false;
		if (let parts = FindReferenceType(type))
		{
			let field = ValueInfoOf(target)?.FindField(parts.Id);
			if ((field == null) || (field.ValueType != typeof(Guid)))
				return false;
			var boxed = System.Variant.Create(id);
			defer boxed.Dispose();
			return field.Set(whole.DataPtr, boxed) && WriteLink(target, target.Depth, whole);
		}
		return (mReferenceShape != null) && mReferenceShape.Is(type) && mReferenceShape.Assign(type, whole.DataPtr, id)
			&& WriteLink(target, target.Depth, whole);
	}

	// === Registered curves and gradients: the parts the application named, read and written whole ===

	private CurveType FindCurveType(System.Type type)
	{
		if (mCurveTypes.IsEmpty || (type == null))
			return null;
		let name = type.GetName(.. scope String());
		for (let entry in mCurveTypes)
		{
			if (entry.Name == name)
				return entry;
		}
		return null;
	}

	private GradientType FindGradientType(System.Type type)
	{
		if (mGradientTypes.IsEmpty || (type == null))
			return null;
		let name = type.GetName(.. scope String());
		for (let entry in mGradientTypes)
		{
			if (entry.Name == name)
				return entry;
		}
		return null;
	}

	// The most the list field `name` of a value struct holds (0: no limit, or no such list).
	protected static uint32 PartCapacity(GuiValueInfo value, StringView name)
	{
		let list = value?.FindField(name)?.Value?.ListInfo;
		return (list != null) ? (uint32)list.MaxCount : 0;
	}

	// The list field `name` of the value struct at `target`: its list and what it is; false when
	// absent.
	protected bool PartList(Target target, StringView name, out Object outList, out GuiListInfo outInfo)
	{
		outList = null;
		outInfo = null;
		let field = ValueInfoOf(target)?.FindField(name);
		let info = field?.Value?.ListInfo;
		if (info == null)
			return false;
		var whole = ReadLink(target, target.Depth);
		defer whole.Dispose();
		if (!whole.HasValue || whole.IsObject)
			return false;
		var held = field.Get(whole.DataPtr);
		defer held.Dispose();
		outList = held.IsObject ? held.Get<Object>() : null;
		outInfo = info;
		return outList != null;
	}

	// The list's elements as `T` (Core's key or stop), by value, appended to `outValues`.
	protected static void ReadElements<T>(GuiListInfo info, Object list, List<T> outValues) where T : struct
	{
		for (int i = 0; i < info.Count(list); ++i)
		{
			var element = info.GetAt(list, i);
			if (element.VariantType == typeof(T))
				outValues.Add(element.Get<T>());
			element.Dispose();
		}
	}

	// The list made `values`: grown or cut to their count (a bounded list to its most), then each
	// set. False when it could not hold them all.
	protected static bool WriteElements<T>(GuiListInfo info, Object list, Span<T> values) where T : struct
	{
		while (info.Count(list) > values.Length)
			info.RemoveAt(list, info.Count(list) - 1);
		while (info.Count(list) < values.Length)
		{
			if (!info.Insert(list, info.Count(list)))
				break; // at its most
		}
		bool all = info.Count(list) == values.Length;
		for (int i = 0; i < info.Count(list); ++i)
		{
			var boxed = System.Variant.Create(values[i]);
			all = info.SetAt(list, i, boxed) && all;
			boxed.Dispose();
		}
		return all;
	}

	protected Sedulous.GUI.Variant ReadCurve(Target target)
	{
		let parts = FindCurveType(TypeOf(target));
		Object list = null;
		GuiListInfo info = null;
		if ((parts == null) || !PartList(target, parts.Keys, out list, out info))
			return .();
		let keys = scope List<CurveKey>();
		ReadElements(info, list, keys);
		return Sedulous.GUI.Variant.FromCurve(keys).Copy();
	}

	protected bool WriteCurve(Target target, Span<CurveKey> keys)
	{
		let parts = FindCurveType(TypeOf(target));
		Object list = null;
		GuiListInfo info = null;
		return (parts != null) && PartList(target, parts.Keys, out list, out info) && WriteElements(info, list, keys);
	}

	protected Sedulous.GUI.Variant ReadGradient(Target target)
	{
		let parts = FindGradientType(TypeOf(target));
		if (parts == null)
			return .();
		let gradient = scope ColorGradient();
		Object list = null;
		GuiListInfo info = null;
		if (PartList(target, parts.Colors, out list, out info))
			ReadElements(info, list, gradient.Colors);
		if (PartList(target, parts.Alphas, out list, out info))
			ReadElements(info, list, gradient.Alphas);
		if (let blend = ValueInfoOf(target)?.FindField(parts.Interpolation))
		{
			var whole = ReadLink(target, target.Depth);
			defer whole.Dispose();
			if (whole.HasValue && !whole.IsObject)
			{
				var held = blend.Get(whole.DataPtr);
				gradient.Interpolation = (GradientInterpolation)ReflectedSourceDetail.ReadInteger(held, blend.ValueType);
				held.Dispose();
			}
		}
		return Sedulous.GUI.Variant(gradient).Copy();
	}

	protected bool WriteGradient(Target target, ColorGradient gradient)
	{
		let parts = FindGradientType(TypeOf(target));
		if (parts == null)
			return false;
		Object list = null;
		GuiListInfo info = null;
		bool ok = PartList(target, parts.Colors, out list, out info) && WriteElements<GradientColorStop>(info, list, gradient.Colors);
		ok = PartList(target, parts.Alphas, out list, out info) && WriteElements<GradientAlphaStop>(info, list, gradient.Alphas) && ok;
		if (let blend = ValueInfoOf(target)?.FindField(parts.Interpolation))
		{
			// The blend into a copy of the struct, written back whole.
			var whole = ReadLink(target, target.Depth);
			defer whole.Dispose();
			if (whole.HasValue && !whole.IsObject)
			{
				var bits = ReflectedSourceDetail.IntegerOf((int64)gradient.Interpolation, blend.ValueType);
				defer bits.Dispose();
				ok = blend.Set(whole.DataPtr, bits) && WriteLink(target, target.Depth, whole) && ok;
			}
		}
		return ok;
	}

	// A property's change may show or hide others (visibleWhen): the properties changed.
	protected void Changed(StringView path)
	{
		NotifyPropertiesChanged();
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

	private void DropOriginal(StringView path)
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

	private void ReleaseTypeDefault()
	{
		if (mTypeDefault == null)
			return;
		if (let counted = mTypeDefault as IRefCounted)
			counted.Release();
		else
			delete mTypeDefault;
		mTypeDefault = null;
	}
}

/// What ReflectedSource.bf keeps out of the public surface.
internal static class ReflectedSourceDetail
{
	/// An integer (or an enum's) value as an int64, by its own type's width and sign (an enum's
	/// underlying type's).
	public static int64 ReadInteger(System.Variant value, System.Type type)
	{
		var held = value;
		let data = held.DataPtr;
		if (data == null)
			return 0;
		var integer = type;
		if (type.IsEnum && (type.UnderlyingType != null))
			integer = type.UnderlyingType;
		switch (integer.Size)
		{
		case 1: return integer.IsSigned ? (int64)*(int8*)data : (int64)*(uint8*)data;
		case 2: return integer.IsSigned ? (int64)*(int16*)data : (int64)*(uint16*)data;
		case 4: return integer.IsSigned ? (int64)*(int32*)data : (int64)*(uint32*)data;
		default: return *(int64*)data;
		}
	}

	/// `bits` as a Variant of `type` itself (an integer type, or an enum), so its setter takes it
	/// without a conversion.
	public static System.Variant IntegerOf(int64 bits, System.Type type)
	{
		var value = bits;
		int8 v8 = (int8)bits;
		int16 v16 = (int16)bits;
		int32 v32 = (int32)bits;
		switch (type.Size)
		{
		case 1: return System.Variant.Create(type, &v8);
		case 2: return System.Variant.Create(type, &v16);
		case 4: return System.Variant.Create(type, &v32);
		default: return System.Variant.Create(type, &value);
		}
	}

	/// A curve's keys either way: their count, then each key's fields.
	public static void SerializeKeys(ISerializer ar, List<CurveKey> keys)
	{
		uint32 count = (uint32)keys.Count;
		ar.BeginArray(ref count);
		if (ar.Mode == .Read)
		{
			keys.Clear();
			for (uint32 i = 0; (i < count) && ar.IsPayloadOk; ++i)
				keys.Add(CurveKey());
		}
		for (int i = 0; i < keys.Count; ++i)
		{
			ar.BeginObject();
			ar.Key("time");
			Serialize(ar, ref keys[i].Time);
			ar.Key("value");
			Serialize(ar, ref keys[i].Value);
			ar.Key("tangentIn");
			Serialize(ar, ref keys[i].TangentIn);
			ar.Key("tangentOut");
			Serialize(ar, ref keys[i].TangentOut);
			ar.Key("interpolation");
			SerializeEnum(ar, ref keys[i].Interpolation);
			ar.Key("tangentMode");
			SerializeEnum(ar, ref keys[i].TangentMode);
			ar.EndObject();
		}
		ar.EndArray();
	}

	/// A gradient either way: its colour stops, its alpha stops, its blend.
	public static void SerializeGradient(ISerializer ar, ColorGradient gradient)
	{
		ar.BeginObject();
		ar.Key("colors");
		uint32 colors = (uint32)gradient.Colors.Count;
		ar.BeginArray(ref colors);
		if (ar.Mode == .Read)
		{
			gradient.Colors.Clear();
			for (uint32 i = 0; (i < colors) && ar.IsPayloadOk; ++i)
				gradient.Colors.Add(GradientColorStop());
		}
		for (int i = 0; i < gradient.Colors.Count; ++i)
		{
			ar.BeginObject();
			ar.Key("time");
			Serialize(ar, ref gradient.Colors[i].Time);
			ar.Key("color");
			Serialize(ar, ref gradient.Colors[i].Color);
			ar.EndObject();
		}
		ar.EndArray();
		ar.Key("alphas");
		uint32 alphas = (uint32)gradient.Alphas.Count;
		ar.BeginArray(ref alphas);
		if (ar.Mode == .Read)
		{
			gradient.Alphas.Clear();
			for (uint32 i = 0; (i < alphas) && ar.IsPayloadOk; ++i)
				gradient.Alphas.Add(GradientAlphaStop());
		}
		for (int i = 0; i < gradient.Alphas.Count; ++i)
		{
			ar.BeginObject();
			ar.Key("time");
			Serialize(ar, ref gradient.Alphas[i].Time);
			ar.Key("alpha");
			Serialize(ar, ref gradient.Alphas[i].Alpha);
			ar.EndObject();
		}
		ar.EndArray();
		ar.Key("interpolation");
		SerializeEnum(ar, ref gradient.Interpolation);
		ar.EndObject();
	}
}
