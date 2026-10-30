using System;
using Sedulous.Core;
using Sedulous.Json;
using Sedulous.Mcp;
using Sedulous.Editor.Mcp;
using static Sedulous.Integration.Mcp.McpCalls;

namespace Sedulous.Integration.Mcp;

/// gui_validate: a document that builds is valid with the asset guids it names; a document that does
/// not build is invalid with its error's level; a sheet always reads, its unknown property a warning
/// on its rule's line.
static class GuiValidateToolTests
{
	[Test]
	public static void ADocumentThatBuildsOneThatDoesNotASheetsWarning()
	{
		let server = scope McpServer();
		GuiValidateTool.Register(server);

		let good = CallOk(server, "gui_validate", With(With(Obj(), "kind", "document"), "source",
			"<Panel class=\"hud\">\n  <Image src=\"{0b9d6a52-1c1e-4e0f-9a43-7d2f61c0aa01}\"/>\n  <Label text=\"0\"/>\n</Panel>\n"));
		defer delete good;
		Test.Assert(good.Get("valid").AsBool(), scope $"{good.Get("diagnostics").ToString(.. scope .())}");
		Test.Assert(good.Get("references").Count == 1);
		Test.Assert(good.Get("references").At(0).AsString().IndexOf("0b9d6a52", true) >= 0);

		let broken = CallOk(server, "gui_validate", With(With(Obj(), "kind", "document"), "source", "<Panel>\n  <Label text=\"0\">\n</Panel\n"));
		defer delete broken;
		Test.Assert(!broken.Get("valid").AsBool());
		Test.Assert(broken.Get("diagnostics").Count > 0);
		Test.Assert(broken.Get("diagnostics").At(0).Get("level").AsString() == "error");

		// The name check reports the line of the rule holding the property.
		let sheet = CallOk(server, "gui_validate", With(With(Obj(), "kind", "sheet"), "source",
			".a { padding: 2px; }\n\n.hud { padding: 8px; not-a-property: 3; }\n"));
		defer delete sheet;
		Test.Assert(sheet.Get("valid").AsBool());
		Test.Assert(sheet.Get("diagnostics").Count > 0);
		let warning = sheet.Get("diagnostics").At(0);
		Test.Assert(warning.Get("level").AsString() == "warning");
		Test.Assert(warning.Get("line").AsNumber() == 3.0);
		Test.Assert(warning.Get("message").AsString().IndexOf("not-a-property", true) >= 0);
	}
}
