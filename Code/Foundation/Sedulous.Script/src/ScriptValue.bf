using System;
using Sedulous.Core;
using Sedulous.Scene;

namespace Sedulous.Script;

/// One value crossing the script boundary, in either direction.
///
/// A flat union with a kind: no allocation for the kinds a frame sees every tick. The
/// accessors assume the kind; the surface says what each slot is, and the VM checks
/// against it before calling.
/// A script's entity: the handle AND the scene it lives in, so a call resolves it there and
/// never in whichever scene happens to be ambient. Null scene means "the context's".
[CRepr]
struct ScriptEntity
{
	public EntityHandle Handle;
	public Scene Scene;

	public this(EntityHandle handle, Scene scene)
	{
		Handle = handle;
		Scene = scene;
	}
}

[Union]
struct ScriptValueData
{
	public bool Bool;
	public int64 Int;
	public double Float;
	public StringView String;
	public Guid Guid;
	public ScriptEntity Entity;
	public Float2 Float2;
	public Float3 Float3;
	public Float4 Float4;
	public Quaternion Quaternion;
	public Color Color;
	public Object Object;
	public void* Struct;
	public ScriptList* List;
}

struct ScriptValue
{
	public ScriptValueKind Kind = .Nil;
	public ScriptValueData Data = default;
	/// For a Struct: what the pointer points at.
	public Type StructType = null;

	public this() {}

	public static ScriptValue Nil => .();

	// ---- in ----

	public static ScriptValue FromBool(bool v) { var r = ScriptValue(); r.Kind = .Bool; r.Data.Bool = v; return r; }
	public static ScriptValue FromInt(int64 v) { var r = ScriptValue(); r.Kind = .Int; r.Data.Int = v; return r; }
	public static ScriptValue FromFloat(double v) { var r = ScriptValue(); r.Kind = .Float; r.Data.Float = v; return r; }
	public static ScriptValue FromString(StringView v) { var r = ScriptValue(); r.Kind = .String; r.Data.String = v; return r; }
	public static ScriptValue FromGuid(Guid v) { var r = ScriptValue(); r.Kind = .Guid; r.Data.Guid = v; return r; }
	public static ScriptValue FromEntity(EntityHandle v, Scene scene = null) { var r = ScriptValue(); r.Kind = .Entity; r.Data.Entity = .(v, scene); return r; }
	public static ScriptValue FromFloat2(Float2 v) { var r = ScriptValue(); r.Kind = .Float2; r.Data.Float2 = v; return r; }
	public static ScriptValue FromFloat3(Float3 v) { var r = ScriptValue(); r.Kind = .Float3; r.Data.Float3 = v; return r; }
	public static ScriptValue FromFloat4(Float4 v) { var r = ScriptValue(); r.Kind = .Float4; r.Data.Float4 = v; return r; }
	public static ScriptValue FromQuaternion(Quaternion v) { var r = ScriptValue(); r.Kind = .Quaternion; r.Data.Quaternion = v; return r; }
	public static ScriptValue FromColor(Color v) { var r = ScriptValue(); r.Kind = .Color; r.Data.Color = v; return r; }
	public static ScriptValue FromObject(Object v) { var r = ScriptValue(); r.Kind = (v != null) ? .Object : .Nil; r.Data.Object = v; return r; }
	public static ScriptValue FromStruct(void* p, Type type) { var r = ScriptValue(); r.Kind = .Struct; r.Data.Struct = p; r.StructType = type; return r; }
	public static ScriptValue FromList(ScriptList* list) { var r = ScriptValue(); r.Kind = (list != null) ? .List : .Nil; r.Data.List = list; return r; }

	// ---- out ----

	public bool AsBool => Data.Bool;
	public int64 AsInt => Data.Int;
	public double AsFloat => Data.Float;
	public StringView AsString => Data.String;
	public Guid AsGuid => Data.Guid;
	public EntityHandle AsEntity => Data.Entity.Handle;
	/// The scene an entity value names, null when it names none.
	public Scene AsEntityScene => (Kind == .Entity) ? Data.Entity.Scene : null;
	public Float2 AsFloat2 => Data.Float2;
	public Float3 AsFloat3 => Data.Float3;
	public Float4 AsFloat4 => Data.Float4;
	public Quaternion AsQuaternion => Data.Quaternion;
	public Color AsColor => Data.Color;
	public Object AsObject => (Kind == .Object) ? Data.Object : null;
	public void* AsStruct => (Kind == .Struct) ? Data.Struct : null;
	public ScriptList* AsList => (Kind == .List) ? Data.List : null;

	public bool IsNil => Kind == .Nil;

	/// A script has one number: an Int crosses into a float parameter. The reverse does
	/// not hold; a float into an integer would truncate silently.
	public bool IsNumber => (Kind == .Float) || (Kind == .Int);
	public double AsNumber => (Kind == .Int) ? (double)Data.Int : Data.Float;

	/// Whether this value can fill a slot of `kind`, with `typeName` naming the class or
	/// struct for the Object and Struct kinds. Exact is a kind match; a promotion is Int
	/// into Float, or Nil into Object.
	public bool Matches(ScriptValueKind kind, StringView typeName, out bool exact)
	{
		exact = Kind == kind;
		switch (kind)
		{
		case .Float:
			return IsNumber;
		case .Object:
			if (Kind == .Nil)
				return true;
			if (Kind != .Object)
				return false;
			// The runtime type, or a base of it: a script may hold a derived object.
			var t = Data.Object.GetType();
			while (t != null)
			{
				if (t.GetFullName(.. scope .()) == typeName)
					return true;
				t = t.BaseType;
			}
			return false;
		case .Struct:
			return (Kind == .Struct) && (Data.Struct != null) && (StructType != null)
				&& (StructType.GetFullName(.. scope .()) == typeName);
		case .List:
			// Nil stands for an empty list; a list must be of the slot's element type.
			if (Kind == .Nil)
				return true;
			return (Kind == .List) && (Data.List != null)
				&& (typeName.IsEmpty || (Data.List.ElementType == typeName));
		default:
			return Kind == kind;
		}
	}
}
