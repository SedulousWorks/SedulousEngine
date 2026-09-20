using System;
using System.IO;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Materials.Pipeline;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Scene.Tests;

/// The material creators over a real project.
class MaterialCreatorTests
{
	[Test]
	public static void PbrAndUnlitPresetsLandInMaterialsWithTheRightShader()
	{
		MaterialsPipeline.RegisterAll();
		let dir = PathJoin(Directory.GetCurrentDirectory(.. scope .()), "scratch_editor_mat_creator_test", .. scope .());
		RemoveDirectoryRecursive(dir);
		defer RemoveDirectoryRecursive(dir);
		Test.Assert(EditorProject.Create(dir, "P") case .Ok);
		let project = EditorProject.Open(dir);
		Test.Assert(project != null);
		defer delete project;
		let ctx = scope EditorContext();
		ctx.SetProject(project);

		// No project: nothing.
		let empty = scope EditorContext();
		Test.Assert(MaterialAssetCreators.CreateMaterialInstance(empty, null, false) == null);

		// PBR: the lit property set on the "forward" shader; lands in Materials/ (unique names).
		let pbr = MaterialAssetCreators.CreateMaterialInstance(ctx, null, false);
		Test.Assert(pbr != null);
		Test.Assert(pbr.GetPath(.. scope .()) == "Materials/Material");
		Test.Assert(AssetTypeNames.Matches(pbr.TypeName, "MaterialAsset"));
		{
			let object = pbr.ReadObject();
			defer delete object;
			let asset = object as MaterialAsset;
			Test.Assert(asset != null);
			Test.Assert(asset.Source.ShaderName == "forward");
			Test.Assert(asset.Source.Name == "Material");
			Test.Assert(HasProperty(asset, "Metallic"));
			Test.Assert(HasProperty(asset, "BaseColor"));
			Test.Assert(HasProperty(asset, "AlbedoMap"));
			// The packed defaults are readable by name: Roughness is the preset's 0.5.
			Test.Assert(MaterialSourceEdit.ReadFloat(asset.Source, "Roughness") == 0.5f);
		}

		// Unlit: BaseColor + AlbedoMap only, on the "unlit" shader.
		let unlit = MaterialAssetCreators.CreateMaterialInstance(ctx, null, true);
		Test.Assert(unlit != null);
		Test.Assert(unlit.GetPath(.. scope .()) == "Materials/Material.2");
		{
			let object = unlit.ReadObject();
			defer delete object;
			let asset = object as MaterialAsset;
			Test.Assert(asset != null);
			Test.Assert(asset.Source.ShaderName == "unlit");
			Test.Assert(!HasProperty(asset, "Metallic"));
			Test.Assert(HasProperty(asset, "BaseColor"));
			Test.Assert(HasProperty(asset, "AlbedoMap"));
		}

		// A browser group wins over the default folder.
		let props = project.SourceDb.RootGroup.CreateGroup("Props");
		let inProps = MaterialAssetCreators.CreateMaterialInstance(ctx, props, false);
		Test.Assert(inProps != null);
		Test.Assert(inProps.GetPath(.. scope .()) == "Props/Material");
	}

	private static bool HasProperty(MaterialAsset asset, StringView name)
	{
		for (let n in asset.Source.PropertyNames)
		{
			if (n == name)
				return true;
		}
		return false;
	}
}
