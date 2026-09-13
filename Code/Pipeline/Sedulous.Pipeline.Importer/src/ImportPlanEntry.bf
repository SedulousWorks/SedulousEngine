using System;
using Sedulous.Core.Serialization;

namespace Sedulous.Pipeline.Importer;

/// One resource an import WOULD create.
class ImportPlanEntry : ISerializable
{
	public ImportResourceKind Kind = .Texture;

	/// The importer's deterministic base name for the resource, which is the stable key a
	/// commit matches on.
	public String SourceName = new .() ~ delete _;

	/// What the user wants it called, defaulting to the source name.
	public String TargetName = new .() ~ delete _;

	/// An unchecked entry is skipped.
	public bool Enabled = true;

	public this() {}

	public this(ImportResourceKind kind, StringView sourceName, StringView targetName)
	{
		Kind = kind;
		SourceName.Set(sourceName);
		TargetName.Set(targetName);
	}

	public void Serialize(ISerializer ar)
	{
		ar.Key("kind");
		SerializeEnum(ar, ref Kind);
		// QUALIFIED: the member method of the same name shadows the whole free overload set.
		Sedulous.Core.Serialization.Serialize(ar, "sourceName", SourceName);
		Sedulous.Core.Serialization.Serialize(ar, "targetName", TargetName);
		SerializeValue(ar, "enabled", ref Enabled);
	}
}
