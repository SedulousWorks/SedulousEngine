using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.GUI;
using Sedulous.Editor.App;

namespace Sedulous.Editor.App.Tests;

/// The code languages: each of the shared definitions (Data/Editor/Code) read by its id the first
/// time it is asked for and kept, one with no file none (and not read again).
class CodeLanguagesTests
{
	[Test]
	public static void EachSharedDefinitionReadByItsIdOnceAnUnknownOneNone()
	{
		let data = scope String();
		Test.Assert(EditorSplashTests.DataRoot(data));
		int reads = 0;
		let languages = scope CodeLanguages(new [&reads, =data] (path, outText) =>
			{
				reads++;
				return System.IO.File.ReadAllText(PathJoin(data, path, .. scope .()), outText) case .Ok;
			});
		for (let id in StringView[?]("angelscript", "luau", "hlsl", "xml", "css"))
		{
			let language = languages.Find(id);
			Test.Assert(language != null);
			Test.Assert(!language.Contexts.IsEmpty);
			Test.Assert(languages.Find(id) === language, "kept: the same, not read again");
		}
		Test.Assert(reads == 5);
		Test.Assert(languages.Find("cobol") == null);
		Test.Assert(languages.Find("cobol") == null);
		Test.Assert(reads == 6, "a miss is kept too");
		Test.Assert(languages.Find("") == null);
	}
}
