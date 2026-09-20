using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.UI.Toolkit;
using Sedulous.Particles;

namespace Sedulous.Editor.Scene;

/// The particle inspector's row makers: each edits a module or system field IN PLACE
/// through a pointer and commits under the category plus name as its merge key, so a
/// scrub on one row is one undo step. The pointers are into objects the page owns, valid
/// until the next inspector rebuild.
static class ParticleRows
{
	private static String Key(StringView category, StringView name) => new String(category)..Append(name);

	public static void Float(ParticleEffectEditorPage page, PropertyGrid g, StringView name, float* field, StringView category,
		double min = -1e9, double max = 1e9, double step = 0.05)
	{
		let key = Key(category, name);
		g.AddProperty(new FloatEditor(name, *field, min, max, step, 3, new [=field, =page, =key](v) =>
			{
				*field = (float)v;
				page.CommitEdit(key);
			} ~ delete key, category));
	}

	public static void Int(ParticleEffectEditorPage page, PropertyGrid g, StringView name, int32* field, StringView category,
		int64 min = 0, int64 max = 1000000)
	{
		let key = Key(category, name);
		g.AddProperty(new IntEditor(name, *field, min, max, new [=field, =page, =key](v) =>
			{
				*field = (int32)v;
				page.CommitEdit(key);
			} ~ delete key, category));
	}

	public static void Bool(ParticleEffectEditorPage page, PropertyGrid g, StringView name, bool* field, StringView category)
	{
		let key = Key(category, name);
		g.AddProperty(new BoolEditor(name, *field, new [=field, =page, =key](v) =>
			{
				*field = v;
				page.CommitEdit(key);
			} ~ delete key, category));
	}

	public static void Float2(ParticleEffectEditorPage page, PropertyGrid g, StringView name, Float2* field, StringView category,
		float min = -100000.0f, float max = 100000.0f, float step = 0.01f)
	{
		let key = Key(category, name);
		g.AddProperty(new Float2Editor(name, *field, min, max, step, new [=field, =page, =key](v) =>
			{
				*field = v;
				page.CommitEdit(key);
			} ~ delete key, category));
	}

	public static void Float3(ParticleEffectEditorPage page, PropertyGrid g, StringView name, Float3* field, StringView category)
	{
		let key = Key(category, name);
		g.AddProperty(new Float3Editor(name, *field, -1000.0f, 1000.0f, 0.05f, new [=field, =page, =key](v) =>
			{
				*field = v;
				page.CommitEdit(key);
			} ~ delete key, category));
	}

	public static void Color(ParticleEffectEditorPage page, PropertyGrid g, StringView name, Float4* field, StringView category)
	{
		let key = Key(category, name);
		g.AddProperty(new ColorEditor(name, .(field.X, field.Y, field.Z, field.W), new [=field, =page, =key](c) =>
			{
				*field = .(c.R, c.G, c.B, c.A);
				page.CommitEdit(key);
			} ~ delete key, category));
	}

	/// `setter` is consumed.
	public static void Enum(PropertyGrid g, StringView name, int32 value, Span<StringView> items, delegate void(int32) setter, StringView category)
	{
		g.AddProperty(new EnumEditor(name, value, items, setter, category));
	}

	/// `action` is consumed.
	public static void Button(PropertyGrid g, StringView name, StringView category, delegate void() action)
	{
		g.AddProperty(new ButtonEditor(name, action, category));
	}

	public static void RangeFloat(ParticleEffectEditorPage page, PropertyGrid g, StringView label, RangeFloat* r, StringView category,
		double min = -1e6, double max = 1e6, double step = 0.02)
	{
		Float(page, g, scope $"{label} min", &r.Min, category, min, max, step);
		Float(page, g, scope $"{label} max", &r.Max, category, min, max, step);
	}

	public static void RangeFloat2(ParticleEffectEditorPage page, PropertyGrid g, StringView label, RangeFloat2* r, StringView category)
	{
		Float2(page, g, scope $"{label} min", &r.Min, category, 0.0f, 1000.0f, 0.01f);
		Float2(page, g, scope $"{label} max", &r.Max, category, 0.0f, 1000.0f, 0.01f);
	}

	public static void RangeColor(ParticleEffectEditorPage page, PropertyGrid g, StringView label, RangeColor* r, StringView category)
	{
		Color(page, g, scope $"{label} start", &r.Min, category);
		Color(page, g, scope $"{label} end", &r.Max, category);
	}

	private static readonly StringView[8] cShapes = .("Point", "Sphere", "Hemisphere", "Box", "Cone", "Ring", "Circle", "Edge");

	public static void EmissionShape(ParticleEffectEditorPage page, PropertyGrid g, StringView label, EmissionShape* shape, StringView category)
	{
		let key = Key(category, label);
		Enum(g, scope $"{label} shape", (int32)shape.Type, cShapes, new [=shape, =page, =key](v) =>
			{
				shape.Type = (EmissionShapeType)v;
				page.CommitEdit(key);
			} ~ delete key, category);
		Float(page, g, scope $"{label} radius", &shape.Radius, category, 0.0, 100.0, 0.05);
		Float3(page, g, scope $"{label} box extents", &shape.Extents, category);
		Float(page, g, scope $"{label} cone angle", &shape.Angle, category, 0.0, 3.1416, 0.01);
		Float(page, g, scope $"{label} arc", &shape.Arc, category, 0.0, 1.0, 0.01);
		Bool(page, g, scope $"{label} from shell", &shape.EmitFromShell, category);
	}

	public static void CurveFloat(ParticleEffectEditorPage page, PropertyGrid g, StringView name, ParticleCurveFloat* curve, StringView category)
	{
		let key = Key(category, name);
		defer delete key;
		g.AddProperty(new CurveFieldEditor(name, curve, page, key, category));
	}

	public static void CurveFloat2(ParticleEffectEditorPage page, PropertyGrid g, StringView name, ParticleCurveFloat2* curve, StringView category)
	{
		let key = Key(category, name);
		defer delete key;
		g.AddProperty(new CurveFieldEditor(name, curve, page, key, category));
	}

	public static void CurveColor(ParticleEffectEditorPage page, PropertyGrid g, StringView name, ParticleCurveColor* curve, StringView category)
	{
		let key = Key(category, name);
		defer delete key;
		g.AddProperty(new GradientFieldEditor(name, curve, page, key, category));
	}
}
