using System;
using Sedulous.Core;

namespace Sedulous.Script.Resource;

/// The name hashing an override is keyed by. Stable across builds and platforms, since it
/// is written into scene files.
static class ScriptPropertyNames
{
	public static uint64 HashOf(StringView name) => HashText(name);

	/// One authored type name and the kind it means.
	public struct TypeEntry
	{
		public String Name;
		public ScriptPropertyType Kind;

		public this(String name, ScriptPropertyType kind)
		{
			Name = name;
			Kind = kind;
		}
	}

	/// The asset kind is authored as "asset:<TypeName>": this prefix, then the product type name.
	public const String cAssetTypePrefix = "asset:";

	/// Every authored kind, in declaration order (None has no spelling). The one table both
	/// directions read: Parse, and anything that lists the kinds (the scene format reference).
	public static readonly TypeEntry[?] TypeNames = .(
		.("float", .Float), .("int", .Int), .("bool", .Bool), .("string", .String),
		.("color", .Color), .("vec3", .Vec3), .("entity", .Entity), .("asset", .Asset));

	/// The authored spelling of `kind` ("float", "asset" for the prefixed form); empty for None.
	public static StringView TypeName(ScriptPropertyType kind)
	{
		for (let entry in TypeNames)
		{
			if (entry.Kind == kind)
				return entry.Name;
		}
		return "";
	}

	/// The parsed "float" / "asset:AudioClip" type text a script declares a property with,
	/// to its kind and, for an asset, the product type name. False for anything else.
	public static bool Parse(StringView text, out ScriptPropertyType outKind, String outAssetType)
	{
		outAssetType.Clear();
		outKind = .None;
		for (let entry in TypeNames)
		{
			if (entry.Kind == .Asset)
			{
				if (text.StartsWith(cAssetTypePrefix) && (text.Length > cAssetTypePrefix.Length))
				{
					outKind = .Asset;
					outAssetType.Append(text.Substring(cAssetTypePrefix.Length));
					return true;
				}
				continue;
			}
			if (text == entry.Name)
			{
				outKind = entry.Kind;
				return true;
			}
		}
		return false;
	}
}
