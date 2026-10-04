using System;
using Sedulous.Materials;

namespace Sedulous.Editor.Scene.Tests;

/// Which row a material property gets is a pure function of its declared type.
class MaterialPropertyRowTests
{
	[Test]
	public static void OnlyADeclaredColourGetsAColourPicker()
	{
		Test.Assert(MaterialPropertyRow.For(.Color) == .Color);
		Test.Assert(MaterialPropertyRow.For(.ColorHdr) == .ColorWithIntensity);
		// A Float4 that is not declared a colour is four numbers, not a swatch.
		Test.Assert(MaterialPropertyRow.For(.Float4) == .Numbers4);
		Test.Assert(MaterialPropertyRow.For(.Float) == .Number);
		Test.Assert(MaterialPropertyRow.For(.Texture2D) == .Texture);
		Test.Assert(MaterialPropertyRow.For(.Sampler) == .None);

		// The builtin PBR template's colours land on colour rows.
		let pbr = MaterialPresets.BuiltinTemplate("forward");
		defer delete pbr;
		Test.Assert(pbr.FindProperty("BaseColor", let baseColor) && (MaterialPropertyRow.For(baseColor.Type) == .Color));
		Test.Assert(pbr.FindProperty("EmissiveColor", let emissive) && (MaterialPropertyRow.For(emissive.Type) == .ColorWithIntensity));
	}
}
