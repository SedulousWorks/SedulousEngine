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
/// fields (public, instance, not [Hidden]) by path, as the toolkit's are:
///   - bool, every integer width, float, double and text are values; an enum is choices from its
///     cases; a Color is a colour; a Guid is a reference (to what its [References] names), and a
///     Ref<T> one to its T; an EntityRef
///     is a reference by its id, hinted "EntityRef" (the scene's entity slot, chosen before the
///     asset one).
///   - Float2, Float3 and Float4 are groups hinted with their names, their parts x, y, z, w; a
///     Quaternion is a Float3 group of Euler degrees (pitch, yaw, roll).
///   - A List<T> is a list, its elements by index; one of plain values (no text, no objects) may
///     have elements added, removed and moved.
///   - A structure or an object with shown fields is a group of them; any other type (one with
///     none: an asset's SourcePath) a group hinted with its type's name, for an editor registered
///     by that name (an asset page's source file).
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

		public this() { }
	}

	/// An EntityRef's hint: the entity slot's.
	public const String cEntityRefHint = "EntityRef";

	private Type mType;
	private int mCount;
	private Resolver mResolve ~ delete _;
	private Committer mCommit ~ delete _;
	/// SetOnDescribe's; null: none.
	private delegate void(StringView path, PropertyInfo info) mOnDescribe = null ~ delete _;
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
		switch (ShapeOf(target.Type))
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
		if ((target.Address == null) || target.ReadOnly || (ShapeOf(target.Type) != .List) || !MayChangeList(ElementOf(target.Type)))
			return false;
		var changed = false;
		let held = scope String(path);
		mCommit(scope [&] (object, value) =>
			{
				let list = ListAt(Resolve(held, value));
				if ((list != null) && ChangeList(list, edit))
					changed = true;
			});
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
		let json = FieldJson.ValueJson(target.Type, target.Address);
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
			if ((target.Address == null) || (target.Euler >= 0))
				return Target();
			switch (ShapeOf(target.Type))
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
				if (!(type.GetField(scope String(segment)) case .Ok(let field)) || !FieldJson.IsShown(field))
					return Target();
				target.Address = (uint8*)address + field.MemberOffset;
				target.Type = field.FieldType;
				target.Direct = false;
				target.ReadOnly = target.ReadOnly || field.HasCustomAttribute<ReadOnlyAttribute>();
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
		let shape = (target.Euler >= 0) ? Shape.Float : ShapeOf(target.Type);
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
			if (!FieldJson.IsShown(field))
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
			// A guid that says what it is the id of: a slot for that.
			if ((info.Kind == .Reference) && (info.ReferenceType == null) && (field.GetCustomAttribute<ReferencesAttribute>() case .Ok(let references)))
				info.ReferenceType = references.Target;
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
			if (field.GetCustomAttribute<VisibleWhenAttribute>() case .Ok(let visible))
				info.Visible = Holds(parent, visible.Condition);
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
		for (int i < count)
		{
			let info = new PropertyInfo();
			i.ToString(info.Name);
			info.ReadOnly = target.ReadOnly;
			DescribeType(element, info);
			if (ShapeOf(element) == .Group)
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
		case .Guid:
			info.Kind = .Reference;
		case .Reference:
			info.Kind = .Reference;
			info.ReferenceType = ReferenceShape.Target(type);
		case .List:
			info.Kind = .List;
			if (!info.ReadOnly && MayChangeList(ElementOf(type)))
				info.ListOps = PropertyListAdd | PropertyListRemove | PropertyListMove;
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
	private bool Holds(StringView group, StringView condition)
	{
		var eq = condition.IndexOf('=');
		if (eq == 0)
			return true;
		if (eq < 0)
			eq = condition.Length;
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
		if (ElementOf(type) != null)
			return .List;
		if (type.IsObject || (type.IsStruct && !type.IsPrimitive))
			return FieldJson.HasShownFields(type) ? .Group : .Other;
		return .Other;
	}

	private static Type ElementOf(Type type) => FieldJson.ListElement(type);

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

	// An element inserted (a zeroed one), removed or moved, the others' bytes shifted.
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
		if (target.Euler >= 0)
		{
			float[3] angles = ?;
			ToYawPitchRoll(*(Quaternion*)address, out angles[1], out angles[0], out angles[2]);
			return Sedulous.GUI.Variant((double)RadiansToDegrees(angles[target.Euler]));
		}
		switch (ShapeOf(target.Type))
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
		if (target.Euler >= 0)
		{
			float[3] angles = ?;
			let rotation = (Quaternion*)address;
			ToYawPitchRoll(*rotation, out angles[1], out angles[0], out angles[2]);
			angles[target.Euler] = DegreesToRadians((float)value.AsFloat);
			*rotation = FromYawPitchRoll(angles[1], angles[0], angles[2]);
			return true;
		}
		switch (ShapeOf(target.Type))
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
		let shape = (target.Euler >= 0) ? Shape.Float : ShapeOf(target.Type);
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
