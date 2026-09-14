using System;
using Sedulous.Model;
using Sedulous.Model.Resource;

namespace Sedulous.ModelImporter;

/// Recording the node hierarchy the file described.
///
/// Hierarchy PRESERVING, deliberately: a node becomes an entity rather than everything being
/// merged into one mesh, so what the author built is what arrives.
static class ModelImportNodes
{
	public static void Import(Model model, ModelManifestSource manifest)
	{
		let bones = model.Bones;
		for (int i < bones.Length)
		{
			let bone = bones[i];
			manifest.NodeName.Add(new String(bone.Name));
			manifest.NodeParent.Add(bone.ParentIndex);
			manifest.NodeTranslation.Add(bone.Translation);
			manifest.NodeRotation.Add(bone.Rotation);
			manifest.NodeScale.Add(bone.Scale);
			manifest.NodeMesh.Add(bone.MeshIndex);
		}
	}
}
