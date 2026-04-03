namespace Sedulous.Animation.Tests;

using System;
using System.Collections;

class AnimationEventTests
{
	// ==================== AnimationEvent class ====================

	[Test]
	public static void Constructor_SetsTimeAndName()
	{
		let evt = scope AnimationEvent(0.5f, "Footstep");
		Test.Assert(evt.Time == 0.5f);
		Test.Assert(evt.Name.Equals("Footstep"));
	}

	[Test]
	public static void Name_IsOwnedCopy()
	{
		let original = scope String("TestEvent");
		let evt = scope AnimationEvent(1.0f, original);
		Test.Assert(evt.Name.Equals("TestEvent"));
		Test.Assert(evt.Name.Ptr != original.Ptr);
	}

	// ==================== AnimationClip event storage ====================

	[Test]
	public static void AddEvent_IncreasesCount()
	{
		let clip = scope AnimationClip("Test", 2.0f);
		Test.Assert(clip.Events.Count == 0);
		clip.AddEvent(0.5f, "Hit");
		Test.Assert(clip.Events.Count == 1);
		clip.AddEvent(1.0f, "Sound");
		Test.Assert(clip.Events.Count == 2);
	}

	[Test]
	public static void SortEvents_SortsByTime()
	{
		let clip = scope AnimationClip("Test", 2.0f);
		clip.AddEvent(1.5f, "C");
		clip.AddEvent(0.2f, "A");
		clip.AddEvent(0.8f, "B");
		clip.SortEvents();
		Test.Assert(clip.Events[0].Time == 0.2f);
		Test.Assert(clip.Events[1].Time == 0.8f);
		Test.Assert(clip.Events[2].Time == 1.5f);
		Test.Assert(clip.Events[0].Name.Equals("A"));
		Test.Assert(clip.Events[1].Name.Equals("B"));
		Test.Assert(clip.Events[2].Name.Equals("C"));
	}

	[Test]
	public static void AddEvent_MultipleEvents_StoredCorrectly()
	{
		let clip = scope AnimationClip("Test", 3.0f);
		clip.AddEvent(0.0f, "Start");
		clip.AddEvent(1.5f, "Middle");
		clip.AddEvent(3.0f, "End");
		Test.Assert(clip.Events.Count == 3);
		Test.Assert(clip.Events[0].Name.Equals("Start"));
		Test.Assert(clip.Events[1].Name.Equals("Middle"));
		Test.Assert(clip.Events[2].Name.Equals("End"));
	}

	// ==================== AnimationClip.FireEvents ====================

	[Test]
	public static void FireEvents_CrossesThreshold_Fires()
	{
		let clip = scope AnimationClip("Test", 2.0f);
		clip.AddEvent(0.5f, "Hit");
		int32 fireCount = 0;
		AnimationEventHandler handler = scope [&] (name, time) => { fireCount++; };
		clip.FireEvents(0.0f, 1.0f, handler);
		Test.Assert(fireCount == 1);
	}

	[Test]
	public static void FireEvents_BeforeThreshold_DoesNotFire()
	{
		let clip = scope AnimationClip("Test", 2.0f);
		clip.AddEvent(1.5f, "Hit");
		int32 fireCount = 0;
		AnimationEventHandler handler = scope [&] (name, time) => { fireCount++; };
		clip.FireEvents(0.0f, 1.0f, handler);
		Test.Assert(fireCount == 0);
	}

	[Test]
	public static void FireEvents_MultipleEvents_FireInOrder()
	{
		let clip = scope AnimationClip("Test", 2.0f);
		clip.AddEvent(0.3f, "A");
		clip.AddEvent(0.7f, "B");
		clip.AddEvent(1.2f, "C");
		clip.SortEvents();
		let firedNames = scope List<String>();
		AnimationEventHandler handler = scope [&] (name, time) => { firedNames.Add(new String(name)); };
		clip.FireEvents(0.0f, 1.5f, handler);
		Test.Assert(firedNames.Count == 3);
		Test.Assert(firedNames[0].Equals("A"));
		Test.Assert(firedNames[1].Equals("B"));
		Test.Assert(firedNames[2].Equals("C"));
		for (let s in firedNames) delete s;
	}

	[Test]
	public static void FireEvents_LoopWrap_FiresEventsAfterWrap()
	{
		let clip = scope AnimationClip("Test", 1.0f, true);
		clip.AddEvent(0.2f, "Early");
		clip.AddEvent(0.8f, "Late");
		clip.SortEvents();
		let firedNames = scope List<String>();
		AnimationEventHandler handler = scope [&] (name, time) => { firedNames.Add(new String(name)); };
		clip.FireEvents(0.9f, 1.3f, handler);
		Test.Assert(firedNames.Count == 1);
		Test.Assert(firedNames[0].Equals("Early"));
		for (let s in firedNames) delete s;
	}

	[Test]
	public static void FireEvents_NonLooping_PastDuration_FiresUpToDuration()
	{
		let clip = scope AnimationClip("Test", 1.0f, false);
		clip.AddEvent(0.8f, "NearEnd");
		clip.AddEvent(1.0f, "AtEnd");
		clip.SortEvents();
		int32 fireCount = 0;
		AnimationEventHandler handler = scope [&] (name, time) => { fireCount++; };
		clip.FireEvents(0.5f, 1.5f, handler);
		Test.Assert(fireCount == 2);
	}

	[Test]
	public static void FireEvents_NullHandler_DoesNotCrash()
	{
		let clip = scope AnimationClip("Test", 1.0f);
		clip.AddEvent(0.5f, "Hit");
		clip.FireEvents(0.0f, 1.0f, null);
	}

	[Test]
	public static void FireEvents_NoEvents_DoesNotCrash()
	{
		let clip = scope AnimationClip("Test", 1.0f);
		int32 fireCount = 0;
		AnimationEventHandler handler = scope [&] (name, time) => { fireCount++; };
		clip.FireEvents(0.0f, 1.0f, handler);
		Test.Assert(fireCount == 0);
	}

	[Test]
	public static void FireEvents_EventAtZero_Behavior()
	{
		let clip = scope AnimationClip("Test", 1.0f);
		clip.AddEvent(0.0f, "Start");
		int32 fireCount = 0;
		AnimationEventHandler handler = scope [&] (name, time) => { fireCount++; };
		// (prevTime, currentTime] exclusive on left: event at 0.0 NOT > 0.0
		clip.FireEvents(0.0f, 0.1f, handler);
		Test.Assert(fireCount == 0);
		// After loop wrap, [0, wrappedTime] is inclusive on left
		let clip2 = scope AnimationClip("Test2", 1.0f, true);
		clip2.AddEvent(0.0f, "Start");
		clip2.FireEvents(0.9f, 1.1f, handler);
		Test.Assert(fireCount == 1);
	}

	[Test]
	public static void FireEvents_ExactTime_Fires()
	{
		let clip = scope AnimationClip("Test", 1.0f);
		clip.AddEvent(0.5f, "Exact");
		int32 fireCount = 0;
		AnimationEventHandler handler = scope [&] (name, time) => { fireCount++; };
		clip.FireEvents(0.3f, 0.5f, handler);
		Test.Assert(fireCount == 1);
	}

	// ==================== AnimationPlayer integration ====================

	[Test]
	public static void Player_SetEventHandler_SetsHandler()
	{
		let skeleton = new Skeleton(2);
		defer delete skeleton;
		let player = scope AnimationPlayer(skeleton);
		int32 fireCount = 0;
		player.SetEventHandler(new [&] (name, time) => { fireCount++; });
		let clip = new AnimationClip("Test", 1.0f);
		defer delete clip;
		clip.AddEvent(0.5f, "Hit");
		player.Play(clip);
		player.Update(0.6f);
		Test.Assert(fireCount == 1);
	}

	[Test]
	public static void Player_Update_EventFires_WhenTimeCrosses()
	{
		let skeleton = new Skeleton(2);
		defer delete skeleton;
		let player = scope AnimationPlayer(skeleton);
		let firedNames = scope List<String>();
		player.SetEventHandler(new [&] (name, time) => { firedNames.Add(new String(name)); });
		let clip = new AnimationClip("Test", 2.0f);
		defer delete clip;
		clip.AddEvent(0.3f, "A");
		clip.AddEvent(0.8f, "B");
		clip.AddEvent(1.5f, "C");
		clip.SortEvents();
		player.Play(clip);
		player.Update(0.5f);
		Test.Assert(firedNames.Count == 1);
		Test.Assert(firedNames[0].Equals("A"));
		player.Update(0.5f);
		Test.Assert(firedNames.Count == 2);
		Test.Assert(firedNames[1].Equals("B"));
		player.Update(0.5f);
		Test.Assert(firedNames.Count == 3);
		Test.Assert(firedNames[2].Equals("C"));
		for (let s in firedNames) delete s;
	}

	[Test]
	public static void Player_Update_LoopingClip_EventFiresEachLoop()
	{
		let skeleton = new Skeleton(2);
		defer delete skeleton;
		let player = scope AnimationPlayer(skeleton);
		int32 fireCount = 0;
		player.SetEventHandler(new [&] (name, time) => { fireCount++; });
		let clip = new AnimationClip("Test", 1.0f, true);
		defer delete clip;
		clip.AddEvent(0.5f, "Hit");
		player.Play(clip);
		player.Update(0.8f);
		Test.Assert(fireCount == 1);
		player.Update(0.8f);
		Test.Assert(fireCount == 2);
	}

	[Test]
	public static void Player_SetEventHandler_ReplacesOld()
	{
		let skeleton = new Skeleton(2);
		defer delete skeleton;
		let player = scope AnimationPlayer(skeleton);
		int32 count1 = 0;
		int32 count2 = 0;
		player.SetEventHandler(new [&] (name, time) => { count1++; });
		let clip = new AnimationClip("Test", 1.0f);
		defer delete clip;
		clip.AddEvent(0.5f, "Hit");
		player.Play(clip);
		player.Update(0.6f);
		Test.Assert(count1 == 1);
		Test.Assert(count2 == 0);
		player.SetEventHandler(new [&] (name, time) => { count2++; });
		player.Play(clip);
		player.Update(0.6f);
		Test.Assert(count1 == 1);
		Test.Assert(count2 == 1);
	}

	// ==================== IAnimationStateNode.FireEvents ====================

	[Test]
	public static void ClipStateNode_FireEvents_ConvertsNormalizedToAbsolute()
	{
		let clip = new AnimationClip("Test", 2.0f);
		defer delete clip;
		clip.AddEvent(1.0f, "Midpoint");
		let node = scope ClipStateNode(clip);
		int32 fireCount = 0;
		float firedTime = 0;
		AnimationEventHandler handler = scope [&] (name, time) => { fireCount++; firedTime = time; };
		node.FireEvents(0.0f, 0.6f, true, handler);
		Test.Assert(fireCount == 1);
		Test.Assert(firedTime == 1.0f);
	}

	[Test]
	public static void ClipStateNode_FireEvents_LoopWrap_DetectsWrap()
	{
		let clip = new AnimationClip("Test", 1.0f);
		defer delete clip;
		clip.AddEvent(0.2f, "Early");
		let node = scope ClipStateNode(clip);
		int32 fireCount = 0;
		AnimationEventHandler handler = scope [&] (name, time) => { fireCount++; };
		node.FireEvents(0.9f, 0.3f, true, handler);
		Test.Assert(fireCount == 1);
	}

	[Test]
	public static void BlendTree1D_FireEvents_NoOp()
	{
		let tree = scope BlendTree1D();
		let clip = new AnimationClip("Test", 1.0f);
		defer delete clip;
		clip.AddEvent(0.5f, "Hit");
		tree.AddEntry(0.0f, clip);
		int32 fireCount = 0;
		AnimationEventHandler handler = scope [&] (name, time) => { fireCount++; };
		tree.FireEvents(0.0f, 1.0f, true, handler);
		Test.Assert(fireCount == 0);
	}
}
