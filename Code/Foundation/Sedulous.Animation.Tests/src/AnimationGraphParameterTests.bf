namespace Sedulous.Animation.Tests;

using System;

class AnimationGraphParameterTests
{
	[Test]
	public static void FloatParameter_DefaultValue_IsZero()
	{
		let param = scope AnimationGraphParameter("Speed", .Float);
		Test.Assert(param.FloatValue == 0.0f);
		Test.Assert(param.Type == .Float);
		Test.Assert(StringView.Compare(param.Name, "Speed", false) == 0);
	}

	[Test]
	public static void FloatParameter_SetGet()
	{
		let param = scope AnimationGraphParameter("Speed", .Float);
		param.FloatValue = 1.5f;
		Test.Assert(param.FloatValue == 1.5f);
	}

	[Test]
	public static void IntParameter_SetGet()
	{
		let param = scope AnimationGraphParameter("Count", .Int);
		param.IntValue = 42;
		Test.Assert(param.IntValue == 42);
	}

	[Test]
	public static void BoolParameter_SetGet()
	{
		let param = scope AnimationGraphParameter("Grounded", .Bool);
		Test.Assert(param.BoolValue == false);
		param.BoolValue = true;
		Test.Assert(param.BoolValue == true);
	}

	[Test]
	public static void TriggerParameter_ConsumeResets()
	{
		let param = scope AnimationGraphParameter("Fire", .Trigger);
		param.BoolValue = true;
		Test.Assert(param.BoolValue == true);

		param.ConsumeTrigger();
		Test.Assert(param.BoolValue == false);
	}

	[Test]
	public static void ConsumeTrigger_OnlyAffectsTriggerType()
	{
		let boolParam = scope AnimationGraphParameter("Flag", .Bool);
		boolParam.BoolValue = true;
		boolParam.ConsumeTrigger();
		Test.Assert(boolParam.BoolValue == true); // Bool is not affected

		let floatParam = scope AnimationGraphParameter("Val", .Float);
		floatParam.FloatValue = 1.0f;
		floatParam.ConsumeTrigger();
		Test.Assert(floatParam.FloatValue == 1.0f); // Float is not affected
	}
}
