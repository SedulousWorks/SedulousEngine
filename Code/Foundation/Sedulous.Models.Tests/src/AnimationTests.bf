using System;
using Sedulous.Models;
using Sedulous.Core.Mathematics;

namespace Sedulous.Models.Tests;

class AnimationTests
{
	[Test]
	public static void TestAnimationChannelCreation()
	{
		let channel = new AnimationChannel();
		defer delete channel;

		channel.TargetBone = 5;
		channel.Path = .Translation;
		channel.Interpolation = .Linear;

		Test.Assert(channel.TargetBone == 5);
		Test.Assert(channel.Path == .Translation);
	}

	[Test]
	public static void TestAnimationKeyframes()
	{
		let channel = new AnimationChannel();
		defer delete channel;

		channel.Path = .Translation;
		channel.AddKeyframe(0.0f, .(0, 0, 0, 0));
		channel.AddKeyframe(1.0f, .(10, 0, 0, 0));

		Test.Assert(channel.Keyframes.Count == 2);
	}

	[Test]
	public static void TestAnimationSampleLinear()
	{
		let channel = new AnimationChannel();
		defer delete channel;

		channel.Path = .Translation;
		channel.Interpolation = .Linear;
		channel.AddKeyframe(0.0f, .(0, 0, 0, 0));
		channel.AddKeyframe(1.0f, .(10, 0, 0, 0));

		let sample = channel.Sample(0.5f);
		Test.Assert(Math.Abs(sample.X - 5.0f) < 0.001f);
	}

	[Test]
	public static void TestAnimationSampleStep()
	{
		let channel = new AnimationChannel();
		defer delete channel;

		channel.Path = .Translation;
		channel.Interpolation = .Step;
		channel.AddKeyframe(0.0f, .(0, 0, 0, 0));
		channel.AddKeyframe(1.0f, .(10, 0, 0, 0));

		let sample = channel.Sample(0.5f);
		Test.Assert(sample.X == 0.0f);
	}

	[Test]
	public static void TestModelAnimation()
	{
		let animation = new ModelAnimation();
		defer delete animation;

		animation.SetName("Walk");

		let channel = new AnimationChannel();
		channel.Path = .Translation;
		channel.AddKeyframe(0.0f, .(0, 0, 0, 0));
		channel.AddKeyframe(2.0f, .(10, 0, 0, 0));

		animation.AddChannel(channel);
		animation.CalculateDuration();

		Test.Assert(animation.Name == "Walk");
		Test.Assert(animation.Channels.Count == 1);
		Test.Assert(animation.Duration == 2.0f);
	}

	[Test]
	public static void TestAnimationSampleBounds()
	{
		let channel = new AnimationChannel();
		defer delete channel;

		channel.Path = .Translation;
		channel.Interpolation = .Linear;
		channel.AddKeyframe(0.0f, .(0, 0, 0, 0));
		channel.AddKeyframe(1.0f, .(10, 0, 0, 0));

		// Before start
		let before = channel.Sample(-1.0f);
		Test.Assert(before.X == 0.0f);

		// After end
		let after = channel.Sample(2.0f);
		Test.Assert(after.X == 10.0f);
	}
}
