using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.GUI;
using Sedulous.Xml;
using Sedulous.Xml.Serialization;
using static Sedulous.GUI.Docking.Tests.DockingFixtures;

namespace Sedulous.GUI.Docking.Tests;

/// A dock layout saved and restored (D2 of Specs/gui-lab-evolution-3.md): through the engine's
/// text serializer and back whole; another version refused; a broken layout refused and the
/// current one left as it was; panels not registered kept as placeholders, registered ones not
/// named put at their default place; a floating window off every screen brought back onto one.
class DockDocumentTests
{
	private static void Save(DockLayoutDocument document, String outText)
	{
		let writer = scope XmlSerializer();
		document.Serialize(writer);
		Test.Assert(writer.IsOk);
		writer.GetOutput(outText);
	}

	// The text read into `@out`; whether it read.
	private static bool Load(StringView text, DockLayoutDocument @out)
	{
		let doc = scope XmlDocument();
		if (doc.Parse(text) != .Ok)
			return false;
		let reader = scope XmlSerializer(doc);
		@out.Serialize(reader);
		return reader.IsOk;
	}

	// `text` with each `from` made `to`, into `outText`; how many there were.
	private static int Replaced(StringView text, StringView from, StringView to, String outText)
	{
		int found = 0;
		int i = 0;
		while (i < text.Length)
		{
			if ((i + from.Length <= text.Length) && (text.Substring(i, from.Length) == from))
			{
				outText.Append(to);
				i += from.Length;
				++found;
			}
			else
				outText.Append(text[i++]);
		}
		return found;
	}

	private static void Sample(DockLayout layout)
	{
		let central = layout.CentralStack;
		Test.Assert(layout.InsertTab("scene", central).Ok);
		Test.Assert(layout.InsertBeside("hierarchy", central, .Start, 0.2f).Ok);
		Test.Assert(layout.InsertAtEdge("console", layout.MainSurface, .Bottom, 0.3f).Ok);
		Test.Assert(layout.InsertTab("log", layout.StackOf("console")).Ok);
		Test.Assert(layout.Float("profiler", .(1500.0f, 200.0f, 500.0f, 400.0f)).Ok);
		Test.Assert(layout.InsertBeside("inspector", central, .End).Ok);
		Test.Assert(layout.Close("inspector").Ok);
	}

	[Test]
	public static void ALayoutThroughTextAndBackWhole()
	{
		let saved = scope DockLayoutDocument();
		Sample(saved.Layout);
		let text = scope String();
		Save(saved, text);
		let loaded = scope DockLayoutDocument();
		Test.Assert(Load(text, loaded));
		let l = loaded.Layout;
		let why = scope String();
		Test.Assert(l.CheckInvariants(why), why);
		Test.Assert(l.Surfaces.Count == 2);
		Test.Assert(l.StackOf("log") == l.StackOf("console"));
		Test.Assert(l.FindNode(l.StackOf("console")).Active == 1);
		Test.Assert(l.FindHidden("inspector") != null);
		Test.Assert(Near(l.FindSurface(l.SurfaceOf(l.StackOf("profiler"))).Bounds.X, 1500.0f));
		let again = scope String();
		Save(loaded, again);
		Test.Assert(again == text); // nothing lost or changed on the way
		// Operations go on from where it was: new ids do not collide.
		let copy = scope DockLayout();
		copy.Set(l);
		Test.Assert(copy.InsertTab("assets", copy.StackOf("hierarchy")).Ok);
		Test.Assert(copy.CheckInvariants(why), why);
	}

	[Test]
	public static void ALayoutOfAnotherVersionIsRefused()
	{
		let saved = scope DockLayoutDocument();
		Sample(saved.Layout);
		let text = scope String();
		Save(saved, text);
		let stale = scope String();
		let found = Replaced(text, "<u32 name=\"version\">1</u32>", "<u32 name=\"version\">2</u32>", stale);
		Test.Assert(found == 1); // the document's version, stored once
		let loaded = scope DockLayoutDocument();
		Test.Assert(!Load(stale, loaded));
	}

	[Test]
	public static void ABrokenLayoutIsRefusedAndTheCurrentOneStays()
	{
		let current = scope DockLayout();
		Sample(current);
		let saved = scope DockLayoutDocument();
		saved.Layout.Set(current);
		let was = scope String();
		Save(saved, was);
		// A panel docked in two stacks in the text.
		let broken = scope String();
		let found = Replaced(was, "<string>hierarchy</string>", "<string>scene</string>", broken);
		Test.Assert(found >= 1); // its stack's, and a closed panel's neighbour
		let read = scope DockLayoutDocument();
		Test.Assert(Load(broken, read)); // it reads, but does not hold together
		let adopted = current.Adopt(read.Layout, default);
		Test.Assert(!adopted.Ok);
		Test.Assert(adopted.Refused == "a panel docked twice");
		saved.Layout.Set(current);
		let after = scope String();
		Save(saved, after);
		Test.Assert(after == was); // unchanged
		// Ids past the next one made (a file edited by hand): a new node would collide.
		let behind = scope String();
		Test.Assert(Replaced(was, "<u32 name=\"nextNode\">8</u32>", "<u32 name=\"nextNode\">3</u32>", behind) == 1);
		Test.Assert(Load(behind, read));
		Test.Assert(current.Adopt(read.Layout, default).Refused == "a node's id past the next one made");
	}

	[Test]
	public static void PlaceholdersKeptRegisteredPanelsItDoesNotNameAtTheirDefaultPlaceFloatsBroughtOnScreen()
	{
		let saved = scope DockLayoutDocument();
		Sample(saved.Layout);
		let text = scope String();
		Save(saved, text);
		let read = scope DockLayoutDocument();
		Test.Assert(Load(text, read));
		let layout = scope DockLayout();
		DockDefault[3] known = .(
			.("scene", true, .End, 0.25f), // named: stays where it is
			.("assets", false, .Bottom, 0.25f), // not named: at the bottom
			.("documents", true, .End, 0.25f)); // not named: a central tab
		Rectangle[1] screens = .(.(0.0f, 0.0f, 1280.0f, 720.0f));
		Test.Assert(layout.Adopt(read.Layout, known, screens).Ok);
		Test.Assert(layout.StackOf("hierarchy") != cNoDock); // not registered: kept, a placeholder
		Test.Assert(layout.StackOf("documents") == layout.CentralStack);
		let assets = layout.StackOf("assets");
		Test.Assert(assets != cNoDock);
		Test.Assert(layout.FindNode(layout.FindSurface(layout.MainSurface).Root).Children.Back == assets); // along the bottom
		Test.Assert(layout.FindHidden("inspector") != null); // closed stays closed
		// The profiler floated at 1500 across, off the one screen: back on it.
		let floating = layout.FindSurface(layout.SurfaceOf(layout.StackOf("profiler")));
		Test.Assert(floating != null);
		Test.Assert(floating.Bounds.X + floating.Bounds.Width <= 1280.0f);
		Test.Assert(Near(floating.Bounds.Width, 500.0f));
		let why = scope String();
		Test.Assert(layout.CheckInvariants(why), why);
	}

	/// A document read into one that holds a layout already ends holding the one read, whole: what
	/// it held before goes (no surface, node or closed panel of it is left over).
	[Test]
	public static void AReadIntoADocumentHoldingALayoutReplacesItWhole()
	{
		let saved = scope DockLayoutDocument();
		Sample(saved.Layout);
		let text = scope String();
		Save(saved, text);
		let reused = scope DockLayoutDocument();
		let had = reused.Layout;
		Test.Assert(had.InsertTab("left over", had.CentralStack).Ok);
		Test.Assert(had.Float("stray", .(10.0f, 10.0f, 200.0f, 100.0f)).Ok);
		Test.Assert(had.Float("gone", .(20.0f, 20.0f, 200.0f, 100.0f)).Ok);
		Test.Assert(had.Close("gone").Ok);
		Test.Assert(Load(text, reused));
		let l = reused.Layout;
		Test.Assert(l.StackOf("left over") == cNoDock);
		Test.Assert(l.StackOf("stray") == cNoDock);
		Test.Assert(l.FindHidden("gone") == null);
		Test.Assert(l.Surfaces.Count == 2);
		Test.Assert(l.Hidden.Count == 1);
		let why = scope String();
		Test.Assert(l.CheckInvariants(why), why);
		let again = scope String();
		Save(reused, again);
		Test.Assert(again == text);
	}
}
