using System;
using Sedulous.Core;
using Sedulous.UI.Toolkit;

namespace Sedulous.Editor.App;

/// Property rows that edit a field IN PLACE through a pointer and report the edit under the
/// category plus name as its merge key, so a scrub on one row is one undo step. What the
/// asset pages whose undo is a whole snapshot build their inspectors from. The pointers are
/// into objects the page owns, valid until the next inspector rebuild; `commit` is BORROWED
/// from the page and outlives the rows.
static class InPlaceRows
{
	public typealias Commit = delegate void(StringView key);

	private static String Key(StringView category, StringView name) => new String(category)..Append(name);

	public static void Float(PropertyGrid g, StringView name, float* field, StringView category, Commit commit,
		double min = -1e9, double max = 1e9, double step = 0.05)
	{
		let key = Key(category, name);
		g.AddProperty(new FloatEditor(name, *field, min, max, step, 3, new [=field, =commit, =key](v) =>
			{
				*field = (float)v;
				commit(key);
			} ~ delete key, category));
	}

	public static void Int(PropertyGrid g, StringView name, int32* field, StringView category, Commit commit,
		int64 min = 0, int64 max = 1000000)
	{
		let key = Key(category, name);
		g.AddProperty(new IntEditor(name, *field, min, max, new [=field, =commit, =key](v) =>
			{
				*field = (int32)v;
				commit(key);
			} ~ delete key, category));
	}

	public static void Bool(PropertyGrid g, StringView name, bool* field, StringView category, Commit commit)
	{
		let key = Key(category, name);
		g.AddProperty(new BoolEditor(name, *field, new [=field, =commit, =key](v) =>
			{
				*field = v;
				commit(key);
			} ~ delete key, category));
	}

	public static void Text(PropertyGrid g, StringView name, String field, StringView category, Commit commit)
	{
		let key = Key(category, name);
		g.AddProperty(new StringEditor(name, field, new [=field, =commit, =key](v) =>
			{
				field.Set(v);
				commit(key);
			} ~ delete key, category));
	}

	public static void Float2(PropertyGrid g, StringView name, Float2* field, StringView category, Commit commit,
		float min = -100000.0f, float max = 100000.0f, float step = 0.01f)
	{
		let key = Key(category, name);
		g.AddProperty(new Float2Editor(name, *field, min, max, step, new [=field, =commit, =key](v) =>
			{
				*field = v;
				commit(key);
			} ~ delete key, category));
	}

	public static void Float3(PropertyGrid g, StringView name, Float3* field, StringView category, Commit commit)
	{
		let key = Key(category, name);
		g.AddProperty(new Float3Editor(name, *field, -1000.0f, 1000.0f, 0.05f, new [=field, =commit, =key](v) =>
			{
				*field = v;
				commit(key);
			} ~ delete key, category));
	}

	public static void Color(PropertyGrid g, StringView name, Float4* field, StringView category, Commit commit)
	{
		let key = Key(category, name);
		g.AddProperty(new ColorEditor(name, .(field.X, field.Y, field.Z, field.W), new [=field, =commit, =key](c) =>
			{
				*field = .(c.R, c.G, c.B, c.A);
				commit(key);
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
}
