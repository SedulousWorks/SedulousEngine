using System;
using Sedulous.Core;
using Sedulous.Core.Serialization;

namespace Sedulous.Script.Resource;

/// One tagged property value: a harvested default, or a component's override. The kind
/// selects the payload that means anything; the rest stay at their defaults.
///
/// The tag is written FIRST, so both directions branch on the same kind and the writer and
/// reader stay symmetric by construction: one switch, two modes.
struct ScriptPropertyValue : ISerializable
{
	public ScriptPropertyType Kind = .None;
	/// Float and Int.
	public double Number = 0.0;
	public bool Boolean = false;
	public String Text = null;
	public Color Color = .(1, 1, 1, 1);
	public Float3 Vector = .(0, 0, 0);
	/// Entity and Asset.
	public Guid Id = .();

	public this() {}

	public static ScriptPropertyValue Float(double v) { var r = ScriptPropertyValue(); r.Kind = .Float; r.Number = v; return r; }
	public static ScriptPropertyValue Int(int64 v) { var r = ScriptPropertyValue(); r.Kind = .Int; r.Number = (double)v; return r; }
	public static ScriptPropertyValue Bool(bool v) { var r = ScriptPropertyValue(); r.Kind = .Bool; r.Boolean = v; return r; }
	public static ScriptPropertyValue Vec3(Float3 v) { var r = ScriptPropertyValue(); r.Kind = .Vec3; r.Vector = v; return r; }
	public static ScriptPropertyValue Colour(Color v) { var r = ScriptPropertyValue(); r.Kind = .Color; r.Color = v; return r; }
	public static ScriptPropertyValue Entity(Guid id) { var r = ScriptPropertyValue(); r.Kind = .Entity; r.Id = id; return r; }
	public static ScriptPropertyValue Asset(Guid id) { var r = ScriptPropertyValue(); r.Kind = .Asset; r.Id = id; return r; }

	/// Text is OWNED by the holder that sets it; a value copied by assignment shares the
	/// string, so the holder that owns the record frees it, once.
	public static ScriptPropertyValue Str(String owned) { var r = ScriptPropertyValue(); r.Kind = .String; r.Text = owned; return r; }

	public void Serialize(ISerializer ar) mut
	{
		uint8 kind = (uint8)Kind;
		SerializeValue(ar, "kind", ref kind);
		Kind = (ScriptPropertyType)kind;
		switch (Kind)
		{
		case .Float, .Int:
			SerializeValue(ar, "number", ref Number);
		case .Bool:
			SerializeValue(ar, "boolean", ref Boolean);
		case .String:
			if (Text == null)
				Text = new String();
			Sedulous.Core.Serialization.Serialize(ar, "text", Text);
		case .Color:
			SerializeValue(ar, "color", ref Color);
		case .Vec3:
			SerializeValue(ar, "vector", ref Vector);
		case .Entity, .Asset:
			SerializeValue(ar, "id", ref Id);
		case .None:
		}
	}

	public bool Equals(ScriptPropertyValue other)
	{
		if (Kind != other.Kind)
			return false;
		switch (Kind)
		{
		case .Float, .Int: return Number == other.Number;
		case .Bool: return Boolean == other.Boolean;
		case .String: return StringView(Text ?? "") == StringView(other.Text ?? "");
		case .Color: return Color == other.Color;
		case .Vec3: return Vector == other.Vector;
		case .Entity, .Asset: return Id == other.Id;
		case .None: return true;
		}
	}
}
