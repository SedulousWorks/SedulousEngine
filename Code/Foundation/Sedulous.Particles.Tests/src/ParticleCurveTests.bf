using System;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Particles;
using Sedulous.Xml;
using Sedulous.Xml.Serialization;

namespace Sedulous.Particles.Tests;

/// Particle curves on Core's types: float curves of CurveKeys sampled by EvaluateCurve, colour
/// curves as gradients, size over lifetime as Size with SeparateAxes and SizeY; and the
/// legacy reader of text written before them (old float keys, old colour keys, the old Float2
/// size curve).
class ParticleCurveTests
{
	private static bool Near(float a, float b, float epsilon = 0.001f) => Abs(a - b) <= epsilon;

	private static void WriteText(ISerializable value, String outText)
	{
		let writer = scope XmlSerializer();
		value.Serialize(writer);
		writer.GetOutput(outText);
	}

	private static bool ReadText(StringView text, ISerializable value)
	{
		let document = scope XmlDocument();
		if (document.Parse(text) != .Ok)
			return false;
		let reader = scope XmlSerializer(document);
		value.Serialize(reader);
		return reader.IsOk;
	}

	[Test]
	public static void AFloatCurveIsOfCoresKeysCubicByDefaultAndLinearWhenAsked()
	{
		var eased = ParticleCurveFloat();
		eased.AddKey(0.0f, 0.0f);
		eased.AddKey(1.0f, 10.0f);
		Test.Assert(eased.Keys[0].Interpolation == .Cubic);
		Test.Assert(Near(eased.Evaluate(0.25f), 10.0f * 0.15625f));   // smoothstep(0.25)

		let straight = ParticleCurveFloat.Linear(0.0f, 10.0f);
		Test.Assert(Near(straight.Evaluate(0.25f), 2.5f));
		Test.Assert(Near(ParticleCurveFloat.Ease(0.0f, 10.0f).Evaluate(0.5f), 5.0f));
		Test.Assert(Near(ParticleCurveFloat.Ease(0.0f, 10.0f).Evaluate(0.25f), eased.Evaluate(0.25f)));

		// The same function Core's curve samples with.
		var keys = straight.Keys;
		Test.Assert(Near(straight.Evaluate(0.7f), EvaluateCurve(.(&keys[0], 2), 0.7f)));
	}

	[Test]
	public static void AColourCurveIsAGradientItsAlphaStopsApart()
	{
		let fade = ParticleCurveColor.FadeAlpha(.(1.0f, 0.5f, 0.0f, 1.0f), 0.5f);
		Test.Assert(fade.ColorCount == 1);
		Test.Assert(fade.AlphaCount == 3);
		Test.Assert(Near(fade.Evaluate(0.25f).W, 1.0f));
		Test.Assert(Near(fade.Evaluate(0.75f).W, 0.5f));
		Test.Assert(Near(fade.Evaluate(0.75f).Y, 0.5f));

		var ramp = ParticleCurveColor();
		ramp.AddKey(0.0f, .(0.0f, 0.0f, 0.0f, 1.0f));
		ramp.AddKey(1.0f, .(1.0f, 1.0f, 1.0f, 0.0f));
		Test.Assert(Near(ramp.Evaluate(0.5f).X, 0.5f));   // sRGB values, straight, as before
		Test.Assert(Near(ramp.Evaluate(0.5f).W, 0.5f));
		ramp.Interpolation = .LinearLight;
		Test.Assert(ramp.Evaluate(0.5f).X > 0.5f);
		Test.Assert(Near(ParticleCurveColor().Evaluate(0.3f).X, 1.0f));   // empty: white
	}

	[Test]
	public static void SizeSetsBothAxesOrYFromSizeYWithSeparateAxes()
	{
		let streams = scope ParticleStreamContainer(8);
		let behavior = scope SizeOverLifetimeBehavior();
		behavior.Size = ParticleCurveFloat.Linear(1.0f, 3.0f);
		behavior.SizeY = ParticleCurveFloat.Constant(9.0f);
		behavior.DeclareStreams(streams);
		streams.AliveCount = 1;
		streams.Ages[0] = 0.5f;
		streams.Lifetimes[0] = 1.0f;

		var rng = Sedulous.Core.Random(1);
		var context = ParticleUpdateContext();
		context.DeltaTime = 0.016f;
		context.Rng = &rng;
		behavior.Update(streams, ref context);
		Test.Assert(Near(streams.Sizes[0].X, 2.0f));
		Test.Assert(Near(streams.Sizes[0].Y, 2.0f));   // one curve, both axes

		behavior.SeparateAxes = true;
		behavior.Update(streams, ref context);
		Test.Assert(Near(streams.Sizes[0].X, 2.0f));
		Test.Assert(Near(streams.Sizes[0].Y, 9.0f));
	}

	[Test]
	public static void TheNewLayoutRoundTripsThroughText()
	{
		let size = scope SizeOverLifetimeBehavior();
		size.Size = ParticleCurveFloat.Ease(0.5f, 2.0f);
		size.SeparateAxes = true;
		size.SizeY = ParticleCurveFloat.Linear(1.0f, 4.0f);
		let color = scope ColorOverLifetimeBehavior();
		color.Curve = ParticleCurveColor.FadeAlpha(.(0.2f, 0.4f, 0.6f, 1.0f));
		color.Curve.Interpolation = .OkLab;
		let alpha = scope AlphaOverLifetimeBehavior();
		alpha.Curve = ParticleCurveFloat.FadeOut(1.0f, 0.5f);

		let sizeText = WriteText(size, .. scope String());
		let colorText = WriteText(color, .. scope String());
		let alphaText = WriteText(alpha, .. scope String());

		let sizeBack = scope SizeOverLifetimeBehavior();
		Test.Assert(ReadText(sizeText, sizeBack), sizeText);
		Test.Assert(sizeBack.SeparateAxes);
		Test.Assert(sizeBack.Size.KeyCount == 2);
		Test.Assert(sizeBack.Size.Keys[1].TangentMode == .Flat);
		Test.Assert(sizeBack.SizeY.Keys[1].Interpolation == .Linear);
		Test.Assert(Near(sizeBack.SizeY.Evaluate(0.5f), 2.5f));

		let colorBack = scope ColorOverLifetimeBehavior();
		Test.Assert(ReadText(colorText, colorBack), colorText);
		Test.Assert(colorBack.Curve.Interpolation == .OkLab);
		Test.Assert(colorBack.Curve.AlphaCount == 3);
		Test.Assert(Near(colorBack.Curve.Colors[0].Color.B, 0.6f));

		let alphaBack = scope AlphaOverLifetimeBehavior();
		Test.Assert(ReadText(alphaText, alphaBack), alphaText);
		Test.Assert(alphaBack.Curve.KeyCount == 3);
		Test.Assert(alphaBack.Curve.Keys[2].TangentMode == .Flat);
		Test.Assert(Near(alphaBack.Curve.Evaluate(0.75f), 0.5f));
	}

	/// The layouts the samples were saved in, the curve's fields loose in the module's object.
	[Test]
	public static void TextWrittenBeforeCoresTypesReadsOn()
	{
		// An old alpha curve: keys always Hermite, their tangents as stored.
		let alpha = scope AlphaOverLifetimeBehavior();
		Test.Assert(ReadText("""
			<root><object><i32 name="keyCount">2</i32>
			<f32 name="time">0</f32><f32 name="value">1</f32><f32 name="tangentIn">0</f32><f32 name="tangentOut">0</f32>
			<f32 name="time">1</f32><f32 name="value">0</f32><f32 name="tangentIn">0</f32><f32 name="tangentOut">0</f32>
			</object></root>
			""", alpha));
		Test.Assert(alpha.Curve.KeyCount == 2);
		Test.Assert(alpha.Curve.Keys[0].Interpolation == .Cubic);
		Test.Assert(Near(alpha.Curve.Evaluate(0.25f), 1.0f - 0.15625f));   // eased, as it played

		// An old colour curve: keys of an rgba each.
		let color = scope ColorOverLifetimeBehavior();
		Test.Assert(ReadText("""
			<root><object><i32 name="keyCount">2</i32>
			<f32 name="time">0</f32><object name="color"><f32 name="x">1</f32><f32 name="y">0.5</f32><f32 name="z">0</f32><f32 name="w">1</f32></object>
			<f32 name="time">1</f32><object name="color"><f32 name="x">0</f32><f32 name="y">0</f32><f32 name="z">0</f32><f32 name="w">0</f32></object>
			</object></root>
			""", color));
		Test.Assert(color.Curve.ColorCount == 2);
		Test.Assert(color.Curve.AlphaCount == 2);
		Test.Assert(Near(color.Curve.Evaluate(0.5f).X, 0.5f));
		Test.Assert(Near(color.Curve.Evaluate(0.5f).W, 0.5f));

		// An old size curve of Float2 keys, X equal to Y: one curve, both axes.
		let size = scope SizeOverLifetimeBehavior();
		Test.Assert(ReadText("""
			<root><object><i32 name="keyCount">2</i32>
			<f32 name="time">0</f32><object name="value"><f32 name="x">0.6</f32><f32 name="y">0.6</f32></object>
			<object name="tangentIn"><f32 name="x">0</f32><f32 name="y">0</f32></object><object name="tangentOut"><f32 name="x">0</f32><f32 name="y">0</f32></object>
			<f32 name="time">1</f32><object name="value"><f32 name="x">1.4</f32><f32 name="y">1.4</f32></object>
			<object name="tangentIn"><f32 name="x">0</f32><f32 name="y">0</f32></object><object name="tangentOut"><f32 name="x">0</f32><f32 name="y">0</f32></object>
			</object></root>
			""", size));
		Test.Assert(!size.SeparateAxes);
		Test.Assert(size.Size.KeyCount == 2);
		Test.Assert(Near(size.Size.Keys[1].Value, 1.4f));
		Test.Assert(Near(size.Size.Evaluate(0.5f), 1.0f));
		Test.Assert(!size.SizeY.IsActive);
	}

	/// A binary reader says it has every key, so a binary payload always reads the new layout.
	[Test]
	public static void BinaryAlwaysReadsTheNewLayout()
	{
		let size = scope SizeOverLifetimeBehavior();
		size.Size = ParticleCurveFloat.Ease(0.5f, 2.0f);
		size.SeparateAxes = true;
		size.SizeY = ParticleCurveFloat.Linear(1.0f, 4.0f);

		let stream = scope MemoryStream();
		{
			let writer = scope BinarySerializer(stream, .Write);
			((ISerializable)size).Serialize(writer);
			Test.Assert(writer.IsOk);
		}
		stream.Seek(0, .Begin);
		let back = scope SizeOverLifetimeBehavior();
		let reader = scope BinarySerializer(stream, .Read);
		((ISerializable)back).Serialize(reader);
		Test.Assert(reader.IsOk);
		Test.Assert(back.SeparateAxes);
		Test.Assert(Near(back.SizeY.Evaluate(0.5f), 2.5f));
	}
}
