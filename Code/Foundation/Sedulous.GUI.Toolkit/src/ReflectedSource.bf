using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using internal Sedulous.GUI;

namespace Sedulous.GUI;

// The property source over the GUI's reflection: one reflected object or several of one type, their
// properties as the grid's paths. A type is reflected by its [GuiReflect] table (GuiTypeInfo): its
// [GuiProperty] properties, its base's after its own, each read and written through its table's
// get and set.
//   - bool, every integer width, float, double and text are values; an enum is its integer (its
//     enumerators are not in the table); a property without a setter is read only.
//   - A Color is a colour.
//   - Float2, Float3 and Float4 are groups hinted with their names, their parts x, y, z, w; a
//     Quaternion is a Float3 group of Euler degrees (pitch, yaw, roll) the source converts, as the
//     editor's Transform row does; a node held by a property is a group of its own table's
//     properties.
//   - Core's Curve is one value of kind Curve, its keys whole; the GUI's ColorGradient is one value
//     of kind Gradient.
//   - Any other type is a group hinted with its type's name, for an application's editor; with no
//     editor, the grid's row saying no editor fits.
//   - A row says its property's name made readable.
// Defaults: the type's, read from an instance its creator makes, under any an application stacks
// over it (a prefab's, by path and object); a revert puts each object's own back.
// Writes go through the property's setter. Each commit is told to the application as one change:
// what, where, and each object's value there before and after as text, written with the text
// format the application gives (its serializer), which Restore reads back for an undo; the undo is
// the application's.

/// What the application gives a reflected source to write text with: its serializer (the engine's
/// XmlSerializer, say), so the toolkit takes on no format.
interface IPropertyTextFormat
{
	/// Text written by `write`, appended to `outText`; nothing when it failed.
	void Write(delegate void(ISerializer ar) write, String outText);
	/// Reads `text` with `read`; false when it is not the format's or the read failed.
	bool Read(StringView text, delegate void(ISerializer ar) read);
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
		/// Core's Curve.
		Curve,
		/// The GUI's ColorGradient.
		Gradient,
		/// An object with a table of its own (the root, a node a property holds).
		Group,
		Other,
	}

	// A place a path names in one object: a property of an owner, a part of a Float or a
	// Quaternion, or an object with a table (the root, a node a property holds).
	protected struct Target
	{
		// A group's: its table and its object.
		public GuiTypeInfo Table = null;
		public Object Instance = null;
		// A property's: its owner and its record.
		public Object Owner = null;
		public GuiPropertyInfo Property = null;
		// A part of the Float or Quaternion above.
		public int32 Part = -1;
		public bool ReadOnly = false;

		public this() { }
	}

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

	// Not owned: the application's.
	private List<Object> mObjects = new .() ~ delete _;
	private GuiTypeInfo mType = null;
	private List<Original> mOriginals = new .() ~ DeleteContainerAndItems!(_);
	// Not owned.
	private IPropertyTextFormat mFormat = null;
	private List<Provider> mProviders = new .() ~ DeleteContainerAndItems!(_);
	// The type's defaults, made by its creator.
	private Object mTypeDefault = null;
	private delegate void(ReflectedChange change) mOnChange ~ delete _;

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
		NotifyPropertiesChanged(); // what shows may have changed back
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

	// === IPropertySource ===

	public override int ObjectCount => mObjects.Count;

	public override void GetProperties(StringView parent, List<PropertyInfo> outInfos)
	{
		if (mObjects.IsEmpty)
			return;
		Target target = .();
		if (!Resolve(0, parent, out target))
			return;
		if ((parent.Length == 0) || IsGroup(target))
		{
			ListPropertiesOf(target, outInfos);
			return;
		}
		let shape = ShapeOf(target);
		if ((target.Part < 0) && ((shape == .Float2) || (shape == .Float3) || (shape == .Float4) || (shape == .Quaternion)))
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

	/// A table holds no lists (a list's elements are not reflected), so no list is changed here.
	public override bool EditList(StringView path, ListEdit edit) => false;

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

	// A type's shape, what a property of it is.
	protected static Shape ShapeOf(System.Type type)
	{
		if (type == null)
			return .Other;
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

	// A place's shape: a group's (an object with a table), else its property's type's.
	protected static Shape ShapeOf(Target target)
	{
		if (target.Property == null)
			return (target.Table != null) ? .Group : .Other;
		return ShapeOf(target.Property.ValueType);
	}

	protected static bool IsGroup(Target target) => (target.Part < 0) && (target.Table != null) && (target.Instance != null);

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

	// One segment further from `at`: a property of a group, or a part.
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
			next.ReadOnly = at.ReadOnly || !property.CanWrite;
			if (ShapeOf(property.ValueType) == .Group)
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
		if (at.Property == null)
			return false;
		let part = PartIndex(ShapeOf(at), segment);
		if (part >= 0)
		{
			at.Part = part;
			return true;
		}
		return false;
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

	// A group's properties, its type's bases first, as rows.
	protected void ListPropertiesOf(Target group, List<PropertyInfo> outInfos)
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
				Describe(group, property, info);
				outInfos.Add(info);
			}
		}
	}

	// A property as a row: its kind, hint and names.
	protected void Describe(Target group, GuiPropertyInfo property, PropertyInfo info)
	{
		info.Name.Set(property.Name);
		ReadablePropertyName(property.Name, info.DisplayName);
		info.ReadOnly = group.ReadOnly || !property.CanWrite;
		DescribeType(property.ValueType, info);
	}

	// A type's kind as a row.
	protected void DescribeType(System.Type type, PropertyInfo info)
	{
		switch (ShapeOf(type))
		{
		case .Bool:
			info.Kind = .Bool;
		case .Integer, .Enum:
			info.Kind = .Integer;
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
		case .Gradient:
			info.Kind = .Gradient;
		case .Group, .Other: // its type's name, for an editor of its own; else its rows
			info.Kind = .Group;
			info.Hint.Clear();
			type.GetName(info.Hint);
		}
	}

	protected static void ListParts(Shape shape, List<PropertyInfo> outInfos)
	{
		StringView[4] floats = .("x", "y", "z", "w");
		StringView[4] shownFloats = .("X", "Y", "Z", "W");
		StringView[3] angles = .("pitch", "yaw", "roll");
		StringView[3] shownAngles = .("Pitch", "Yaw", "Roll");
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

	// A value at a place, through its property's get; the caller disposes it.
	protected Sedulous.GUI.Variant Read(Target target)
	{
		if (target.Property == null)
			return .();
		let shape = ShapeOf(target);
		if (target.Part >= 0)
			return Sedulous.GUI.Variant(PartOf(target, shape));
		var value = target.Property.Get(target.Owner);
		defer value.Dispose();
		return FromCore(value, shape, target.Property.ValueType);
	}

	// Writes `value` to a place; false when it cannot be written.
	protected bool WriteTarget(Target target, Sedulous.GUI.Variant value)
	{
		if ((target.Property == null) || target.ReadOnly || value.IsEmpty)
			return false;
		let shape = ShapeOf(target);
		if (target.Part >= 0)
			return SetPart(target, shape, value.AsFloat);
		let type = target.Property.ValueType;
		switch (shape)
		{
		case .Curve:
			{
				// Written into the curve it holds.
				if (value.Kind != .Curve)
					return false;
				var held = target.Property.Get(target.Owner);
				defer held.Dispose();
				let curve = (held.HasValue && held.IsObject) ? (held.Get<Object>() as Sedulous.Core.Curve) : null;
				if (curve == null)
					return false;
				let keys = scope List<CurveKey>();
				keys.AddRange(value.AsCurve); // the value may be a view of the curve's own keys
				curve.Keys.Clear();
				curve.Keys.AddRange(keys);
				return true;
			}
		case .Gradient:
			{
				if (value.Kind != .Gradient)
					return false;
				var held = target.Property.Get(target.Owner);
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
					var held = target.Property.Get(target.Owner);
					defer held.Dispose();
					let text = (held.HasValue && held.IsObject) ? (held.Get<Object>() as String) : null;
					if (text == null)
						return false;
					text.Set(scope String(value.AsString));
					return true;
				}
			}
		default:
		}
		var boxed = ToCore(value, shape, type);
		defer boxed.Dispose();
		return boxed.HasValue && target.Property.Set(target.Owner, boxed);
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

	// The grid's value as the table's, of the property's own type (the caller disposes it).
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

	// A Float2/3/4 as x, y, z, w; a Quaternion as its Euler degrees (pitch, yaw, roll).
	protected bool ReadCompound(Target target, Shape shape, out Float4 outParts)
	{
		outParts = .(0.0f, 0.0f, 0.0f, 0.0f);
		if (target.Property == null)
			return false;
		var value = target.Property.Get(target.Owner);
		defer value.Dispose();
		if (!value.HasValue)
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
		return target.Property.Set(target.Owner, boxed);
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
	// a curve as its keys, a gradient as its stops, a group as an object of its properties by name.
	protected void SerializeTarget(ISerializer ar, StringView key, Target target)
	{
		if ((target.Property == null) && (target.Table == null))
			return;
		let reading = ar.Mode == .Read;
		let shape = ShapeOf(target);
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
		case .String:
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
			{
				if ((target.Table == null) || (target.Instance == null))
					return;
				ar.Key(key);
				ar.BeginObject();
				for (var t = target.Table; t != null; t = t.Base)
				{
					for (let property in t.OwnProperties)
					{
						var child = Target();
						child.Owner = target.Instance;
						child.Property = property;
						child.ReadOnly = target.ReadOnly || !property.CanWrite;
						if (child.ReadOnly && reading)
							continue;
						if (reading && !ar.HasKey(property.Name))
							continue;
						if (ShapeOf(property.ValueType) == .Group)
							continue; // a node it holds is its own, not written with its holder
						SerializeTarget(ar, property.Name, child);
					}
				}
				ar.EndObject();
			}
		default:
		}
	}

	// Each value at `path` and under it in object `object` given its default. Whether anything
	// changed.
	protected bool RevertUnder(StringView path, int object)
	{
		Target target = .();
		if (!Resolve(object, path, out target) || target.ReadOnly)
			return false;
		let shape = (target.Part >= 0) ? Shape.Float : ShapeOf(target);
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
	// Float3, as the grid shows it), a group's type, a value's kind; appended to `outText`.
	protected void ShapeTag(Target target, String outText)
	{
		if (target.Part >= 0)
		{
			outText.Append("number");
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
		case .Curve, .Gradient:
			target.Property.ValueType.GetName(outText);
		case .Group:
			if (target.Table != null)
				target.Table.Type.GetName(outText);
		default:
		}
	}

	// A property's change may show or hide others: the properties changed.
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
