using System;
using Sedulous.Audio;
using Sedulous.Audio.Resources;

namespace Sedulous.Audio.Tests;

class AudioClipResourceTests
{
	[Test]
	public static void TestResourceCreation()
	{
		let resource = scope AudioClipResource();

		Test.Assert(resource.Clip == null);
	}

	[Test]
	public static void TestResourceSetClip()
	{
		let resource = new AudioClipResource();
		defer delete resource;

		// Note: We can't easily create a mock clip without the audio system,
		// so we just verify the property works with null
		resource.Clip = null;

		Test.Assert(resource.Clip == null);
	}

	[Test]
	public static void TestResourceHasId()
	{
		let resource = scope AudioClipResource();

		// Resource should have a valid GUID
		Test.Assert(resource.Id != default);
	}

	[Test]
	public static void TestResourceName()
	{
		let resource = scope AudioClipResource();

		resource.Name = "TestClip";

		Test.Assert(resource.Name == "TestClip");
	}

	[Test]
	public static void TestResourceSerializationVersion()
	{
		let resource = scope AudioClipResource();

		Test.Assert(resource.SerializationVersion >= 1);
	}
}
