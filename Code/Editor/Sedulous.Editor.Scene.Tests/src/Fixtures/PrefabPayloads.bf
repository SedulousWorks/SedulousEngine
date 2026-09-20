using System;
using System.Collections;
using Sedulous.Core.IO;
using Sedulous.Scene;
using Sedulous.Scene.Resource;

namespace Sedulous.Editor.Scene.Tests;

static class PrefabPayloads
{
	/// Captures a one entity template with an optional health amount as prefab bytes. The
	/// caller owns the list.
	public static List<uint8> Capture(StringView name, int32? amount)
	{
		let author = scope Scene("author");
		let health = author.AddSystem<HealthManager>();
		let root = author.CreateEntity(name);
		if (amount.HasValue)
			health.Add(root).Amount = amount.Value;
		let payload = scope MemoryStream();
		Test.Assert(PrefabCapture.Capture(author, root, payload, .Binary) case .Ok);
		let bytes = new List<uint8>();
		bytes.AddRange(payload.Bytes);
		return bytes;
	}
}
