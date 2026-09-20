using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Resource;
using Sedulous.Scene;
using Sedulous.Geometry;
using Sedulous.Materials;
using Sedulous.Animation;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Scene;

/// A skeleton's bind pose as a mesh of bone octahedra, one per parented bone.
class SkeletonThumbnailGenerator : ISceneThumbnailGenerator
{
	private ThumbnailStageEntities mEntities = new .() ~ delete _;
	private Proxy<Skeleton> mProxy = default;
	private List<Float4x4> mWorld = new .() ~ delete _;
	private StaticMesh mMesh = null ~ delete _;
	private Material mMaterial = null ~ delete _;

	public void AssetTypeNames(List<StringView> outNames) => outNames.Add("SkeletonAsset");

	public bool NeedsPrivateScene => false;

	public ThumbnailStageStep Stage(Guid id, Sedulous.Scene.Scene stage, ResourceManager resources,
		ref ThumbnailFraming outFraming)
	{
		let component = mEntities.Ensure(stage, "ThumbSkeleton");
		if (component == null)
			return .Failed;
		mProxy = resources.Bind<Skeleton>(id);
		let skeleton = mProxy.Get;
		if (skeleton == null)
			return ThumbnailStaging.StepForPending(mProxy);
		let boneCount = skeleton.BoneCount;
		if (boneCount <= 0)
			return .Failed;
		mWorld.Count = boneCount;
		skeleton.ComputeWorldPoses(default, mWorld); // empty is the bind pose

		// (head, tip) pairs, one per bone with a parent.
		let segments = scope List<Float3>();
		for (int32 b < boneCount)
		{
			let bone = skeleton.GetBone(b);
			if ((bone == null) || (bone.ParentIndex < 0))
				continue;
			let head = TranslationOf(mWorld[bone.ParentIndex]);
			let tip = TranslationOf(mWorld[b]);
			if (Length(tip - head) >= 0.0005f)
			{
				segments.Add(head);
				segments.Add(tip);
			}
		}
		if (segments.IsEmpty)
		{
			// A single root: a stub so the thumbnail is not blank.
			segments.Add(TranslationOf(mWorld[0]) - Float3(0, 0.05f, 0));
			segments.Add(TranslationOf(mWorld[0]) + Float3(0, 0.05f, 0));
		}

		if (mMesh == null)
			mMesh = new StaticMesh();
		mMesh.ClearForReload();
		let indexCount = (uint32)(segments.Count / 2) * 24;
		mMesh.Vertices.Reserve((int)indexCount);
		mMesh.Indices.Resize(indexCount);
		for (int i = 0; i + 1 < segments.Count; i += 2)
			AppendBoneOctahedron(mMesh, segments[i], segments[i + 1]);
		mMesh.GenerateNormals();
		mMesh.GenerateTangents();
		mMesh.CalculateBounds();
		mMesh.SubMeshes.Add(.(0, (int32)mMesh.IndexCount, 0, .Triangles));

		component.Mesh.SetId(.());
		component.Mesh.SetDirect(mMesh);
		if (mMaterial == null)
			mMaterial = MaterialPresets.CreatePbr("ThumbSkeletonDefault");
		component.SetMaterial(mMaterial);

		var t = Transform();
		t.Position = Float3.Zero - mMesh.Bounds.Center();
		stage.SetLocalTransform(mEntities.Display, t);
		outFraming.Radius = Max(Length(mMesh.Bounds.Extents()), 0.05f);
		return .Ready;
	}

	public void Unstage(Sedulous.Scene.Scene stage)
	{
		ThumbnailStaging.ClearDisplayMesh(stage, mEntities.Display);
		mProxy = default;
		mEntities.Deactivate(stage);
	}

	private static Float3 TranslationOf(Float4x4 world) => .(world.M[3][0], world.M[3][1], world.M[3][2]);

	/// Eight facets: a short cap toward the parent joint, a long one toward the child.
	private static bool AppendBoneOctahedron(StaticMesh mesh, Float3 head, Float3 tip)
	{
		let axis = tip - head;
		let length = Length(axis);
		if (length < 0.0005f)
			return false;
		let direction = axis * (1.0f / length);
		let up = (Abs(direction.Y) < 0.95f) ? Float3(0, 1, 0) : Float3(1, 0, 0);
		let side = Normalized(Cross(direction, up));
		let binormal = Cross(direction, side);
		let radius = Clamp(length * 0.12f, 0.002f, 0.08f);
		let girdleCenter = head + axis * 0.2f;
		let girdle = scope Float3[](
			girdleCenter + side * radius, girdleCenter + binormal * radius,
			girdleCenter - side * radius, girdleCenter - binormal * radius);
		for (int i < 4)
		{
			let a = girdle[i];
			let b = girdle[(i + 1) % 4];
			EmitTriangle(mesh, head, b, a);
			EmitTriangle(mesh, tip, a, b);
		}
		return true;
	}

	private static void EmitTriangle(StaticMesh mesh, Float3 a, Float3 b, Float3 c)
	{
		let first = mesh.VertexCount;
		for (let p in scope Float3[](a, b, c))
		{
			var vertex = StaticMeshVertex();
			vertex.Position = p;
			vertex.Normal = .(0, 1, 0);
			vertex.TexCoord = .(0, 0);
			vertex.Color = 0xFFFFFFFF;
			vertex.Tangent = .(1, 0, 0, 1);
			mesh.Vertices.Add(vertex);
		}
		mesh.Indices.AddTriangle(first, first + 1, first + 2);
	}
}
