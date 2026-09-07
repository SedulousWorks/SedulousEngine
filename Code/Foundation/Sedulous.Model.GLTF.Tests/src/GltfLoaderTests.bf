using System;
using System.Collections;
using System.IO;
using Sedulous.Core;
using Sedulous.Model;
using Sedulous.Model.IO;
using Sedulous.Model.GLTF;

namespace Sedulous.Model.GLTF.Tests;

/// One document exercised from several angles: node transforms in both spellings, several
/// primitives merged into one mesh, a primitive with no indices, missing attributes filled
/// with defaults, sampler defaulting, and animation channels.
///
/// The buffer is a base64 data URI, so the whole fixture is this one file and no binary
/// sits beside it going stale.
class GltfLoaderTests
{
	private static bool Near(float a, float b, float tolerance = 0.001f) => Abs(a - b) <= tolerance;

	/// glTF is column major for column vectors; the engine is row major for row vectors.
	/// The two nodes below describe the SAME transform, one as a matrix and one as a TRS
	/// triple, so any convention slip makes them disagree.
	private const String cDocument = """
{"asset":{"version":"2.0"},"scene":0,"scenes":[{"nodes":[0,1,2]}],"buffers":[{"byteLength":144,"uri":"data:application/octet-stream;base64,AAAAAAAAAAAAAAAAAACAPwAAAAAAAAAAAAAAAAAAgD8AAAAAAAABAAIAAAAAAABAAAAAAAAAAAAAAEBAAAAAAAAAAAAAAABAAACAPwAAAAAAAAEAAgAAAAAAAAAAAMA/AAAAAAAAAAAAAAAAAAAAAAAAoEAAAAAAAAAAAAAAAAAAAIA/AAAAAAAAAAAAAIA/"}],"bufferViews":[{"buffer":0,"byteOffset":0,"byteLength":36},{"buffer":0,"byteOffset":36,"byteLength":6},{"buffer":0,"byteOffset":44,"byteLength":36},{"buffer":0,"byteOffset":80,"byteLength":6},{"buffer":0,"byteOffset":88,"byteLength":8},{"buffer":0,"byteOffset":96,"byteLength":24},{"buffer":0,"byteOffset":120,"byteLength":24}],"accessors":[{"bufferView":0,"componentType":5126,"count":3,"type":"VEC3","min":[0,0,0],"max":[1,1,0]},{"bufferView":1,"componentType":5123,"count":3,"type":"SCALAR"},{"bufferView":2,"componentType":5126,"count":3,"type":"VEC3","min":[2,0,0],"max":[3,1,0]},{"bufferView":3,"componentType":5123,"count":3,"type":"SCALAR"},{"bufferView":4,"componentType":5126,"count":2,"type":"SCALAR","min":[0.0],"max":[1.5]},{"bufferView":5,"componentType":5126,"count":2,"type":"VEC3","min":[0,0,0],"max":[0,5,0]},{"bufferView":6,"componentType":5126,"count":3,"type":"VEC2","min":[0,0],"max":[1,1]}],"materials":[{"name":"cutout","alphaMode":"MASK","alphaCutoff":0.25,"doubleSided":true,"pbrMetallicRoughness":{"baseColorFactor":[0.5,0.25,0.125,1.0],"metallicFactor":0.75,"roughnessFactor":0.4,"baseColorTexture":{"index":0}},"emissiveFactor":[1.0,0.5,0.0],"normalTexture":{"index":1,"scale":0.5},"occlusionTexture":{"index":1,"strength":0.25}},{"name":"plain"}],"images":[{"uri":"missing-on-purpose.png"}],"samplers":[{"wrapS":33071,"wrapT":33648,"minFilter":9728,"magFilter":9728}],"textures":[{"name":"noSampler","source":0},{"name":"clamped","source":0,"sampler":0}],"meshes":[{"name":"merged","primitives":[{"attributes":{"POSITION":0},"indices":1,"material":0},{"attributes":{"POSITION":2},"indices":3,"material":1}]},{"name":"nonIndexed","primitives":[{"attributes":{"POSITION":0}}]},{"name":"textured","primitives":[{"attributes":{"POSITION":0,"TEXCOORD_0":6},"indices":1}]}],"nodes":[{"name":"viaMatrix","matrix":[2,0,0,0,0,2,0,0,0,0,2,0,10,0,0,1]},{"name":"viaTrs","translation":[10,0,0],"scale":[2,2,2]},{"name":"mergedNode","mesh":0,"children":[3]},{"name":"nonIndexedNode","mesh":1}],"animations":[{"name":"bob","channels":[{"sampler":0,"target":{"node":1,"path":"translation"}}],"samplers":[{"input":4,"output":5,"interpolation":"STEP"}]}]}
""";

	/// Writes the fixture, runs the body, and cleans up afterwards whatever happens.
	private static void WithDocument(StringView name, delegate void(ModelData model) body)
	{
		let path = scope String(name);
		File.WriteAllText(path, cDocument).IgnoreError();
		// A braced defer, because `defer a.B().C()` in Beef evaluates a.B() NOW and only
		// defers the C(): unbraced, the delete would run before the load.
		defer { File.Delete(path).IgnoreError(); }


		let model = scope ModelData();
		let loader = scope GltfLoader();
		Test.Assert(loader.Load(path, model) == .Ok);
		body(model);
	}

	private static ModelBone FindBone(ModelData model, StringView name)
	{
		for (let bone in model.Bones)
		{
			if (bone.Name == name)
				return bone;
		}
		return null;
	}

	private static ModelMesh FindMesh(ModelData model, StringView name)
	{
		for (let mesh in model.Meshes)
		{
			if (mesh.Name == name)
				return mesh;
		}
		return null;
	}

	[Test]
	public static void OnlyGltfAndGlbAreClaimed()
	{
		let loader = scope GltfLoader();
		Test.Assert(loader.SupportsExtension(".gltf"));
		Test.Assert(loader.SupportsExtension(".glb"));
		Test.Assert(loader.SupportsExtension(".GLTF"), "extensions arrive in any case");
		Test.Assert(!loader.SupportsExtension(".fbx"));
		Test.Assert(!loader.SupportsExtension(""));
	}

	[Test]
	public static void AMissingFileIsReportedRatherThanCrashing()
	{
		let model = scope ModelData();
		let loader = scope GltfLoader();
		Test.Assert(loader.Load("no-such-model.gltf", model) == .FileNotFound);
	}

	[Test]
	public static void NonsenseIsAParseErrorNotAnEmptyModel()
	{
		let path = scope String("scratch_gltf_garbage.gltf");
		File.WriteAllText(path, "this is not glTF at all").IgnoreError();


		let model = scope ModelData();
		let loader = scope GltfLoader();
		Test.Assert(loader.Load(path, model) == .ParseError);
	}

	/// A node carrying only a matrix has to populate the translation, rotation and scale
	/// fields too, because that is what every consumer reads. Leaving them at identity puts
	/// the node at the origin, which only shows up on models exported with baked matrices.
	[Test]
	public static void AMatrixNodeAgreesWithTheEquivalentTrsNode()
	{
		WithDocument("scratch_gltf_nodes.gltf", scope (model) =>
		{
			let viaMatrix = FindBone(model, "viaMatrix");
			let viaTrs = FindBone(model, "viaTrs");
			Test.Assert(viaMatrix != null && viaTrs != null);

			Test.Assert(Near(viaMatrix.Translation.X, 10.0f));
			Test.Assert(Near(viaMatrix.Translation.Y, 0.0f));
			Test.Assert(Near(viaMatrix.Translation.Z, 0.0f));
			Test.Assert(Near(viaMatrix.Scale.X, 2.0f));
			Test.Assert(Near(viaMatrix.Scale.Y, 2.0f));
			Test.Assert(Near(viaMatrix.Scale.Z, 2.0f));
			Test.Assert(Near(viaMatrix.Rotation.W, 1.0f), "no rotation");

			for (int r < 4)
			{
				for (int c < 4)
					Test.Assert(Near(viaMatrix.LocalTransform[r, c], viaTrs.LocalTransform[r, c]),
						scope $"element {r},{c} differs");
			}

			// Scaled by two then moved ten along X, in the engine's row vector convention.
			let point = TransformPoint(Float3(1, 0, 0), viaMatrix.LocalTransform);
			Test.Assert(Near(point.X, 12.0f), scope $"got {point.X}");
		});
	}

	[Test]
	public static void ParentsAreResolvedAfterEveryNodeExists()
	{
		WithDocument("scratch_gltf_parents.gltf", scope (model) =>
		{
			let child = FindBone(model, "nonIndexedNode");
			let parent = FindBone(model, "mergedNode");
			Test.Assert((child != null) && (parent != null));
			Test.Assert(child.ParentIndex == parent.Index, "the child points back at its parent");
			Test.Assert(parent.ParentIndex == -1, "and the parent is a root");

			// BuildBoneHierarchy has run, so the parent knows its child too.
			Test.Assert(parent.Children.Length == 1);
			Test.Assert(parent.Children[0] === child);
		});
	}

	[Test]
	public static void ANodesMeshAndSkinAreRecorded()
	{
		WithDocument("scratch_gltf_meshref.gltf", scope (model) =>
		{
			Test.Assert(FindBone(model, "mergedNode").MeshIndex == 0);
			Test.Assert(FindBone(model, "nonIndexedNode").MeshIndex == 1);
			Test.Assert(FindBone(model, "viaTrs").MeshIndex == -1, "a node with no mesh stays unset");
			Test.Assert(FindBone(model, "viaTrs").SkinIndex == -1);
		});
	}

	/// Two primitives become one mesh with two parts sharing a buffer, and the second
	/// primitive's indices are shifted by where its vertices landed.
	[Test]
	public static void PrimitivesAreMergedWithRemappedIndices()
	{
		WithDocument("scratch_gltf_merge.gltf", scope (model) =>
		{
			let mesh = FindMesh(model, "merged");
			Test.Assert(mesh != null);
			Test.Assert(mesh.VertexCount == 6, "three vertices from each primitive");
			Test.Assert(mesh.IndexCount == 6);
			Test.Assert(mesh.Parts.Length == 2);
			Test.Assert(!mesh.Use32BitIndices, "far under the short limit");

			Test.Assert(mesh.Parts[0].IndexStart == 0);
			Test.Assert(mesh.Parts[0].IndexCount == 3);
			Test.Assert(mesh.Parts[0].MaterialIndex == 0);
			Test.Assert(mesh.Parts[1].IndexStart == 3, "the second part starts after the first");
			Test.Assert(mesh.Parts[1].MaterialIndex == 1, "and keeps its own material");

			let indices = (uint16*)mesh.IndexData;
			Test.Assert((indices[0] == 0) && (indices[1] == 1) && (indices[2] == 2));
			Test.Assert((indices[3] == 3) && (indices[4] == 4) && (indices[5] == 5),
				"the second primitive's 0,1,2 shifted by three");

			// The positions of the second primitive really are the second primitive's.
			let stride = mesh.VertexStride;
			let fourth = *(Float3*)(mesh.VertexData + 3 * stride);
			Test.Assert(Near(fourth.X, 2.0f), scope $"got {fourth.X}");
		});
	}

	/// glTF allows geometry with no index accessor. Rendering it here does not, so
	/// sequential indices are generated rather than the primitive being dropped.
	[Test]
	public static void ANonIndexedPrimitiveGetsSequentialIndices()
	{
		WithDocument("scratch_gltf_nonindexed.gltf", scope (model) =>
		{
			let mesh = FindMesh(model, "nonIndexed");
			Test.Assert(mesh != null);
			Test.Assert(mesh.VertexCount == 3);
			Test.Assert(mesh.IndexCount == 3);
			Test.Assert(mesh.Parts.Length == 1);

			let indices = (uint16*)mesh.IndexData;
			Test.Assert((indices[0] == 0) && (indices[1] == 1) && (indices[2] == 2));
		});
	}

	/// Every vertex carries a full slot set whether the file supplies it or not, so one
	/// shader serves every model. The defaults have to be neutral, not zero: a zero normal
	/// lights black and a zero colour multiplies everything away.
	[Test]
	public static void AbsentAttributesGetNeutralDefaults()
	{
		WithDocument("scratch_gltf_defaults.gltf", scope (model) =>
		{
			let mesh = FindMesh(model, "merged");
			Test.Assert(!mesh.HasNormals && !mesh.HasTangents);

			let stride = mesh.VertexStride;
			let normalOffset = mesh.OffsetOf(.Normal);
			let colorOffset = mesh.OffsetOf(.Color);
			let tangentOffset = mesh.OffsetOf(.Tangent);
			Test.Assert((normalOffset >= 0) && (colorOffset >= 0) && (tangentOffset >= 0),
				"the slots exist even unsupplied");

			let normal = *(Float3*)(mesh.VertexData + normalOffset);
			Test.Assert(Near(normal.Y, 1.0f), "up, which at least lights consistently");

			let color = *(uint32*)(mesh.VertexData + colorOffset);
			Test.Assert(color == 0xFFFFFFFF, "opaque white multiplies to a no-op");

			let tangent = *(Float4*)(mesh.VertexData + tangentOffset);
			Test.Assert(Near(tangent.X, 1.0f) && Near(tangent.W, 1.0f));

			// And the vertex is as wide as the elements say, with no skinning slots since
			// nothing in the document is skinned.
			Test.Assert(stride == (int32)(sizeof(Float3) * 2 + sizeof(Float2) + sizeof(uint32) + sizeof(Float4)));
		});
	}

	[Test]
	public static void SuppliedAttributesAreRead()
	{
		WithDocument("scratch_gltf_uv.gltf", scope (model) =>
		{
			let mesh = FindMesh(model, "textured");
			let stride = mesh.VertexStride;
			let uvOffset = mesh.OffsetOf(.TexCoord);

			let first = *(Float2*)(mesh.VertexData + uvOffset);
			let second = *(Float2*)(mesh.VertexData + stride + uvOffset);
			Test.Assert(Near(first.X, 0.0f) && Near(first.Y, 0.0f));
			Test.Assert(Near(second.X, 1.0f) && Near(second.Y, 0.0f));
		});
	}

	[Test]
	public static void MaterialFactorsAndTextureIndicesSurvive()
	{
		WithDocument("scratch_gltf_materials.gltf", scope (model) =>
		{
			Test.Assert(model.Materials.Length == 2);
			let cutout = model.Materials[0];

			Test.Assert(cutout.Name == "cutout");
			Test.Assert(Near(cutout.BaseColorFactor.X, 0.5f));
			Test.Assert(Near(cutout.BaseColorFactor.W, 1.0f));
			Test.Assert(Near(cutout.MetallicFactor, 0.75f));
			Test.Assert(Near(cutout.RoughnessFactor, 0.4f));
			Test.Assert(cutout.BaseColorTextureIndex == 0);
			Test.Assert(cutout.NormalTextureIndex == 1);
			Test.Assert(Near(cutout.NormalScale, 0.5f));
			Test.Assert(cutout.OcclusionTextureIndex == 1);
			Test.Assert(Near(cutout.OcclusionStrength, 0.25f), "occlusion strength is the view's scale");
			Test.Assert(Near(cutout.EmissiveFactor.X, 1.0f) && Near(cutout.EmissiveFactor.Y, 0.5f));
			Test.Assert(cutout.AlphaMode == .Mask);
			Test.Assert(Near(cutout.AlphaCutoff, 0.25f));
			Test.Assert(cutout.DoubleSided);

			// A material that says nothing gets the glTF defaults, not zeroes.
			let plain = model.Materials[1];
			Test.Assert(plain.AlphaMode == .Opaque);
			Test.Assert(!plain.DoubleSided);
			Test.Assert(plain.BaseColorTextureIndex == -1);
		});
	}

	/// A texture with no sampler of its own gets the glTF default rather than being left
	/// unset, so no renderer has to invent the policy.
	[Test]
	public static void ATextureWithoutASamplerGetsTheDefault()
	{
		WithDocument("scratch_gltf_samplers.gltf", scope (model) =>
		{
			Test.Assert(model.Textures.Length == 2);
			let noSampler = model.Textures[0];
			let clamped = model.Textures[1];

			Test.Assert(clamped.SamplerIndex == 0, "the one the document declared");
			Test.Assert(model.Samplers[0].WrapS == .ClampToEdge);
			Test.Assert(model.Samplers[0].WrapT == .MirroredRepeat);
			Test.Assert(model.Samplers[0].MagFilter == .Nearest);

			Test.Assert(noSampler.SamplerIndex >= 0, "and one was invented for the other");
			Test.Assert(model.Samplers[noSampler.SamplerIndex].WrapS == .Repeat);
			Test.Assert(model.Samplers[noSampler.SamplerIndex].WrapT == .Repeat);
		});
	}

	/// An image the loader cannot find leaves the texture without pixels rather than
	/// failing the whole load: a model with a missing texture is still a usable model.
	[Test]
	public static void AMissingImageDoesNotFailTheLoad()
	{
		WithDocument("scratch_gltf_missingimage.gltf", scope (model) =>
		{
			let texture = model.Textures[0];
			Test.Assert(texture.Uri == "missing-on-purpose.png");
			Test.Assert(!texture.HasEmbeddedData);
			Test.Assert(texture.PixelFormat == .Unknown);
		});
	}

	[Test]
	public static void AnimationChannelsAndDurationAreRead()
	{
		WithDocument("scratch_gltf_animation.gltf", scope (model) =>
		{
			Test.Assert(model.Animations.Length == 1);
			let animation = model.Animations[0];
			Test.Assert(animation.Name == "bob");
			Test.Assert(animation.ChannelCount == 1);
			Test.Assert(Near(animation.Duration, 1.5f), "the last keyframe time");

			let channel = animation.Channels[0];
			Test.Assert(channel.Path == .Translation);
			Test.Assert(channel.Interpolation == .Step);
			Test.Assert(channel.TargetBone == FindBone(model, "viaTrs").Index);
			Test.Assert(channel.KeyframeCount == 2);

			Test.Assert(Near(channel.Keyframes[0].Time, 0.0f));
			Test.Assert(Near(channel.Keyframes[1].Time, 1.5f));
			Test.Assert(Near(channel.Keyframes[1].Value.Y, 5.0f));
			Test.Assert(Near(channel.Keyframes[1].Value.W, 0.0f),
				"a translation leaves the fourth component alone");

			// Stepped, so a time between keys holds the earlier value rather than blending.
			Test.Assert(Near(channel.Sample(0.75f).Y, 0.0f));
		});
	}

	/// Y up by specification, so it is set rather than guessed at.
	[Test]
	public static void TheUpAxisIsSetFromTheSpecification()
	{
		WithDocument("scratch_gltf_upaxis.gltf", scope (model) =>
		{
			Test.Assert(model.OriginalUpAxis == .PositiveY);
		});
	}

	/// Loading twice through one loader has to free the first document, and must not leave
	/// the second reading through freed accessors.
	[Test]
	public static void ALoaderCanBeReused()
	{
		let path = scope String("scratch_gltf_reuse.gltf");
		File.WriteAllText(path, cDocument).IgnoreError();


		let loader = scope GltfLoader();

		let first = scope ModelData();
		Test.Assert(loader.Load(path, first) == .Ok);
		let second = scope ModelData();
		Test.Assert(loader.Load(path, second) == .Ok);

		Test.Assert(second.Bones.Length == first.Bones.Length);
		Test.Assert(Near(FindBone(second, "viaMatrix").Translation.X, 10.0f));
	}
}
