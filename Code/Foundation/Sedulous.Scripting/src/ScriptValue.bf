using System;
using Sedulous.Core;
using Sedulous.Scene;

namespace Sedulous.Scripting;

/// One value crossing the script boundary, in either direction.
///
/// A flat union with a kind: no allocation for the kinds a frame sees every tick. The
/// accessors assume the kind; the surface says what each slot is, and the VM checks
/// against it before calling.
[Union]
struct ScriptValueData
{
	public bool Bool;
	public int64 Int;
	public double Float;
	public StringView String;
	public Guid Guid;
	public EntityHandle Entity;
	public Float2 Float2;
	public Float3 Float3;
	public Float4 Float4;
	public Quaternion Quaternion;
	public Color Color;
	public Object Object;
	public void* Struct;
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
	public static ScriptValue FromEntity(EntityHandle v) { var r = ScriptValue(); r.Kind = .Entity; r.Data.Entity = v; return r; }
	public static ScriptValue FromFloat2(Float2 v) { var r = ScriptValue(); r.Kind = .Float2; r.Data.Float2 = v; return r; }
	public static ScriptValue FromFloat3(Float3 v) { var r = ScriptValue(); r.Kind = .Float3; r.Data.Float3 = v; return r; }
	public static ScriptValue FromFloat4(Float4 v) { var r = ScriptValue(); r.Kind = .Float4; r.Data.Float4 = v; return r; }
	public static ScriptValue FromQuaternion(Quaternion v) { var r = ScriptValue(); r.Kind = .Quaternion; r.Data.Quaternion = v; return r; }
	public static ScriptValue FromColor(Color v) { var r = ScriptValue(); r.Kind = .Color; r.Data.Color = v; return r; }
	public static ScriptValue FromObject(Object v) { var r = ScriptValue(); r.Kind = (v != null) ? .Object : .Nil; r.Data.Object = v; return r; }
	public static ScriptValue FromStruct(void* p, Type type) { var r = ScriptValue(); r.Kind = .Struct; r.Data.Struct = p; r.StructType = type; return r; }

	// ---- out ----

	public bool AsBool => Data.Bool;
	public int64 AsInt => Data.Int;
	public double AsFloat => Data.Float;
	public StringView AsString => Data.String;
	public Guid AsGuid => Data.Guid;
	public EntityHandle AsEntity => Data.Entity;
	public Float2 AsFloat2 => Data.Float2;
	public Float3 AsFloat3 => Data.Float3;
	public Float4 AsFloat4 => Data.Float4;
	public Quaternion AsQuaternion => Data.Quaternion;
	public Color AsColor => Data.Color;
	public Object AsObject => (Kind == .Object) ? Data.Object : null;
	public void* AsStruct => (Kind == .Struct) ? Data.Struct : null;

	public bool IsNil => Kind == .Nil;
}
