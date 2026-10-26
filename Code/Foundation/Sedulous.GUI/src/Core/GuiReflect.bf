using System;
using System.Collections;
using System.Reflection;

namespace Sedulous.GUI;

// The GUI's reflection: a property written down once, with its CSS name and its flags, serves the
// style applier (a sheet sets any property it names), the markup loader (an element built by its
// tag, its attributes set by name), bindings (a property found by either name) and accessibility.
//
// Raptor builds these records at run time (REFLECT_MEMBERS blocks). Here they are generated at
// compile time: a property carries [GuiProperty], its type [GuiReflect], and the type's table,
// with a typed get and set thunk per property, is emitted from the declaration, so the two cannot
// drift and nothing is reflected at run time.
//
// What an inspector reads of a member rides in the same records, generated the same way:
//   - Core's [DisplayName], [Description], [Range] and [VisibleWhen] beside [GuiProperty], and the
//     GUI's own flags on it (BitFlags, NoAlpha, HdrColor);
//   - an enum's cases, as written in its declaration;
//   - a value struct (one whose public fields carry [GuiProperty]) as its fields, each with a typed
//     get and set over a pointer to the struct, so a source reads one, changes a copy and writes it
//     back through the property's own setter;
//   - a List<T> as typed count, element and change thunks, its most and, for a list of objects,
//     the types an add makes ([GuiList]);
//   - what a Guid member names ([GuiReference]): the type it points at, for a slot that picks.

/// What a reflected property is to the GUI beyond its name.
enum GuiPropertyFlags : uint8
{
	case None = 0;
	/// Its text is a translation key's (`@key` in markup binds it to the string table).
	case Translatable = 1;
	/// A binding to it writes back (`value="{{volume}}"` on a slider moves `volume`).
	case TwoWay = 2;
	/// An enum read as flags: any of its cases' bits, not one of them.
	case BitFlags = 4;
	/// A colour whose alpha an inspector does not edit.
	case NoAlpha = 8;
	/// A Float4 that is an HDR colour: sRGB rgb, a linear intensity in w.
	case HdrColor = 16;
}

/// Marks a property the GUI reflects: by its CSS name when it has one (`[GuiProperty("page")]`),
/// for bindings and markup by its own name either way. On the property; Beef puts it on the
/// getter, where the generator reads it. On a public field of a struct, it makes the struct a
/// value group of its marked fields (the attribute reflected so the generator sees it on a field).
[AttributeUsage(.Property | .Field, .ReflectAttribute)]
struct GuiPropertyAttribute : Attribute
{
	public String Css;
	public GuiPropertyFlags Flags;
	public String Access;

	/// `css`: the kebab-case name a sheet sets it by, empty when a sheet does not. `access`: what
	/// accessibility reports it as (a slider's value as its value), empty when nothing.
	public this(String css = "", GuiPropertyFlags flags = .None, String access = "")
	{
		Css = css;
		Flags = flags;
		Access = access;
	}
}

/// What a List<T> member holds beyond its element type, beside [GuiProperty]: the most elements it
/// takes (0: no limit; a bounded array's capacity), and for a list of objects the types an add
/// makes, by name, comma separated (`[GuiList(0, "BloomEffect, VignetteEffect")]`). Each is a [GuiReflect] type
/// with a creator, its name resolved where the reflected class that holds the list is declared.
[AttributeUsage(.Property | .Field, .ReflectAttribute)]
struct GuiListAttribute : Attribute
{
	public int32 MaxCount;
	public String Types;

	public this(int32 maxCount, String types = "")
	{
		MaxCount = maxCount;
		Types = types;
	}
}

/// What a Guid member is the id of, beside [GuiProperty]: the type it points at, by name
/// (`[GuiReference("Mesh")]`), resolved where the reflected type that holds it is declared, so a
/// name no type has fails the build. An inspector offers what can fill it.
[AttributeUsage(.Property | .Field, .ReflectAttribute)]
struct GuiReferenceAttribute : Attribute
{
	public String TypeName;

	public this(String typeName)
	{
		TypeName = typeName;
	}
}

/// Generates the type's GUI table from the [GuiProperty] properties it declares: a static
/// `StaticGuiType`, chained to the nearest reflected base's, and an override of `GuiType` when an
/// ancestor declares one (Node does), so an instance answers for its own most derived type.
/// `creator`: markup may build one by its tag (it has a public constructor taking nothing).
[AttributeUsage(.Class, .NotInherited | .DisallowAllowMultiple)]
struct GuiReflectAttribute : Attribute, IComptimeTypeApply
{
	// How deep a value's description goes (a struct in a struct in a list...).
	private const int cMostDepth = 6;

	private bool mCreator;
	private String mTag;

	/// `tag`: the element name markup builds it by (empty: the type's own name).
	public this(bool creator = false, String tag = "")
	{
		mCreator = creator;
		mTag = tag;
	}

	[Comptime]
	public void ApplyToType(Type type)
	{
		let typeName = type.GetFullName(.. scope String());
		let baseInfo = scope String("null");
		bool hidesBase = false;
		for (var walk = type.BaseType; (walk != null) && (walk != typeof(Object)); walk = walk.BaseType)
		{
			if (walk.GetCustomAttribute<GuiReflectAttribute>() case .Ok)
			{
				baseInfo.Clear();
				walk.GetFullName(baseInfo);
				baseInfo.Append(".StaticGuiType");
				hidesBase = true;
				break;
			}
		}

		let body = scope String();
		body.AppendF("private static Sedulous.GUI.GuiTypeInfo sGuiType ~ delete _;\n");
		body.AppendF("/// This type's GUI table: its reflected properties, then its base's.\n");
		body.AppendF("public static {}Sedulous.GUI.GuiTypeInfo StaticGuiType => sGuiType ?? (sGuiType = BuildGuiType());\n", hidesBase ? "new " : "");
		// The properties are added by a compile-time mixin in the builder's body: a type's own
		// methods (its properties' accessors) cannot be read while it is being applied to, but
		// they can once its methods compile.
		let tag = mTag.IsEmpty ? type.GetName(.. scope String()) : mTag;
		body.Append("private static Sedulous.GUI.GuiTypeInfo BuildGuiType()\n{\n");
		body.AppendF("\tlet t = new Sedulous.GUI.GuiTypeInfo(typeof({}), \"{}\", {});\n", typeName, tag, baseInfo);
		if (mCreator)
			body.AppendF("\tt.[System.Friend]mCreate = () => new {}();\n", typeName);
		body.AppendF("\tSedulous.GUI.GuiReflectAttribute.EmitProperties(typeof({}));\n\treturn t;\n}}\n", typeName);

		// An instance answers for its most derived type, where an ancestor asks (Node declares the
		// virtual; a reflected type below it overrides it).
		if (hidesBase && DeclaresGuiType(type.BaseType))
			body.Append("public override Sedulous.GUI.GuiTypeInfo GuiType => StaticGuiType;\n");

		Compiler.EmitTypeBody(type, body);
	}

	/// Mixes into a type's builder one Add per [GuiProperty] getter the type declares, onto its
	/// local `t`, each with what an inspector reads of it and what its value is beyond its type;
	/// and the type's own [DisplayName].
	[Comptime]
	public static void EmitProperties(Type type)
	{
		let typeName = type.GetFullName(.. scope String());
		let body = scope String();
		if (type.GetCustomAttribute<Sedulous.Core.DisplayNameAttribute>() case .Ok(let shown))
			body.AppendF("\tt.[System.Friend]mDisplayName.Set({});\n", Quote(shown.Name, .. scope String()));
		for (let m in type.GetMethods(.Public | .Instance | .DeclaredOnly))
		{
			if (!m.Name.StartsWith("get__"))
				continue;
			let name = m.Name.Substring(5);
			if (name.IsEmpty)
				continue; // an indexer
			if (!(m.GetCustomAttribute<GuiPropertyAttribute>() case .Ok(let attr)))
				continue;
			let propertyType = m.ReturnType;
			let propertyTypeName = propertyType.GetFullName(.. scope String());

			bool canWrite = false;
			let setter = scope String("set__");
			setter.Append(name);
			for (let s in type.GetMethods(.Public | .Instance | .DeclaredOnly))
			{
				if (s.Name == setter)
				{
					canWrite = true;
					break;
				}
			}

			// The getter's Variant: text as its own copy (a StringView would only point into the
			// node), anything else by value; the caller disposes it. The setter converts what it is
			// given to the property's type first; false when it cannot (a word for a number).
			let access = scope String()..AppendF("(({})o).{}", typeName, name);
			let get = EmitGetter(propertyType, "o", access, .. scope String());
			let set = scope String("null");
			if (canWrite)
			{
				set.Clear();
				EmitSetter(propertyType, "o", access, set);
			}

			let add = scope String()..AppendF("t.[System.Friend]Add(\"{}\", \"{}\", typeof({}), (Sedulous.GUI.GuiPropertyFlags){}, \"{}\", {}, {})",
				name, attr.Css, propertyTypeName, (int)attr.Flags, attr.Access, get, set);

			let displayName = scope String();
			let description = scope String();
			let visibleWhen = scope String();
			bool hasRange = false;
			float min = 0.0f;
			float max = 0.0f;
			float step = 0.0f;
			if (m.GetCustomAttribute<Sedulous.Core.DisplayNameAttribute>() case .Ok(let dn))
				displayName.Set(dn.Name);
			if (m.GetCustomAttribute<Sedulous.Core.DescriptionAttribute>() case .Ok(let ds))
				description.Set(ds.Text);
			if (m.GetCustomAttribute<Sedulous.Core.VisibleWhenAttribute>() case .Ok(let vw))
				visibleWhen.Set(vw.Condition);
			if (m.GetCustomAttribute<Sedulous.Core.RangeAttribute>() case .Ok(let r))
			{
				hasRange = true;
				min = r.Min;
				max = r.Max;
				step = r.Step;
			}
			let referenceType = scope String();
			if ((m.GetCustomAttribute<GuiReferenceAttribute>() case .Ok(let reference)) && (reference.TypeName != null))
				referenceType.Set(reference.TypeName);
			// What follows the Add reads it as `p`; a property with nothing more is the Add alone (an
			// unread `p` would warn in every reflected type).
			let tail = scope String();
			EmitMarks("p", displayName, description, visibleWhen, hasRange, min, max, step, referenceType, tail, "\t\t");

			int32 maxCount = 0;
			let types = scope String();
			if (m.GetCustomAttribute<GuiListAttribute>() case .Ok(let list))
			{
				maxCount = list.MaxCount;
				if (list.Types != null)
					types.Set(list.Types);
			}
			EmitValue("p.[System.Friend]MakeValue()", propertyType, maxCount, types, tail, 1);
			if (tail.IsEmpty)
				body.AppendF("\t{};\n", add);
			else
				body.AppendF("\t{{\n\t\tlet p = {};\n{}\t}}\n", add, tail);
		}
		Compiler.MixinRoot(body);
	}

	[Comptime]
	private static bool DeclaresGuiType(Type type)
	{
		for (var walk = type; (walk != null) && (walk != typeof(Object)); walk = walk.BaseType)
		{
			for (let m in walk.GetMethods(.Public | .Instance | .DeclaredOnly))
			{
				if (m.Name == "get__GuiType")
					return true;
			}
		}
		return false;
	}

	// `(param) => value`, read through `access`: text as its own copy, an object by reference,
	// anything else by value.
	[Comptime]
	private static void EmitGetter(Type valueType, StringView param, StringView access, String outCode)
	{
		if (valueType == typeof(StringView))
			outCode.AppendF("({}) => Sedulous.GUI.TextVariant({})", param, access);
		else if (valueType.IsObject)
			outCode.AppendF("({}) => System.Variant.Create({}, false)", param, access);
		else
			outCode.AppendF("({}) => System.Variant.Create({})", param, access);
	}

	// `(param, v) => written`: `v` converted to the member's type, then assigned through `access`.
	[Comptime]
	private static void EmitSetter(Type valueType, StringView param, StringView access, String outCode)
	{
		let valueName = valueType.GetFullName(.. scope String());
		if (valueType == typeof(StringView))
			outCode.AppendF("({}, v) => {{ var c = Sedulous.GUI.ConvertVariant(v, typeof(System.String)); defer c.Dispose(); if (!c.HasValue) return false; {} = Sedulous.GUI.TextOf(c); return true; }}", param, access);
		else if (valueType.IsObject)
			outCode.AppendF("({}, v) => {{ if (!(v.VariantType?.IsSubtypeOf(typeof({})) ?? false)) return false; {} = v.Get<{}>(); return true; }}", param, valueName, access, valueName);
		else
			outCode.AppendF("({}, v) => {{ var c = Sedulous.GUI.ConvertVariant(v, typeof({})); defer c.Dispose(); if (!c.HasValue) return false; {} = c.Get<{}>(); return true; }}", param, valueName, access, valueName);
	}

	// What an inspector reads of `member` (a local of the generated code), when it carries any.
	[Comptime]
	private static void EmitMarks(StringView member, StringView displayName, StringView description, StringView visibleWhen,
		bool hasRange, float min, float max, float step, StringView referenceType, String body, StringView indent)
	{
		if (!displayName.IsEmpty || !description.IsEmpty || !visibleWhen.IsEmpty)
		{
			body.AppendF("{}{}.[System.Friend]Describe({}, {}, {});\n", indent, member, Quote(displayName, .. scope String()),
				Quote(description, .. scope String()), Quote(visibleWhen, .. scope String()));
		}
		if (hasRange)
			body.AppendF("{}{}.[System.Friend]SetRange((float)({}), (float)({}), (float)({}));\n", indent, member, min, max, step);
		if (!referenceType.IsEmpty)
			body.AppendF("{}{}.[System.Friend]mReferenceType = typeof({});\n", indent, member, referenceType);
	}

	// What a value of `type` is beyond its type, made by `make` (an expression of the generated
	// code yielding a GuiValueInfo): an enum's cases, a value struct's fields, a list's elements.
	// Nothing for a type that is only itself.
	[Comptime]
	private static void EmitValue(StringView make, Type type, int32 maxCount, StringView types, String body, int depth)
	{
		if ((depth > cMostDepth) || !NeedsValue(type))
			return;
		let indent = scope String();
		for (int i < depth + 1)
			indent.Append('\t');
		let inner = scope String(indent)..Append('\t');
		body.AppendF("{}{{\n{}let v{} = {};\n", indent, inner, depth, make);
		if (type.IsEnum)
		{
			for (let c in type.GetFields())
			{
				if (!c.IsEnumCase)
					continue;
				// A case's constant lives in the field's data slot.
				body.AppendF("{}v{}.[System.Friend]AddCase(\"{}\", {});\n", inner, depth, c.Name, (int64)c.[Friend]mFieldData.mData);
			}
		}
		else if (let element = ListElement(type))
			EmitList(type, element, maxCount, types, body, inner, depth);
		else
			EmitFields(type, body, inner, depth);
		body.AppendF("{}}}\n", indent);
	}

	// A value struct's [GuiProperty] fields onto `v{depth}`, each read and written through a
	// pointer to the struct.
	[Comptime]
	private static void EmitFields(Type type, String body, StringView indent, int depth)
	{
		let structName = type.GetFullName(.. scope String());
		let inner = scope String(indent)..Append('\t');
		for (let f in type.GetFields())
		{
			if (!f.IsInstanceField || !f.IsPublic)
				continue;
			if (!(f.GetCustomAttribute<GuiPropertyAttribute>() case .Ok(let attr)))
				continue;
			let fieldType = f.FieldType;
			let access = scope String()..AppendF("(({}*)s).{}", structName, f.Name);
			let get = EmitGetter(fieldType, "s", access, .. scope String());
			let set = scope String();
			if (fieldType == typeof(String))
			{
				// Text it holds, written in place: replacing the reference would leave the old one.
				set.AppendF("(s, v) => {{ let into = {}; if (into == null) return false; var c = Sedulous.GUI.ConvertVariant(v, typeof(System.String)); defer c.Dispose(); if (!c.HasValue) return false; into.Set(Sedulous.GUI.TextOf(c)); return true; }}", access);
			}
			else if (fieldType.IsObject)
				set.Append("null"); // a list or an object it holds changes in place, never replaced
			else
				EmitSetter(fieldType, "s", access, set);

			let add = scope String()..AppendF("v{}.[System.Friend]AddField(\"{}\", typeof({}), (Sedulous.GUI.GuiPropertyFlags){}, {}, {})",
				depth, f.Name, fieldType.GetFullName(.. scope String()), (int)attr.Flags, get, set);

			let displayName = scope String();
			let description = scope String();
			let visibleWhen = scope String();
			bool hasRange = false;
			float min = 0.0f;
			float max = 0.0f;
			float step = 0.0f;
			if (f.GetCustomAttribute<Sedulous.Core.DisplayNameAttribute>() case .Ok(let dn))
				displayName.Set(dn.Name);
			if (f.GetCustomAttribute<Sedulous.Core.DescriptionAttribute>() case .Ok(let ds))
				description.Set(ds.Text);
			if (f.GetCustomAttribute<Sedulous.Core.VisibleWhenAttribute>() case .Ok(let vw))
				visibleWhen.Set(vw.Condition);
			if (f.GetCustomAttribute<Sedulous.Core.RangeAttribute>() case .Ok(let r))
			{
				hasRange = true;
				min = r.Min;
				max = r.Max;
				step = r.Step;
			}
			let referenceType = scope String();
			if ((f.GetCustomAttribute<GuiReferenceAttribute>() case .Ok(let reference)) && (reference.TypeName != null))
				referenceType.Set(reference.TypeName);
			// As a property's: the field is named only when something follows reads it.
			let tail = scope String();
			let member = scope String()..AppendF("f{}", depth);
			EmitMarks(member, displayName, description, visibleWhen, hasRange, min, max, step, referenceType, tail, inner);

			int32 maxCount = 0;
			let types = scope String();
			if (f.GetCustomAttribute<GuiListAttribute>() case .Ok(let list))
			{
				maxCount = list.MaxCount;
				if (list.Types != null)
					types.Set(list.Types);
			}
			let make = scope String()..AppendF("f{}.[System.Friend]MakeValue()", depth);
			EmitValue(make, fieldType, maxCount, types, tail, depth + 1);
			if (tail.IsEmpty)
				body.AppendF("{}{};\n", indent, add);
			else
				body.AppendF("{}{{\n{}let f{} = {};\n{}{}}}\n", indent, inner, depth, add, tail, indent);
		}
	}

	// A List<T>'s thunks onto `v{depth}`: its count, an element read and written, an element made
	// at an index (a value's default, or an object an add made), one removed and one moved.
	[Comptime]
	private static void EmitList(Type listType, Type element, int32 maxCount, StringView types, String body, StringView indent, int depth)
	{
		let listName = listType.GetFullName(.. scope String());
		let elementName = element.GetFullName(.. scope String());
		body.AppendF("{}let l{} = v{}.[System.Friend]MakeList(typeof({}), {});\n", indent, depth, depth, elementName, maxCount);
		body.AppendF("{}l{}.[System.Friend]mCount = (l) => (({})l).Count;\n", indent, depth, listName);
		body.AppendF("{}l{}.[System.Friend]mMove = (l, a, b) => {{ let list = ({})l; let e = list[a]; list.RemoveAt(a); list.Insert(b, e); }};\n",
			indent, depth, listName);
		if (element.IsObject)
		{
			// Objects of their own: read by reference, never replaced; one removed is let go of.
			body.AppendF("{}l{}.[System.Friend]mGetAt = (l, i) => System.Variant.Create((({})l)[i], false);\n", indent, depth, listName);
			body.AppendF("{}l{}.[System.Friend]mInsertObject = (l, i, e) => {{ if (let made = e as {}) {{ (({})l).Insert(i, made); return true; }} return false; }};\n",
				indent, depth, elementName, listName);
			body.AppendF("{}l{}.[System.Friend]mRemoveAt = (l, i) => {{ let list = ({})l; let e = list[i]; list.RemoveAt(i); Sedulous.GUI.GuiListInfo.ReleaseElement(e); }};\n",
				indent, depth, listName);
			if (element.GetCustomAttribute<GuiReflectAttribute>() case .Ok)
				body.AppendF("{}l{}.[System.Friend]mElementTable = () => {}.StaticGuiType;\n", indent, depth, elementName);
			for (var name in types.Split(','))
			{
				name.Trim();
				if (!name.IsEmpty)
					body.AppendF("{}l{}.[System.Friend]mTypes.Add(() => {}.StaticGuiType);\n", indent, depth, name);
			}
			return;
		}
		let get = scope String();
		if (element == typeof(StringView))
			get.AppendF("(l, i) => Sedulous.GUI.TextVariant((({})l)[i])", listName);
		else
			get.AppendF("(l, i) => System.Variant.Create((({})l)[i])", listName);
		body.AppendF("{}l{}.[System.Friend]mGetAt = {};\n", indent, depth, get);
		body.AppendF("{}l{}.[System.Friend]mSetAt = (l, i, v) => {{ var c = Sedulous.GUI.ConvertVariant(v, typeof({})); defer c.Dispose(); if (!c.HasValue) return false; (({})l)[i] = c.Get<{}>(); return true; }};\n",
			indent, depth, elementName, listName, elementName);
		// A new element is its type's default: a struct's own constructor (its field initializers),
		// where it has one taking nothing.
		let made = scope String();
		if (!element.IsPrimitive && !element.IsEnum && HasDefaultConstructor(element))
			made.AppendF("{}()", elementName);
		else
			made.AppendF("default({})", elementName);
		body.AppendF("{}l{}.[System.Friend]mInsert = (l, i) => {{ (({})l).Insert(i, {}); return true; }};\n", indent, depth, listName, made);
		body.AppendF("{}l{}.[System.Friend]mRemoveAt = (l, i) => {{ (({})l).RemoveAt(i); }};\n", indent, depth, listName);
		let make = scope String()..AppendF("l{}.[System.Friend]MakeElement()", depth);
		EmitValue(make, element, 0, "", body, depth + 1);
	}

	// Whether a value of `type` is more than itself: an enum (its cases), a List<T>, a value struct.
	[Comptime]
	private static bool NeedsValue(Type type) => type.IsEnum || (ListElement(type) != null) || HasGuiFields(type);

	// A List<T>'s T; null for any other type.
	[Comptime]
	private static Type ListElement(Type type)
	{
		if (let generic = type as SpecializedGenericType)
		{
			if (generic.UnspecializedType == typeof(System.Collections.List<>))
				return generic.GetGenericArg(0);
		}
		return null;
	}

	// Whether `type` is a value struct: a public instance field of it carries [GuiProperty].
	[Comptime]
	private static bool HasGuiFields(Type type)
	{
		if (!type.IsValueType || type.IsEnum || type.IsPrimitive)
			return false;
		for (let f in type.GetFields())
		{
			if (f.IsInstanceField && f.IsPublic && (f.GetCustomAttribute<GuiPropertyAttribute>() case .Ok))
				return true;
		}
		return false;
	}

	// Whether `type` can be made with `T()`: it declares no constructor, or one taking nothing.
	[Comptime]
	private static bool HasDefaultConstructor(Type type)
	{
		bool any = false;
		for (let m in type.GetMethods(.Public | .NonPublic | .Instance | .DeclaredOnly))
		{
			if (!m.IsConstructor)
				continue;
			if (m.ParamCount == 0)
				return true;
			any = true;
		}
		return !any;
	}

	// `text` as a string literal of the generated code.
	[Comptime]
	private static void Quote(StringView text, String outCode)
	{
		outCode.Append('"');
		for (int i < text.Length)
		{
			let c = text[i];
			if (c == '\n')
			{
				outCode.Append("\\n");
				continue;
			}
			if ((c == '"') || (c == '\\'))
				outCode.Append('\\');
			outCode.Append(c);
		}
		outCode.Append('"');
	}
}

/// A reflected member, a type's property or a value struct's field: its name, its value's type and
/// flags, what an inspector reads of it (a display name, a description, a range, when it shows),
/// and what its value is beyond its type (an enum's cases, a struct's fields, a list's elements).
abstract class GuiMemberInfo
{
	protected String mName = new .() ~ delete _;
	protected Type mValueType;
	protected GuiPropertyFlags mFlags;
	protected String mDisplayName = new .() ~ delete _;
	protected String mDescription = new .() ~ delete _;
	protected String mVisibleWhen = new .() ~ delete _;
	protected bool mHasRange;
	protected float mMin;
	protected float mMax;
	protected float mStep;
	protected Type mReferenceType;
	protected GuiValueInfo mValue ~ delete _;

	/// Its Beef name (`Page`).
	public StringView Name => mName;
	public Type ValueType => mValueType;
	public GuiPropertyFlags Flags => mFlags;
	public bool IsTranslatable => mFlags.HasFlag(.Translatable);
	public bool IsTwoWay => mFlags.HasFlag(.TwoWay);
	/// Its [DisplayName]; empty: none (a reader makes one from its name).
	public StringView DisplayName => mDisplayName;
	/// Its [Description]; empty: none.
	public StringView Description => mDescription;
	/// Its [VisibleWhen] ("Kind=1", a sibling by its name); empty: always shown.
	public StringView VisibleWhen => mVisibleWhen;
	/// Whether it carries a [Range], and its bounds and step (0: the reader's own).
	public bool HasRange => mHasRange;
	public float Min => mMin;
	public float Max => mMax;
	public float Step => mStep;
	/// What a Guid member is the id of ([GuiReference]); null when it says not.
	public Type ReferenceType => mReferenceType;
	/// What its value is beyond its type; null when it is only its type.
	public GuiValueInfo Value => mValue;

	protected void Describe(StringView displayName, StringView description, StringView visibleWhen)
	{
		mDisplayName.Set(displayName);
		mDescription.Set(description);
		mVisibleWhen.Set(visibleWhen);
	}

	protected void SetRange(float min, float max, float step)
	{
		mHasRange = true;
		mMin = min;
		mMax = max;
		mStep = step;
	}

	protected GuiValueInfo MakeValue() => mValue ?? (mValue = new GuiValueInfo(mValueType));
}

/// One reflected property: its names, its type, its flags, and how to read and write it.
class GuiPropertyInfo : GuiMemberInfo
{
	private String mCss = new .() ~ delete _;
	private String mAccess = new .() ~ delete _;
	private function System.Variant(Object) mGet;
	private function bool(Object, System.Variant) mSet;

	/// The kebab-case name a sheet sets it by; empty when a sheet does not.
	public StringView Css => mCss;
	/// What accessibility reports it as; empty when nothing.
	public StringView Access => mAccess;
	public bool CanWrite => mSet != null;

	/// Whether `name` names it: its CSS name exactly, or its own name in any case (markup's
	/// `maxLength` and a script's `MaxLength` alike).
	public bool Matches(StringView name) =>
		(!mCss.IsEmpty && (mCss == name)) || mName.Equals(name, .OrdinalIgnoreCase);

	/// Its value on `target` (an instance of the type it belongs to, or one derived). The caller
	/// disposes the result.
	public System.Variant Get(Object target) => mGet(target);

	/// Writes `value`, converted to its type first; false when it cannot be (read only, or a value
	/// that does not convert). The caller keeps `value`.
	public bool Set(Object target, System.Variant value) => (mSet != null) && mSet(target, value);
}

/// One field of a value struct: read and written through a pointer to the struct (a copy the
/// reader holds, written back whole through what holds the struct).
class GuiFieldInfo : GuiMemberInfo
{
	private function System.Variant(void*) mGet;
	private function bool(void*, System.Variant) mSet;

	/// Null: an object it holds (a list), changed in place and never replaced.
	public bool CanWrite => mSet != null;

	/// Its value in the struct at `data`; the caller disposes it.
	public System.Variant Get(void* data) => mGet(data);

	/// Writes `value`, converted to its type, into the struct at `data`; false when it cannot be.
	public bool Set(void* data, System.Variant value) => (mSet != null) && mSet(data, value);
}

/// An enum's case, by its declared name.
class GuiEnumCase
{
	public String Name = new .() ~ delete _;
	public int64 Value;
}

/// What a reflected value is beyond its type: an enum's cases, a value struct's fields, or a
/// List<T>'s elements.
class GuiValueInfo
{
	private Type mType;
	private List<GuiEnumCase> mCases = new .() ~ DeleteContainerAndItems!(_);
	private List<GuiFieldInfo> mFields = new .() ~ DeleteContainerAndItems!(_);
	private GuiListInfo mList ~ delete _;

	public this(Type type)
	{
		mType = type;
	}

	public Type Type => mType;
	/// An enum's cases, in their declared order.
	public Span<GuiEnumCase> Cases => mCases;
	/// A value struct's [GuiProperty] fields, in their declared order.
	public Span<GuiFieldInfo> Fields => mFields;
	/// A List<T>'s elements; null for anything else.
	public GuiListInfo ListInfo => mList;
	public bool IsStruct => !mFields.IsEmpty;

	/// The field `name` names (in any case); null when none does.
	public GuiFieldInfo FindField(StringView name)
	{
		for (let field in mFields)
		{
			if (field.Name.Equals(name, true))
				return field;
		}
		return null;
	}

	private void AddCase(StringView name, int64 value)
	{
		let made = new GuiEnumCase();
		made.Name.Set(name);
		made.Value = value;
		mCases.Add(made);
	}

	private GuiFieldInfo AddField(StringView name, Type valueType, GuiPropertyFlags flags, function System.Variant(void*) get,
		function bool(void*, System.Variant) set)
	{
		let field = new GuiFieldInfo();
		field.[Friend]mName.Set(name);
		field.[Friend]mValueType = valueType;
		field.[Friend]mFlags = flags;
		field.[Friend]mGet = get;
		field.[Friend]mSet = set;
		mFields.Add(field);
		return field;
	}

	private GuiListInfo MakeList(Type elementType, int32 maxCount)
	{
		delete mList;
		mList = new GuiListInfo(elementType, maxCount);
		return mList;
	}
}

/// A List<T> member's elements: its count, each read and written by index, one made, removed or
/// moved, all through typed thunks over the list. A list of values makes its type's default; a
/// list of objects takes an object an add made, of the types it names (each a [GuiReflect] type
/// with a creator), and lets go of one removed.
class GuiListInfo
{
	private Type mElementType;
	private int32 mMaxCount;
	private GuiValueInfo mElement ~ delete _;
	private List<function GuiTypeInfo()> mTypes = new .() ~ delete _;
	private function GuiTypeInfo() mElementTable;
	private function int(Object) mCount;
	private function System.Variant(Object, int) mGetAt;
	private function bool(Object, int, System.Variant) mSetAt;
	private function bool(Object, int) mInsert;
	private function bool(Object, int, Object) mInsertObject;
	private function void(Object, int) mRemoveAt;
	private function void(Object, int, int) mMove;

	public this(Type elementType, int32 maxCount)
	{
		mElementType = elementType;
		mMaxCount = maxCount;
	}

	public Type ElementType => mElementType;
	/// The most elements it takes; 0: no limit.
	public int32 MaxCount => mMaxCount;
	/// Whether its elements are objects of their own (each a group of its table).
	public bool HoldsObjects => mElementType.IsObject;
	/// What an element is beyond its type (an enum's cases, a struct's fields); null when it is only
	/// its type.
	public GuiValueInfo Element => mElement;
	/// Its element type's table, for a list of [GuiReflect] objects; null otherwise.
	public GuiTypeInfo ElementTable => (mElementTable != null) ? mElementTable() : null;

	/// The tables of the types an add makes (those named by [GuiList]), appended to `outTypes`.
	public void GetTypes(List<GuiTypeInfo> outTypes)
	{
		for (let type in mTypes)
			outTypes.Add(type());
	}

	public int Count(Object list) => mCount(list);

	/// Whether it holds as many as it takes.
	public bool IsFull(Object list) => (mMaxCount > 0) && (mCount(list) >= mMaxCount);

	/// Element `index`: a value by value, an object by reference. The caller disposes it.
	public System.Variant GetAt(Object list, int index) => mGetAt(list, index);

	/// Writes element `index` (a value; an object is never replaced); false when it cannot be.
	public bool SetAt(Object list, int index, System.Variant value) => (mSetAt != null) && mSetAt(list, index, value);

	/// A value list's default element made at `index`; false for a list of objects, or a full one.
	public bool Insert(Object list, int index) => (mInsert != null) && !IsFull(list) && mInsert(list, index);

	/// `made` (an object an add made) put at `index`; false when it is not of the list's type, or
	/// the list is full (the caller keeps it then).
	public bool InsertObject(Object list, int index, Object made) => (mInsertObject != null) && !IsFull(list) && mInsertObject(list, index, made);

	/// Removes element `index`; an object removed is let go of.
	public void RemoveAt(Object list, int index) => mRemoveAt(list, index);

	/// Moves element `from` to `to` (its place after the move).
	public void Move(Object list, int from, int to) => mMove(list, from, to);

	/// An object a list let go of: released when counted, else deleted.
	public static void ReleaseElement(Object element)
	{
		if (element == null)
			return;
		if (let counted = element as IRefCounted)
			counted.Release();
		else
			delete element;
	}

	private GuiValueInfo MakeElement() => mElement ?? (mElement = new GuiValueInfo(mElementType));
}

/// A reflected type's table: its own properties, then its base's.
class GuiTypeInfo
{
	private Type mType;
	private String mTag = new .() ~ delete _;
	private String mDisplayName = new .() ~ delete _;
	private GuiTypeInfo mBase;
	private List<GuiPropertyInfo> mProperties = new .() ~ DeleteContainerAndItems!(_);
	private function Object() mCreate;

	public this(Type type, StringView tag, GuiTypeInfo baseInfo)
	{
		mType = type;
		mTag.Set(tag);
		mBase = baseInfo;
	}

	public Type Type => mType;
	/// The element name markup builds it by.
	public StringView Tag => mTag;
	/// Its [DisplayName] (what an add of it is called); empty: none.
	public StringView DisplayName => mDisplayName;
	/// The nearest reflected base's table, or null.
	public GuiTypeInfo Base => mBase;
	/// The properties this type declares (not its base's).
	public Span<GuiPropertyInfo> OwnProperties => mProperties;
	/// Whether markup may build one by its tag.
	public bool CanCreate => mCreate != null;

	/// A new instance, for markup; null when the type has no creator.
	public Object Create() => (mCreate != null) ? mCreate() : null;

	/// The property `name` names (its CSS name, or its own in any case), this type's first, then
	/// its bases'; null when none does.
	public GuiPropertyInfo Find(StringView name)
	{
		for (var walk = this; walk != null; walk = walk.mBase)
		{
			for (let property in walk.mProperties)
			{
				if (property.Matches(name))
					return property;
			}
		}
		return null;
	}

	/// The property a sheet sets by `css`, this type's first; null when none.
	public GuiPropertyInfo FindCss(StringView css)
	{
		for (var walk = this; walk != null; walk = walk.mBase)
		{
			for (let property in walk.mProperties)
			{
				if (!property.Css.IsEmpty && (property.Css == css))
					return property;
			}
		}
		return null;
	}

	/// Whether this is `other` or derived from it.
	public bool Is(GuiTypeInfo other)
	{
		for (var walk = this; walk != null; walk = walk.mBase)
		{
			if (walk == other)
				return true;
		}
		return false;
	}

	private GuiPropertyInfo Add(StringView name, StringView css, Type valueType, GuiPropertyFlags flags, StringView access,
		function System.Variant(Object) get, function bool(Object, System.Variant) set)
	{
		let property = new GuiPropertyInfo();
		property.[Friend]mName.Set(name);
		property.[Friend]mCss.Set(css);
		property.[Friend]mAccess.Set(access);
		property.[Friend]mValueType = valueType;
		property.[Friend]mFlags = flags;
		property.[Friend]mGet = get;
		property.[Friend]mSet = set;
		mProperties.Add(property);
		return property;
	}
}
