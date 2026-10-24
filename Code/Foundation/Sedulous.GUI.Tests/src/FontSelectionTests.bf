using System;
using Sedulous.Fonts.TrueType;
using Sedulous.GUI;
using internal Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// font-weight and font-style: a run's face is the family's of the nearest weight in CSS's order,
/// its style matched first; bold and italic are synthesized only where no face has them. The faces
/// are named as font files name them ("Roboto Bold", "Roboto Light Italic"), each loaded under its
/// name.
class FontSelectionTests
{
	[Test]
	public static void WeightsAreTriedInCSSsOrder()
	{
		uint16[9] order = default;
		TextLayoutDetail.WeightOrder(400, ref order);
		uint16[9] normal = .(400, 500, 300, 200, 100, 600, 700, 800, 900);
		for (int i = 0; i < 9; i++)
			Test.Assert(order[i] == normal[i]);
		TextLayoutDetail.WeightOrder(300, ref order);
		uint16[9] light = .(300, 200, 100, 400, 500, 600, 700, 800, 900);
		for (int i = 0; i < 9; i++)
			Test.Assert(order[i] == light[i]);
		TextLayoutDetail.WeightOrder(650, ref order); // to the nearest hundred: 700
		uint16[9] bold = .(700, 800, 900, 600, 500, 400, 300, 200, 100);
		for (int i = 0; i < 9; i++)
			Test.Assert(order[i] == bold[i]);
		Test.Assert(TextLayoutDetail.Bolder(400) == 700);
		Test.Assert(TextLayoutDetail.Bolder(700) == 900);
		Test.Assert(TextLayoutDetail.Lighter(700) == 400);
		Test.Assert(TextLayoutDetail.Lighter(400) == 100);
	}

	[Test]
	public static void TheNearestWeightsFaceTheStyleMatchedFirstTheRestSynthesized()
	{
		let service = scope TrueTypeFontService();
		TextFixtures.Load(service, "X", TextFixtures.cRoboto);
		TextFixtures.Load(service, "X Bold", TextFixtures.cRobotoBold);
		TextFixtures.Load(service, "X Light Italic", TextFixtures.cRoboto);

		let face = scope TextLayoutDetail.FaceChoice();
		TextLayoutDetail.ChooseFace(service, "X", 700, false, face);
		Test.Assert(face.Face == "X Bold");
		Test.Assert(!face.SyntheticBold);
		TextLayoutDetail.ChooseFace(service, "X", 900, false, face); // none heavier: down to Bold
		Test.Assert(face.Face == "X Bold");
		TextLayoutDetail.ChooseFace(service, "X", 600, false, face); // up before down
		Test.Assert(face.Face == "X Bold");
		TextLayoutDetail.ChooseFace(service, "X", 500, false, face); // 500 then down: the regular
		Test.Assert(face.Face == "X");
		TextLayoutDetail.ChooseFace(service, "X", 300, true, face);
		Test.Assert(face.Face == "X Light Italic");
		Test.Assert(!face.SyntheticItalic);
		// Italic before weight: the light italic face, emboldened.
		TextLayoutDetail.ChooseFace(service, "X", 700, true, face);
		Test.Assert(face.Face == "X Light Italic");
		Test.Assert(face.SyntheticBold);
		Test.Assert(!face.SyntheticItalic);
		// No face of the family: asked for as it is, all of it synthesized.
		TextLayoutDetail.ChooseFace(service, "Y", 700, true, face);
		Test.Assert(face.Face == "Y");
		Test.Assert(face.SyntheticBold);
		Test.Assert(face.SyntheticItalic);
	}
}
