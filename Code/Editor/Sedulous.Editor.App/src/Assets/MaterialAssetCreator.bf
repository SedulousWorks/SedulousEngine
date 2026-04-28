namespace Sedulous.Editor.App;

using System;
using System.IO;
using Sedulous.Editor.Core;
using Sedulous.Materials;
using Sedulous.Materials.Resources;
using Sedulous.Resources;

/// Creates a default PBR material asset.
class MaterialAssetCreator : IAssetCreator
{
	public StringView DisplayName => "Material";
	public StringView Category => "Rendering";
	public StringView Extension => ".material";

	public Result<Guid> Create(StringView path, EditorContext context)
	{
		let provider = context.ResourceSystem?.SerializerProvider;
		if (provider == null)
			return .Err;

		let mat = Materials.CreatePBR("New Material", "forward");
		let res = new MaterialResource(mat, true);
		defer delete res;

		res.Name = "New Material";
		if (res.SaveToFile(path, provider) case .Err)
			return .Err;

		return .Ok(res.Id);
	}
}
