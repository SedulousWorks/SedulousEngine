using System;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Content;
using Sedulous.Pipeline.Core;

namespace NativeSample.Notes;

/// A note as the editor authors it: a line of text, the reference game's own asset type.
[Serializable]
class NoteAsset : Asset
{
	public String Text = new .("A note from the game's own code") ~ delete _;
}

/// A note as the game reads it, cooked.
[Serializable]
class NoteProduct
{
	public String Text = new .() ~ delete _;
}

/// Cooks a note: its text, as written.
class NoteBuilder : IAssetBuilder
{
	public Type AssetType => typeof(NoteAsset);
	public Type ProductType => typeof(NoteProduct);

	public Result<void, ErrorCode> Build(Asset asset, AssetBuildContext context)
	{
		if (context.Output == null)
			return .Err(.InvalidArgument);
		let product = scope NoteProduct();
		product.Text.Set(((NoteAsset)asset).Text);
		return context.Output.WriteObject(product);
	}
}

/// The note types' registration, which the Pipeline part's load runs (recorded and reversed).
[SerializableRegistry]
static class NoteTypes
{
}

static class Notes
{
	/// The creator's label, as File > New and asset_create name it.
	public const String cCreator = "Native Sample Note";

	/// The note type's name as instances record it.
	public static void TypeName(String outName) => typeof(NoteAsset).GetFullName(outName);

	/// Every note under `group`, its subgroups included.
	public static void ForEach(Group group, delegate void(Instance note) visit)
	{
		let typeName = TypeName(.. scope .());
		for (let instance in group.Instances)
		{
			if (instance.TypeName == typeName)
				visit(instance);
		}
		for (let child in group.Groups)
			ForEach(child, visit);
	}
}
