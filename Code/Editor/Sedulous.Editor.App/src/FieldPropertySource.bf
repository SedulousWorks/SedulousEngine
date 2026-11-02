using System;
using System.Collections;
using System.Reflection;
using Sedulous.Core;
using Sedulous.Json;
using Sedulous.Resource;
using Sedulous.Scene;
using Sedulous.GUI;

namespace Sedulous.Editor.App;

/// A property source over values that live at an address, read through their RUN TIME field
/// reflection: a component inside its manager's pool, a copy of an entity's transform, a scene's
/// settings block, or the asset an asset page holds (AssetObjectPage). Raptor shows these with the
/// toolkit's reflected source, over its one reflection; here the toolkit's reflects the GUI's own
/// [GuiReflect] objects, and a component is a struct a pool holds and an asset an object that only
/// Beef's reflection describes ([Component], [SerializableComponent] and [Serializable] ask for
/// their fields), so the editor reads them through FieldJson, as the MCP tools do (the user's
/// rulings, 2026-10-29). Its rows are the shown
/// fields (public, instance, not [Hidden]; a private one marked [InspectorField] too, though FieldJson
/// and the MCP tools still see only the public) by path, as the toolkit's are:
///   - bool, every integer width, float, double and text are values; an enum is choices from its
///     cases; a Color is a colour; a Guid is a reference (to what its [References] names), and a
///     Ref<T> one to its T; an EntityRef
///     is a reference by its id, hinted "EntityRef" (the scene's entity slot, chosen before the
///     asset one).
///   - Float2, Float3 and Float4 are groups hinted with their names, their parts x, y, z, w; a
///     Quaternion is a Float3 group of Euler degrees (pitch, yaw, roll). A Float4 field marked
///     [AsColor] is a colour as a Color is (four floats a runtime keeps its tints in), one value.
///   - A List<T> is a list, its elements by index; one of plain values (no text, no objects) may
///     have elements added (its type's default when that reflects), removed and moved. A list of Guids marked [References] names its
///     elements' target, as a single Guid's does. A list of objects (which it owns) adds any type
///     deriving from its element type that can be made, chosen by [DisplayName] (else its name),
///     removes (deleting the object) and moves; each element is named by its own type.
///   - A value struct registered as a curve (its fixed array of CurveKey and the count of those in
///     use) is one value of kind Curve, its keys whole; one registered as a gradient (its colour and
///     alpha stop arrays, their counts, its blend) one of kind Gradient: the toolkit's curve and
///     gradient editors take them. The registry is the process's (RegisterCurveType,
///     RegisterGradientType): an editor library registers its runtime's types once.
///   - A structure or an object with shown fields is a group of them; any other type (one with
///     none: an asset's SourcePath) a group hinted with its type's name, for an editor registered
///     by that name (an asset page's source file).
///   - A method marked [InspectorProperty] is a row of its own after the fields, by the attribute's
///     name: its getter's value, written through the named setter (read only without one), its
///     own [DisplayName], [Description] and [Range] said as a field's are.
///   - A row says its [DisplayName], else its field's name made readable; its [Description], its
///     [Range] (a ranged float a slider), [ReadOnly] and [VisibleWhen] ("Kind" or "Kind=1,2",
///     a sibling's; shown when it holds for every object).
/// Its values are re-resolved on every call (a pool moves). An edit previews on the live values;
/// its commit puts the originals back and hands the owner the write to apply as one change, the
/// owner's undo (a component's through its edit context, a transform's through its command).
/// Defaults are the type's, from an instance its default constructor makes. An object type's value
/// is the object itself at its address (a settings block a system keeps as a class); a field that
/// holds one is the reference to it.
class FieldPropertySource : IPropertySource
{
	/// Object `object`'s live value; null when it is gone.
	public typealias Resolver = delegate void*(int object);
	/// Applies a change: `apply` run over each object's live value, the owner's one undo step.
	public typealias Committer = delegate void(delegate void(int object, void* value) apply);

	private enum Shape : uint8
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
		Guid,
		Reference,
		EntityRef,
		Curve,
		Gradient,
		List,
		Group,
		Other,
	}

	// A place a path names in one object: a value of a type at an address, or a Quaternion's Euler
	// angle (the quaternion's address).
	private struct Target
	{
		public void* Address = null;
		public Type Type = null;
		public int32 Euler = -1;
		public bool ReadOnly = false;
		/// The address is an object's own, not a reference to one: the root of an object type.
		public bool Direct = false;
		/// A Float4 field marked [AsColor]: one colour, not its parts.
		public bool AsColor = false;
		/// What a list field's Guid elements point at (its [References]); null: nothing named.
		public Type ElementReference = null;
		/// An [InspectorProperty] row: Owner is what its getter and setter are called on (an
		/// object's own address, or a struct's), Type the getter's value's; Address is Owner too.
		public bool Accessor = false;
		public void* Owner = null;
		public Type OwnerType = null;
		public MethodInfo Getter = default;

		public this() { }
	}

	/// An EntityRef's hint: the entity slot's.
	public const String cEntityRefHint = "EntityRef";

	/// Where a value struct registered as a curve keeps its keys, by field name: a fixed array of
	/// CurveKey (its length the most keys) and the int32 counting those in use.
	public struct CurveParts
	{
		public StringView Keys;
		public StringView Count;

		public this(StringView keys, StringView count)
		{
			Keys = keys;
			Count = count;
		}
	}

	/// Where a value struct registered as a gradient keeps its parts, by field name: fixed arrays of
	/// GradientColorStop and GradientAlphaStop, the int32s counting those in use, and its
	/// GradientInterpolation.
	public struct GradientParts
	{
		public StringView Colors;
		public StringView ColorCount;
		public StringView Alphas;
		public StringView AlphaCount;
		public StringView Interpolation;

		public this(StringView colors, StringView colorCount, StringView alphas, StringView alphaCount, StringView interpolation)
		{
			Colors = colors;
			ColorCount = colorCount;
			Alphas = alphas;
			AlphaCount = alphaCount;
			Interpolation = interpolation;
		}
	}

	// The process's curve and gradient value types (their part names live as long as the process:
	// literals).
	private static Dictionary<Type, CurveParts> sCurveTypes = new .() ~ delete _;
	private static Dictionary<Type, GradientParts> sGradientTypes = new .() ~ delete _;

	/// A value struct shown as one curve value, its keys where `parts` says; its fields must be
	/// reflected. Again replaces.
	public static void RegisterCurveType(Type type, CurveParts parts) { sCurveTypes[type] = parts; }
	/// A value struct shown as one gradient value, its parts where `parts` says.
	public static void RegisterGradientType(Type type, GradientParts parts) { sGradientTypes[type] = parts; }

	// The process's hint attributes: a field carrying one is hinted with its name (literals).
	private static List<(delegate bool(FieldInfo field) carries, String hint)> sHintAttributes = new .() ~ { for (let entry in _) delete entry.carries; delete _; };

	/// Hints a field carrying the attribute `T` with `hint` (a literal: it lives as long as the
	/// process), for the application's editor of what that attribute says (a string naming a bone
	/// of a skeleton). Raptor's RegisterHintAttribute: Beef reads an attribute by its type.
	public static void RegisterHintAttribute<T>(String hint) where T : Attribute
	{
		delegate bool(FieldInfo field) carries = new (field) => field.HasCustomAttribute<T>();
		sHintAttributes.Add((carries, hint));
	}

	private Type mType;
	private int mCount;
	private Resolver mResolve ~ delete _;
	private Committer mCommit ~ delete _;
	/// SetOnDescribe's; null: none.
	private delegate void(StringView path, PropertyInfo info) mOnDescribe = null ~ delete _;
	/// SetOnCommitted's; null: none.
	private delegate void(StringView path) mOnCommitted = null ~ delete _;
	// Not owned: what a reference written binds through; null binds it on its next resolve.
	private ResourceManager mResources;
	// The type's defaults; null when its default constructor is not reflected.
	private void* mDefault = null;
	private String mEditPath = new .() ~ delete _;
	// Each object's value at mEditPath when its edit began, for a cancel and the commit.
	private List<Sedulous.GUI.Variant> mOriginals = new .() ~ DisposeAll(_);

	/// `count` objects of `type`, each found by `resolve` and changed through `commit` (both
	/// taken); a reference written binds through `resources` (null: on its next resolve).
	public this(Type type, int count, Resolver resolve, Committer commit, ResourceManager resources = null)
	{
		mType = type;
		mCount = count;
		mResolve = resolve;
		mCommit = commit;
		mResources = resources;
		if (let instance = type as TypeInstance)
		{
			if (instance.CreateValue() case .Ok(let made))
				mDefault = made;
		}
	}

	public ~this()
	{
		if (mDefault != null)
			delete mDefault;
	}

	public Type ValueType => mType;
	/// An edit is open (begun, not yet committed or cancelled).
	public bool Editing => mEditPath.Length != 0;
	/// The path of the edit open now, or being committed (the committer may ask); empty when none.
	public StringView EditPath => mEditPath;

	/// The values changed elsewhere (a gizmo's drag, an undo): what shows is read again.
	public void Refresh() => NotifyPropertiesChanged();

	// === IPropertySource ===

	public override int ObjectCount => mCount;

	public override void GetProperties(StringView parent, List<PropertyInfo> outInfos)
	{
		let first = outInfos.Count;
		ListProperties(parent, outInfos);
		// What the application says of each (a list element named by a field of its own, a group's
		// line, a row shown only by its source): its describe hook, last, as the toolkit's reflected
		// source has it.
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

	/// Told after each change committed through it (an edit, a revert, a paste, a list's change),
	/// with the path it changed. OWNERSHIP of `onCommitted` transfers.
	public void SetOnCommitted(delegate void(StringView path) onCommitted)
	{
		delete mOnCommitted;
		mOnCommitted = onCommitted;
	}

	private void Committed(StringView path)
	{
		if (mOnCommitted != null)
			mOnCommitted(path);
	}

	/// Told of each row as it is described, its info to change: what the fields cannot say of it (an
	/// element's name from a field of its own, a closed group's line, a row shown or not by another's
	/// value). OWNERSHIP of `onDescribe` transfers.
	public void SetOnDescribe(delegate void(StringView path, PropertyInfo info) onDescribe)
	{
		delete mOnDescribe;
		mOnDescribe = onDescribe;
	}

	private void ListProperties(StringView parent, List<PropertyInfo> outInfos)
	{
		let target = Resolve(parent, Address(0));
		if ((target.Address == null) || (target.Euler >= 0))
			return;
		// An object held by reference is shaped by its own type (a list's module under an abstract base).
		var shaped = target;
		if (target.Type.IsObject && !target.Direct && (target.Type != typeof(String)) && (ElementOf(target.Type) == null))
		{
			if (let held = *(Object*)target.Address)
				shaped.Type = held.GetType();
		}
		switch (ShapeAt(shaped))
		{
		case .Float2: ListParts(2, false, outInfos);
		case .Float3: ListParts(3, false, outInfos);
		case .Float4: ListParts(4, false, outInfos);
		case .Quaternion: ListParts(3, true, outInfos);
		case .List: ListElements(parent, target, outInfos);
		case .Group: ListFields(parent, target, outInfos);
		default:
		}
	}

	public override Sedulous.GUI.Variant GetValue(StringView path, int object)
	{
		return Read(Resolve(path, Address(object)));
	}

	public override void BeginEdit(StringView path)
	{
		mEditPath.Set(path);
		DisposeAll(mOriginals, false);
		for (int i < mCount)
			mOriginals.Add(GetValue(path, i));
	}

	public override void PreviewEdit(StringView path, PropertyWrite write)
	{
		if (!IsEditing(path))
			BeginEdit(path);
		for (int i < mCount)
			WriteAt(path, Address(i), i, write);
	}

	public override void CommitEdit(StringView path, PropertyWrite write)
	{
		if (!IsEditing(path))
			BeginEdit(path);
		PutOriginalsBack();
		let held = scope String(path);
		mCommit(scope [&] (object, value) => { WriteAt(held, value, object, write); });
		mEditPath.Clear();
		DisposeAll(mOriginals, false);
		Committed(held);
	}

	public override void CancelEdit(StringView path)
	{
		if (!IsEditing(path))
			return;
		PutOriginalsBack();
		mEditPath.Clear();
		DisposeAll(mOriginals, false);
	}

	public override bool EditList(StringView path, ListEdit edit)
	{
		let target = Resolve(path, Address(0));
		if ((target.Address == null) || target.ReadOnly || (ShapeOf(target.Type) != .List))
			return false;
		let element = ElementOf(target.Type);
		let objects = HoldsObjectElements(element);
		if (!objects && !MayChangeList(element))
			return false;
		var changed = false;
		let held = scope String(path);
		mCommit(scope [&] (object, value) =>
			{
				let list = ListAt(Resolve(held, value));
				if ((list != null) && (objects ? ChangeObjectList(list, edit) : ChangeList(list, edit)))
					changed = true;
			});
		if (changed)
			Committed(held);
		return changed;
	}

	public override Sedulous.GUI.Variant GetDefault(StringView path, int object)
	{
		if (mDefault == null)
			return .();
		let target = Resolve(path, mDefault);
		if (ShapeOf(target.Type) == .List)
			return .();
		return Read(target);
	}

	public override bool Revert(StringView path)
	{
		if (mDefault == null)
			return false;
		// The values under `path` (itself, when it is one) that differ from the type's.
		let leaves = scope List<String>();
		defer { ClearAndDeleteItems!(leaves); }
		CollectValues(path, leaves);
		var differs = false;
		for (let leaf in leaves)
		{
			var wanted = GetDefault(leaf, 0);
			defer wanted.Dispose();
			for (int i < mCount)
			{
				var now = GetValue(leaf, i);
				defer now.Dispose();
				if ((now.Kind != wanted.Kind) || (now.Compare(wanted) != 0))
					differs = true;
			}
		}
		if (!differs)
			return false;
		mCommit(scope [&] (object, value) =>
			{
				for (let leaf in leaves)
				{
					var wanted = Read(Resolve(leaf, mDefault));
					defer wanted.Dispose();
					Write(Resolve(leaf, value), wanted);
				}
			});
		for (let leaf in leaves)
			Committed(leaf);
		return true;
	}

	public override void GetRevertText(StringView path, String outText)
	{
		if (mDefault != null)
			outText.Append("Revert to default");
	}

	public override void CopyValue(StringView path, String outText)
	{
		let target = Resolve(path, Address(0));
		if (target.Address == null)
			return;
		if (target.Euler >= 0)
		{
			var angle = Read(target);
			defer angle.Dispose();
			angle.AsFloat.ToString(outText);
			return;
		}
		if (target.Accessor)
		{
			let value = scope uint8[Math.Max(target.Type.Stride, sizeof(int64))]*;
			if (!ReadAccessor(target, value))
				return;
			let json = FieldJson.ValueJson(target.Type, value);
			defer delete json;
			json.ToString(outText);
			return;
		}
		let json = FieldJson.ValueJson(target.AsColor ? typeof(Color) : target.Type, target.Address);
		defer delete json;
		json.ToString(outText);
	}

	public override bool PasteValue(StringView path, StringView text, String reason)
	{
		let target = Resolve(path, Address(0));
		if ((target.Address == null) || target.ReadOnly)
		{
			reason.Set("Read only");
			return false;
		}
		let json = JsonValue.Parse(text);
		defer delete json;
		var value = ValueOf(target, json);
		defer value.Dispose();
		if (value.IsEmpty)
		{
			reason.Set("The clipboard holds no value of this kind");
			return false;
		}
		let held = scope String(path);
		mCommit(scope [&] (object, at) => { Write(Resolve(held, at), value); });
		Committed(held);
		return true;
	}

	/// Object `object`'s values: each value row's path (none read only, no list's) and its value,
	/// appended (the caller deletes the paths and disposes the values). What an undo puts back.
	public void ReadValues(int object, List<String> outPaths, List<Sedulous.GUI.Variant> outValues)
	{
		let start = outPaths.Count;
		CollectValues("", outPaths);
		for (int i = start; i < outPaths.Count; ++i)
			outValues.Add(GetValue(outPaths[i], object));
	}

	/// Writes `values` at `paths` (ReadValues') into object `object`'s value, as they are.
	public void WriteValues(int object, Span<String> paths, Span<Sedulous.GUI.Variant> values)
	{
		let root = Address(object);
		for (int i < Math.Min(paths.Length, values.Length))
			Write(Resolve(paths[i], root), values[i]);
	}

	// === Paths ===

	private void* Address(int object) => ((object >= 0) && (object < mCount)) ? mResolve(object) : null;

	private bool IsEditing(StringView path) => (mEditPath.Length != 0) && (mEditPath == path) && (mOriginals.Count == mCount);

	private void PutOriginalsBack()
	{
		for (int i < Math.Min(mCount, mOriginals.Count))
			Write(Resolve(mEditPath, Address(i)), mOriginals[i]);
	}

	// `write` applied to object `object`'s value at `path` under `root` (flags keep the bits
	// outside its mask, over what the edit began with).
	private void WriteAt(StringView path, void* root, int object, PropertyWrite write)
	{
		let target = Resolve(path, root);
		if (write.Mask == ~(uint64)0)
		{
			Write(target, write.Value);
			return;
		}
		let old = (object < mOriginals.Count) ? mOriginals[object].View() : Read(target);
		var applied = ApplyPropertyWrite(old, write);
		defer applied.Dispose();
		Write(target, applied);
	}

	// What `path` names under `root`: each segment a field, a part of a Float, an angle of a
	// Quaternion, or an element of a list by its index.
	private Target Resolve(StringView path, void* root)
	{
		var target = Target();
		target.Address = root;
		target.Type = mType;
		target.Direct = mType.IsObject;
		if ((root == null) || (path.Length == 0))
			return target;
		for (let segment in path.Split('.'))
		{
			if ((target.Address == null) || (target.Euler >= 0) || target.Accessor)
				return Target(); // an accessor's row is a value, no parts
			// An object held by reference (a list's module): its own type's fields, not its slot's type's
			// (an abstract base may have none).
			if (target.Type.IsObject && !target.Direct && (target.Type != typeof(String)) && (ElementOf(target.Type) == null))
			{
				let held = *(Object*)target.Address;
				if (held == null)
					return Target();
				target.Address = Internal.UnsafeCastToPtr(held);
				target.Type = held.GetType();
				target.Direct = true;
			}
			switch (ShapeAt(target)) // a colour has no parts
			{
			case .Quaternion:
				let angle = AngleIndex(segment);
				if (angle < 0)
					return Target();
				target.Euler = angle;
			case .Float2, .Float3, .Float4:
				let part = PartIndex(segment, PartCount(target.Type));
				if (part < 0)
					return Target();
				target.Address = (uint8*)target.Address + part * sizeof(float);
				target.Type = typeof(float);
			case .List:
				let list = ListAt(target);
				if (!(int.Parse(segment) case .Ok(let index)) || (list == null) || (index < 0) || (index >= list.Count))
					return Target();
				target.Address = list.ElementAddress(index);
				target.Type = list.ElementType;
				target.ElementReference = null;
			case .Group:
				var address = target.Address;
				var type = target.Type;
				if (type.IsObject && !target.Direct)
				{
					let held = *(Object*)address;
					if (held == null)
						return Target();
					address = Internal.UnsafeCastToPtr(held);
					type = held.GetType();
				}
				if (!(type.GetField(scope String(segment)) case .Ok(let field)) || !IsShown(field))
				{
					// An [InspectorProperty] row by its name.
					if (!FindAccessor(type, segment, var getter, var property))
						return Target();
					target.Accessor = true;
					target.Owner = address;
					target.OwnerType = type;
					target.Getter = getter;
					target.Address = address;
					target.Type = getter.ReturnType;
					target.Direct = false;
					target.AsColor = false;
					target.ElementReference = null;
					target.ReadOnly = target.ReadOnly || (property.Setter.Length == 0);
					continue;
				}
				target.Address = (uint8*)address + field.MemberOffset;
				target.Type = field.FieldType;
				target.Direct = false;
				target.ReadOnly = target.ReadOnly || field.HasCustomAttribute<ReadOnlyAttribute>();
				target.AsColor = (field.FieldType == typeof(Float4)) && field.HasCustomAttribute<AsColorAttribute>();
				target.ElementReference = (ElementOf(field.FieldType) != null) ? ReferenceOf(field) : null;
			default:
				return Target();
			}
		}
		return target;
	}

	// The value paths under `path` (itself when it is one), for a revert.
	private void CollectValues(StringView path, List<String> outPaths)
	{
		let target = Resolve(path, Address(0));
		if (target.Address == null)
			return;
		let shape = (target.Euler >= 0) ? Shape.Float : ShapeAt(target);
		if (shape == .List)
			return; // a list keeps its elements
		if ((shape != .Group) && (shape != .Float2) && (shape != .Float3) && (shape != .Float4) && (shape != .Quaternion))
		{
			if ((shape != .Other) && !target.ReadOnly)
				outPaths.Add(new String(path));
			return;
		}
		if (shape == .Quaternion)
		{
			outPaths.Add(new String(path)); // whole, not by its angles
			return;
		}
		let infos = scope List<PropertyInfo>();
		defer { ClearAndDeleteItems!(infos); }
		GetProperties(path, infos);
		for (let info in infos)
		{
			if (info.ReadOnly)
				continue;
			CollectValues(JoinPropertyPath(path, info.Name, .. scope String()), outPaths);
		}
	}

	// === Rows ===

	private void ListFields(StringView parent, Target group, List<PropertyInfo> outInfos)
	{
		var type = group.Type;
		if (type.IsObject && !group.Direct)
		{
			let held = *(Object*)group.Address;
			if (held == null)
				return;
			type = held.GetType();
		}
		for (let field in type.GetFields())
		{
			if (!IsShown(field))
				continue;
			let info = new PropertyInfo();
			info.Name.Set(field.Name);
			if (field.GetCustomAttribute<DisplayNameAttribute>() case .Ok(let shown))
				info.DisplayName.Set(shown.Name);
			else
				ReadablePropertyName(field.Name, info.DisplayName);
			if (field.GetCustomAttribute<DescriptionAttribute>() case .Ok(let description))
				info.Description.Set(description.Text);
			info.ReadOnly = group.ReadOnly || field.HasCustomAttribute<ReadOnlyAttribute>();
			DescribeType(field.FieldType, info);
			// Four floats kept as a colour (a particle's tint): one colour, as a Color is.
			if ((field.FieldType == typeof(Float4)) && (field.GetCustomAttribute<AsColorAttribute>() case .Ok(let asColor)))
			{
				info.Kind = .Color;
				info.Hint.Clear();
				info.ShowsAlpha = asColor.ShowsAlpha;
			}
			// A guid that says what it is the id of: a slot for that.
			if ((info.Kind == .Reference) && (info.ReferenceType == null))
				info.ReferenceType = ReferenceOf(field);
			if (field.GetCustomAttribute<RangeAttribute>() case .Ok(let range))
			{
				info.HasRange = true;
				info.Min = range.Min;
				info.Max = range.Max;
				info.Step = range.Step;
				// A ranged float slides over its range (an integer's range only bounds its field).
				if ((info.Kind == .Float) && (info.Hint.Length == 0))
					info.Hint.Set("slider");
			}
			for (let entry in sHintAttributes)
			{
				if ((info.Hint.Length == 0) && entry.carries(field))
					info.Hint.Set(entry.hint);
			}
			if (field.GetCustomAttribute<VisibleWhenAttribute>() case .Ok(let visible))
				info.Visible = Holds(parent, visible.Condition);
			outInfos.Add(info);
		}
		// The computed rows, after the fields.
		for (let method in type.GetMethods())
		{
			if (method.IsStatic || (method.ParamCount != 0))
				continue;
			if (!(method.GetCustomAttribute<InspectorPropertyAttribute>() case .Ok(let property)))
				continue;
			let info = new PropertyInfo();
			info.Name.Set(property.Name);
			if (method.GetCustomAttribute<DisplayNameAttribute>() case .Ok(let shown))
				info.DisplayName.Set(shown.Name);
			else
				ReadablePropertyName(property.Name, info.DisplayName);
			if (method.GetCustomAttribute<DescriptionAttribute>() case .Ok(let description))
				info.Description.Set(description.Text);
			info.ReadOnly = group.ReadOnly || (property.Setter.Length == 0);
			DescribeType(method.ReturnType, info);
			if (method.GetCustomAttribute<RangeAttribute>() case .Ok(let range))
			{
				info.HasRange = true;
				info.Min = range.Min;
				info.Max = range.Max;
				info.Step = range.Step;
				if ((info.Kind == .Float) && (info.Hint.Length == 0))
					info.Hint.Set("slider");
			}
			outInfos.Add(info);
		}
	}

	private void ListElements(StringView parent, Target target, List<PropertyInfo> outInfos)
	{
		// The elements every object has.
		var count = int.MaxValue;
		for (int i < mCount)
		{
			let list = ListAt(Resolve(parent, Address(i)));
			count = Math.Min(count, (list != null) ? list.Count : 0);
		}
		let element = ElementOf(target.Type);
		if ((count == int.MaxValue) || (element == null))
			return;
		let list0 = ListAt(target); // the first object's, for its elements' own types
		for (int i < count)
		{
			let info = new PropertyInfo();
			i.ToString(info.Name);
			info.ReadOnly = target.ReadOnly;
			DescribeType(element, info);
			// A list of ids names what its elements point at, by its own field's [References].
			if ((info.Kind == .Reference) && (info.ReferenceType == null))
				info.ReferenceType = target.ElementReference;
			let held = HoldsObjectElements(element) ? HeldAt(list0, i) : null;
			if (held != null)
			{
				// A module by its own type: a group of its own fields.
				info.Kind = .Group;
				info.Hint.Clear();
				info.DisplayName.AppendF("{} {}", TypeShownName(held.GetType(), .. scope String()), i + 1);
			}
			else if (ShapeOf(element) == .Group)
				info.DisplayName.AppendF("{} {}", element.GetName(.. scope String()), i + 1);
			else
				info.DisplayName.AppendF("Element {}", i + 1);
			outInfos.Add(info);
		}
	}

	// A type's kind as a row: what a field or an element is.
	private void DescribeType(Type type, PropertyInfo info)
	{
		switch (ShapeOf(type))
		{
		case .Bool:
			info.Kind = .Bool;
		case .Integer:
			info.Kind = .Integer;
		case .Float:
			info.Kind = .Float;
		case .String:
			info.Kind = .String;
		case .Enum:
			info.Kind = .Enum;
			for (var (name, value) in Enum.GetEnumerator(type))
				info.AddChoice(ReadablePropertyName(name, .. scope String()), value);
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
			info.MaxCount = (uint32)CurveMost(type);
		case .Gradient:
			info.Kind = .Gradient;
			info.MaxCount = (uint32)GradientMost(type);
		case .Guid:
			info.Kind = .Reference;
		case .Reference:
			info.Kind = .Reference;
			info.ReferenceType = ReferenceShape.Target(type);
		case .List:
			info.Kind = .List;
			let element = ElementOf(type);
			if (!info.ReadOnly && MayChangeList(element))
				info.ListOps = PropertyListAdd | PropertyListRemove | PropertyListMove;
			else if (!info.ReadOnly && HoldsObjectElements(element))
			{
				// Objects: an add chooses among the types that can be made.
				let creatable = CreatableTypes(element);
				for (let made in creatable)
					info.ElementTypes.Add(TypeShownName(made, .. new String()));
				info.ListOps = PropertyListRemove | PropertyListMove;
				if (!creatable.IsEmpty)
					info.ListOps |= PropertyListAdd;
			}
		case .Group:
			info.Kind = .Group;
		case .EntityRef:
			info.Kind = .Reference;
			info.Hint.Set(cEntityRefHint);
		case .Other:
			// For an application's editor by its type's name; none yet says no editor fits.
			info.Kind = .Group;
			type.GetName(info.Hint);
		}
	}

	private static void ListParts(int count, bool euler, List<PropertyInfo> outInfos)
	{
		StringView[4] floats = .("x", "y", "z", "w");
		StringView[4] shownFloats = .("X", "Y", "Z", "W");
		StringView[3] angles = .("pitch", "yaw", "roll");
		// Shown as the axes they turn about (pitch about X, yaw about Y, roll about Z), so a
		// rotation reads like the position and scale beside it.
		StringView[3] shownAngles = .("X", "Y", "Z");
		for (int i < count)
		{
			let info = new PropertyInfo();
			info.Name.Set(euler ? angles[i] : floats[i]);
			info.DisplayName.Set(euler ? shownAngles[i] : shownFloats[i]);
			info.Kind = .Float;
			info.Step = euler ? 1.0 : 0.01;
			outInfos.Add(info);
		}
	}

	// `visibleWhen` ("prop", or "prop=1,2" of its raw integer): a sibling's value, in every object.
	// A condition that does not read so (no name, an empty or non-integer value) hides nothing.
	private bool Holds(StringView group, StringView condition)
	{
		var eq = condition.IndexOf('=');
		if (eq == 0)
			return true;
		if (eq < 0)
			eq = condition.Length;
		for (var listed in condition.Substring(Math.Min(eq + 1, condition.Length)).Split(','))
		{
			listed.Trim();
			if ((eq < condition.Length) && !(int64.Parse(listed) case .Ok))
				return true;
		}
		let sibling = JoinPropertyPath(group, condition.Substring(0, eq), .. scope String());
		for (int i < mCount)
		{
			var value = GetValue(sibling, i);
			let held = (value.Kind == .Bool) ? (value.AsBool ? 1 : 0) : value.AsInt;
			value.Dispose();
			if (!Matches(condition, eq, held))
				return false;
		}
		return true;
	}

	// Whether `value` meets the condition after its name (`eq` is where its `=` is, if any):
	// nonzero, or one of the integers listed.
	private static bool Matches(StringView condition, int eq, int64 value)
	{
		if (eq == condition.Length)
			return value != 0;
		for (var listed in condition.Substring(eq + 1).Split(','))
		{
			listed.Trim();
			if ((int64.Parse(listed) case .Ok(let number)) && (number == value))
				return true;
		}
		return false;
	}

	// === Values ===

	private static Shape ShapeOf(Type type)
	{
		if (type == null)
			return .Other;
		if (ReferenceShape.Is(type))
			return .Reference;
		if (type == typeof(EntityRef))
			return .EntityRef;
		if (type.IsEnum)
			return .Enum;
		switch (type)
		{
		case typeof(bool): return .Bool;
		case typeof(float), typeof(double): return .Float;
		case typeof(int8), typeof(uint8), typeof(int16), typeof(uint16), typeof(int32), typeof(uint32),
			typeof(int64), typeof(uint64), typeof(int), typeof(uint):
			return .Integer;
		case typeof(String): return .String;
		case typeof(Guid): return .Guid;
		case typeof(Float2): return .Float2;
		case typeof(Float3): return .Float3;
		case typeof(Float4): return .Float4;
		case typeof(Quaternion): return .Quaternion;
		case typeof(Color): return .Color;
		default:
		}
		if (sCurveTypes.ContainsKey(type))
			return .Curve;
		if (sGradientTypes.ContainsKey(type))
			return .Gradient;
		if (ElementOf(type) != null)
			return .List;
		if (type.IsObject || (type.IsStruct && !type.IsPrimitive))
			return HasShownFields(type) ? .Group : .Other;
		return .Other;
	}

	private static Type ElementOf(Type type) => FieldJson.ListElement(type);

	// === Curves and gradients ===

	// A part of a registered value struct at `address`: its address, and the length of the fixed
	// array it is (0 when it is none).
	private static void* PartAt(Type type, void* address, StringView name, out int outLength)
	{
		outLength = 0;
		if (!(type.GetField(scope String(name)) case .Ok(let field)))
			return null;
		if (let array = field.FieldType as SizedArrayType)
			outLength = array.ElementCount;
		return (uint8*)address + field.MemberOffset;
	}

	private static int CurveMost(Type type)
	{
		if (!sCurveTypes.TryGetValue(type, let parts))
			return 0;
		if (!(type.GetField(scope String(parts.Keys)) case .Ok(let field)))
			return 0;
		return (field.FieldType as SizedArrayType)?.ElementCount ?? 0;
	}

	private static int GradientMost(Type type)
	{
		if (!sGradientTypes.TryGetValue(type, let parts))
			return 0;
		var colors = 0;
		var alphas = 0;
		if (type.GetField(scope String(parts.Colors)) case .Ok(let field))
			colors = (field.FieldType as SizedArrayType)?.ElementCount ?? 0;
		if (type.GetField(scope String(parts.Alphas)) case .Ok(let field))
			alphas = (field.FieldType as SizedArrayType)?.ElementCount ?? 0;
		return Math.Min(colors, alphas);
	}

	// How many of a fixed array are in use, by its count field, kept within the array.
	private static int InUse(void* count, int length) => (count != null) ? Math.Clamp((int)*(int32*)count, 0, length) : 0;

	private static Sedulous.GUI.Variant ReadCurve(Type type, void* address)
	{
		if (!sCurveTypes.TryGetValue(type, let parts))
			return .();
		let keys = (CurveKey*)PartAt(type, address, parts.Keys, let length);
		let count = PartAt(type, address, parts.Count, let unused1);
		if (keys == null)
			return .();
		return Sedulous.GUI.Variant.FromCurve(.(keys, InUse(count, length))).Copy();
	}

	private static bool WriteCurve(Type type, void* address, Span<CurveKey> keys)
	{
		if (!sCurveTypes.TryGetValue(type, let parts))
			return false;
		let at = (CurveKey*)PartAt(type, address, parts.Keys, let length);
		let count = (int32*)PartAt(type, address, parts.Count, let unused2);
		if ((at == null) || (count == null))
			return false;
		let kept = Math.Min(keys.Length, length);
		for (int i < kept)
			at[i] = keys[i];
		*count = (int32)kept;
		return true;
	}

	private static Sedulous.GUI.Variant ReadGradient(Type type, void* address)
	{
		if (!sGradientTypes.TryGetValue(type, let parts))
			return .();
		let gradient = scope ColorGradient();
		let colors = (GradientColorStop*)PartAt(type, address, parts.Colors, let colorLength);
		let colorCount = PartAt(type, address, parts.ColorCount, let unused3);
		let alphas = (GradientAlphaStop*)PartAt(type, address, parts.Alphas, let alphaLength);
		let alphaCount = PartAt(type, address, parts.AlphaCount, let unused4);
		if (colors != null)
		{
			for (int i < InUse(colorCount, colorLength))
				gradient.Colors.Add(colors[i]);
		}
		if (alphas != null)
		{
			for (int i < InUse(alphaCount, alphaLength))
				gradient.Alphas.Add(alphas[i]);
		}
		if (let blend = (GradientInterpolation*)PartAt(type, address, parts.Interpolation, let unused5))
			gradient.Interpolation = *blend;
		return Sedulous.GUI.Variant(gradient).Copy();
	}

	private static bool WriteGradient(Type type, void* address, ColorGradient gradient)
	{
		if (!sGradientTypes.TryGetValue(type, let parts))
			return false;
		let colors = (GradientColorStop*)PartAt(type, address, parts.Colors, let colorLength);
		let colorCount = (int32*)PartAt(type, address, parts.ColorCount, let unused6);
		let alphas = (GradientAlphaStop*)PartAt(type, address, parts.Alphas, let alphaLength);
		let alphaCount = (int32*)PartAt(type, address, parts.AlphaCount, let unused7);
		if ((colors == null) || (colorCount == null) || (alphas == null) || (alphaCount == null))
			return false;
		let keptColors = Math.Min(gradient.Colors.Count, colorLength);
		for (int i < keptColors)
			colors[i] = gradient.Colors[i];
		*colorCount = (int32)keptColors;
		let keptAlphas = Math.Min(gradient.Alphas.Count, alphaLength);
		for (int i < keptAlphas)
			alphas[i] = gradient.Alphas[i];
		*alphaCount = (int32)keptAlphas;
		if (let blend = (GradientInterpolation*)PartAt(type, address, parts.Interpolation, let unused8))
			*blend = gradient.Interpolation;
		return true;
	}

	// The [InspectorProperty] getter named `name` on `type` (an instance method taking nothing).
	private static bool FindAccessor(Type type, StringView name, out MethodInfo outGetter, out InspectorPropertyAttribute outProperty)
	{
		outGetter = default;
		outProperty = default;
		for (let method in type.GetMethods())
		{
			if (method.IsStatic || (method.ParamCount != 0))
				continue;
			if ((method.GetCustomAttribute<InspectorPropertyAttribute>() case .Ok(let property)) && (property.Name == name))
			{
				outGetter = method;
				outProperty = property;
				return true;
			}
		}
		return false;
	}

	// What an accessor's getter or setter is called on: the object, or a reference to the struct.
	private static System.Variant AccessorSelf(Target target)
	{
		if (target.OwnerType.IsObject)
			return System.Variant.Create(Internal.UnsafeCastToObject(target.Owner));
		return System.Variant.CreateReference(target.OwnerType, target.Owner);
	}

	// The getter's value copied into `outValue` (room for its type); false when the call failed.
	private static bool ReadAccessor(Target target, void* outValue)
	{
		var self = AccessorSelf(target);
		defer self.Dispose();
		if (!(target.Getter.Invoke(self) case .Ok(var result)))
			return false;
		defer result.Dispose();
		result.CopyValueData(outValue);
		return true;
	}

	// `value` (of the accessor's type) handed to its setter; false without one or when it failed.
	private static bool WriteAccessor(Target target, void* value)
	{
		if (!(target.Getter.GetCustomAttribute<InspectorPropertyAttribute>() case .Ok(let property)) || (property.Setter.Length == 0))
			return false;
		if (!(target.OwnerType.GetMethod(property.Setter) case .Ok(let setter)))
			return false;
		var self = AccessorSelf(target);
		defer self.Dispose();
		var argument = System.Variant.Create(target.Type, value);
		defer argument.Dispose();
		if (setter.Invoke(self, argument) case .Ok(var done))
		{
			done.Dispose();
			return true;
		}
		return false;
	}

	// A field this source shows: FieldJson's (public, instance, not [Hidden]), or a private one an
	// inspector is given ([InspectorField]).
	private static bool IsShown(FieldInfo field)
		=> FieldJson.IsShown(field) || (!field.IsStatic && field.HasCustomAttribute<InspectorFieldAttribute>() && !field.HasCustomAttribute<HiddenAttribute>());

	private static bool HasShownFields(Type type)
	{
		for (let field in type.GetFields())
		{
			if (IsShown(field))
				return true;
		}
		return false;
	}

	// A place's shape: a Float4 marked [AsColor] is a Color (the same four floats, laid out alike).
	private static Shape ShapeAt(Target target) => target.AsColor ? .Color : ShapeOf(target.Type);

	// What a field's [References] names: its type, or the type its full name names (a library
	// that cannot see the type it points at names it); null when none.
	private static Type ReferenceOf(FieldInfo field)
	{
		if (!(field.GetCustomAttribute<ReferencesAttribute>() case .Ok(let references)))
			return null;
		if (references.Target != null)
			return references.Target;
		return TypeNamed(references.TargetName);
	}

	private static Dictionary<String, Type> sTypesByName = new .() ~ DeleteDictionaryAndKeys!(_);

	// The type of a full name, or null; scanned once a name and remembered.
	private static Type TypeNamed(StringView fullName)
	{
		if (fullName.IsEmpty)
			return null;
		if (sTypesByName.TryGetValue(scope String(fullName), let known))
			return known;
		Type found = null;
		let name = scope String();
		for (let type in Type.Types)
		{
			// As EditorPageRegistry.ResolveType: a tuple's or an array's full name is not to be asked.
			if (!(type is TypeInstance) || type.IsBoxed || type.IsPointer || type.IsArray
				|| type.IsSizedArray || type.IsGenericParam || type.IsTuple)
				continue;
			name.Clear();
			type.GetFullName(name);
			if (name == fullName)
			{
				found = type;
				break;
			}
		}
		sTypesByName[new String(fullName)] = found;
		return found;
	}

	private static int32 PartCount(Type type) => (type == typeof(Float2)) ? 2 : ((type == typeof(Float3)) ? 3 : 4);

	private static int32 PartIndex(StringView name, int32 count)
	{
		StringView[4] names = .("x", "y", "z", "w");
		for (int32 i < count)
		{
			if (names[i] == name)
				return i;
		}
		return -1;
	}

	private static int32 AngleIndex(StringView name)
	{
		switch (name)
		{
		case "pitch": return 0;
		case "yaw": return 1;
		case "roll": return 2;
		default: return -1;
		}
	}

	// A list's element that is an object (not text): the list holds references, and owns what they
	// point at.
	private static bool HoldsObjectElements(Type element)
		=> (element != null) && element.IsObject && (element != typeof(String));

	// The object at `index` of a list of objects; null when there is none.
	private static Object HeldAt(IReflectedList list, int index)
	{
		if ((list == null) || (index < 0) || (index >= list.Count) || !HoldsObjectElements(list.ElementType))
			return null;
		return *(Object*)list.ElementAddress(index);
	}

	// What a type is called to a user: its [DisplayName], else its name.
	private static void TypeShownName(Type type, String outName)
	{
		if (type.GetCustomAttribute<DisplayNameAttribute>() case .Ok(let shown))
			outName.Append(shown.Name);
		else
			type.GetName(outName);
	}

	private static Dictionary<Type, List<Type>> sCreatable = new .() ~ DeleteDictionaryAndValues!(_);

	// The types an add to a list of `element` can make: it, or any class deriving from it, that is
	// not abstract and that reflection or the serializable registry constructs; by their shown names.
	// Scanned once a type.
	private static List<Type> CreatableTypes(Type element)
	{
		if (sCreatable.TryGetValue(element, let known))
			return known;
		let found = new List<Type>();
		for (let type in Type.Types)
		{
			if (!(type is TypeInstance) || !type.IsObject || type.IsInterface || type.IsAbstract || type.IsBoxed
				|| type.IsGenericParam || type.IsGenericType || type.IsTuple || type.IsArray
				|| ((type != element) && !type.IsSubtypeOf(element)))
				continue;
			let made = Make(type);
			if (made == null)
				continue;
			delete made;
			found.Add(type);
		}
		found.Sort(scope (a, b) => TypeShownName(a, .. scope String()).CompareTo(TypeShownName(b, .. scope String())));
		sCreatable[element] = found;
		return found;
	}

	// A new `type` (OWNED by the caller), by its reflected default constructor or the serializable
	// registry; null when neither makes one.
	private static Object Make(Type type)
	{
		if (type.CreateObject() case .Ok(let made))
			return made;
		let registered = Sedulous.Core.Serialization.GlobalSerializableRegistry;
		let id = Sedulous.Core.Serialization.TypeIdOf(type.GetFullName(.. scope String()));
		if (!registered.IsRegistered(id))
			return null;
		let created = registered.Create(id);
		if (created == null)
			return null;
		let object = Internal.UnsafeCastToObject(Internal.UnsafeCastToPtr(created));
		if (object.GetType() == type)
			return object;
		delete object;
		return null;
	}

	// A list of objects changed: one made (of the type shown as `edit.ElementType`; empty: the
	// first that can be) and inserted, one removed and deleted, or one moved.
	private static bool ChangeObjectList(IReflectedList list, ListEdit edit)
	{
		let count = list.Count;
		switch (edit.Kind)
		{
		case .Insert:
			if ((edit.Index < 0) || (edit.Index > count))
				return false;
			Object made = null;
			for (let type in CreatableTypes(list.ElementType))
			{
				if ((edit.ElementType.Length != 0) && (TypeShownName(type, .. scope String()) != edit.ElementType))
					continue;
				made = Make(type);
				break;
			}
			if (made == null)
				return false;
			ChangeList(list, edit); // a null slot made at the place
			*(Object*)list.ElementAddress(edit.Index) = made;
			return true;
		case .Remove:
			let removed = HeldAt(list, edit.Index);
			if (!ChangeList(list, edit))
				return false;
			delete removed; // the list's own
			return true;
		case .Move:
			return ChangeList(list, edit); // references move as bytes
		}
	}

	// A list of plain values may change its elements' count and order in place: moving their
	// bytes moves nothing anything else owns.
	private static bool MayChangeList(Type element)
		=> (element != null) && !element.IsObject && (ShapeOf(element) != .List) && !HoldsObjects(element);

	private static bool HoldsObjects(Type type)
	{
		if (type.IsObject)
			return true;
		if (!type.IsStruct || type.IsPrimitive)
			return false;
		for (let field in type.GetFields())
		{
			if (!field.IsStatic && HoldsObjects(field.FieldType))
				return true;
		}
		return false;
	}

	private static IReflectedList ListAt(Target target)
	{
		if ((target.Address == null) || (target.Euler >= 0) || (ShapeOf(target.Type) != .List))
			return null;
		return (*(Object*)target.Address) as IReflectedList;
	}

	// An element inserted (its type's default, else a zeroed one), removed or moved, the others'
	// bytes shifted.
	private static bool ChangeList(IReflectedList list, ListEdit edit)
	{
		let count = list.Count;
		let stride = list.ElementType.Stride;
		switch (edit.Kind)
		{
		case .Insert:
			if ((edit.Index < 0) || (edit.Index > count))
				return false;
			list.Count = count + 1;
			let at = (uint8*)list.ElementAddress(edit.Index);
			Internal.MemMove(at + stride, at, (count - edit.Index) * stride);
			// Its type's default (a struct's own initialisers: a sub-emitter link spawns one, its
			// chance whole), else zeroed.
			let element = list.ElementType;
			if (!element.IsObject && (element.CreateValue() case .Ok(let made)))
			{
				Internal.MemCpy(at, made, stride);
				delete made;
			}
			else
				Internal.MemSet(at, 0, stride);
			return true;
		case .Remove:
			if ((edit.Index < 0) || (edit.Index >= count))
				return false;
			let at = (uint8*)list.ElementAddress(edit.Index);
			Internal.MemMove(at, at + stride, (count - edit.Index - 1) * stride);
			list.Count = count - 1;
			return true;
		case .Move:
			if ((edit.Index < 0) || (edit.Index >= count) || (edit.To < 0) || (edit.To >= count) || (edit.Index == edit.To))
				return false;
			let first = (uint8*)list.ElementAddress(0);
			let moved = scope uint8[stride];
			Internal.MemCpy(moved.Ptr, first + edit.Index * stride, stride);
			if (edit.To < edit.Index)
				Internal.MemMove(first + (edit.To + 1) * stride, first + edit.To * stride, (edit.Index - edit.To) * stride);
			else
				Internal.MemMove(first + edit.Index * stride, first + (edit.Index + 1) * stride, (edit.To - edit.Index) * stride);
			Internal.MemCpy(first + edit.To * stride, moved.Ptr, stride);
			return true;
		}
	}

	// The value at `target` as the grid reads it; the caller disposes it.
	private static Sedulous.GUI.Variant Read(Target target)
	{
		let address = target.Address;
		if (address == null)
			return .();
		if (target.Accessor)
		{
			// The getter's value, read as a field holding it would be.
			let value = scope uint8[Math.Max(target.Type.Stride, sizeof(int64))]*;
			if (!ReadAccessor(target, value))
				return .();
			var held = Target();
			held.Address = value;
			held.Type = target.Type;
			return Read(held);
		}
		if (target.Euler >= 0)
		{
			float[3] angles = ?;
			ToYawPitchRoll(*(Quaternion*)address, out angles[1], out angles[0], out angles[2]);
			return Sedulous.GUI.Variant((double)RadiansToDegrees(angles[target.Euler]));
		}
		switch (ShapeAt(target))
		{
		case .Bool:
			return Sedulous.GUI.Variant(*(bool*)address);
		case .Integer:
			return Sedulous.GUI.Variant(ReadInteger(target.Type, address));
		case .Float:
			return Sedulous.GUI.Variant((target.Type == typeof(float)) ? (double)*(float*)address : *(double*)address);
		case .String:
			let text = *(String*)address;
			return Sedulous.GUI.Variant((text != null) ? (StringView)text : "").Copy();
		case .Enum:
			return Sedulous.GUI.Variant(RawFieldAccess.ReadRawInt(address, target.Type.Size));
		case .Color:
			return Sedulous.GUI.Variant(*(Color*)address);
		case .Curve:
			return ReadCurve(target.Type, address);
		case .Gradient:
			return ReadGradient(target.Type, address);
		case .Guid:
			return GuidText(*(Guid*)address);
		case .Reference:
			if (ReferenceShape.Id(target.Type, address) case .Ok(let id))
				return GuidText(id);
			return Sedulous.GUI.Variant("").Copy();
		case .EntityRef:
			return GuidText(((EntityRef*)address).Id);
		case .List:
			let list = ListAt(target);
			return Sedulous.GUI.Variant((int64)((list != null) ? list.Count : 0));
		default:
			return .();
		}
	}

	// Writes `value` at `target`; false when it is not writable there.
	private bool Write(Target target, Sedulous.GUI.Variant value)
	{
		let address = target.Address;
		if ((address == null) || target.ReadOnly || value.IsEmpty)
			return false;
		if (target.Accessor)
		{
			// Written into a copy of what the getter says, then handed to the setter.
			let held = scope uint8[Math.Max(target.Type.Stride, sizeof(int64))]*;
			if (!ReadAccessor(target, held))
				return false;
			var copy = Target();
			copy.Address = held;
			copy.Type = target.Type;
			if (!Write(copy, value))
				return false;
			return WriteAccessor(target, held);
		}
		if (target.Euler >= 0)
		{
			float[3] angles = ?;
			let rotation = (Quaternion*)address;
			ToYawPitchRoll(*rotation, out angles[1], out angles[0], out angles[2]);
			angles[target.Euler] = DegreesToRadians((float)value.AsFloat);
			*rotation = FromYawPitchRoll(angles[1], angles[0], angles[2]);
			return true;
		}
		switch (ShapeAt(target))
		{
		case .Bool:
			*(bool*)address = value.AsBool;
		case .Integer:
			WriteInteger(target.Type, address, value.AsInt);
		case .Float:
			if (target.Type == typeof(float))
				*(float*)address = (float)value.AsFloat;
			else
				*(double*)address = value.AsFloat;
		case .String:
			let text = *(String*)address;
			if (text == null)
				return false;
			text.Set(value.AsString);
		case .Enum:
			RawFieldAccess.WriteRawInt(address, target.Type.Size, value.AsInt);
		case .Color:
			*(Color*)address = value.AsColor;
		case .Curve:
			return (value.Kind == .Curve) && WriteCurve(target.Type, address, value.AsCurve);
		case .Gradient:
			return (value.Kind == .Gradient) && WriteGradient(target.Type, address, value.AsGradient);
		case .Guid:
			*(Guid*)address = GuidOf(value.AsString);
		case .Reference:
			return ReferenceShape.Assign(target.Type, address, GuidOf(value.AsString), mResources) case .Ok;
		case .EntityRef:
			((EntityRef*)address).Id = GuidOf(value.AsString);
		default:
			return false;
		}
		return true;
	}

	// A pasted JSON value as what `target` holds; empty when it is no value of its kind.
	private static Sedulous.GUI.Variant ValueOf(Target target, JsonValue json)
	{
		if (json == null)
			return .();
		let shape = (target.Euler >= 0) ? Shape.Float : ShapeAt(target);
		switch (shape)
		{
		case .Bool:
			return json.IsBool ? Sedulous.GUI.Variant(json.AsBool()) : .();
		case .Integer:
			return json.IsNumber ? Sedulous.GUI.Variant((int64)json.AsNumber()) : .();
		case .Float:
			return json.IsNumber ? Sedulous.GUI.Variant(json.AsNumber()) : .();
		case .String:
			return json.IsString ? Sedulous.GUI.Variant(json.AsString()).Copy() : .();
		case .Enum:
			return FieldJson.EnumValueOf(target.Type, json, let number) ? Sedulous.GUI.Variant(number) : .();
		case .Color:
			var color = FieldJson.LeafVariant(typeof(Color), json);
			defer color.Dispose();
			return color.HasValue ? Sedulous.GUI.Variant(color.Get<Color>()) : .();
		case .Guid, .Reference, .EntityRef:
			if (json.IsNull)
				return Sedulous.GUI.Variant("").Copy();
			return (json.IsString && (Guid.Parse(json.AsString()) case .Ok)) ? Sedulous.GUI.Variant(json.AsString()).Copy() : .();
		default:
			return .();
		}
	}

	private static Sedulous.GUI.Variant GuidText(Guid id)
	{
		if (id == .())
			return Sedulous.GUI.Variant("").Copy();
		return Sedulous.GUI.Variant(id.ToString(.. scope String())).Copy();
	}

	private static Guid GuidOf(StringView text)
	{
		if (Guid.Parse(text) case .Ok(let id))
			return id;
		return .();
	}

	private static int64 ReadInteger(Type type, void* address)
	{
		switch (type)
		{
		case typeof(int8): return *(int8*)address;
		case typeof(uint8): return *(uint8*)address;
		case typeof(int16): return *(int16*)address;
		case typeof(uint16): return *(uint16*)address;
		case typeof(int32): return *(int32*)address;
		case typeof(uint32): return *(uint32*)address;
		case typeof(uint64): return (int64)*(uint64*)address;
		case typeof(uint): return (int64)*(uint*)address;
		case typeof(int): return *(int*)address;
		default: return *(int64*)address;
		}
	}

	private static void WriteInteger(Type type, void* address, int64 value)
	{
		switch (type)
		{
		case typeof(int8): *(int8*)address = (int8)value;
		case typeof(uint8): *(uint8*)address = (uint8)value;
		case typeof(int16): *(int16*)address = (int16)value;
		case typeof(uint16): *(uint16*)address = (uint16)value;
		case typeof(int32): *(int32*)address = (int32)value;
		case typeof(uint32): *(uint32*)address = (uint32)value;
		case typeof(uint64): *(uint64*)address = (uint64)value;
		case typeof(uint): *(uint*)address = (uint)value;
		case typeof(int): *(int*)address = (int)value;
		default: *(int64*)address = value;
		}
	}

	private static void DisposeAll(List<Sedulous.GUI.Variant> values, bool andDelete = true)
	{
		for (var value in ref values)
			value.Dispose();
		values.Clear();
		if (andDelete)
			delete values;
	}
}
