using System;
using Sedulous.Engine.GUI;
using Sedulous.GUI.Resources;

namespace Sedulous.Engine.GUI.Tests;

/// The gui domain as the engine composition reads it.
class GuiDomainTests
{
	[Test]
	public static void TheDomainBringsTheDocumentsAndSheetsResourceModule()
	{
		let domain = GuiDomain.Module;
		Test.Assert(domain.Id == "gui");
		bool documents = false;
		for (let library in domain.Resources)
			documents = documents || (library === GuiResources.Module);
		Test.Assert(documents);
		Test.Assert(domain.HasScene, "its components");
	}
}
