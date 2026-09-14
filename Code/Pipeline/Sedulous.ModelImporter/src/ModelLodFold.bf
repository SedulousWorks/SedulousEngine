using System;
using System.Collections;
using Sedulous.Model;

namespace Sedulous.ModelImporter;

/// Collapsing authored level of detail meshes into the mesh they are levels of.
///
/// A model shipping "Foo", "Foo_LOD1" and "Foo_LOD2" is describing ONE mesh with a chain, and
/// importing the three as separate assets throws the author's own levels away. The fold is
/// shared by the fan out and by the review plan so the dialog lists exactly the mesh assets
/// the import will create.
static class ModelLodFold
{
	/// Works out, per model mesh, which mesh it folds into and which levels it absorbs.
	///
	/// `outFoldsInto` holds the base mesh index a suffixed mesh belongs to, or MINUS ONE for a
	/// mesh of its own. `outLevels` holds, per base, the mesh indices it absorbs in suffix
	/// order. THE CALLER OWNS the lists inside `outLevels`.
	public static void Compute(Model model, List<int32> outFoldsInto, List<List<int>> outLevels)
	{
		let hasSkin = !model.Skins.IsEmpty;
		let meshes = model.Meshes;

		outFoldsInto.Clear();
		outLevels.Clear();
		for (int i < meshes.Length)
		{
			outFoldsInto.Add(-1);
			outLevels.Add(new List<int>());
		}

		for (int i < meshes.Length)
		{
			let lodBase = scope String();
			let level = LodSuffix.Parse(meshes[i].Name, lodBase);
			if (level == 0)
				continue;

			var baseIndex = -1;
			for (int j < meshes.Length)
			{
				if ((j != i) && (meshes[j].Name == lodBase))
				{
					baseIndex = j;
					break;
				}
			}
			// No mesh of that name, so this is a plain mesh that happens to end in a suffix.
			if (baseIndex < 0)
				continue;

			// A MIXED pair cannot hold: the skinning stream runs parallel to the geometry, and
			// a level that disagrees with its base about having one has nothing to run beside.
			if ((ModelCook.IsSkinned(meshes[baseIndex]) && hasSkin)
				!= (ModelCook.IsSkinned(meshes[i]) && hasSkin))
			{
				continue;
			}

			outFoldsInto[i] = (int32)baseIndex;

			// Sorted by the suffix NUMBER, so level two lands after level one whatever order
			// the file listed its nodes in.
			let levels = outLevels[baseIndex];
			let otherBase = scope String();
			var at = levels.Count;
			for (int k < levels.Count)
			{
				if (level < LodSuffix.Parse(meshes[levels[k]].Name, otherBase))
				{
					at = k;
					break;
				}
			}
			levels.Insert(at, i);
		}
	}
}
