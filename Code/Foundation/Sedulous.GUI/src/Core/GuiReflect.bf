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

/// What a reflected property is to the GUI beyond its name.
enum GuiPropertyFlags : uint8
{
	case None = 0;
	/// Its text is a translation key's (`@key` in markup binds it to the string table).
	case Translatable = 1;
	/// A binding to it writes back (`value="{{volume}}"` on a slider moves `volume`).
	case TwoWay = 2;
}

/// Marks a property the GUI reflects: by its CSS name when it has one (`[GuiProperty("page")]`),
/// for bindings and markup by its own name either way. On the property; Beef puts it on the
/// getter, where the generator reads it.
[AttributeUsage(.Property)]
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

/// Generates the type's GUI table from the [GuiProperty] properties it declares: a static
/// `StaticGuiType`, chained to the nearest reflected base's, and an override of `GuiType` when an
/// ancestor declares one (Node does), so an instance answers for its own most derived type.
/// `creator`: markup may build one by its tag (it has a public constructor taking nothing).
[AttributeUsage(.Class, .NotInherited | .DisallowAllowMultiple)]
struct GuiReflectAttribute : Attribute, IComptimeTypeApply
{
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
	/// local `t`.
	[Comptime]
	public static void EmitProperties(Type type)
	{
		let typeName = type.GetFullName(.. scope String());
		let body = scope String();
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
			// node), anything else by value; the caller disposes it.
			let get = scope String();
			if (propertyType == typeof(StringView))
				get.AppendF("(o) => Sedulous.GUI.TextVariant((({})o).{})", typeName, name);
			else if (propertyType.IsObject)
				get.AppendF("(o) => System.Variant.Create((({})o).{}, false)", typeName, name);
			else
				get.AppendF("(o) => System.Variant.Create((({})o).{})", typeName, name);

			// The setter converts what it is given to the property's type first; false when it
			// cannot (a word for a number).
			let set = scope String("null");
			if (canWrite)
			{
				set.Clear();
				if (propertyType == typeof(StringView))
					set.AppendF("(o, v) => {{ var c = Sedulous.GUI.ConvertVariant(v, typeof(System.String)); defer c.Dispose(); if (!c.HasValue) return false; (({})o).{} = Sedulous.GUI.TextOf(c); return true; }}", typeName, name);
				else if (propertyType.IsObject)
					set.AppendF("(o, v) => {{ if (!(v.VariantType?.IsSubtypeOf(typeof({})) ?? false)) return false; (({})o).{} = v.Get<{}>(); return true; }}", propertyTypeName, typeName, name, propertyTypeName);
				else
					set.AppendF("(o, v) => {{ var c = Sedulous.GUI.ConvertVariant(v, typeof({})); defer c.Dispose(); if (!c.HasValue) return false; (({})o).{} = c.Get<{}>(); return true; }}", propertyTypeName, typeName, name, propertyTypeName);
			}

			body.AppendF("\tt.[System.Friend]Add(\"{}\", \"{}\", typeof({}), (Sedulous.GUI.GuiPropertyFlags){}, \"{}\", {}, {});\n",
				name, attr.Css, propertyTypeName, (int)attr.Flags, attr.Access, get, set);
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
}

/// One reflected property: its names, its type, its flags, and how to read and write it.
class GuiPropertyInfo
{
	private String mName = new .() ~ delete _;
	private String mCss = new .() ~ delete _;
	private String mAccess = new .() ~ delete _;
	private Type mValueType;
	private GuiPropertyFlags mFlags;
	private function Variant(Object) mGet;
	private function bool(Object, Variant) mSet;

	/// Its Beef name (`Page`).
	public StringView Name => mName;
	/// The kebab-case name a sheet sets it by; empty when a sheet does not.
	public StringView Css => mCss;
	/// What accessibility reports it as; empty when nothing.
	public StringView Access => mAccess;
	public Type ValueType => mValueType;
	public GuiPropertyFlags Flags => mFlags;
	public bool IsTranslatable => mFlags.HasFlag(.Translatable);
	public bool IsTwoWay => mFlags.HasFlag(.TwoWay);
	public bool CanWrite => mSet != null;

	/// Whether `name` names it: its CSS name exactly, or its own name in any case (markup's
	/// `maxLength` and a script's `MaxLength` alike).
	public bool Matches(StringView name) =>
		(!mCss.IsEmpty && (mCss == name)) || mName.Equals(name, .OrdinalIgnoreCase);

	/// Its value on `target` (an instance of the type it belongs to, or one derived). The caller
	/// disposes the result.
	public Variant Get(Object target) => mGet(target);

	/// Writes `value`, converted to its type first; false when it cannot be (read only, or a value
	/// that does not convert). The caller keeps `value`.
	public bool Set(Object target, Variant value) => (mSet != null) && mSet(target, value);
}

/// A reflected type's table: its own properties, then its base's.
class GuiTypeInfo
{
	private Type mType;
	private String mTag = new .() ~ delete _;
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

	private void Add(StringView name, StringView css, Type valueType, GuiPropertyFlags flags, StringView access,
		function Variant(Object) get, function bool(Object, Variant) set)
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
	}
}
