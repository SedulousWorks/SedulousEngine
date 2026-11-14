using System;
using Sedulous.Core;

namespace Sedulous.Script;

/// One value crossing the script boundary, in either direction.
///
/// A flat union with a kind: no allocation for the kinds a frame sees every tick. The
/// accessors assume the kind; the surface says what each slot is, and the VM checks
/// against it before calling.
/// A script's entity: the handle AND the owner it lives in, so a call resolves it there and
/// never in whichever owner happens to be ambient. No owner means "the context's".
///
/// Opaque to the core: an index and generation laid out as the scene's EntityHandle, and
/// the owner as its slot and generation in ScriptWeakTable.Shared, so the core carries an
/// entity without knowing what a scene is, and an entity kept past its scene reads its owner
/// as gone rather than reaching it. Sixteen bytes, as AngelScript registers it.
[CRepr, Align(8)]
struct ScriptEntity
{
	/// The same value as EntityHandle's: an unassigned entity reads the same through both.
	public const uint32 cInvalidIndex = 0xFFFFFFFF;

	public uint32 Index;
	public uint32 Generation;
	/// The owner's place in the process's weak table; generation 0 names none.
	public uint32 OwnerSlot;
	public uint32 OwnerGeneration;

	public this(uint32 index, uint32 generation, Object owner)
	{
		Index = index;
		Generation = generation;
		OwnerSlot = 0;
		OwnerGeneration = 0;
		Owner = owner;
	}

	public static ScriptEntity Invalid => .(cInvalidIndex, 0, null);

	/// The owner, read through the table on every use: null when the entity names none, or
	/// the one it names is gone. Set from an object in the table (a scene, which takes its slot
	/// here when it has none); any other object names none.
	public Object Owner
	{
		get => ScriptWeakTable.Shared.ResolveWeak(OwnerSlot, OwnerGeneration);
		set mut
		{
			ScriptWeakRef named = default;
			if (let held = value as IScriptWeaklyHeld)
				named = held.TakeScriptWeak();
			let inTable = ScriptWeakTable.Shared.Holds(named);
			OwnerSlot = inTable ? named.Slot : 0;
			OwnerGeneration = inTable ? named.Generation : 0;
		}
	}

	/// Whether the entity names an owner, there or gone.
	public bool NamesOwner => OwnerGeneration != 0;

	/// Whether the owner it names is gone: an entity kept past its scene.
	public bool OwnerGone => NamesOwner && (Owner == null);

	/// The same owner, by its place and never resolving, so two entities of one gone scene
	/// still share it.
	public bool SameOwner(ScriptEntity other) => (OwnerSlot == other.OwnerSlot) && (OwnerGeneration == other.OwnerGeneration);
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
	/// Sixteen bytes, as the widest of the rest: the union does not grow for it.
	public ScriptWeakRef Weak;
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
	public static ScriptValue FromEntityRef(ScriptEntity v) { var r = ScriptValue(); r.Kind = .Entity; r.Data.Entity = v; return r; }
	public static ScriptValue FromFloat2(Float2 v) { var r = ScriptValue(); r.Kind = .Float2; r.Data.Float2 = v; return r; }
	public static ScriptValue FromFloat3(Float3 v) { var r = ScriptValue(); r.Kind = .Float3; r.Data.Float3 = v; return r; }
	public static ScriptValue FromFloat4(Float4 v) { var r = ScriptValue(); r.Kind = .Float4; r.Data.Float4 = v; return r; }
	public static ScriptValue FromQuaternion(Quaternion v) { var r = ScriptValue(); r.Kind = .Quaternion; r.Data.Quaternion = v; return r; }
	public static ScriptValue FromColor(Color v) { var r = ScriptValue(); r.Kind = .Color; r.Data.Color = v; return r; }
	public static ScriptValue FromObject(Object v) { var r = ScriptValue(); r.Kind = (v != null) ? .Object : .Nil; r.Data.Object = v; return r; }
	public static ScriptValue FromStruct(void* p, Type type) { var r = ScriptValue(); r.Kind = .Struct; r.Data.Struct = p; r.StructType = type; return r; }
	public static ScriptValue FromList(ScriptList* list) { var r = ScriptValue(); r.Kind = (list != null) ? .List : .Nil; r.Data.List = list; return r; }
	public static ScriptValue FromDelegate(ScriptDelegate d) { var r = ScriptValue(); r.Kind = (d != null) ? .Delegate : .Nil; r.Data.Object = d; return r; }
	/// The weak handle to `held`; Nil when there is none, or it is in no table.
	public static ScriptValue FromWeak(IScriptWeaklyHeld held) => (held != null) ? FromWeakRef(held.TakeScriptWeak()) : .Nil;
	public static ScriptValue FromWeakRef(ScriptWeakRef v) { var r = ScriptValue(); r.Kind = v.IsEmpty ? .Nil : .Weak; r.Data.Weak = v; return r; }
	/// A counted object, borrowed: no reference is taken. Nil for null.
	public static ScriptValue FromCounted(IScriptCounted v) { var r = ScriptValue(); r.Kind = (v != null) ? .Counted : .Nil; r.Data.Object = (Object)v; return r; }

	// ---- out ----

	public bool AsBool => Data.Bool;
	public int64 AsInt => Data.Int;
	public double AsFloat => Data.Float;
	public StringView AsString => Data.String;
	public Guid AsGuid => Data.Guid;
	/// The index and generation read whatever the kind, as AsEntity; the owner only from an
	/// entity value, and as it was named, so one whose owner is gone stays gone where it is
	/// written back.
	public ScriptEntity AsEntityRef
	{
		get
		{
			var e = Data.Entity;
			if (Kind != .Entity)
			{
				e.OwnerSlot = 0;
				e.OwnerGeneration = 0;
			}
			return e;
		}
	}
	/// The owner an entity value names, null when it names none or that owner is gone.
	public Object AsEntityOwner => (Kind == .Entity) ? Data.Entity.Owner : null;
	/// Whether this is an entity value that names an owner, there or gone.
	public bool NamesEntityOwner => (Kind == .Entity) && Data.Entity.NamesOwner;
	/// Whether this is an entity value whose owner is gone: one kept past its scene, whose
	/// calls do nothing.
	public bool EntityOwnerGone => (Kind == .Entity) && Data.Entity.OwnerGone;
	public Float2 AsFloat2 => Data.Float2;
	public Float3 AsFloat3 => Data.Float3;
	public Float4 AsFloat4 => Data.Float4;
	public Quaternion AsQuaternion => Data.Quaternion;
	public Color AsColor => Data.Color;
	public Object AsObject => (Kind == .Object) ? Data.Object : null;
	public void* AsStruct => (Kind == .Struct) ? Data.Struct : null;
	public ScriptList* AsList => (Kind == .List) ? Data.List : null;
	public ScriptDelegate AsDelegate => (Kind == .Delegate) ? (ScriptDelegate)Data.Object : null;
	public ScriptWeakRef AsWeak => (Kind == .Weak) ? Data.Weak : default;
	public IScriptCounted AsCounted => (Kind == .Counted) ? (Data.Object as IScriptCounted) : null;

	/// What a weak handle names now: null when this is not one, or its object is gone.
	public Object ResolveWeak() => (Kind == .Weak) ? Data.Weak.Resolve() : null;

	/// Whether two values are the same weak handle, by identity and never resolving, so two
	/// gone handles to one object still compare equal. Nil is the same as Nil only.
	public bool SameWeak(ScriptValue other)
	{
		if ((Kind != .Weak) || (other.Kind != .Weak))
			return (Kind == .Nil) && (other.Kind == .Nil);
		return Data.Weak.SameAs(other.Data.Weak);
	}

	public bool IsNil => Kind == .Nil;

	/// A script has one number: an Int crosses into a float parameter. The reverse does
	/// not hold; a float into an integer would truncate silently.
	public bool IsNumber => (Kind == .Float) || (Kind == .Int);
	public double AsNumber => (Kind == .Int) ? (double)Data.Int : Data.Float;

	/// Whether this value can fill a slot of `kind`, with `typeName` naming the class or
	/// struct for the Object, Struct, Weak and Counted kinds. Exact is a kind match; a promotion
	/// is Int into Float, or Nil into Object, Weak or Counted.
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
		case .Weak:
			if (Kind == .Nil)
				return true;
			if (Kind != .Weak)
				return false;
			// A gone handle passes: the callee reads null, as for a Nil.
			let resolved = Data.Weak.Resolve();
			if (resolved == null)
				return true;
			var w = resolved.GetType();
			while (w != null)
			{
				if (w.GetFullName(.. scope .()) == typeName)
					return true;
				w = w.BaseType;
			}
			return false;
		case .Counted:
			if (Kind == .Nil)
				return true;
			if (Kind != .Counted)
				return false;
			// The runtime type, or a base of it, as for an Object.
			var c = Data.Object.GetType();
			while (c != null)
			{
				if (c.GetFullName(.. scope .()) == typeName)
					return true;
				c = c.BaseType;
			}
			return false;
		case .Delegate:
			// Nil clears a binding.
			return (Kind == .Nil) || (Kind == .Delegate);
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
