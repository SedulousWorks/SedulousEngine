using System;
using System.Collections;
using System.Reflection;
using Sedulous.Core;
using Sedulous.Resource;
using Sedulous.Scene;

namespace Sedulous.Editor.Scene;

/// The inspector rows for one type, GENERATED at compile time from its public fields and
/// their attributes: a typed reader per field, the enum cases by name, the [Range] bounds,
/// the [DisplayName] and [Description] presentation, and a [VisibleWhen] condition resolved
/// to the dependent field. Nothing is looked up by name at run time.
///
/// A field is skipped when it is [Hidden], a pointer, an object other than a String or a
/// List, or a struct the inspector has no editor for. A Ref<X> becomes an asset row whose
/// accepted asset types follow from X; a List becomes a slot list.
static class InspectorRows<T>
{
	/// Adds every row to the section, in declaration order.
	public static void Build(InspectorSection s)
	{
		Emit(typeof(T));
	}

	/// The type's label and add-menu category, from its [DisplayName] and [Category].
	public static void Meta(String outDisplayName, String outCategory)
	{
		EmitMeta(typeof(T));
	}

	[Comptime]
	private static void EmitMeta(Type type)
	{
		if (type.IsGenericParam)
			return;
		let code = scope String();
		let label = scope String();
		if (type.GetCustomAttribute<DisplayNameAttribute>() case .Ok(let dn))
			label.Set(dn.Name);
		else
			PropertyNames.ComponentLabel(type.GetName(.. scope .()), label);
		let category = scope String("Other");
		if (type.GetCustomAttribute<CategoryAttribute>() case .Ok(let c))
			category.Set(c.Name);
		code.AppendF("outDisplayName.Set({});\n", Quote(label, .. scope .()));
		code.AppendF("outCategory.Set({});\n", Quote(category, .. scope .()));
		Compiler.MixinRoot(code);
	}

	[Comptime]
	private static void Emit(Type type)
	{
		if (type.IsGenericParam)
			return;
		let code = scope String();
		// A struct is read through its address; a class through the object at it.
		let access = type.IsObject ? "((T)Internal.UnsafeCastToObject(p))" : "((T*)p)";

		for (let field in type.GetFields())
		{
			if (!field.IsInstanceField || !field.IsPublic)
				continue;
			if (field.GetCustomAttribute<HiddenAttribute>() case .Ok)
				continue;
			let ft = field.FieldType;
			let name = field.Name;
			let quoted = Quote(name, .. scope .());
			let member = scope $"{access}.{name}";

			let row = scope String();
			if (!EmitRow(field, ft, quoted, member, row))
				continue;

			code.Append("{\n\tlet first = s.RowCount;\n");
			// The label and tooltip apply to the row added next.
			let label = scope String();
			if (field.GetCustomAttribute<DisplayNameAttribute>() case .Ok(let dn))
				label.Set(dn.Name);
			let tooltip = scope String();
			if (field.GetCustomAttribute<DescriptionAttribute>() case .Ok(let ds))
				tooltip.Set(ds.Text);
			if (!label.IsEmpty || !tooltip.IsEmpty)
				code.AppendF("\ts.Label({}, {});\n", Quote(label, .. scope .()), Quote(tooltip, .. scope .()));
			code.Append("\t");
			code.Append(row);
			if (field.GetCustomAttribute<VisibleWhenAttribute>() case .Ok(let v))
				EmitVisibleWhen(type, access, v.Condition, code);
			code.Append("}\n");
		}
		EmitComputed(type, access, code);
		Compiler.MixinRoot(code);
	}

	/// The rows a type computes rather than stores: a getter marked [InspectorProperty],
	/// written back through its named setter, or read-only without one. Only a bool is
	/// writable; a getter with a parameter or an unwritable setter is a comptime error,
	/// since a silent skip would read as "not marked".
	[Comptime]
	private static void EmitComputed(Type type, StringView access, String code)
	{
		for (let method in type.GetMethods(.Public | .Instance | .DeclaredOnly))
		{
			if (!(method.GetCustomAttribute<InspectorPropertyAttribute>() case .Ok(let mark)))
				continue;
			if (method.ParamCount != 0)
				Runtime.FatalError(scope $"[InspectorProperty] {type.GetName(.. scope .())}.{method.Name} takes parameters; a getter takes none");
			let rt = method.ReturnType;
			let quoted = Quote(mark.Name, .. scope .());
			let call = scope $"{access}.{method.Name}()";
			code.Append("{\n\t");
			if (mark.Setter.IsEmpty)
			{
				// Read-only: whatever it is, shown as text.
				code.AppendF("s.ReadOnlyRow({}, new (p, text) => text.AppendF(\"{{}}\", {}));\n", quoted, call);
			}
			else if (rt == typeof(bool))
				code.AppendF("s.BoolRow({}, new (p) => {}, new (p, v) => {}.{}(v));\n", quoted, call, access, mark.Setter);
			else
				Runtime.FatalError(scope $"[InspectorProperty] {type.GetName(.. scope .())}.{method.Name} returns {rt.GetName(.. scope .())}; only a bool is writable, drop the setter for a read-only row");
			code.Append("}\n");
		}
	}

	/// One row's call, or false for a field the inspector does not show.
	[Comptime]
	private static bool EmitRow(FieldInfo field, Type ft, StringView quoted, StringView member,
		String row)
	{
		let reader = scope $"new (p) => {member}";
		if (ft == typeof(float))
		{
			// A [Range] makes the row a slider between its bounds.
			if (field.GetCustomAttribute<RangeAttribute>() case .Ok(let r))
				row.AppendF("s.FloatRow({}, {}, true, {}f, {}f, {}f);\n", quoted, reader, r.Min, r.Max, r.Step);
			else
				row.AppendF("s.FloatRow({}, {}, false, 0f, 0f, 0f);\n", quoted, reader);
			return true;
		}
		if (ft == typeof(bool))
		{
			row.AppendF("s.BoolRow({}, {});\n", quoted, reader);
			return true;
		}
		if (IsInteger(ft))
		{
			let intName = ft.GetFullName(.. scope .());
			row.AppendF("s.IntRow({}, new (p) => (int64){}, new (v) => Variant.Create<{}>(({})v));\n",
				quoted, member, intName, intName);
			return true;
		}
		if (ft.IsEnum)
		{
			let names = scope String();
			let values = scope String();
			for (let c in ft.GetFields())
			{
				if (!c.IsEnumCase)
					continue;
				if (!names.IsEmpty)
				{
					names.Append(", ");
					values.Append(", ");
				}
				Quote(c.Name, names);
				// A case's constant lives in the field's data slot.
				((int64)c.[Friend]mFieldData.mData).ToString(values);
			}
			row.AppendF("s.EnumRow({}, new (p) => (int64){}, scope StringView[]({}), scope int64[]({}));\n",
				quoted, member, names, values);
			return true;
		}
		if (ft == typeof(String))
		{
			row.AppendF("s.TextRow({}, new (p) => StringView({}), new (p, v) => {{ {}.Set(v); }});\n",
				quoted, member, member);
			return true;
		}
		if (ft == typeof(Float2))
		{
			row.AppendF("s.Float2Row({}, {});\n", quoted, reader);
			return true;
		}
		if (ft == typeof(Float3))
		{
			row.AppendF("s.Float3Row({}, {});\n", quoted, reader);
			return true;
		}
		if (ft == typeof(Float4))
		{
			row.AppendF("s.Float4Row({}, {});\n", quoted, reader);
			return true;
		}
		if (ft == typeof(Color))
		{
			row.AppendF("s.ColorRow({}, {});\n", quoted, reader);
			return true;
		}
		if (ft == typeof(EntityRef))
		{
			row.AppendF("s.EntityRefRow({}, new (p) => {}.Id);\n", quoted, member);
			return true;
		}
		if (let generic = ft as SpecializedGenericType)
		{
			if (generic.UnspecializedType == typeof(Ref<>))
			{
				let resource = generic.GetGenericArg(0);
				row.AppendF("s.ResourceRefRow<{}>({}, new (p) => {}.Id, scope StringView[]({}));\n",
					resource.GetFullName(.. scope .()), quoted, member, AssetTypesFor(resource, .. scope .()));
				return true;
			}
			if (generic.UnspecializedType == typeof(List<>))
			{
				let element = generic.GetGenericArg(0);
				if (let inner = element as SpecializedGenericType)
				{
					if (inner.UnspecializedType == typeof(Ref<>))
					{
						let resource = inner.GetGenericArg(0);
						row.AppendF("s.ResourceRefListRow<{}>({}, {}, scope StringView[]({}));\n",
							resource.GetFullName(.. scope .()), quoted, reader, AssetTypesFor(resource, .. scope .()));
						return true;
					}
				}
				if (element == typeof(EntityRef))
				{
					row.AppendF("s.EntityRefListRow({}, {});\n", quoted, reader);
					return true;
				}
				let elementLabel = ElementLabel(element, .. scope .());
				if (element.IsValueType)
				{
					row.AppendF("s.ValueListRow<{}>({}, {}, {});\n", element.GetFullName(.. scope .()),
						quoted, reader, Quote(elementLabel, .. scope .()));
					return true;
				}
				if (element.IsObject && !element.IsAbstract)
				{
					let elementName = element.GetFullName(.. scope .());
					row.AppendF("s.ObjectListRow<{}>({}, {}, {});\n", elementName,
						quoted, reader, Quote(elementLabel, .. scope .()));
					// A reflected element gets its own rows per slot, so a list of structs is
					// editable rather than a column of type labels. The slot's title is the
					// element's `Name`, when it has one, else the type label.
					if (HasEditableRows(element))
					{
						let titled = HasNameField(element);
						row.AppendF(
							"s.SlotSections<{}>({}, {}, new (e, outTitle) => {{ outTitle.AppendF(\"{{}} {{}}\", {}, {}); }});\n",
							elementName, quoted, reader,
							Quote(elementLabel, .. scope .()),
							titled ? "e.Name" : "\"\"");
					}
					return true;
				}
			}
		}
		return false;
	}

	/// Whether a list element is worth its own rows: a public instance field the emitter can
	/// build a row for. A bag with nothing editable keeps the plain list.
	[Comptime]
	private static bool HasEditableRows(Type element)
	{
		for (let field in element.GetFields())
		{
			if (!field.IsInstanceField || !field.IsPublic)
				continue;
			if (field.GetCustomAttribute<HiddenAttribute>() case .Ok)
				continue;
			let row = scope String();
			if (EmitRow(field, field.FieldType, "\"x\"", "x", row))
				return true;
		}
		return false;
	}

	/// Whether the element titles its own slot, which is a public `String Name`.
	[Comptime]
	private static bool HasNameField(Type element)
	{
		for (let field in element.GetFields())
		{
			if (field.IsInstanceField && field.IsPublic && (field.Name == "Name")
				&& (field.FieldType == typeof(String)))
				return true;
		}
		return false;
	}

	/// Resolves the condition's dependent field and emits the reader for it: a bool as 0 or 1,
	/// anything else as its raw integer.
	[Comptime]
	private static void EmitVisibleWhen(Type type, StringView access, StringView spec, String code)
	{
		var eq = spec.Length;
		for (int i < spec.Length)
		{
			if (spec[i] == '=')
			{
				eq = i;
				break;
			}
		}
		let prop = spec.Substring(0, eq);
		for (let dependent in type.GetFields())
		{
			if (dependent.Name != prop)
				continue;
			let dt = dependent.FieldType;
			let read = scope String();
			if (dt == typeof(bool))
				read.AppendF("new (p) => {}.{} ? 1 : 0", access, dependent.Name);
			else if (dt.IsEnum || IsInteger(dt))
				read.AppendF("new (p) => (int64){}.{}", access, dependent.Name);
			else
				return; // not a condition the reader could evaluate
			code.AppendF("\ts.VisibleWhen(first, {}, {});\n", Quote(spec, .. scope .()), read);
			return;
		}
	}

	[Comptime]
	private static bool IsInteger(Type t)
		=> (t == typeof(int8)) || (t == typeof(uint8)) || (t == typeof(int16)) || (t == typeof(uint16))
			|| (t == typeof(int32)) || (t == typeof(uint32)) || (t == typeof(int64)) || (t == typeof(uint64))
			|| (t == typeof(int)) || (t == typeof(uint));

	/// The asset types a Ref<X> row picks from, by the resource's name; an unknown resource
	/// takes its name plus "Asset".
	[Comptime]
	private static void AssetTypesFor(Type resource, String outList)
	{
		let name = resource.GetName(.. scope .());
		switch (name)
		{
		case "StaticMesh": outList.Append("\"StaticMeshAsset\", \"SkinnedMeshAsset\"");
		case "Material": outList.Append("\"MaterialAsset\"");
		case "Skeleton": outList.Append("\"SkeletonAsset\"");
		case "AnimationClip": outList.Append("\"AnimationClipAsset\"");
		case "NavigationZoneResource": outList.Append("\"NavigationZoneAsset\"");
		case "AnimationGraph": outList.Append("\"AnimationGraphAsset\"");
		case "PropertyAnimationClipResource": outList.Append("\"PropertyAnimationClipAsset\"");
		case "Texture": outList.Append("\"TextureAsset\"");
		case "ParticleEffectResource": outList.Append("\"ParticleEffectAsset\"");
		case "CollisionShape": outList.Append("\"CollisionShapeAsset\"");
		case "PhysicalMaterial": outList.Append("\"PhysicalMaterialAsset\"");
		case "Heightfield": outList.Append("\"HeightfieldAsset\"");
		case "TerrainResource": outList.Append("\"TerrainAsset\"");
		case "AudioClip": outList.Append("\"AudioClipAsset\"");
		case "SoundCue": outList.Append("\"SoundCueAsset\"");
		case "UIDocument": outList.Append("\"UIDocumentAsset\"");
		case "UITheme": outList.Append("\"UIThemeAsset\"");
		case "ScriptClass": outList.Append("\"ScriptClassAsset\"");
		default:
			outList.Append('"');
			outList.Append(name);
			outList.Append("Asset\"");
		}
	}

	/// A list element's slot label: the type's [DisplayName], else its name prettified.
	[Comptime]
	private static void ElementLabel(Type element, String outLabel)
	{
		if (element.GetCustomAttribute<DisplayNameAttribute>() case .Ok(let dn))
		{
			outLabel.Set(dn.Name);
			return;
		}
		PropertyNames.Prettify(element.GetName(.. scope .()), outLabel);
	}

	[Comptime]
	private static void Quote(StringView text, String outCode)
	{
		outCode.Append('"');
		for (let c in text)
		{
			if ((c == '"') || (c == '\\'))
				outCode.Append('\\');
			outCode.Append(c);
		}
		outCode.Append('"');
	}
}
