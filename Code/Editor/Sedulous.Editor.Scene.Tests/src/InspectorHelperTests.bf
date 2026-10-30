using System;
using System.Collections;
using System.Reflection;
using Sedulous.Core;
using Sedulous.Render;
using Sedulous.Engine.Render;
using Sedulous.Engine.Physics;
using Sedulous.Engine.Navigation;
using Sedulous.Engine.Script;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;
using Sedulous.GUI;

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

		// The shadow controls have their ranges and show only while the light casts shadows.
		for (let name in String[3]("ShadowStrength", "ShadowNormalBias", "ShadowDepthBiasScale"))
		{
			Test.Assert(light.GetField(name) case .Ok(let control));
			Test.Assert(control.GetCustomAttribute<RangeAttribute>() case .Ok);
			Test.Assert(control.GetCustomAttribute<VisibleWhenAttribute>() case .Ok(let shadowVis));
			Test.Assert(PropertyCondition.Parse(shadowVis.Condition, c));
			Test.Assert(c.Prop == "CastsShadows");
		}

		let env = typeof(EnvironmentSettings);
		Test.Assert(env.GetField("Turbidity") case .Ok(let turbidity));
		Test.Assert(turbidity.GetCustomAttribute<RangeAttribute>() case .Ok);
		Test.Assert(turbidity.GetCustomAttribute<VisibleWhenAttribute>() case .Ok(let tvis));
		Test.Assert(PropertyCondition.Parse(tvis.Condition, c));
		Test.Assert(c.Matches(1)); // Analytic
		Test.Assert(!c.Matches(3)); // HDR equirect

		// The camera: the field of view shows for a perspective camera, the height for an
		// orthographic one.
		let camera = typeof(CameraComponent);
		Test.Assert(camera.GetField("FovYRadians") case .Ok(let fov));
		Test.Assert(fov.GetCustomAttribute<VisibleWhenAttribute>() case .Ok(let fovVis));
		Test.Assert(PropertyCondition.Parse(fovVis.Condition, c));
		Test.Assert(c.Prop == "Projection");
		Test.Assert(c.Matches(0) && !c.Matches(1));
		Test.Assert(camera.GetField("OrthoHeight") case .Ok(let height));
		Test.Assert(height.GetCustomAttribute<VisibleWhenAttribute>() case .Ok(let heightVis));
		Test.Assert(PropertyCondition.Parse(heightVis.Condition, c));
		Test.Assert(c.Matches(1) && !c.Matches(0));

		Test.Assert(env.GetField("SkyZenith") case .Ok(let zenith));
		Test.Assert(zenith.GetCustomAttribute<DisplayNameAttribute>() case .Ok(let label));
		Test.Assert(label.Name == "Sky Zenith / Color");
	}

	/// Whether the row `name` of `source` shows now.
	static bool RowVisible(FieldPropertySource source, StringView name)
	{
		let rows = scope List<PropertyInfo>();
		defer { ClearAndDeleteItems!(rows); }
		source.GetProperties("", rows);
		for (let row in rows)
		{
			if (row.Name == name)
				return row.Visible;
		}
		Test.Assert(false, "no such row");
		return false;
	}

	/// The inspector's source shows and hides the render components' rows by their conditions,
	/// read again from the values each time it lists them.
	[Test]
	public static void TheFieldSourceShowsAndHidesTheRenderComponentsRowsByTheirConditions()
	{
		var lamp = LightComponent();
		lamp.Type = .Directional;
		lamp.CastsShadows = false;
		void* lampAddress = &lamp;
		let lights = scope FieldPropertySource(typeof(LightComponent), 1, new (object) => lampAddress, new (apply) => { apply(0, lampAddress); });
		Test.Assert(!RowVisible(lights, "InnerAngle"));
		Test.Assert(!RowVisible(lights, "ShadowStrength"));
		lamp.Type = .Spot;
		lamp.CastsShadows = true;
		Test.Assert(RowVisible(lights, "InnerAngle"));
		Test.Assert(RowVisible(lights, "ShadowStrength"));
		lamp.Type = .Point;
		Test.Assert(!RowVisible(lights, "InnerAngle"));
		Test.Assert(RowVisible(lights, "Range")); // Type=1,2

		var eye = CameraComponent();
		eye.Projection = .Perspective;
		void* eyeAddress = &eye;
		let cameras = scope FieldPropertySource(typeof(CameraComponent), 1, new (object) => eyeAddress, new (apply) => { apply(0, eyeAddress); });
		Test.Assert(RowVisible(cameras, "FovYRadians"));
		Test.Assert(!RowVisible(cameras, "OrthoHeight"));
		eye.Projection = .Orthographic;
		Test.Assert(!RowVisible(cameras, "FovYRadians"));
		Test.Assert(RowVisible(cameras, "OrthoHeight"));

		var settings = EnvironmentSettings();
		settings.SkyMode = .Analytic;
		void* settingsAddress = &settings;
		let environments = scope FieldPropertySource(typeof(EnvironmentSettings), 1, new (object) => settingsAddress, new (apply) => { apply(0, settingsAddress); });
		Test.Assert(RowVisible(environments, "Turbidity"));
		settings.SkyMode = .HDREquirect;
		Test.Assert(!RowVisible(environments, "Turbidity"));
		let rows = scope List<PropertyInfo>();
		defer { ClearAndDeleteItems!(rows); }
		environments.GetProperties("", rows);
		bool named = false;
		for (let row in rows)
			named = named || ((row.Name == "SkyZenith") && (row.DisplayName == "Sky Zenith / Color"));
		Test.Assert(named);
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

	/// A settings block's profile reference, the environment's: set by identity through the
	/// reference command, undone and redone.
	[Test]
	public static void TheEnvironmentsProfileReferenceSetsAndUndoes()
	{
		let scene = scope Sedulous.Scene.Scene("s");
		let env = scene.AddSystem<EnvironmentSystem>();
		let commands = scope EditorCommandStack();
		let edit = scope SceneEditContext(scene, commands);
		let profile = Guid.Create();

		edit.SetSceneSettingResourceRef<EnvironmentProfile>(typeof(EnvironmentSettings), "Profile", profile, null);
		Test.Assert(env.Environment.Profile.Id == profile);
		commands.Undo();
		Test.Assert(env.Environment.Profile.Id == Guid.Empty);
		commands.Redo();
		Test.Assert(env.Environment.Profile.Id == profile);
	}
}
