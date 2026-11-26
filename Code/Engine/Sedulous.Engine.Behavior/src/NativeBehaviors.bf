using System;
using System.Reflection;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Scene;
using Sedulous.Script;
using Sedulous.Script.Resource;

namespace Sedulous.Engine.Behavior;

/// Marks a class written in native code as a behavior the run host can make: reflected, so the
/// host makes it by its full name and calls its handlers and properties by the names scripts use,
/// and always built in, though nothing names it in code. The class derives from RunBehavior,
/// SceneBehavior or EntityBehavior and has a constructor taking nothing.
[AttributeUsage(.Class, .ReflectAttribute | .AlwaysIncludeTarget, ReflectUser = .Type | .Methods | .NonStaticFields | .DefaultConstructor, AlwaysIncludeUser = .AssumeInstantiated | .IncludeAllMethods)]
struct NativeBehaviorAttribute : Attribute
{
}

/// Makes a field of a native behavior one of its properties: what the inspector shows and an
/// entity or a scene overrides, by the field's name with its first letter lowered (`Worth` is
/// `worth`). A field without it is never written from outside.
[AttributeUsage(.Field, .ReflectAttribute)]
struct BehaviorPropertyAttribute : Attribute
{
}

/// What the three kinds' bases share: the run host that made it, through which it finds its
/// run's services, and its fault.
abstract class NativeBehavior
{
	/// BORROWED: the run host that made it, which outlives it.
	private BehaviorRunHost mHost;
	private String mFaultReason = new .() ~ delete _;

	/// The run's service of type T (its host's own, then its run's, then the application's), as a
	/// script reaches a facade; null when there is none.
	public T FindService<T>() where T : class => (mHost != null) ? mHost.FindService(typeof(T)) as T : null;

	/// Disables this behavior, as a script error does: its handlers stop, and `reason` is logged
	/// and is the fault's reason (a run behavior's, RunBehaviorFault). For a class that finds its
	/// own state broken; it takes effect as the running handler returns.
	public void Fault(StringView reason)
	{
		if (mFaultReason.IsEmpty)
			mFaultReason.Set(reason.IsEmpty ? "faulted" : reason);
	}

	/// Why it faulted; empty while it has not.
	public StringView FaultReason => mFaultReason;
}

/// A behavior that lives for the run, across scene loads: the game's own object.
abstract class RunBehavior : NativeBehavior
{
}

/// A behavior of one scene, made when the scene starts.
abstract class SceneBehavior : NativeBehavior
{
	/// BORROWED: the scene it belongs to, given as it is made; null when that scene has gone.
	public Sedulous.Scene.Scene Scene => mScene.Resolve() as Sedulous.Scene.Scene;

	private ScriptWeakRef mScene;
}

/// A behavior attached to an entity, one per slot.
abstract class EntityBehavior : NativeBehavior
{
	/// The entity it is attached to, given as it is made.
	public EntityHandle Entity => mEntity;
	/// BORROWED: the entity's scene; null when it has gone.
	public Sedulous.Scene.Scene Scene => mScene.Resolve() as Sedulous.Scene.Scene;

	private EntityHandle mEntity = .Invalid;
	private ScriptWeakRef mScene;
}

/// A native class's object behind the layer's BehaviorObject: it answers the layer's calls itself,
/// with no runtime. A handler is the method named as the script's handler with its first letter
/// raised (`onPing` is `OnPing`), its numbers fitted to the declared types as a script backend fits
/// them; a property is the field named as the property with its first letter raised, any field
/// read (a playtest's probe) and only one marked BehaviorProperty written. Each call runs under a
/// crash note naming the class, the handler and the entity. A call after which the object has
/// faulted (NativeBehavior.Fault) fails, which disables it, its reason kept by its classes.
class NativeBehaviorObject : BehaviorObject
{
	/// OWNED: the native object.
	private NativeBehavior mObject ~ delete _;
	/// BORROWED: the classes that made it (its run host's), which outlive it.
	private NativeBehaviorClasses mClasses;
	/// " on 'orb'" for an entity's: what a crash note and a fault name after the call.
	private String mWhere = new .() ~ delete _;
	/// The class's own name ("Orb"), which a crash note and a fault name.
	private String mTypeName = new .() ~ delete _;

	/// ClassName is the full name its BehaviorClass records ("NativeSample.Orb").
	public this(NativeBehavior object, NativeBehaviorClasses classes, StringView fullName)
	{
		mObject = object;
		mClasses = classes;
		ClassName.Set(fullName);
		object.GetType().GetName(mTypeName);
	}

	/// The native object (for a test, or a host that must reach it).
	public NativeBehavior Object => mObject;

	public override bool HasMethod(StringView name, int arity) => FindMethod(mObject.GetType(), name, arity) case .Ok;

	public override bool Invoke(StringView name, Span<ScriptValue> args, ref ScriptValue result)
	{
		if (!(FindMethod(mObject.GetType(), name, args.Length) case .Ok(let method)))
			return false;
		// The arguments as the method declares them: each converted into a slot of its own.
		let slots = scope uint8[args.Length * cSlotSize];
		let values = scope Variant[args.Length];
		defer
		{
			for (var value in ref values)
				value.Dispose();
		}
		for (int i < args.Length)
		{
			let type = method.GetParamType(i);
			let slot = &slots[i * cSlotSize];
			if (!NativeValues.ToNative(args[i], type, slot))
			{
				Fail(scope $"{mTypeName}.{name}{mWhere}: argument {i + 1} is not a {type}");
				return false;
			}
			values[i] = Variant.Create(type, slot);
		}

		{
			// What a crash inside the call names; restored as the block ends.
			scope CrashNoteScope(mTypeName, ".", name, mWhere);
			Variant target = Variant.Create(mObject);
			Span<Variant> argSpan = values;
			switch (method.Invoke(target, params argSpan))
			{
			case .Ok(var returned):
				returned.Dispose();
			case .Err(let error):
				Fail(scope $"{mTypeName}.{name}{mWhere}: the call could not be made ({error})");
				return false;
			}
		}
		if (!mObject.FaultReason.IsEmpty)
		{
			GlobalLog(.Error, scope $"Script: {mTypeName}.{name}{mWhere} faulted: {mObject.FaultReason}");
			mClasses.SetLastError(mObject.FaultReason);
			return false;
		}
		return true;
	}

	public override bool GetProperty(StringView name, ref ScriptValue value)
	{
		if (!(FindField(mObject.GetType(), name) case .Ok(let field)))
			return false;
		switch (field.GetValueReference(mObject))
		{
		case .Ok(var reference):
			defer reference.Dispose();
			return NativeValues.FromNative(field.FieldType, reference.DataPtr, ref value);
		case .Err:
			return false;
		}
	}

	public override bool SetProperty(StringView name, ScriptValue value)
	{
		// What the layer tells every object of its place: an entity's its entity, a scene's its scene.
		if (name == "self")
			return BindEntity(value);
		if (name == "scene")
			return BindScene(value);
		if (!(FindField(mObject.GetType(), name) case .Ok(let field)) || !(field.GetCustomAttribute<BehaviorPropertyAttribute>() case .Ok))
			return false;
		let type = field.FieldType;
		if (type == typeof(String))
		{
			// The object's own text, set in place: the field keeps owning its string.
			if (value.Kind != .String)
				return false;
			switch (field.GetValue<String>(mObject))
			{
			case .Ok(let text):
				if (text == null)
					return false;
				text.Set(value.AsString);
				return true;
			case .Err:
				return false;
			}
		}
		uint8[cSlotSize] slot = default;
		if (!NativeValues.ToNative(value, type, &slot[0]))
			return false;
		var converted = Variant.Create(type, &slot[0]);
		defer converted.Dispose();
		return field.SetValue(mObject, converted) case .Ok;
	}

	public override void Release()
	{
		delete this;
	}

	/// The largest value a call or a property converts (a Quaternion, a Float4 or a Guid).
	private const int cSlotSize = 16;

	private bool BindEntity(ScriptValue value)
	{
		let entityBehavior = mObject as EntityBehavior;
		if ((entityBehavior == null) || (value.Kind != .Entity))
			return false;
		let entity = value.AsEntity;
		let scene = value.AsEntityOwner as Scene;
		entityBehavior.[Friend]mEntity = entity;
		entityBehavior.[Friend]mScene = (scene != null) ? scene.TakeScriptWeak() : default;
		mWhere.Clear();
		if (scene != null)
			mWhere.AppendF(" on '{}'", scene.GetEntityName(entity));
		return true;
	}

	private bool BindScene(ScriptValue value)
	{
		let weak = value.AsWeak;
		if (let entityBehavior = mObject as EntityBehavior)
		{
			if (!weak.IsEmpty)
				entityBehavior.[Friend]mScene = weak;
			return true;
		}
		if (let sceneBehavior = mObject as SceneBehavior)
		{
			sceneBehavior.[Friend]mScene = weak;
			return true;
		}
		return false;
	}

	/// Logs a call that failed for a reason of its own (not the object's fault) and keeps it.
	private void Fail(StringView reason)
	{
		GlobalLog(.Error, scope $"Script: {reason}");
		mClasses.SetLastError(reason);
	}

	/// The instance method that handles `handler` taking `arity` arguments, on the type or a base.
	private static Result<MethodInfo> FindMethod(Type type, StringView handler, int arity)
	{
		let name = NativeValues.Raised(handler, .. scope .());
		for (var t = type; t != null; t = t.BaseType)
		{
			for (let method in t.GetMethods(.Instance | .Public | .NonPublic | .DeclaredOnly))
			{
				if ((method.Name == name) && (method.ParamCount == arity))
					return method;
			}
		}
		return .Err;
	}

	/// The instance field that holds `property`, on the type or a base.
	private static Result<FieldInfo> FindField(Type type, StringView property)
	{
		let name = NativeValues.Raised(property, .. scope .());
		for (var t = type; t != null; t = t.BaseType)
		{
			for (let field in t.GetFields(.Instance | .Public | .NonPublic | .DeclaredOnly))
			{
				if (field.Name == name)
					return field;
			}
		}
		return .Err;
	}
}

/// Makes the objects of a run's native classes. A class is found by the full name its
/// BehaviorClass records ("NativeSample.Orb"), checked to derive from its kind's base, and made
/// through its constructor taking nothing. The run host holds one.
class NativeBehaviorClasses
{
	/// The language a native class's BehaviorClass records.
	public const String cLanguage = "native";

	/// BORROWED: the run host whose classes these are.
	private BehaviorRunHost mHost;
	private String mLastError = new .() ~ delete _;

	public this(BehaviorRunHost host)
	{
		mHost = host;
	}

	/// An object of `nativeClass` for the place that takes kind `kind`; null, logged and kept as the
	/// last error, when the class is not registered, is not of `kind`, or cannot be made.
	public BehaviorObject Create(BehaviorClass nativeClass, BehaviorKind kind)
	{
		let type = FindClass(nativeClass.ClassName);
		if (type == null)
		{
			Fail(scope $"native class '{nativeClass.ClassName}' is not built in (is its plugin enabled?)");
			return null;
		}
		let baseType = BaseOf(kind);
		if ((baseType == null) || !type.IsSubtypeOf(baseType))
		{
			Fail(scope $"native class '{nativeClass.ClassName}' does not derive from {BehaviorKinds.TypeName(kind)}");
			return null;
		}
		switch (type.CreateObject())
		{
		case .Ok(let made):
			let object = made as NativeBehavior;
			if (object == null)
			{
				delete made;
				return null;
			}
			object.[Friend]mHost = mHost;
			return new NativeBehaviorObject(object, this, nativeClass.ClassName);
		case .Err:
			Fail(scope $"native class '{nativeClass.ClassName}' cannot be made (does it have a constructor taking nothing?)");
			return null;
		}
	}

	/// The class whose full name is `fullName` ("NativeSample.Orb"), marked NativeBehavior; null
	/// when none is built in.
	public static Type FindClass(StringView fullName)
	{
		let name = scope String();
		for (let type in Type.Types)
		{
			if (!type.IsObject || !(type.GetCustomAttribute<NativeBehaviorAttribute>() case .Ok))
				continue;
			name.Clear();
			type.GetFullName(name);
			if (name == fullName)
				return type;
		}
		return null;
	}

	/// The base type of `kind`'s native classes; null for None.
	public static Type BaseOf(BehaviorKind kind)
	{
		switch (kind)
		{
		case .Run: return typeof(RunBehavior);
		case .Scene: return typeof(SceneBehavior);
		case .Entity: return typeof(EntityBehavior);
		default: return null;
		}
	}

	/// Appends why the last native object failed to be made or faulted, then forgets it.
	public void TakeLastError(String outText)
	{
		outText.Append(mLastError);
		mLastError.Clear();
	}

	public void SetLastError(StringView reason) => mLastError.Set(reason);

	private void Fail(StringView reason)
	{
		GlobalLog(.Error, scope $"Script: {reason}");
		mLastError.Set(reason);
	}
}

/// Converting between the layer's values and the types a native behavior declares.
static class NativeValues
{
	/// `name` with its first letter raised: a script's `onPing` or `worth` as a native member's name.
	public static void Raised(StringView name, String outName)
	{
		outName.Append(name);
		if (!outName.IsEmpty)
			outName[0] = outName[0].ToUpper;
	}

	/// Writes `value` into `slot` as `type` declares it, a number fitted to its width; false when
	/// the value is not one of that type.
	public static bool ToNative(ScriptValue value, Type type, void* slot)
	{
		if (value.IsNumber)
		{
			let number = value.AsNumber;
			if (type == typeof(float))
				*(float*)slot = (float)number;
			else if (type == typeof(double))
				*(double*)slot = number;
			else if (type == typeof(int32))
				*(int32*)slot = (int32)number;
			else if (type == typeof(int64))
				*(int64*)slot = (int64)number;
			else if (type == typeof(int))
				*(int*)slot = (int)number;
			else if (type == typeof(uint32))
				*(uint32*)slot = (uint32)number;
			else
				return false;
			return true;
		}
		switch (value.Kind)
		{
		case .Bool:
			if (type != typeof(bool))
				return false;
			*(bool*)slot = value.AsBool;
		case .String:
			if (type != typeof(StringView))
				return false;
			*(StringView*)slot = value.AsString;
		case .Float2:
			if (type != typeof(Float2))
				return false;
			*(Float2*)slot = value.AsFloat2;
		case .Float3:
			if (type != typeof(Float3))
				return false;
			*(Float3*)slot = value.AsFloat3;
		case .Float4:
			if (type != typeof(Float4))
				return false;
			*(Float4*)slot = value.AsFloat4;
		case .Quaternion:
			if (type != typeof(Quaternion))
				return false;
			*(Quaternion*)slot = value.AsQuaternion;
		case .Color:
			if (type != typeof(Color))
				return false;
			*(Color*)slot = value.AsColor;
		case .Guid:
			if (type != typeof(Guid))
				return false;
			*(Guid*)slot = value.AsGuid;
		case .Entity:
			if (type != typeof(EntityHandle))
				return false;
			*(EntityHandle*)slot = value.AsEntity;
		default:
			return false;
		}
		return true;
	}

	/// The value of `type` at `data` as the layer's; false for a type a behavior's property cannot
	/// be. Text is borrowed from the object.
	public static bool FromNative(Type type, void* data, ref ScriptValue value)
	{
		if (type == typeof(float))
			value = .FromFloat(*(float*)data);
		else if (type == typeof(double))
			value = .FromFloat(*(double*)data);
		else if (type == typeof(int32))
			value = .FromInt(*(int32*)data);
		else if (type == typeof(int64))
			value = .FromInt(*(int64*)data);
		else if (type == typeof(int))
			value = .FromInt(*(int*)data);
		else if (type == typeof(uint32))
			value = .FromInt(*(uint32*)data);
		else if (type == typeof(bool))
			value = .FromBool(*(bool*)data);
		else if (type == typeof(String))
		{
			let text = *(String*)data;
			value = .FromString((text != null) ? text : "");
		}
		else if (type == typeof(Float2))
			value = .FromFloat2(*(Float2*)data);
		else if (type == typeof(Float3))
			value = .FromFloat3(*(Float3*)data);
		else if (type == typeof(Float4))
			value = .FromFloat4(*(Float4*)data);
		else if (type == typeof(Quaternion))
			value = .FromQuaternion(*(Quaternion*)data);
		else if (type == typeof(Color))
			value = .FromColor(*(Color*)data);
		else if (type == typeof(Guid))
			value = .FromGuid(*(Guid*)data);
		else if (type == typeof(EntityHandle))
			value = .FromEntity(*(EntityHandle*)data);
		else
			return false;
		return true;
	}
}
