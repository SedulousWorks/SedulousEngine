using System;
using System.Reflection;
using Sedulous.Core;
using Sedulous.Render;
using Sedulous.Engine.Render;
using Sedulous.Engine.Physics;
using Sedulous.Engine.Navigation;
using Sedulous.Engine.Script;
using Sedulous.Editor.Core;

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

	/// Every field of a settings block a scene inspector edits must carry RUNTIME reflection
	/// data, not only the ones an attribute forced it on.
	///
	/// The inspector's rows are generated at comptime, where every field is visible, but the
	/// write goes through Type.GetField at runtime. A field the reflection tables omit renders
	/// a row that silently refuses every edit: the sky mode dropdown sat on Procedural
	/// whatever was picked, because SkyMode and AmbientColor were the two fields with no
	/// attribute above them to pull them in.
	[Test]
	public static void EverySettingsFieldIsReflectedAtRuntimeNotJustTheAnnotatedOnes()
	{
		for (let type in scope Type[](typeof(EnvironmentSettings), typeof(PostProcessSettings),
			typeof(PhysicsSceneSettings), typeof(NavigationSceneSettings), typeof(SceneScriptSettings)))
		{
			var reflected = 0;
			for (let f in type.GetFields())
			{
				if (f.IsInstanceField)
					reflected++;
			}
			Test.Assert(reflected > 0, scope $"{type.GetName(.. scope .())} reflects no field at all");
		}

		// The two that had none, by name: the dropdown and the colour the inspector writes.
		let env = typeof(EnvironmentSettings);
		Test.Assert(env.GetField("SkyMode") case .Ok);
		Test.Assert(env.GetField("AmbientColor") case .Ok);
	}

	/// The dropdown's edit reaches the live settings and undoes, which is the whole path the
	/// inspector row drives: a raw enum write through the command stack.
	[Test]
	public static void TheSkyModeEditReachesTheEnvironmentAndUndoes()
	{
		let scene = scope Sedulous.Scene.Scene("s");
		let env = scene.AddSystem<EnvironmentSystem>();
		let commands = scope EditorCommandStack();
		let edit = scope SceneEditContext(scene, commands);

		Test.Assert(env.Environment.SkyMode == .Procedural);
		edit.SetSceneSettingPropertyRaw(typeof(EnvironmentSettings), "SkyMode", (int64)SkyMode.Cubemap);
		Test.Assert(env.Environment.SkyMode == .Cubemap);
		commands.Undo();
		Test.Assert(env.Environment.SkyMode == .Procedural);
	}
}
