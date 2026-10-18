using System;
using Sedulous.Editor.App;

namespace Sedulous.Editor.App.Tests;

/// A reflected property's name as a row's label.
class PropertyNamesTests
{
	[Test]
	public static void APropertysNameBecomesARowsLabel()
	{
		Test.Assert(PropertyNames.Prettify("castsShadows", .. scope .()) == "Casts Shadows");
		Test.Assert(PropertyNames.Prettify("fovYRadians", .. scope .()) == "Fov Y Radians");
		Test.Assert(PropertyNames.Prettify("type", .. scope .()) == "Type");
		Test.Assert(PropertyNames.Prettify("skyIntensity", .. scope .()) == "Sky Intensity");
		Test.Assert(PropertyNames.Prettify("IBL", .. scope .()) == "IBL");
		Test.Assert(PropertyNames.Prettify("ReflectionProbe", .. scope .()) == "Reflection Probe");
		Test.Assert(PropertyNames.ComponentLabel("LightComponent", .. scope .()) == "Light");
	}
}
