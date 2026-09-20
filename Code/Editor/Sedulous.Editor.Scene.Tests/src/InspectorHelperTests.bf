using System;
using System.Reflection;
using Sedulous.Core;
using Sedulous.Engine.Render;

namespace Sedulous.Editor.Scene.Tests;

/// The inspector's small helpers: the condition grammar, name prettifying, and the
/// annotations the render components carry for the inspector.
class InspectorHelperTests
{
	[Test]
	public static void ParsePropertyConditionGrammar()
	{
		let c = scope PropertyCondition();

		Test.Assert(PropertyCondition.Parse("castsShadows", c));
		Test.Assert(c.Prop == "castsShadows");
		Test.Assert(c.Values.IsEmpty);
		Test.Assert(c.Matches(1));
		Test.Assert(!c.Matches(0));

		Test.Assert(PropertyCondition.Parse("type=1,2", c));
		Test.Assert(c.Prop == "type");
		Test.Assert(c.Values.Count == 2);
		Test.Assert(c.Matches(1));
		Test.Assert(c.Matches(2));
		Test.Assert(!c.Matches(0));
		Test.Assert(!c.Matches(3));

		Test.Assert(PropertyCondition.Parse("mode=-1", c));
		Test.Assert(c.Values.Count == 1);
		Test.Assert(c.Values[0] == -1);
		Test.Assert(c.Matches(-1));

		Test.Assert(!PropertyCondition.Parse("", c));
		Test.Assert(!PropertyCondition.Parse("=1", c));
		Test.Assert(!PropertyCondition.Parse("type=", c));
		Test.Assert(!PropertyCondition.Parse("type=1,,2", c));
		Test.Assert(!PropertyCondition.Parse("type=x", c));
	}

	[Test]
	public static void PrettifyPropertyName()
	{
		Test.Assert(PropertyNames.Prettify("castsShadows", .. scope .()) == "Casts Shadows");
		Test.Assert(PropertyNames.Prettify("fovYRadians", .. scope .()) == "Fov Y Radians");
		Test.Assert(PropertyNames.Prettify("type", .. scope .()) == "Type");
		Test.Assert(PropertyNames.Prettify("skyIntensity", .. scope .()) == "Sky Intensity");
		Test.Assert(PropertyNames.Prettify("IBL", .. scope .()) == "IBL");
		Test.Assert(PropertyNames.Prettify("ReflectionProbe", .. scope .()) == "Reflection Probe");
		Test.Assert(PropertyNames.ComponentLabel("LightComponent", .. scope .()) == "Light");
	}

	[Test]
	public static void RenderComponentsCarryTheInspectorAnnotations()
	{
		let light = typeof(LightComponent);
		Test.Assert(light.GetField("InnerAngle") case .Ok(let inner));
		Test.Assert(inner.GetCustomAttribute<VisibleWhenAttribute>() case .Ok(let vis));
		let c = scope PropertyCondition();
		Test.Assert(PropertyCondition.Parse(vis.Condition, c));
		Test.Assert(c.Prop == "Type");
		Test.Assert(c.Matches(2)); // Spot
		Test.Assert(!c.Matches(0)); // Directional

		Test.Assert(light.GetField("Intensity") case .Ok(let intensity));
		Test.Assert(intensity.GetCustomAttribute<RangeAttribute>() case .Ok(let range));
		Test.Assert(range.Max == 50.0f);

		let env = typeof(EnvironmentSettings);
		Test.Assert(env.GetField("Turbidity") case .Ok(let turbidity));
		Test.Assert(turbidity.GetCustomAttribute<RangeAttribute>() case .Ok);
		Test.Assert(turbidity.GetCustomAttribute<VisibleWhenAttribute>() case .Ok(let tvis));
		Test.Assert(PropertyCondition.Parse(tvis.Condition, c));
		Test.Assert(c.Matches(1)); // Analytic
		Test.Assert(!c.Matches(3)); // HDR equirect

		Test.Assert(env.GetField("SkyZenith") case .Ok(let zenith));
		Test.Assert(zenith.GetCustomAttribute<DisplayNameAttribute>() case .Ok(let label));
		Test.Assert(label.Name == "Sky Zenith / Color");
	}
}
