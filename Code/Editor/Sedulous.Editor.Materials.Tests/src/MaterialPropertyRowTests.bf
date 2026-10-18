using System;
using Sedulous.Materials;

namespace Sedulous.Editor.Materials.Tests;

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
	}

	/// Every value a shader's properties block can declare has a row of its own size: a custom
	/// shader's float2, float3 and int are edited as what they are, not as four floats.
	[Test]
	public static void AShadersFloat2Float3AndIntGetRowsOfTheirOwn()
	{
		Test.Assert(MaterialPropertyRow.For(.Float2) == .Numbers2);
		Test.Assert(MaterialPropertyRow.For(.Float3) == .Numbers3);
		Test.Assert(MaterialPropertyRow.For(.Int) == .Integer);
	}

	[Test]
	public static void TheBuiltinPbrTemplatesColoursLandOnColourRows()
	{
		let pbr = MaterialPresets.BuiltinTemplate("forward");
		defer delete pbr;
		Test.Assert(pbr.FindProperty("BaseColor", let baseColor) && (MaterialPropertyRow.For(baseColor.Type) == .Color));
		Test.Assert(pbr.FindProperty("EmissiveColor", let emissive) && (MaterialPropertyRow.For(emissive.Type) == .ColorWithIntensity));
	}
}
