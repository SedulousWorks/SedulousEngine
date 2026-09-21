using System;

namespace Sedulous.Editor.Core;

/// A content instance's type name is the asset type's FULL name
/// ("Sedulous.Geometry.Pipeline.StaticMeshAsset"); the editor's filters, icons and thumbnail
/// generators name asset types by their SHORT name ("StaticMeshAsset"). These bridge the
/// two.
static class AssetTypeNames
{
	/// The segment after the last dot, or the whole name when it has none.
	public static StringView Short(StringView typeName)
	{
		let dot = typeName.LastIndexOf('.');
		return (dot >= 0) ? typeName.Substring(dot + 1) : typeName;
	}

	/// Whether an instance's type name names `wanted`, given as its full or its short name.
	public static bool Matches(StringView instanceTypeName, StringView wanted)
		=> (instanceTypeName == wanted) || (Short(instanceTypeName) == wanted);
}
