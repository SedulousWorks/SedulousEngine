using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Model;
using Sedulous.Model.IO;
using Sedulous.Model.FBX;

namespace Sedulous.Model.FBX.Tests;

/// The material mapping, through OBJ's material library.
///
/// An OBJ material is the legacy non-PBR kind, which is the branch that maps a Lambert or
/// Phong material onto the PBR fields. The PBR branch needs a real FBX to reach and is not
/// covered here; nor is skinning or animation, which OBJ cannot express at all.
class FbxMaterialTests
{
	private static bool Near(float a, float b, float tolerance = 0.01f) => Abs(a - b) <= tolerance;

	private const String cTwoMaterials = """
o shapes
v 0 0 0
v 1 0 0
v 0 1 0
v 2 0 0
v 3 0 0
v 2 1 0
usemtl red
f 1 2 3
usemtl blue
f 4 5 6
""";

	private const String cMaterialLibrary = """
newmtl red
Kd 0.8 0.1 0.1

newmtl blue
Kd 0.1 0.1 0.8
""";

	/// Two materials means two parts, each naming its own, so the mesh can be drawn in two
	/// calls.
	[Test]
	public static void MaterialsBecomePartsThatNameThem()
	{
		let fixture = scope ObjFixture("mats", cTwoMaterials, cMaterialLibrary);
		let model = scope ModelData();
		let loader = scope FbxLoader();
		Test.Assert(loader.Load(fixture.Path, model) == .Ok);

		Test.Assert(model.Materials.Length == 2, scope $"got {model.Materials.Length} materials");
		let mesh = model.Meshes[0];
		Test.Assert(mesh.Parts.Length == 2, scope $"got {mesh.Parts.Length} parts");

		// Each part names a real material, and the two are different ones.
		let seen = scope List<int32>();
		for (let part in mesh.Parts)
		{
			Test.Assert(part.MaterialIndex >= 0, "a part with a material must name it");
			Test.Assert(part.MaterialIndex < (int32)model.Materials.Length);
			Test.Assert(!seen.Contains(part.MaterialIndex), "the two parts are not the same material");
			seen.Add(part.MaterialIndex);
			Test.Assert(part.IndexCount == 3, "a triangle each");
		}

		// The parts partition the index buffer: together they cover it exactly once.
		int32 covered = 0;
		for (let part in mesh.Parts)
			covered += part.IndexCount;
		Test.Assert(covered == mesh.IndexCount);
	}

	/// A diffuse colour becomes the base colour factor, and an old material gets PBR
	/// defaults that do not turn it into a mirror.
	[Test]
	public static void ALegacyMaterialMapsOntoThePbrFields()
	{
		let fixture = scope ObjFixture("legacy", cTwoMaterials, cMaterialLibrary);
		let model = scope ModelData();
		let loader = scope FbxLoader();
		Test.Assert(loader.Load(fixture.Path, model) == .Ok);

		bool sawRed = false, sawBlue = false;
		for (let material in model.Materials)
		{
			let c = material.BaseColorFactor;
			// The file's scene linear 0.8 and 0.1, encoded to the sRGB colours they are.
			if (Near(c.X, LinearToSrgb(0.8f)) && Near(c.Y, LinearToSrgb(0.1f))) sawRed = true;
			if (Near(c.Z, LinearToSrgb(0.8f)) && Near(c.X, LinearToSrgb(0.1f))) sawBlue = true;

			Test.Assert(Near(material.MetallicFactor, 0.0f),
				"a material from before PBR is not metal");
			Test.Assert(material.RoughnessFactor > 0.5f, "and it is not a mirror either");
			Test.Assert(Near(c.W, 1.0f), "opaque");
			Test.Assert(material.AlphaMode == .Opaque);
		}
		Test.Assert(sawRed && sawBlue, "both diffuse colours came through");
	}

	/// A mesh with no material at all is ONE part with no material index, rather than no
	/// parts: the geometry still has to be drawn.
	[Test]
	public static void AMeshWithNoMaterialIsStillOnePart()
	{
		let plain = """
o plain
v 0 0 0
v 1 0 0
v 0 1 0
f 1 2 3
""";
		let fixture = scope ObjFixture("nomat", plain);
		let model = scope ModelData();
		let loader = scope FbxLoader();
		Test.Assert(loader.Load(fixture.Path, model) == .Ok);

		let mesh = model.Meshes[0];
		Test.Assert(mesh.Parts.Length == 1);
		Test.Assert(mesh.Parts[0].IndexCount == 3);
		Test.Assert(mesh.Parts[0].IndexStart == 0);
	}

	/// An OBJ naming a material library that is not there still LOADS. Refusing the whole
	/// model over an absent sidecar would reject files that render perfectly well, only
	/// untextured, and that is the caller's decision rather than the loader's.
	[Test]
	public static void AnAbsentMaterialLibraryIsNotAnError()
	{
		// The mtllib line is written, the .mtl is not: the loader goes looking and misses.
		let fixture = scope ObjFixture("nolib", cTwoMaterials, cMaterialLibrary, false);
		let model = scope ModelData();
		let loader = scope FbxLoader();

		Test.Assert(loader.Load(fixture.Path, model) == .Ok, "a missing .mtl is not a failure");
		Test.Assert(model.Meshes.Length == 1, "and the geometry still arrived");
		Test.Assert(model.Meshes[0].IndexCount == 6, "both triangles");
	}

	/// A material colour is the DCC's scene linear value in the file; read, it is the authored
	/// sRGB colour: linear 0.2140 is sRGB 0.5.
	[Test]
	public static void AMaterialColourReadsAsAuthoredSrgb()
	{
		let fixture = scope ObjFixture("grey", "o quad\nv 0 0 0\nv 1 0 0\nv 0 1 0\nusemtl grey\nf 1 2 3\n",
			"newmtl grey\nKd 0.2140 0.2140 0.2140\n");
		let model = scope ModelData();
		let loader = scope FbxLoader();
		Test.Assert(loader.Load(fixture.Path, model) == .Ok);
		Test.Assert(model.Materials.Length >= 1);
		let grey = model.Materials[0].BaseColorFactor;
		Test.Assert(Near(grey.X, 0.5f, 0.002f) && Near(grey.Y, 0.5f, 0.002f), scope $"{grey.X}, {grey.Y}");
	}

	/// Blender writes DiffuseFactor 0.8 beside a legacy material's colour, and the same
	/// model's glTF carries the colour alone: the factor is ignored, so linear 0.2140 reads as
	/// sRGB 0.5 whatever it says.
	[Test]
	public static void ALegacyMaterialsColourIgnoresItsDiffuseFactor()
	{
		let path = "scratch_fbx_factor.fbx";
		System.IO.File.WriteAllText(path, """
			; FBX 7.4.0 project file
			FBXHeaderExtension:  {
				FBXHeaderVersion: 1003
				FBXVersion: 7400
			}
			Objects:  {
				Material: 1000, "Material::Grey", "" {
					Version: 102
					ShadingModel: "phong"
					Properties70:  {
						P: "DiffuseColor", "Color", "", "A",0.2140,0.2140,0.2140
						P: "DiffuseFactor", "Number", "", "A",0.8
					}
				}
			}
			Connections:  {
			}
			""").IgnoreError();
		defer { System.IO.File.Delete(path).IgnoreError(); }
		let model = scope ModelData();
		let loader = scope FbxLoader();
		Test.Assert(loader.Load(path, model) == .Ok);
		Test.Assert(model.Materials.Length >= 1);
		Test.Assert(Near(model.Materials[0].BaseColorFactor.X, 0.5f, 0.002f), scope $"{model.Materials[0].BaseColorFactor.X}");
	}

	// Imported as authored: an FBX Phong material keeps its highlight
	// (its specular colour times its factor, as sRGB, and its exponent), a Lambert one has none; both
	// are told apart from PBR by the shading model the file names.
	[Test]
	public static void APhongMaterialKeepsItsHighlightALambertOneIsDiffuseAlone()
	{
		let path = "scratch_fbx_phong.fbx";
		System.IO.File.WriteAllText(path, """
			; FBX 7.4.0 project file
			FBXHeaderExtension:  {
				FBXHeaderVersion: 1003
				FBXVersion: 7400
			}
			Objects:  {
				Material: 1000, "Material::Shiny", "" {
					Version: 102
					ShadingModel: "phong"
					Properties70:  {
						P: "DiffuseColor", "Color", "", "A",1,1,1
						P: "SpecularColor", "Color", "", "A",0.2140,0.2140,0.2140
						P: "SpecularFactor", "Number", "", "A",1
						P: "ShininessExponent", "Number", "", "A",32
					}
				}
				Material: 1001, "Material::Matte", "" {
					Version: 102
					ShadingModel: "lambert"
					Properties70:  {
						P: "DiffuseColor", "Color", "", "A",0.2140,0.2140,0.2140
					}
				}
			}
			Connections:  {
			}
			""").IgnoreError();
		defer { System.IO.File.Delete(path).IgnoreError(); }
		let model = scope ModelData();
		let loader = scope FbxLoader();
		Test.Assert(loader.Load(path, model) == .Ok);
		ModelMaterial shiny = null;
		ModelMaterial matte = null;
		for (let material in model.Materials)
		{
			if (material.Name == "Shiny")
				shiny = material;
			if (material.Name == "Matte")
				matte = material;
		}
		Test.Assert((shiny != null) && (matte != null));
		Test.Assert(shiny.Shading == .Phong);
		Test.Assert(Near(shiny.SpecularColor.X, 0.5f, 0.002f), scope $"{shiny.SpecularColor.X}"); // linear 0.2140 is sRGB 0.5
		Test.Assert(Near(shiny.Shininess, 32.0f));
		Test.Assert(matte.Shading == .Lambert);
		Test.Assert(matte.SpecularColor.X == 0.0f);
		Test.Assert(Near(matte.BaseColorFactor.X, 0.5f, 0.002f));
	}

	[Test]
	public static void AClassicMtlIsPhongOneWithPbrKeysStaysPbr()
	{
		{
			let fixture = scope ObjFixture("classic", cTwoMaterials, "newmtl red\nKd 1 0 0\nKs 0.2140 0.2140 0.2140\nNs 50\n");
			let model = scope ModelData();
			let loader = scope FbxLoader();
			Test.Assert(loader.Load(fixture.Path, model) == .Ok);
			Test.Assert(model.Materials.Length >= 1);
			let red = model.Materials[0];
			Test.Assert(red.Shading == .Phong);
			Test.Assert(Near(red.SpecularColor.X, 0.5f, 0.002f), scope $"{red.SpecularColor.X}");
			Test.Assert(Near(red.Shininess, 50.0f));
		}
		{
			let fixture = scope ObjFixture("pbrmtl", cTwoMaterials, "newmtl red\nKd 1 0 0\nPr 0.4\nPm 0.0\n");
			let model = scope ModelData();
			let loader = scope FbxLoader();
			Test.Assert(loader.Load(fixture.Path, model) == .Ok);
			Test.Assert(model.Materials.Length >= 1);
			Test.Assert(model.Materials[0].Shading == .Pbr);
		}
	}

	[Test]
	public static void BlendersExportStaysPbrThoughItNamesEveryMaterialPhong()
	{
		let path = "scratch_fbx_blender.fbx";
		System.IO.File.WriteAllText(path, """
			; FBX 7.4.0 project file
			FBXHeaderExtension:  {
				FBXHeaderVersion: 1003
				FBXVersion: 7400
				Creator: "Blender (stable FBX IO) - 4.2.0 - 5.12.3"
			}
			Creator: "Blender (stable FBX IO) - 4.2.0 - 5.12.3"
			Objects:  {
				Material: 1000, "Material::Painted", "" {
					Version: 102
					ShadingModel: "Phong"
					Properties70:  {
						P: "DiffuseColor", "Color", "", "A",0.8,0.8,0.8
						P: "SpecularColor", "Color", "", "A",0.8,0.8,0.8
						P: "ShininessExponent", "Number", "", "A",25
					}
				}
			}
			Connections:  {
			}
			""").IgnoreError();
		defer { System.IO.File.Delete(path).IgnoreError(); }
		let model = scope ModelData();
		let loader = scope FbxLoader();
		Test.Assert(loader.Load(path, model) == .Ok);
		Test.Assert(model.Materials.Length >= 1);
		Test.Assert(model.Materials[0].Shading == .Pbr);
	}
}
