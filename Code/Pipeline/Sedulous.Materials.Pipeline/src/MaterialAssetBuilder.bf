using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Materials.Resource;
using Sedulous.Pipeline.Core;
using Sedulous.Shaders;
using Sedulous.Shaders.Resource;

namespace Sedulous.Materials.Pipeline;

/// Cooks the authored material into its product. A material on a built-in shader (a nil shader
/// id) is its authored source; one on a custom shader is laid out by that shader's cooked
/// property table, so it always matches what the shader reads.
class MaterialAssetBuilder : IAssetBuilder
{
	public Type AssetType => typeof(MaterialAsset);
	public Type ProductType => typeof(MaterialSource);

	/// Two: the property arrays carry full names now, and the reader REFUSES a product cooked
	/// under the older record version, so the recipe hash has to change to re-cook it. Three: a
	/// material on a custom shader is laid out by the shader's property table.
	public int32 Version => 3;

	/// A bound texture is a runtime REFERENCE: its product has to exist, but editing the
	/// texture never re-cooks the material, since the factory re-binds when it loads. A custom
	/// shader is READ: its property table lays the product out, so a shader edit (a property
	/// added, removed or retyped) re-cooks the material.
	public void ScanDependencies(Asset asset, AssetBuildContext context, AssetDependencies outDeps)
	{
		let material = (MaterialAsset)asset;
		for (let id in material.Source.TextureIds)
		{
			if (id != Guid())
				outDeps.References.Add(id);
		}
		if (material.Source.ShaderId != Guid())
			outDeps.Reads.Add(material.Source.ShaderId);
	}

	public Result<void, ErrorCode> Build(Asset asset, AssetBuildContext context)
	{
		if (context.Output == null)
			return .Err(.InvalidArgument);

		let material = (MaterialAsset)asset;
		// A built-in shader: the authored source is the runtime source.
		if (material.Source.ShaderId == Guid())
			return context.Output.WriteObject(material.Source);

		// A custom shader: its cooked property table is the layout, the asset the values.
		let instance = (context.Database != null) ? context.Database.GetInstance(material.Source.ShaderId) : null;
		let object = (instance != null) ? instance.ReadObject() : null;
		defer { if (object != null) delete object; }
		let shader = (object != null) ? Internal.UnsafeCastToObject(Internal.UnsafeCastToPtr(object)) as ShaderSource : null;
		if (shader == null)
		{
			GlobalLog(.Error, "Materials: material '{}': its shader has not cooked - cook failed", material.Source.Name);
			return .Err(.NotFound);
		}
		let product = scope MaterialSource();
		LayOutByShader(material.Source, shader, product);
		return context.Output.WriteObject(product);
	}

	/// A material on a custom shader, laid out by the shader's property table: each property in
	/// the shader's order and at its offset, its value taken from the authored material by name
	/// where the type and size match, else the shader's default. An authored value the shader no
	/// longer declares is dropped with a warning; so is a texture binding to a slot it lacks.
	public static void LayOutByShader(MaterialSource authored, ShaderSource shader, MaterialSource outProduct)
	{
		// Name, shader reference, render state and samplers come from the authored material.
		outProduct.Name.Set(authored.Name);
		outProduct.ShaderId = authored.ShaderId;
		outProduct.ShaderName.Set(shader.Name);
		outProduct.ShaderFlags = authored.ShaderFlags;
		outProduct.BlendMode = authored.BlendMode;
		outProduct.DepthMode = authored.DepthMode;
		outProduct.CullMode = authored.CullMode;
		outProduct.VertexLayout = authored.VertexLayout;
		outProduct.SamplerU = authored.SamplerU;
		outProduct.SamplerV = authored.SamplerV;
		ClearAndDeleteItems!(outProduct.PropertyNames);
		outProduct.PropertyTypes.Clear();
		outProduct.PropertyBindings.Clear();
		outProduct.PropertyOffsets.Clear();
		outProduct.PropertySizes.Clear();
		ClearAndDeleteItems!(outProduct.TextureSlots);
		outProduct.TextureIds.Clear();
		outProduct.UniformDefaults.Clear();
		outProduct.UniformDefaults.Resize((int)shader.UniformSize);
		for (var b in ref outProduct.UniformDefaults)
			b = 0;

		let table = scope List<ShaderProperty>();
		defer { ClearAndDeleteItems!(table); }
		shader.GetProperties(table);
		for (int i < table.Count)
		{
			let property = table[i];
			let type = MaterialTypeOf(property.Type);
			outProduct.PropertyNames.Add(new String(property.Name));
			outProduct.PropertyTypes.Add((uint8)type);
			outProduct.PropertyBindings.Add((uint32)i);
			outProduct.PropertyOffsets.Add(property.Offset);
			outProduct.PropertySizes.Add(property.Size);

			if (property.Size == 0)
			{
				// A texture keeps its authored binding when the slot is still a texture.
				if (property.Type == .Sampler)
					continue;
				let slot = IndexOf(authored.TextureSlots, property.Name);
				if ((slot >= 0) && (slot < authored.TextureIds.Count))
				{
					outProduct.TextureSlots.Add(new String(property.Name));
					outProduct.TextureIds.Add(authored.TextureIds[slot]);
				}
				continue;
			}
			let authoredIndex = IndexOf(authored.PropertyNames, property.Name);
			let sameKind = (authoredIndex >= 0) && (authoredIndex < authored.PropertyTypes.Count)
				&& (authoredIndex < authored.PropertyOffsets.Count) && (authoredIndex < authored.PropertySizes.Count)
				&& (authored.PropertyTypes[authoredIndex] == (uint8)type) && (authored.PropertySizes[authoredIndex] == property.Size);
			let from = sameKind ? (int)authored.PropertyOffsets[authoredIndex] : 0;
			if (sameKind && (from + (int)property.Size <= authored.UniformDefaults.Count))
			{
				Internal.MemCpy(&outProduct.UniformDefaults[(int)property.Offset], &authored.UniformDefaults[from], property.Size);
				continue;
			}
			WriteDefault(property, &outProduct.UniformDefaults[(int)property.Offset]);
		}

		for (let name in authored.PropertyNames)
		{
			var kept = false;
			for (let property in table)
				kept = kept || (property.Name == name);
			if (!kept)
				GlobalLog(.Warning, "Materials: material '{}': '{}' is not a property of shader '{}' - dropped", authored.Name, name, shader.Name);
		}
		for (let slot in authored.TextureSlots)
		{
			if (IndexOf(outProduct.TextureSlots, slot) < 0)
				GlobalLog(.Warning, "Materials: material '{}': shader '{}' has no texture '{}' - its binding is dropped", authored.Name, shader.Name, slot);
		}
	}

	private static MaterialPropertyType MaterialTypeOf(ShaderPropertyType type)
	{
		switch (type)
		{
		case .Float: return .Float;
		case .Float2: return .Float2;
		case .Float3: return .Float3;
		case .Float4: return .Float4;
		case .Int: return .Int;
		case .Color: return .Color;
		case .ColorHdr: return .ColorHdr;
		case .Texture: return .Texture2D;
		case .TextureCube: return .TextureCube;
		case .Sampler: return .Sampler;
		}
	}

	private static int IndexOf(List<String> names, StringView name)
	{
		for (int i < names.Count)
			if (names[i] == name)
				return i;
		return -1;
	}

	/// The shader's default for a uniform, written as the shader reads it (an int as an int).
	private static void WriteDefault(ShaderProperty property, uint8* at)
	{
		if (property.Type == .Int)
		{
			var value = (int32)property.Value.X;
			Internal.MemCpy(at, &value, sizeof(int32));
			return;
		}
		float[4] values = .(property.Value.X, property.Value.Y, property.Value.Z, property.Value.W);
		Internal.MemCpy(at, &values[0], property.Size);
	}
}
