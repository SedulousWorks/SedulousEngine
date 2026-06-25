namespace Sedulous.Editor;

using System;
using System.Reflection;
using Sedulous.Inspection;

/// Comptime helper that generates DescribeProperties for a [Component] type.
/// Call from [OnCompile(.TypeInit)] in each component extension.
static class InspectorCodegen
{
	[Comptime]
	public static void GenerateDescribeProperties(Type type)
	{
		String body = scope .();
		body.Append("public void DescribeProperties(Sedulous.Inspection.IPropertyDescriptor desc)\n{\n");

		// Category header: strip common suffixes for display name
		let typeName = type.GetName(.. scope .());
		let categoryName = scope String(typeName);
		if (categoryName.EndsWith("Component"))
			categoryName.RemoveFromEnd(9);
		else if (categoryName.EndsWith("SceneModule"))
			categoryName.RemoveFromEnd(11);
		else if (categoryName.EndsWith("Module"))
			categoryName.RemoveFromEnd(6);
		else if (categoryName.EndsWith("Initializer"))
			categoryName.RemoveFromEnd(11);
		else if (categoryName.EndsWith("Behavior"))
			categoryName.RemoveFromEnd(8);
		body.AppendF($"\tdesc.BeginCategory(\"{categoryName}\");\n");

		for (let field in type.GetFields())
		{
			if (!field.IsInstanceField || field.DeclaringType != type)
				continue;

			if (!field.HasCustomAttribute<PropertyAttribute>())
				continue;

			let ft = field.FieldType;

			// Read [Property] editor hint (Default / Color / Resource / Slider).
			let propAttr = field.GetCustomAttribute<PropertyAttribute>().Value;
			let editorHint = propAttr.Editor;

			// Derive default property name from field name.
			// Convention: strip leading 'm' if followed by uppercase (mHealth -> Health).
			String propName = scope .(field.Name);
			if (propName.StartsWith("m") && propName.Length > 1 && propName[1].IsUpper)
				propName.Remove(0, 1);

			// Read names from attribute. Falls back to derived name if null.
			String name = scope .(propAttr.SerializedName ?? propName);
			String displayName = scope .(propAttr.DisplayName ?? propName);

			// Read [Range] if present
			float rangeMin = -1e9f;
			float rangeMax = 1e9f;
			bool hasRange = false;
			if (field.HasCustomAttribute<RangeAttribute>())
			{
				let rangeAttr = field.GetCustomAttribute<RangeAttribute>().Value;
				rangeMin = rangeAttr.Min;
				rangeMax = rangeAttr.Max;
				hasRange = true;
			}

			if (ft == typeof(float))
			{
				if (hasRange)
					body.AppendF($"\tdesc.Slider(\"{name}\", \"{displayName}\", &{field.Name}, {rangeMin}f, {rangeMax}f);\n");
				else
					body.AppendF($"\tdesc.Float(\"{name}\", \"{displayName}\", &{field.Name}, {rangeMin}f, {rangeMax}f);\n");
			}
			else if (ft == typeof(int32))
				body.AppendF($"\tdesc.Int32(\"{name}\", \"{displayName}\", &{field.Name}, {(int32)rangeMin}, {(int32)rangeMax});\n");
			else if (ft == typeof(uint32))
				body.AppendF($"\tdesc.UInt32(\"{name}\", \"{displayName}\", &{field.Name}, 0, {(uint32)rangeMax});\n");
			else if (ft == typeof(bool))
				body.AppendF($"\tdesc.Bool(\"{name}\", \"{displayName}\", &{field.Name});\n");
			else if (ft == typeof(String))
				body.AppendF($"\tdesc.Str(\"{name}\", \"{displayName}\", &{field.Name});\n");
			else if (ft == typeof(Sedulous.Core.Mathematics.Vector3))
				body.AppendF($"\tdesc.Vec3(\"{name}\", \"{displayName}\", &{field.Name});\n");
			else if (ft == typeof(Sedulous.Core.Mathematics.Vector4))
			{
				if (editorHint == .Color)
					body.AppendF($"\tdesc.Color4(\"{name}\", \"{displayName}\", &{field.Name});\n");
				else
					body.AppendF($"\tdesc.Vec4(\"{name}\", \"{displayName}\", &{field.Name});\n");
			}
			else if (ft == typeof(Sedulous.Core.Mathematics.Quaternion))
				body.AppendF($"\tdesc.Quat(\"{name}\", \"{displayName}\", &{field.Name});\n");
			else if (ft == typeof(Sedulous.Resources.ResourceRef))
			{
				{ String extFilter = scope .(); if (field.HasCustomAttribute<ResourceRefTypeAttribute>()) extFilter.Set(field.GetCustomAttribute<ResourceRefTypeAttribute>().Value.Extension); body.AppendF($"\tdesc.ResRef(\"{name}\", \"{displayName}\", new () => {{ return {propName}; }}, new (r) => {{ Set{propName}(r); }}, \"{extFilter}\");\n"); }
			}
			else if (let specType = ft as SpecializedGenericType)
			{
				if (specType.UnspecializedType == typeof(System.Collections.List<>) &&
					specType.GetGenericArg(0) == typeof(Sedulous.Resources.ResourceRef))
				{
					String singularName = scope .(propName);
					if (singularName.EndsWith("s"))
						singularName.RemoveFromEnd(1);

					{ String extFilter = scope .(); if (field.HasCustomAttribute<ResourceRefTypeAttribute>()) extFilter.Set(field.GetCustomAttribute<ResourceRefTypeAttribute>().Value.Extension); body.AppendF($"\tdesc.ResRefList(\"{name}\", \"{displayName}\", new () => {{ return {singularName}Count; }}, new (i) => {{ return Get{singularName}(i); }}, new (i, r) => {{ Set{singularName}(i, r); }}, \"{extFilter}\");\n"); }
				}
			}
			else if (ft.IsEnum)
				body.AppendF($"\tdesc.EnumField(\"{name}\", \"{displayName}\", &{field.Name}, typeof({ft.GetFullName(.. scope .())}));\n");
			// Particle-specific types
			else if (ft == typeof(Sedulous.Particles.RangeFloat))
				body.AppendF($"\tdesc.RangeFloat(\"{field.Name}\", &{field.Name});\n");
			else if (ft == typeof(Sedulous.Particles.RangeVector2))
				body.AppendF($"\tdesc.RangeVector2(\"{field.Name}\", &{field.Name});\n");
			else if (ft == typeof(Sedulous.Particles.RangeColor))
				body.AppendF($"\tdesc.RangeColor(\"{field.Name}\", &{field.Name});\n");
			else if (ft == typeof(Sedulous.Particles.ParticleCurveFloat))
			{
				if (hasRange)
					body.AppendF($"\tdesc.CurveFloat(\"{field.Name}\", &{field.Name}, {rangeMin}f, {rangeMax}f);\n");
				else
					body.AppendF($"\tdesc.CurveFloat(\"{field.Name}\", &{field.Name});\n");
			}
			else if (ft == typeof(Sedulous.Particles.ParticleCurveColor))
				body.AppendF($"\tdesc.CurveColor(\"{field.Name}\", &{field.Name});\n");
			else if (ft == typeof(Sedulous.Particles.ParticleCurveVector2))
			{
				if (hasRange)
					body.AppendF($"\tdesc.CurveVector2(\"{field.Name}\", &{field.Name}, {rangeMin}f, {rangeMax}f);\n");
				else
					body.AppendF($"\tdesc.CurveVector2(\"{field.Name}\", &{field.Name});\n");
			}
			else if (ft == typeof(Sedulous.Particles.EmissionShape))
				body.AppendF($"\tdesc.EmissionShape(\"{field.Name}\", &{field.Name});\n");
			// Physics types
			else if (ft == typeof(Sedulous.Physics.ShapeConfig))
			{
				// If the component has a `NeedsShapeUpdate: bool` field, pass
				// a closure that sets it true on each edit so the physics
				// manager rebuilds the shape on its next tick. Components
				// without that field get no callback (read-only / one-shot
				// inspectors don't need it).
				bool hasNeedsUpdate = type.GetField("NeedsShapeUpdate") case .Ok;
				if (hasNeedsUpdate)
					body.AppendF($"\tdesc.ShapeConfig(\"{field.Name}\", &{field.Name}, new () => {{ NeedsShapeUpdate = true; }});\n");
				else
					body.AppendF($"\tdesc.ShapeConfig(\"{field.Name}\", &{field.Name});\n");
			}
		}

		body.Append("\tdesc.EndCategory();\n");
		body.Append("}\n");

		Compiler.EmitTypeBody(type, body);
		Compiler.EmitAddInterface(type, typeof(IInspectable));
	}
}
