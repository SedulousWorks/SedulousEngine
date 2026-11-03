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

	/// The part's own settings (a clip's root motion), a reflected object its importer made
	/// (IFileImporter.PartSettings), shared with the plan's copies; null while nobody asked, the
	/// part then importing as it would have. Not stored with a previous import's selection: the
	/// part's asset holds them.
	private RefCounted mSettings ~ _?.ReleaseRef();

	public RefCounted Settings => mSettings;

	/// Shares `settings` (null: none), letting go of what the entry had.
	public void SetSettings(RefCounted settings)
	{
		settings?.AddRef();
		mSettings?.ReleaseRef();
		mSettings = settings;
	}

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
