using System;
using Sedulous.Core.Mathematics;
using Sedulous.Drawing;

namespace Sedulous.Drawing.Tests;

class SpriteAnimationTests
{
	static MockTexture sTexture = new MockTexture(256, 256) ~ delete _;

	static Sprite MakeSprite(int x, int y)
	{
		return Sprite(sTexture, .(x, y, 32, 32));
	}

	[Test]
	public static void Constructor_SetsName()
	{
		let anim = scope SpriteAnimation("walk");

		Test.Assert(anim.Name == "walk");
	}

	[Test]
	public static void New_IsEmpty()
	{
		let anim = scope SpriteAnimation("test");

		Test.Assert(anim.FrameCount == 0);
		Test.Assert(anim.TotalDuration == 0);
	}

	[Test]
	public static void AddFrame_IncreasesFrameCount()
	{
		let anim = scope SpriteAnimation("test");
		anim.AddFrame(MakeSprite(0, 0), 0.1f);

		Test.Assert(anim.FrameCount == 1);
	}

	[Test]
	public static void AddFrame_UpdatesTotalDuration()
	{
		let anim = scope SpriteAnimation("test");
		anim.AddFrame(MakeSprite(0, 0), 0.1f);
		anim.AddFrame(MakeSprite(32, 0), 0.2f);

		Test.Assert(Math.Abs(anim.TotalDuration - 0.3f) < 0.001f);
	}

	[Test]
	public static void AddFrames_AddsMultipleFrames()
	{
		let anim = scope SpriteAnimation("test");
		Sprite[] sprites = scope .(MakeSprite(0, 0), MakeSprite(32, 0), MakeSprite(64, 0));
		anim.AddFrames(sprites, 0.1f);

		Test.Assert(anim.FrameCount == 3);
		Test.Assert(Math.Abs(anim.TotalDuration - 0.3f) < 0.001f);
	}

	[Test]
	public static void GetFrame_ReturnsCorrectFrame()
	{
		let anim = scope SpriteAnimation("test");
		anim.AddFrame(MakeSprite(0, 0), 0.1f);
		anim.AddFrame(MakeSprite(32, 0), 0.2f);

		let frame0 = anim.GetFrame(0);
		let frame1 = anim.GetFrame(1);

		Test.Assert(frame0.Sprite.SourceRect.X == 0);
		Test.Assert(frame0.Duration == 0.1f);
		Test.Assert(frame1.Sprite.SourceRect.X == 32);
		Test.Assert(frame1.Duration == 0.2f);
	}

	[Test]
	public static void GetSpriteAtTime_ReturnsFirstFrame_AtZero()
	{
		let anim = scope SpriteAnimation("test");
		anim.AddFrame(MakeSprite(0, 0), 0.1f);
		anim.AddFrame(MakeSprite(32, 0), 0.1f);

		let sprite = anim.GetSpriteAtTime(0);

		Test.Assert(sprite.SourceRect.X == 0);
	}

	[Test]
	public static void GetSpriteAtTime_ReturnsCorrectFrame_InMiddle()
	{
		let anim = scope SpriteAnimation("test");
		anim.AddFrame(MakeSprite(0, 0), 0.1f);
		anim.AddFrame(MakeSprite(32, 0), 0.1f);
		anim.AddFrame(MakeSprite(64, 0), 0.1f);

		let sprite = anim.GetSpriteAtTime(0.15f);

		Test.Assert(sprite.SourceRect.X == 32);
	}

	[Test]
	public static void GetSpriteAtTime_ReturnsLastFrame_AtEnd()
	{
		let anim = scope SpriteAnimation("test");
		anim.Looping = false;
		anim.AddFrame(MakeSprite(0, 0), 0.1f);
		anim.AddFrame(MakeSprite(32, 0), 0.1f);

		let sprite = anim.GetSpriteAtTime(0.5f);

		Test.Assert(sprite.SourceRect.X == 32);
	}

	[Test]
	public static void GetSpriteAtTime_Loops_WhenLoopingEnabled()
	{
		let anim = scope SpriteAnimation("test");
		anim.Looping = true;
		anim.AddFrame(MakeSprite(0, 0), 0.1f);
		anim.AddFrame(MakeSprite(32, 0), 0.1f);

		// At 0.25s with 0.2s total, loops to 0.05s (first frame)
		let sprite = anim.GetSpriteAtTime(0.25f);

		Test.Assert(sprite.SourceRect.X == 0);
	}

	[Test]
	public static void GetFrameIndexAtTime_ReturnsCorrectIndex()
	{
		let anim = scope SpriteAnimation("test");
		anim.AddFrame(MakeSprite(0, 0), 0.1f);
		anim.AddFrame(MakeSprite(32, 0), 0.1f);
		anim.AddFrame(MakeSprite(64, 0), 0.1f);

		Test.Assert(anim.GetFrameIndexAtTime(0) == 0);
		Test.Assert(anim.GetFrameIndexAtTime(0.05f) == 0);
		Test.Assert(anim.GetFrameIndexAtTime(0.1f) == 1);
		Test.Assert(anim.GetFrameIndexAtTime(0.15f) == 1);
		Test.Assert(anim.GetFrameIndexAtTime(0.25f) == 2);
	}

	[Test]
	public static void Looping_DefaultTrue()
	{
		let anim = scope SpriteAnimation("test");

		Test.Assert(anim.Looping == true);
	}

	[Test]
	public static void Looping_CanBeDisabled()
	{
		let anim = scope SpriteAnimation("test");
		anim.Looping = false;

		Test.Assert(anim.Looping == false);
	}

	[Test]
	public static void Clear_RemovesAllFrames()
	{
		let anim = scope SpriteAnimation("test");
		anim.AddFrame(MakeSprite(0, 0), 0.1f);
		anim.AddFrame(MakeSprite(32, 0), 0.1f);

		anim.Clear();

		Test.Assert(anim.FrameCount == 0);
		Test.Assert(anim.TotalDuration == 0);
	}
}

class AnimationPlayerTests
{
	static MockTexture sTexture = new MockTexture(256, 256) ~ delete _;

	static SpriteAnimation MakeAnimation()
	{
		let anim = new SpriteAnimation("test");
		anim.AddFrame(Sprite(sTexture, .(0, 0, 32, 32)), 0.1f);
		anim.AddFrame(Sprite(sTexture, .(32, 0, 32, 32)), 0.1f);
		anim.AddFrame(Sprite(sTexture, .(64, 0, 32, 32)), 0.1f);
		return anim;
	}

	[Test]
	public static void New_NotPlaying()
	{
		let player = AnimationPlayer();

		Test.Assert(!player.IsPlaying);
		Test.Assert(player.CurrentTime == 0);
		Test.Assert(player.Speed == 1.0f);
	}

	[Test]
	public static void Play_SetsIsPlayingTrue()
	{
		var player = AnimationPlayer();
		player.Play();

		Test.Assert(player.IsPlaying);
	}

	[Test]
	public static void Pause_SetsIsPlayingFalse()
	{
		var player = AnimationPlayer();
		player.Play();
		player.Pause();

		Test.Assert(!player.IsPlaying);
	}

	[Test]
	public static void Stop_ResetsTimeAndPauses()
	{
		var player = AnimationPlayer();
		player.Play();
		player.CurrentTime = 0.5f;
		player.Stop();

		Test.Assert(!player.IsPlaying);
		Test.Assert(player.CurrentTime == 0);
	}

	[Test]
	public static void Reset_ResetsTimeOnly()
	{
		var player = AnimationPlayer();
		player.Play();
		player.CurrentTime = 0.5f;
		player.Reset();

		Test.Assert(player.IsPlaying);
		Test.Assert(player.CurrentTime == 0);
	}

	[Test]
	public static void Update_AdvancesTime_WhenPlaying()
	{
		var player = AnimationPlayer();
		player.Play();
		player.Update(0.05f);

		Test.Assert(Math.Abs(player.CurrentTime - 0.05f) < 0.001f);
	}

	[Test]
	public static void Update_DoesNotAdvance_WhenPaused()
	{
		var player = AnimationPlayer();
		player.Update(0.05f);

		Test.Assert(player.CurrentTime == 0);
	}

	[Test]
	public static void Update_RespectsSpeed()
	{
		var player = AnimationPlayer();
		player.Play();
		player.Speed = 2.0f;
		player.Update(0.05f);

		Test.Assert(Math.Abs(player.CurrentTime - 0.1f) < 0.001f);
	}

	[Test]
	public static void GetCurrentSprite_ReturnsCorrectSprite()
	{
		let anim = MakeAnimation();
		defer delete anim;

		var player = AnimationPlayer();
		player.CurrentTime = 0.15f;

		let sprite = player.GetCurrentSprite(anim);

		Test.Assert(sprite.SourceRect.X == 32);
	}

	[Test]
	public static void GetCurrentFrameIndex_ReturnsCorrectIndex()
	{
		let anim = MakeAnimation();
		defer delete anim;

		var player = AnimationPlayer();
		player.CurrentTime = 0.15f;

		let index = player.GetCurrentFrameIndex(anim);

		Test.Assert(index == 1);
	}
}
