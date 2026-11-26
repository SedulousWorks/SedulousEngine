using System;
using System.Reflection;

namespace Sedulous.Script;

/// Marks a class written in native code as a behavior the run host can make: reflected, so the
/// host makes it by its full name and calls its handlers and properties by the names scripts use,
/// and its cook reads what it declares; and always built in, though nothing names it in code. The
/// class derives from RunBehavior, SceneBehavior or EntityBehavior and has a constructor taking
/// nothing.
[AttributeUsage(.Class, .ReflectAttribute | .AlwaysIncludeTarget, ReflectUser = .Type | .Methods | .NonStaticFields | .DefaultConstructor, AlwaysIncludeUser = .AssumeInstantiated | .IncludeAllMethods)]
struct NativeBehaviorAttribute : Attribute
{
}

/// Makes a field of a native behavior one of its properties: what the inspector shows and an
/// entity or a scene overrides, by the field's name with its first letter lowered (`Worth` is
/// `worth`). A field without it is never written from outside. Its type is a number, a bool, a
/// String, a Color, a Float3, an EntityHandle, or a Guid naming an asset of the type it gives
/// (`[BehaviorProperty("AudioClip")]`). What the inspector says of it is the field's Description.
/// Given as constructor arguments: reflection rebuilds an attribute from those alone.
[AttributeUsage(.Field, .ReflectAttribute)]
struct BehaviorPropertyAttribute : Attribute
{
	/// The asset type a Guid property names ("AudioClip"); empty for any other property.
	public String AssetType;
	/// Sent from a networked game's host to its clients.
	public bool Replicated;

	public this(String assetType = "", bool replicated = false)
	{
		AssetType = assetType;
		Replicated = replicated;
	}
}

/// What the engine and the cook share of native behaviors: the language their classes record,
/// how a class is found by its full name, and how its kind and its members' names are read.
static class NativeBehaviorTypes
{
	/// The language a native class's BehaviorClass records.
	public const String cLanguage = "native";
	/// The namespace of the engine's native bases, whose names are the kinds' base types'
	/// (RunBehavior, SceneBehavior, EntityBehavior): how a native class's kind is read.
	public const String cBasesNamespace = "Sedulous.Engine.Behavior";

	/// The class marked NativeBehavior whose full name is `fullName` ("NativeSample.Orb"); null
	/// when none is built in.
	public static Type FindClass(StringView fullName)
	{
		let name = scope String();
		for (let type in Type.Types)
		{
			if (!IsNativeBehavior(type))
				continue;
			name.Clear();
			type.GetFullName(name);
			if (name == fullName)
				return type;
		}
		return null;
	}

	/// Whether `type` is a class marked NativeBehavior.
	public static bool IsNativeBehavior(Type type) => type.IsObject && (type.GetCustomAttribute<NativeBehaviorAttribute>() case .Ok);

	/// The kind `type` is, read from its base chain (the engine's bases are named for the kinds in
	/// cBasesNamespace); None when it derives from none of them.
	public static BehaviorKind KindOf(Type type)
	{
		let name = scope String();
		for (var t = type; t != null; t = t.BaseType)
		{
			name.Clear();
			t.GetFullName(name);
			// "Sedulous.Engine.Behavior.EntityBehavior": the bases' namespace, then the kind's name.
			if (!name.StartsWith(cBasesNamespace) || (name.Length <= cBasesNamespace.Length) || (name[cBasesNamespace.Length] != '.'))
				continue;
			let kind = BehaviorKinds.FromTypeName(StringView(name, cBasesNamespace.Length + 1));
			if (kind != .None)
				return kind;
		}
		return .None;
	}

	/// A script's name as a native member's: its first letter raised (`onPing` is `OnPing`, `worth`
	/// is `Worth`).
	public static void MemberName(StringView scriptName, String outName)
	{
		outName.Append(scriptName);
		if (!outName.IsEmpty)
			outName[0] = outName[0].ToUpper;
	}

	/// A native member's name as a script's: its first letter lowered (`OnPing` is `onPing`).
	public static void ScriptName(StringView memberName, String outName)
	{
		outName.Append(memberName);
		if (!outName.IsEmpty)
			outName[0] = outName[0].ToLower;
	}

	/// Whether a native method's name is a handler's: `On` and a capital (`OnHit`).
	public static bool IsHandlerName(StringView memberName) => (memberName.Length > 2) && memberName.StartsWith("On") && memberName[2].IsUpper;
}
