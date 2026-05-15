namespace Sedulous.Editor.App;

using System;
using System.IO;
using Sedulous.Editor.Core;
using Sedulous.Materials;
using Sedulous.Materials.Resources;
using Sedulous.Resources;
using Sedulous.VFS;

/// Creates a default PBR material asset.
class MaterialAssetCreator : IAssetCreator
{
	public StringView DisplayName => "Material";
	public StringView Category => "Rendering";
	public StringView Extension => ".material";

	public Result<Guid> Create(IWritableMount mount, StringView locator, EditorContext context)
	{
		let provider = context.ResourceSystem?.SerializerProvider;
		if (provider == null)
			return .Err;

		let mat = Materials.CreatePBR("New Material", "forward");
		let res = new MaterialResource(mat, true);
		defer delete res;

		res.Name = "New Material";

		let stream = scope MemoryStream();
		if (res.WriteToStream(stream, provider) case .Err)
			return .Err;
		stream.Position = 0;
		if (mount.Save(locator, stream) case .Err)
			return .Err;

		return .Ok(res.Id);
	}
}
