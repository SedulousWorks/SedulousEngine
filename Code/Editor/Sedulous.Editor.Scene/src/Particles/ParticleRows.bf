using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.UI.Toolkit;
using Sedulous.Particles;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Scene;

/// The particle inspector's compound rows over InPlaceRows: a range as two rows, an emission
/// shape as its enum and fields, and the curve editors. `commit` is BORROWED from the page.
static class ParticleRows
{
	public static void RangeFloat(PropertyGrid g, StringView label, RangeFloat* r, StringView category, InPlaceRows.Commit commit,
		double min = -1e6, double max = 1e6, double step = 0.02)
	{
		InPlaceRows.Float(g, scope $"{label} min", &r.Min, category, commit, min, max, step);
		InPlaceRows.Float(g, scope $"{label} max", &r.Max, category, commit, min, max, step);
	}

	public static void RangeFloat2(PropertyGrid g, StringView label, RangeFloat2* r, StringView category, InPlaceRows.Commit commit)
	{
		InPlaceRows.Float2(g, scope $"{label} min", &r.Min, category, commit, 0.0f, 1000.0f, 0.01f);
		InPlaceRows.Float2(g, scope $"{label} max", &r.Max, category, commit, 0.0f, 1000.0f, 0.01f);
	}

	public static void RangeColor(PropertyGrid g, StringView label, RangeColor* r, StringView category, InPlaceRows.Commit commit)
	{
		InPlaceRows.Color(g, scope $"{label} start", &r.Min, category, commit);
		InPlaceRows.Color(g, scope $"{label} end", &r.Max, category, commit);
	}

	private static readonly StringView[8] cShapes = .("Point", "Sphere", "Hemisphere", "Box", "Cone", "Ring", "Circle", "Edge");

	public static void EmissionShape(PropertyGrid g, StringView label, EmissionShape* shape, StringView category, InPlaceRows.Commit commit)
	{
		let key = new String(category)..Append(label);
		InPlaceRows.Enum(g, scope $"{label} shape", (int32)shape.Type, cShapes, new [=shape, =commit, =key](v) =>
			{
				shape.Type = (EmissionShapeType)v;
				commit(key);
			} ~ delete key, category);
		InPlaceRows.Float(g, scope $"{label} radius", &shape.Radius, category, commit, 0.0, 100.0, 0.05);
		InPlaceRows.Float3(g, scope $"{label} box extents", &shape.Extents, category, commit);
		InPlaceRows.Float(g, scope $"{label} cone angle", &shape.Angle, category, commit, 0.0, 3.1416, 0.01);
		InPlaceRows.Float(g, scope $"{label} arc", &shape.Arc, category, commit, 0.0, 1.0, 0.01);
		InPlaceRows.Bool(g, scope $"{label} from shell", &shape.EmitFromShell, category, commit);
	}

	public static void CurveFloat(PropertyGrid g, StringView name, ParticleCurveFloat* curve, StringView category, ParticleEffectEditorPage page)
	{
		g.AddProperty(new CurveFieldEditor(name, curve, page, scope String(category)..Append(name), category));
	}

	public static void CurveFloat2(PropertyGrid g, StringView name, ParticleCurveFloat2* curve, StringView category, ParticleEffectEditorPage page)
	{
		g.AddProperty(new CurveFieldEditor(name, curve, page, scope String(category)..Append(name), category));
	}

	public static void CurveColor(PropertyGrid g, StringView name, ParticleCurveColor* curve, StringView category, ParticleEffectEditorPage page)
	{
		g.AddProperty(new GradientFieldEditor(name, curve, page, scope String(category)..Append(name), category));
	}
}
