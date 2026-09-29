using System;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Settings;
using Sedulous.Xml.Serialization;

namespace Sedulous.Settings.Tests
{
	/// A section type that moved namespace: its identity is its full name, so what was saved
	/// under the old one has to be told where it lives now, or it loads as unknown.
	class RenameSectionTests
	{
		[Test]
		public static void ASectionSavedUnderAFormerNameLoadsAsItsNewType()
		{
			let factory = XmlSerializerFactory();
			defer delete factory;

			// Saved by a build where the type still lived in Before.
			let stored = scope MemoryStream();
			{
				let source = scope Settings();
				source.Section<Sedulous.Settings.Tests.Before.Recents>().Count = 4;
				Test.Assert(source.Save(stored, factory) case .Ok);
			}

			let former = typeof(Sedulous.Settings.Tests.Before.Recents).GetFullName(.. scope .());
			let current = typeof(Sedulous.Settings.Tests.After.Recents).GetFullName(.. scope .());
			let registry = scope SerializableRegistry();
			registry.Register(Sedulous.Settings.Tests.After.Recents.TypeId, () => new Sedulous.Settings.Tests.After.Recents());
			SerializableRenames.Register(former, current);

			// Loaded by a build where it lives in After: not unknown, and the data came across.
			let loaded = scope Settings();
			Test.Assert(stored.Seek(0, .Begin) == 0);
			Test.Assert(loaded.Load(stored, factory, registry) case .Ok);
			Test.Assert(loaded.UnknownSectionCount == 0);
			Test.Assert(loaded.Find<Sedulous.Settings.Tests.After.Recents>().Count == 4);

			// And it saves under the new name only.
			let resaved = scope MemoryStream();
			Test.Assert(loaded.Save(resaved, factory) case .Ok);
			let text = scope String();
			text.Append((char8*)resaved.Bytes.Ptr, resaved.Bytes.Length);
			Test.Assert(text.Contains(current));
			Test.Assert(!text.Contains(former));
		}
	}
}

namespace Sedulous.Settings.Tests.Before
{
	[Serializable(1)]
	class Recents
	{
		public int32 Count;
	}
}

namespace Sedulous.Settings.Tests.After
{
	[Serializable(1)]
	class Recents
	{
		public int32 Count;
	}
}
