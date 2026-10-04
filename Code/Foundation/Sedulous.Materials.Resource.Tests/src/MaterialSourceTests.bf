using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Materials;
using Sedulous.Materials.Resource;
using Sedulous.RHI;

namespace Sedulous.Materials.Resource.Tests;

/// The authored record: capturing a built material into one, and getting it back.
class MaterialSourceTests
{
	private static void RoundTrip(MaterialSource source, MaterialSource outLoaded)
	{
		ISerializable writable = source;
		let buffer = scope MemoryStream();
		{
			let writer = scope BinarySerializer(buffer, .Write);
			writable.Serialize(writer);
			Test.Assert(writer.IsOk);
		}
		buffer.Seek(0, .Begin);

		ISerializable readable = outLoaded;
		let reader = scope BinarySerializer(buffer, .Read);
		readable.Serialize(reader);
		Test.Assert(reader.IsOk);
	}

	[Test]
	public static void AMaterialCapturesIntoASourceAndBack()
	{
		let material = MaterialPresets.CreatePbr("helmet", .(0.5f, 0.25f, 0.125f, 1), 1.0f, 0.25f);
		defer delete material;
		material.SamplerU = .ClampToEdge;
		material.SamplerV = .MirrorRepeat;

		let shaderId = Guid.Create();
		let source = scope MaterialSource();
		MaterialSource.FromMaterial(material, shaderId, source);

		let loaded = scope MaterialSource();
		RoundTrip(source, loaded);

		Test.Assert(loaded.Name == "helmet");
		Test.Assert(loaded.ShaderId == shaderId);
		Test.Assert(loaded.ShaderName == "forward");
		Test.Assert(loaded.VertexLayout == .Mesh);
		Test.Assert(loaded.SamplerU == (uint8)AddressMode.ClampToEdge);
		Test.Assert(loaded.SamplerV == (uint8)AddressMode.MirrorRepeat);

		Test.Assert(loaded.PropertyNames.Count == material.PropertyCount);
		for (int i = 0; i < material.PropertyCount; i++)
		{
			let declared = material.GetProperty(i);
			Test.Assert(loaded.PropertyNames[i] == declared.Name);
			Test.Assert(loaded.PropertyTypes[i] == (uint8)declared.Type);
			Test.Assert(loaded.PropertyBindings[i] == declared.Binding);
			Test.Assert(loaded.PropertyOffsets[i] == declared.Offset);
			Test.Assert(loaded.PropertySizes[i] == declared.Size);
		}

		Test.Assert(loaded.UniformDefaults.Count == material.DefaultUniformData.Length);
		let baseColor = (float*)loaded.UniformDefaults.Ptr;
		Test.Assert(baseColor[0] == 0.5f, "the authored defaults came through");
	}

	/// The render state enums store as their underlying byte, so the wire is the same
	/// whether they are typed or raw.
	[Test]
	public static void TheRenderStateEnumsRoundTrip()
	{
		let source = scope MaterialSource();
		source.BlendMode = .Additive;
		source.DepthMode = .WriteOnly;
		source.CullMode = .Front;
		source.VertexLayout = .SkinnedMesh;

		let loaded = scope MaterialSource();
		RoundTrip(source, loaded);

		Test.Assert(loaded.BlendMode == .Additive);
		Test.Assert(loaded.DepthMode == .WriteOnly);
		Test.Assert(loaded.CullMode == .Front);
		Test.Assert(loaded.VertexLayout == .SkinnedMesh);
	}

	/// Reading into a REUSED source must neither accumulate nor leak, which is the whole
	/// hazard of a record made of lists.
	[Test]
	public static void ReadingIntoAUsedSourceReplacesItsLists()
	{
		let material = MaterialPresets.CreateUnlit("m");
		defer delete material;

		let source = scope MaterialSource();
		MaterialSource.FromMaterial(material, .(), source);

		let reused = scope MaterialSource();
		reused.PropertyNames.Add(new String("stale"));
		reused.TextureSlots.Add(new String("stale"));
		reused.PropertyTypes.Add(99);

		RoundTrip(source, reused);

		Test.Assert(reused.PropertyNames.Count == material.PropertyCount);
		Test.Assert(reused.PropertyNames[0] == "BaseColor", "the stale entry is gone");
		Test.Assert(reused.TextureSlots.IsEmpty);
		Test.Assert(reused.PropertyTypes.Count == material.PropertyCount);
	}

	/// The texture slots are what make a cooked material self contained: without them only
	/// a model spawn wired textures, so a directly referenced material rendered untextured.
	[Test]
	public static void TheTextureSlotsRoundTrip()
	{
		let first = Guid.Create();
		let second = Guid.Create();

		let source = scope MaterialSource();
		source.TextureSlots.Add(new String("AlbedoMap"));
		source.TextureIds.Add(first);
		source.TextureSlots.Add(new String("NormalMap"));
		source.TextureIds.Add(second);

		let loaded = scope MaterialSource();
		RoundTrip(source, loaded);

		Test.Assert(loaded.TextureSlots.Count == 2);
		Test.Assert(loaded.TextureSlots[0] == "AlbedoMap");
		Test.Assert(loaded.TextureIds[0] == first);
		Test.Assert(loaded.TextureSlots[1] == "NormalMap");
		Test.Assert(loaded.TextureIds[1] == second);
	}

	[Test]
	public static void TheSourceTypeRegisters()
	{
		let registry = scope SerializableRegistry();
		MaterialResources.RegisterAll(registry);

		Test.Assert(registry.IsRegistered(MaterialSource.TypeId));
		Test.Assert(registry.IsRegistered(TypeIdOf("Sedulous.Materials.Resource.MaterialSource")),
			"registered under the name an instance stores");

		let created = registry.Create(MaterialSource.TypeId);
		defer delete created;
		Test.Assert(created is MaterialSource);
	}

	/// The cooked record carries an EXPLICIT data version.
	[Test]
	public static void TheCookedRecordIsVersioned()
	{
		Test.Assert(MaterialSource.DataVersion == 3);
	}


	/// A material stored before colour properties existed declared its colours as Float4: read
	/// back, they take the colour types its builtin shader's template declares, and nothing
	/// else changes.
	[Test]
	public static void AStoredFloat4ColourReadsAsTheTemplatesColourType()
	{
		let pbr = MaterialPresets.CreatePbr("old");
		defer delete pbr;
		let source = scope MaterialSource();
		MaterialSource.FromMaterial(pbr, .(), source);
		int baseColor = -1, emissive = -1, metallic = -1;
		for (int i < source.PropertyNames.Count)
		{
			if (source.PropertyNames[i] == "BaseColor") baseColor = i;
			if (source.PropertyNames[i] == "EmissiveColor") emissive = i;
			if (source.PropertyNames[i] == "Metallic") metallic = i;
			let type = (MaterialPropertyType)source.PropertyTypes[i];
			if ((type == .Color) || (type == .ColorHdr))
				source.PropertyTypes[i] = (uint8)MaterialPropertyType.Float4; // as it was stored
		}
		let offsets = scope List<uint32>()..AddRange(source.PropertyOffsets);

		let loaded = scope MaterialSource();
		RoundTrip(source, loaded);
		Test.Assert(loaded.PropertyTypes[baseColor] == (uint8)MaterialPropertyType.Color);
		Test.Assert(loaded.PropertyTypes[emissive] == (uint8)MaterialPropertyType.ColorHdr);
		Test.Assert(loaded.PropertyTypes[metallic] == (uint8)MaterialPropertyType.Float);
		Test.Assert(loaded.PropertyOffsets.Count == offsets.Count);
		for (int i < offsets.Count)
			Test.Assert(loaded.PropertyOffsets[i] == offsets[i], "no offset moves");

		// Idempotent; and a custom shader's Float4 is left as it is.
		loaded.AdoptTemplateColorTypes();
		Test.Assert(loaded.PropertyTypes[baseColor] == (uint8)MaterialPropertyType.Color);
		source.ShaderName.Set("my_custom_shader");
		source.AdoptTemplateColorTypes();
		Test.Assert(source.PropertyTypes[baseColor] == (uint8)MaterialPropertyType.Float4);
	}
}
