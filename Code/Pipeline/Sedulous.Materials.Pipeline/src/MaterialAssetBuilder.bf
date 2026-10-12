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
		MaterialShaderLayout.LayOut(material.Source, shader, product);
		return context.Output.WriteObject(product);
	}
}

/// A material laid out by a custom shader's property table, and a material's values carried onto
/// another layout of it. The cook lays a material out so; the editor previews one so and keeps its
/// values when it moves to another shader.
static class MaterialShaderLayout
{
	/// A material on a custom shader, laid out by the shader's property table: each property in the
	/// shader's order and at its offset, at the shader's default, then the authored material's
	/// values carried over (CarryValues).
	public static void LayOut(MaterialSource authored, ShaderSource shader, MaterialSource outProduct)
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
			outProduct.PropertyNames.Add(new String(property.Name));
			outProduct.PropertyTypes.Add((uint8)MaterialTypeOf(property.Type));
			outProduct.PropertyBindings.Add((uint32)i);
			outProduct.PropertyOffsets.Add(property.Offset);
			outProduct.PropertySizes.Add(property.Size);
			if (property.Size != 0)
				WriteDefault(property, &outProduct.UniformDefaults[(int)property.Offset]);
		}
		CarryValues(authored, outProduct);
	}

	/// Carries a material's values onto another layout of it (`to`: its properties, offsets and
	/// defaults in place, no texture bound): each uniform whose name, type and size match keeps its
	/// value, each texture binding whose slot `to` still has as a texture keeps its texture, and the
	/// rest of `to` keeps its defaults. What does not carry is dropped with a warning.
	public static void CarryValues(MaterialSource from, MaterialSource to)
	{
		ClearAndDeleteItems!(to.TextureSlots);
		to.TextureIds.Clear();
		for (int i < to.PropertyNames.Count)
		{
			let name = to.PropertyNames[i];
			let type = (i < to.PropertyTypes.Count) ? to.PropertyTypes[i] : 0;
			let size = (i < to.PropertySizes.Count) ? to.PropertySizes[i] : 0;
			if (size == 0)
			{
				let kind = (MaterialPropertyType)type;
				let slot = IndexOf(from.TextureSlots, name);
				if (((kind == .Texture2D) || (kind == .TextureCube)) && (slot >= 0) && (slot < from.TextureIds.Count))
				{
					to.TextureSlots.Add(new String(name));
					to.TextureIds.Add(from.TextureIds[slot]);
				}
				continue;
			}
			let index = IndexOf(from.PropertyNames, name);
			if (index < 0)
				continue;
			let sameKind = (index < from.PropertyTypes.Count) && (index < from.PropertyOffsets.Count)
				&& (index < from.PropertySizes.Count) && (from.PropertyTypes[index] == type) && (from.PropertySizes[index] == size);
			let at = (i < to.PropertyOffsets.Count) ? (int)to.PropertyOffsets[i] : 0;
			if (sameKind && ((int)(from.PropertyOffsets[index] + size) <= from.UniformDefaults.Count)
				&& (at + (int)size <= to.UniformDefaults.Count))
				Internal.MemCpy(&to.UniformDefaults[at], &from.UniformDefaults[(int)from.PropertyOffsets[index]], size);
		}

		for (let name in from.PropertyNames)
		{
			if (IndexOf(to.PropertyNames, name) < 0)
				GlobalLog(.Warning, "Materials: material '{}': '{}' is not a property of shader '{}' - dropped", from.Name, name, to.ShaderName);
		}
		for (let slot in from.TextureSlots)
		{
			if (IndexOf(to.TextureSlots, slot) < 0)
				GlobalLog(.Warning, "Materials: material '{}': shader '{}' has no texture '{}' - its binding is dropped", from.Name, to.ShaderName, slot);
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
