using System;
using System.IO;
using System.Collections;
using Sedulous.Core.Mathematics;
using Sedulous.Geometry;
using Sedulous.Models;
using Sedulous.Animation;
using Sedulous.Images;

namespace Sedulous.Geometry.Tooling;

/// Imports models and creates CPU resources.
class ModelImporter
{
	private ModelImportOptions mOptions ~ delete _;
	/// Maps each skin index to the skeleton result index in result.Skeletons.
	/// Duplicate skins map to the same skeleton index as their first occurrence.
	/// -1 means skeleton creation failed for that skin.
	private List<int32> mSkinToSkeletonIdx = new .() ~ delete _;

	/// Create an importer with the given options and image loader.
	/// The importer does NOT take ownership of the image loader.
	public this(ModelImportOptions options)
	{
		mOptions = options;
	}

	/// Import resources from a loaded model.
	/// Order: Preprocess -> Skeletons -> Textures -> Materials -> StaticMeshes -> SkinnedMeshes -> Animations
	/// Textures are imported before materials so materials can reference them by index.
	/// Skeletons are imported before skinned meshes so meshes can reference them by index.
	public ModelImportResult Import(Model model)
	{
		let result = new ModelImportResult();

		if (model == null)
		{
			result.AddError("Model is null");
			return result;
		}

		// 0a. Promote rigid bone attachments to skinned meshes (before skeleton creation)
		PreprocessRigidAttachments(model);

		// 0b. Merge skins that share the same bone hierarchy into one
		MergeRelatedSkins(model);

		// 1. Skeletons first (needed by skinned meshes for SkeletonIndex)
		if (mOptions.Flags.HasFlag(.Skeletons))
		{
			ImportSkeletons(model, result);
		}

		// 2. Textures (needed by materials for texture index references)
		if (mOptions.Flags.HasFlag(.Textures))
		{
			ImportTextures(model, result);
		}

		// 3. Materials (can now reference imported textures by index)
		if (mOptions.Flags.HasFlag(.Materials))
		{
			ImportMaterials(model, result);
		}

		// 4. Static meshes
		if (mOptions.Flags.HasFlag(.Meshes))
		{
			ImportStaticMeshes(model, result);
		}

		// 5. Skinned meshes (reference skeletons via SkeletonIndex)
		if (mOptions.Flags.HasFlag(.SkinnedMeshes))
		{
			ImportSkinnedMeshes(model, result);
		}

		// 6. Standalone animations
		if (mOptions.Flags.HasFlag(.Animations))
		{
			ImportAnimations(model, result);
		}

		return result;
	}

	/// Promotes rigid meshes attached to skeleton bones into skinned meshes.
	/// For each bone with a mesh but no skin, walks up the parent chain to find
	/// the nearest ancestor that belongs to a skin. If found, adds the bone as
	/// a new joint in that skin and gives the mesh uniform bone weighting.
	/// Must be called BEFORE ImportSkeletons so new joints are included naturally.
	private void PreprocessRigidAttachments(Model model)
	{
		for (let bone in model.Bones)
		{
			if (bone.MeshIndex < 0 || bone.SkinIndex >= 0)
				continue; // No mesh, or already skinned

			let mesh = model.Meshes[bone.MeshIndex];

			// Skip if mesh already has joint data
			bool hasJoints = false;
			for (let element in mesh.VertexElements)
			{
				if (element.Semantic == .Joints)
				{
					hasJoints = true;
					break;
				}
			}
			if (hasJoints)
				continue;

			// Walk up parent chain to find nearest ancestor in any skin's joint list
			int32 foundSkinIdx = -1;
			int32 ancestorJointIdx = -1;
			FindAncestorSkinJoint(model, bone.ParentIndex, out foundSkinIdx, out ancestorJointIdx);

			if (foundSkinIdx < 0)
				continue;

			let skin = model.Skins[foundSkinIdx];

			// Add this bone as a new joint in the skin with Identity IBM
			skin.AddJoint(bone.Index, .Identity);
			let newJointIndex = (int32)(skin.Joints.Count - 1);

			// Bake the bone's local scale into vertex positions so the mesh is in
			// the same coordinate space as other skinned meshes (e.g., meters).
			// Without this, rigid attachment vertices may be in different units
			// (e.g., cm) while the skeleton is in meters, causing mismatched bounds.
			let boneScale = bone.Scale;
			if (boneScale.X != 1.0f || boneScale.Y != 1.0f || boneScale.Z != 1.0f)
			{
				mesh.ScalePositions(boneScale);
				bone.Scale = .(1, 1, 1);
				bone.UpdateLocalTransform();
			}

			// Convert the mesh to a skinned mesh with uniform weighting to the new joint
			mesh.AddUniformSkinning(newJointIndex);

			// Mark the bone as belonging to this skin
			bone.SkinIndex = (int32)foundSkinIdx;
		}
	}

	/// Walks up the parent chain from startNodeIdx to find a skin that shares
	/// the same bone hierarchy. Checks if any ancestor is a joint in a skin OR
	/// is an ancestor of any skin's joints (i.e., a common parent node like "Bip001"
	/// that isn't itself weighted but is the root of the skeleton hierarchy).
	private void FindAncestorSkinJoint(Model model, int32 startNodeIdx, out int32 outSkinIdx, out int32 outJointIdx)
	{
		outSkinIdx = -1;
		outJointIdx = -1;

		for (int32 skinIdx = 0; skinIdx < (int32)model.Skins.Count; skinIdx++)
		{
			let skin = model.Skins[skinIdx];

			// Build set of all ancestors of this skin's joints (including the joints themselves)
			let skinTree = scope HashSet<int32>();
			for (let jointNodeIdx in skin.Joints)
			{
				int32 node = jointNodeIdx;
				while (node >= 0 && node < model.Bones.Count)
				{
					if (!skinTree.Add(node))
						break;
					node = model.Bones[node].ParentIndex;
				}
			}

			// Walk up from startNodeIdx and check if any ancestor is in the skin's tree
			int32 current = startNodeIdx;
			while (current >= 0 && current < model.Bones.Count)
			{
				if (skinTree.Contains(current))
				{
					outSkinIdx = skinIdx;
					// Check if the matched node is actually a joint (for logging)
					for (int32 jointIdx = 0; jointIdx < (int32)skin.Joints.Count; jointIdx++)
					{
						if (skin.Joints[jointIdx] == current)
						{
							outJointIdx = jointIdx;
							break;
						}
					}
					return;
				}
				current = model.Bones[current].ParentIndex;
			}
		}
	}

	/// Merges skins that share the same bone hierarchy into the largest skin.
	/// This ensures meshes skinned to different subsets of the same skeleton
	/// (e.g., body + weapon) end up in one SkinnedMesh with one skeleton.
	private void MergeRelatedSkins(Model model)
	{
		if (model.Skins.Count <= 1)
			return;

		// Find the largest skin (by joint count) — this is the merge target
		int32 targetSkinIdx = 0;
		for (int32 i = 1; i < (int32)model.Skins.Count; i++)
		{
			if (model.Skins[i].Joints.Count > model.Skins[targetSkinIdx].Joints.Count)
				targetSkinIdx = i;
		}

		let targetSkin = model.Skins[targetSkinIdx];

		for (int32 skinIdx = 0; skinIdx < (int32)model.Skins.Count; skinIdx++)
		{
			if (skinIdx == targetSkinIdx)
				continue;

			let skin = model.Skins[skinIdx];

			if (!SkinsShareHierarchy(model, skin, targetSkin))
				continue;

			// Build remapping: skin joint index -> targetSkin joint index
			let remap = scope int32[skin.Joints.Count];
			for (int32 j = 0; j < (int32)skin.Joints.Count; j++)
			{
				let boneIdx = skin.Joints[j];

				// Check if this bone is already in targetSkin
				int32 existingIdx = -1;
				for (int32 k = 0; k < (int32)targetSkin.Joints.Count; k++)
				{
					if (targetSkin.Joints[k] == boneIdx)
					{
						existingIdx = k;
						break;
					}
				}

				if (existingIdx >= 0)
				{
					remap[j] = existingIdx;
				}
				else
				{
					targetSkin.AddJoint(boneIdx, skin.InverseBindMatrices[j]);
					remap[j] = (int32)(targetSkin.Joints.Count - 1);
				}
			}

			// Remap mesh joint indices and update bone SkinIndex for all meshes using this skin
			for (let bone in model.Bones)
			{
				if (bone.SkinIndex == skinIdx && bone.MeshIndex >= 0)
				{
					let mesh = model.Meshes[bone.MeshIndex];
					mesh.RemapJointIndices(remap);
					bone.SkinIndex = targetSkinIdx;
				}
			}
		}
	}

	/// Checks if two skins share the same bone hierarchy by walking up
	/// ancestor chains. Returns true if any ancestor of skinA's joints
	/// overlaps with any ancestor of skinB's joints.
	private bool SkinsShareHierarchy(Model model, ModelSkin skinA, ModelSkin skinB)
	{
		// Collect all ancestors of skinB's joints (including the joints themselves)
		let ancestorsB = scope HashSet<int32>();
		for (let jointNodeIdx in skinB.Joints)
		{
			int32 current = jointNodeIdx;
			while (current >= 0 && current < model.Bones.Count)
			{
				if (!ancestorsB.Add(current))
					break;
				current = model.Bones[current].ParentIndex;
			}
		}

		// Check if any of skinA's joints or their ancestors overlap
		for (let jointNodeIdx in skinA.Joints)
		{
			int32 current = jointNodeIdx;
			while (current >= 0 && current < model.Bones.Count)
			{
				if (ancestorsB.Contains(current))
					return true;
				current = model.Bones[current].ParentIndex;
			}
		}

		return false;
	}

	private void ImportSkeletons(Model model, ModelImportResult result)
	{

		mSkinToSkeletonIdx.Clear();

		for (int skinIdx = 0; skinIdx < model.Skins.Count; skinIdx++)
		{
			let skin = model.Skins[skinIdx];

	
			// Check if this skin is a duplicate of an earlier one (same joint node indices)
			int duplicateOf = -1;
			for (int prevIdx = 0; prevIdx < skinIdx; prevIdx++)
			{
				let prevSkin = model.Skins[prevIdx];
				if (prevSkin.Joints.Count == skin.Joints.Count)
				{
					bool same = true;
					for (int j = 0; j < skin.Joints.Count; j++)
					{
						if (skin.Joints[j] != prevSkin.Joints[j])
						{
							same = false;
							break;
						}
					}
					if (same)
					{
						duplicateOf = prevIdx;
						break;
					}
				}
			}

			if (duplicateOf >= 0)
			{
				// Map this skin to the same skeleton as the original
				mSkinToSkeletonIdx.Add(mSkinToSkeletonIdx[duplicateOf]);
					continue;
			}

			let skeleton = SkeletonConverter.CreateFromSkin(model, skin);
			if (skeleton == null)
			{
				mSkinToSkeletonIdx.Add(-1);
				result.AddWarning(scope $"Failed to create skeleton from skin {skinIdx}");
				continue;
			}

			let skeletonResultIdx = (int32)result.Skeletons.Count;
			mSkinToSkeletonIdx.Add(skeletonResultIdx);

				// Generate name
			let name = scope String();
			if (skin.Joints.Count > 0 && skin.Joints[0] >= 0 && skin.Joints[0] < model.Bones.Count)
			{
				name.AppendF("{}_skeleton", model.Bones[skin.Joints[0]].Name);
			}
			else
			{
				name.AppendF("skeleton_{}", skinIdx);
			}
			skeleton.Name.Set(name);

			result.Skeletons.Add(skeleton);
		}
	}

	private void ImportStaticMeshes(Model model, ModelImportResult result)
	{
		// Convert each ModelMesh to a StaticMesh with transform baked in
		let convertedMeshes = scope List<StaticMesh>();
		String firstName = scope .();

		for (int meshIdx = 0; meshIdx < model.Meshes.Count; meshIdx++)
		{
			let modelMesh = model.Meshes[meshIdx];

			let mesh = ModelMeshConverter.ConvertToStaticMesh(modelMesh, mOptions.GenerateNormals, mOptions.GenerateTangents);
			if (mesh == null)
			{
				result.AddWarning(scope $"Failed to convert mesh '{modelMesh.Name}'");
				continue;
			}

			// Bake the mesh node's world transform into vertices
			let nodeTransform = ComputeMeshNodeWorldTransform(model, (int32)meshIdx);
			ApplyTransform(mesh, nodeTransform);

			if (mOptions.Scale != 1.0f)
				ApplyScale(mesh, mOptions.Scale);

			if (mOptions.RecenterMeshes)
				RecenterStaticMesh(mesh);

			if (firstName.IsEmpty)
				firstName.Set(modelMesh.Name);

			convertedMeshes.Add(mesh);
		}

		if (convertedMeshes.Count == 0)
			return;

		// Merge all static meshes into one resource
		StaticMesh mergedMesh;
		if (convertedMeshes.Count == 1)
		{
			mergedMesh = convertedMeshes[0];
		}
		else
		{
			mergedMesh = MergeStaticMeshes(convertedMeshes);
			// Delete source meshes (merged mesh has its own data)
			for (let m in convertedMeshes)
				delete m;
		}

		mergedMesh.Name.Set(firstName);
		result.StaticMeshes.Add(mergedMesh);
	}

	private void ImportSkinnedMeshes(Model model, ModelImportResult result)
	{
		// Build meshIdx -> skinIdx mapping from bones so we can filter meshes by skin
		let meshToSkin = scope int32[model.Meshes.Count];
		for (int i = 0; i < meshToSkin.Count; i++)
			meshToSkin[i] = -1;
		for (let bone in model.Bones)
		{
			if (bone.MeshIndex >= 0 && bone.MeshIndex < meshToSkin.Count && bone.SkinIndex >= 0)
				meshToSkin[bone.MeshIndex] = bone.SkinIndex;
		}

		// Track which skeleton indices we've already produced a skinned mesh for.
		// Duplicate skins map to the same skeleton, so we skip the second occurrence.
		let processedSkeletons = scope HashSet<int32>();

		for (int skinIdx = 0; skinIdx < model.Skins.Count; skinIdx++)
		{
			let skeletonIdx = (skinIdx < mSkinToSkeletonIdx.Count) ? mSkinToSkeletonIdx[skinIdx] : -1;

			if (skeletonIdx < 0)
				continue;

			if (!processedSkeletons.Add(skeletonIdx))
				continue;

			let skin = model.Skins[skinIdx];

			// Convert meshes that belong to this skin
			let convertedMeshes = scope List<SkinnedMesh>();
			int32[] nodeToBoneMapping = null;
			String firstName = scope .();

			for (int meshIdx = 0; meshIdx < model.Meshes.Count; meshIdx++)
			{
				// Only include meshes whose owning bone's SkinIndex matches this skin
				if (meshToSkin[meshIdx] != (int32)skinIdx)
					continue;

				let modelMesh = model.Meshes[meshIdx];

				bool hasSkinning = false;
				for (let element in modelMesh.VertexElements)
				{
					if (element.Semantic == .Joints)
					{
						hasSkinning = true;
						break;
					}
				}

				if (!hasSkinning)
					continue;

				if (ModelMeshConverter.ConvertToSkinnedMesh(modelMesh, skin, mOptions.GenerateNormals, mOptions.GenerateTangents) case .Ok(var conversionResult))
				{
					if (mOptions.Scale != 1.0f)
						ApplyScaleSkinned(conversionResult.Mesh, mOptions.Scale);

					if (firstName.IsEmpty)
						firstName.Set(modelMesh.Name);

					convertedMeshes.Add(conversionResult.Mesh);

					// Keep the first node-to-bone mapping for animation import
					if (nodeToBoneMapping == null)
						nodeToBoneMapping = conversionResult.NodeToBoneMapping;
					else
						delete conversionResult.NodeToBoneMapping;
				}
				else
				{
					result.AddWarning(scope $"Failed to convert skinned mesh '{modelMesh.Name}'");
				}
			}

			if (convertedMeshes.Count == 0)
			{
				delete nodeToBoneMapping;
				continue;
			}

			// Merge all skinned meshes for this skin into one resource
			SkinnedMesh mergedMesh;
			if (convertedMeshes.Count == 1)
			{
				mergedMesh = convertedMeshes[0];
			}
			else
			{
				mergedMesh = MergeSkinnedMeshes(convertedMeshes);
				for (let m in convertedMeshes)
					delete m;
			}

			// Recenter mesh vertices and adjust skeleton to match
			if (mOptions.RecenterMeshes)
			{
				Skeleton skeleton = null;
				if (skeletonIdx >= 0 && skeletonIdx < result.Skeletons.Count)
					skeleton = result.Skeletons[skeletonIdx];
				RecenterSkinnedMesh(mergedMesh, skeleton);
			}

			mergedMesh.Name.Set(firstName);
			// Store skeleton index so the application can link them
			mergedMesh.SkeletonIndex = (int32)skeletonIdx;

			result.SkinnedMeshes.Add(mergedMesh);

			delete nodeToBoneMapping;
		}
	}

	/// Merges multiple StaticMeshes into a single mesh with SubMeshes preserved.
	private StaticMesh MergeStaticMeshes(List<StaticMesh> meshes)
	{
		// Calculate totals
		int32 totalVertices = 0;
		int32 totalIndices = 0;
		for (let m in meshes)
		{
			totalVertices += m.VertexCount;
			totalIndices += m.Indices?.IndexCount ?? 0;
		}

		let merged = new StaticMesh();
		merged.ResizeVertices(totalVertices);
		merged.ReserveIndices(totalIndices);

		int32 vertexOffset = 0;
		int32 indexOffset = 0;

		for (let src in meshes)
		{
			let srcVertCount = src.VertexCount;
			let srcIdxCount = src.Indices?.IndexCount ?? 0;

			// Copy vertices
			for (int32 i = 0; i < srcVertCount; i++)
				merged.SetVertex(vertexOffset + i, src.GetVertex(i));

			// Copy indices (remapped by vertexOffset)
			for (int32 i = 0; i < srcIdxCount; i++)
			{
				let idx = src.Indices.GetIndex(i);
				merged.SetIndex(indexOffset + i, idx + (uint32)vertexOffset);
			}

			// Copy SubMeshes (adjusting startIndex by indexOffset)
			if (src.SubMeshes != null)
			{
				for (let sub in src.SubMeshes)
					merged.AddSubMesh(SubMesh(indexOffset + sub.startIndex, sub.indexCount, sub.materialIndex, sub.primitiveType));
			}

			vertexOffset += srcVertCount;
			indexOffset += srcIdxCount;
		}

		return merged;
	}

	/// Merges multiple SkinnedMeshes into a single mesh with SubMeshes preserved.
	private SkinnedMesh MergeSkinnedMeshes(List<SkinnedMesh> meshes)
	{
		// Calculate totals
		int32 totalVertices = 0;
		int32 totalIndices = 0;
		for (let m in meshes)
		{
			totalVertices += m.VertexCount;
			totalIndices += m.IndexCount;
		}

		let merged = new SkinnedMesh();
		merged.ResizeVertices(totalVertices);
		merged.ReserveIndices(totalIndices);

		int32 vertexOffset = 0;
		int32 indexOffset = 0;

		for (let src in meshes)
		{
			// Copy vertices
			for (int32 i = 0; i < src.VertexCount; i++)
				merged.SetVertex(vertexOffset + i, src.GetVertex(i));

			// Copy indices (remapped by vertexOffset)
			for (int32 i = 0; i < src.IndexCount; i++)
			{
				let idx = src.Indices.GetIndex(i);
				merged.Indices.SetIndex(indexOffset + i, idx + (uint32)vertexOffset);
			}

			// Copy SubMeshes (adjusting startIndex by indexOffset)
			if (src.SubMeshes != null)
			{
				for (let sub in src.SubMeshes)
					merged.AddSubMesh(SubMesh(indexOffset + sub.startIndex, sub.indexCount, sub.materialIndex, sub.primitiveType));
			}

			vertexOffset += src.VertexCount;
			indexOffset += src.IndexCount;
		}

		merged.CalculateBounds();
		return merged;
	}

	private void ImportTextures(Model model, ModelImportResult result)
	{
		for (int texIdx = 0; texIdx < model.Textures.Count; texIdx++)
		{
			let modelTex = model.Textures[texIdx];

			// Use TextureConverter which handles decoded pixel data
			let textureRes = TextureConverter.Convert(modelTex, mOptions.BasePath);

			if (textureRes == null)
			{
				result.AddWarning(scope $"Failed to load texture '{modelTex.Name}' (uri: {modelTex.Uri})");
				continue;
			}

			result.Textures.Add(textureRes);
		}
	}

	private void ImportMaterials(Model model, ModelImportResult result)
	{
		for (int matIdx = 0; matIdx < model.Materials.Count; matIdx++)
		{
			let modelMat = model.Materials[matIdx];

			// Convert to ImportedMaterial (PBR properties + texture references by index)
			let mat = MaterialConverter.Convert(modelMat, model);
			if (mat != null)
				result.Materials.Add(mat);
			else
				result.AddWarning(scope $"Failed to convert material '{modelMat.Name}'");
		}
	}

	private void ImportAnimations(Model model, ModelImportResult result)
	{
		if (model.Animations.Count == 0 || model.Skins.Count == 0)
			return;

		// Get node-to-bone mapping from the skeleton converter (includes ancestor nodes
		// so that root motion animation channels on non-joint ancestors are preserved)
		let skin = model.Skins[0];
		let nodeToBoneMapping = SkeletonConverter.CreateNodeToBoneMapping(model, skin);
		if (nodeToBoneMapping == null)
			return;
		defer delete nodeToBoneMapping;

		for (let modelAnim in model.Animations)
		{
			let clip = AnimationConverter.Convert(modelAnim, nodeToBoneMapping);
			if (clip != null)
			{
				result.Animations.Add(clip);
			}
			else
			{
				result.AddWarning(scope $"Failed to convert animation '{modelAnim.Name}'");
			}
		}
	}

	private Image LoadImageFromMemory(Span<uint8> data)
	{
		if (ImageLoaderFactory.LoadImageFromMemory(data) case .Ok(var image))
		{
			return image;
		}

		return null;
	}

	private Image LoadImageFromFile(StringView path)
	{
		if (ImageLoaderFactory.LoadImage(path) case .Ok(var image))
		{
			return image;
		}

		return null;
	}

	/// Finds the first node that references the given mesh index and computes its world transform.
	/// Traverses the parent chain to accumulate transforms from the full hierarchy.
	private Matrix ComputeMeshNodeWorldTransform(Model model, int32 meshIndex)
	{
		// Find the first node that references this mesh
		int32 nodeIndex = -1;
		for (let bone in model.Bones)
		{
			if (bone.MeshIndex == meshIndex)
			{
				nodeIndex = bone.Index;
				break;
			}
		}

		if (nodeIndex < 0)
			return Matrix.Identity;

		// Walk up the parent chain, accumulating transforms
		Matrix worldTransform = Matrix.Identity;
		int32 current = nodeIndex;
		while (current >= 0 && current < model.Bones.Count)
		{
			let bone = model.Bones[current];
			bone.UpdateLocalTransform();
			worldTransform = worldTransform * bone.LocalTransform;
			current = bone.ParentIndex;
		}

		return worldTransform;
	}

	private void ApplyTransform(StaticMesh mesh, Matrix transform)
	{
		if (mesh.Vertices == null)
			return;

		// Extract the normal matrix (inverse transpose of upper 3x3) for transforming normals/tangents
		Matrix normalMatrix;
		Matrix.Invert(transform, out normalMatrix);
		normalMatrix = Matrix.Transpose(normalMatrix);

		for (int32 i = 0; i < mesh.VertexCount; i++)
		{
			var v = mesh.Vertices[i];
			v.Position = Vector3.Transform(v.Position, transform);
			v.Normal = Vector3.Normalize(Vector3.TransformNormal(v.Normal, normalMatrix));
			v.Tangent = Vector3.Normalize(Vector3.TransformNormal(v.Tangent, normalMatrix));
			mesh.Vertices[i] = v;
		}
	}

	private void ApplyScale(StaticMesh mesh, float scale)
	{
		for (int32 i = 0; i < mesh.VertexCount; i++)
		{
			var v = mesh.Vertices[i];
			v.Position = v.Position * scale;
			mesh.Vertices[i] = v;
		}
	}

	private void ApplyScaleSkinned(SkinnedMesh mesh, float scale)
	{
		for (int32 i = 0; i < mesh.VertexCount; i++)
		{
			var vertex = mesh.GetVertex(i);
			vertex.Position = vertex.Position * scale;
			mesh.SetVertex(i, vertex);
		}
	}

	/// Recenters a static mesh so the bounding box center is at the origin.
	private void RecenterStaticMesh(StaticMesh mesh)
	{
		if (mesh.VertexCount == 0)
			return;

		let bounds = mesh.GetBounds();
		let center = (bounds.Min + bounds.Max) * 0.5f;

		// Skip if already centered (within tolerance)
		if (center.LengthSquared() < 0.0001f)
			return;

		for (int32 i = 0; i < mesh.VertexCount; i++)
		{
			var v = mesh.Vertices[i];
			v.Position = v.Position - center;
			mesh.Vertices[i] = v;
		}
	}

	/// Recenters a skinned mesh so the bounding box center is at the origin.
	/// Also adjusts the skeleton's InverseBindPose and RootCorrection matrices
	/// so that skinning produces correctly centered output during animation.
	private void RecenterSkinnedMesh(SkinnedMesh mesh, Skeleton skeleton)
	{
		if (mesh.VertexCount == 0)
			return;

		mesh.CalculateBounds();
		let bounds = mesh.Bounds;
		let center = (bounds.Min + bounds.Max) * 0.5f;

		// Skip if already centered (within tolerance)
		if (center.LengthSquared() < 0.0001f)
			return;

		// Shift all vertex positions
		for (int32 i = 0; i < mesh.VertexCount; i++)
		{
			var vertex = mesh.GetVertex(i);
			vertex.Position = vertex.Position - center;
			mesh.SetVertex(i, vertex);
		}

		// Adjust skeleton so skinning remains correct after vertex shift.
		// In row-major convention (point * matrix):
		//   skinned = vertex * InvBindPose * WorldPose
		//   Root WorldPose = localMatrix * RootCorrection
		// After shift: (v-c) * T(c)*OldInvBind * OldWorldPose*T(-c) = OldResult - center
		if (skeleton != null)
		{
			let offsetMatrix = Matrix.CreateTranslation(-center);
			let invOffsetMatrix = Matrix.CreateTranslation(center);

			for (let bone in skeleton.Bones)
			{
				if (bone == null) continue;

				// Pre-multiply InverseBindPose by +center translation for all bones
				bone.InverseBindPose = invOffsetMatrix * bone.InverseBindPose;

				// Post-multiply RootCorrection by -center translation for root bones
				if (bone.ParentIndex < 0)
					bone.RootCorrection = bone.RootCorrection * offsetMatrix;
			}
		}

		mesh.CalculateBounds();
	}
}
