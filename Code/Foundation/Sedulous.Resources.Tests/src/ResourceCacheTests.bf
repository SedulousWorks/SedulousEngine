using System;

namespace Sedulous.Resources.Tests;

class ResourceCacheTests
{
	[Test]
	public static void TestResourceCacheKey()
	{
		var key1 = ResourceCacheKey("test/path", typeof(TestResource));
		var key2 = ResourceCacheKey("test/path", typeof(TestResource));
		var key3 = ResourceCacheKey("other/path", typeof(TestResource));

		defer key1.Dispose();
		defer key2.Dispose();
		defer key3.Dispose();

		Test.Assert(key1 == key2);
		Test.Assert(key1 != key3);
		Test.Assert(key1.GetHashCode() == key2.GetHashCode());
	}

	[Test]
	public static void TestResourceCacheSetGet()
	{
		let cache = scope ResourceCache();

		let resource = new TestResource();
		resource.AddRef();
		defer resource.ReleaseRef();

		var handle = ResourceHandle<IResource>(resource);

		var key = ResourceCacheKey("test/path", typeof(TestResource));
		defer key.Dispose();
		cache.Set(key, handle);

		Test.Assert(cache.Count == 1);

		let retrieved = cache.Get(key);
		Test.Assert(retrieved.IsValid);
		Test.Assert(retrieved.Resource == resource);

		cache.Clear();
		Test.Assert(cache.Count == 0);

		handle.Release();
	}

	[Test]
	public static void TestResourceCacheRemove()
	{
		let cache = scope ResourceCache();

		let resource = new TestResource();
		resource.AddRef();
		defer resource.ReleaseRef();

		var handle = ResourceHandle<IResource>(resource);

		var key = ResourceCacheKey("test/path", typeof(TestResource));
		defer key.Dispose();
		cache.Set(key, handle);

		Test.Assert(cache.Count == 1);

		cache.Remove(key);
		Test.Assert(cache.Count == 0);

		let retrieved = cache.Get(key);
		Test.Assert(!retrieved.IsValid);

		handle.Release();
	}
}
