namespace Sedulous.Editor.App;

using System;
using System.Reflection;

/// Comptime helper that generates DescribeProperties for a [Component] type.
/// Call from [OnCompile(.TypeInit)] in each component extension.
static class InspectorCodegen
{
	[Comptime]
	public static void GenerateDescribeProperties(Type type)
	{
		String body = scope .();
		body.Append("public void DescribeProperties(Sedulous.Engine.Core.IPropertyDescriptor desc)\n{\n");

		// Category header: strip "Component" suffix for display name
		let typeName = type.GetName(.. scope .());
		let displayName = scope String(typeName);
		if (displayName.EndsWith("Component"))
			displayName.RemoveFromEnd(9);
		body.AppendF($"\tdesc.BeginCategory(\"{displayName}\");\n");

		for (let field in type.GetFields())
		{
			if (!field.IsInstanceField || field.DeclaringType != type)
				continue;

			if (!field.HasCustomAttribute<Sedulous.Engine.Core.PropertyAttribute>())
				continue;

			let ft = field.FieldType;

			// Read [Range] if present
			float rangeMin = -1e9f;
			float rangeMax = 1e9f;
			bool hasRange = false;
			if (field.HasCustomAttribute<Sedulous.Engine.Core.RangeAttribute>())
			{
				let rangeAttr = field.GetCustomAttribute<Sedulous.Engine.Core.RangeAttribute>().Value;
				rangeMin = rangeAttr.Min;
				rangeMax = rangeAttr.Max;
				hasRange = true;
			}

			if (ft == typeof(float))
			{
				if (hasRange)
					body.AppendF($"\tdesc.Slider(\"{field.Name}\", &{field.Name}, {rangeMin}f, {rangeMax}f);\n");
				else
					body.AppendF($"\tdesc.Float(\"{field.Name}\", &{field.Name}, {rangeMin}f, {rangeMax}f);\n");
			}
			else if (ft == typeof(int32))
				body.AppendF($"\tdesc.Int32(\"{field.Name}\", &{field.Name}, {(int32)rangeMin}, {(int32)rangeMax});\n");
			else if (ft == typeof(uint32))
				body.AppendF($"\tdesc.UInt32(\"{field.Name}\", &{field.Name}, 0, {(uint32)rangeMax});\n");
			else if (ft == typeof(bool))
				body.AppendF($"\tdesc.Bool(\"{field.Name}\", &{field.Name});\n");
			else if (ft == typeof(String))
				body.AppendF($"\tdesc.Str(\"{field.Name}\", &{field.Name});\n");
			else if (ft == typeof(Sedulous.Core.Mathematics.Vector3))
				body.AppendF($"\tdesc.Vec3(\"{field.Name}\", &{field.Name});\n");
			else if (ft == typeof(Sedulous.Core.Mathematics.Quaternion))
				body.AppendF($"\tdesc.Quat(\"{field.Name}\", &{field.Name});\n");
			else if (ft == typeof(Sedulous.Resources.ResourceRef))
			{
				// Convention: mFooRef -> SetFooRef(ref), FooRef (getter property)
				String baseName = scope .(field.Name);
				if (baseName.StartsWith("m") && baseName.Length > 1 && baseName[1].IsUpper)
					baseName.Remove(0, 1);

				body.AppendF($"\tdesc.ResRef(\"{baseName}\", new () => {{ return {baseName}; }}, new (r) => {{ Set{baseName}(r); }});\n");
			}
			else if (let specType = ft as SpecializedGenericType)
			{
				if (specType.UnspecializedType == typeof(System.Collections.List<>) &&
					specType.GetGenericArg(0) == typeof(Sedulous.Resources.ResourceRef))
				{
					// Convention: mFooRefs -> singular FooRef -> GetFooRef(i), SetFooRef(i, ref), FooRefCount
					String baseName = scope .(field.Name);
					if (baseName.StartsWith("m") && baseName.Length > 1 && baseName[1].IsUpper)
						baseName.Remove(0, 1);
					String singularName = scope .(baseName);
					if (singularName.EndsWith("s"))
						singularName.RemoveFromEnd(1);

					body.AppendF($"\tdesc.ResRefList(\"{singularName}s\", new () => {{ return {singularName}Count; }}, new (i) => {{ return Get{singularName}(i); }}, new (i, r) => {{ Set{singularName}(i, r); }});\n");
				}
			}
			else if (ft.IsEnum)
				body.AppendF($"\tdesc.EnumField(\"{field.Name}\", &{field.Name}, typeof({ft.GetFullName(.. scope .())}));\n");
		}

		body.Append("\tdesc.EndCategory();\n");
		body.Append("}\n");

		Compiler.EmitTypeBody(type, body);
		Compiler.EmitAddInterface(type, typeof(Sedulous.Engine.Core.IInspectable));
	}
}
