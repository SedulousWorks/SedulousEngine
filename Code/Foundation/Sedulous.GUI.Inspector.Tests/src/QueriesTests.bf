using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.GUI;
using Sedulous.GUI.Inspector;

namespace Sedulous.GUI.Inspector.Tests;

/// The queries: the tree in order with depths and labels, a node described, a selector query, a
/// property set through markup's path, what a screen reader is told.
class QueriesTests
{
	/// A root holding a panel (#page) with a button (#ok .primary) and a hidden label.
	private class Bed
	{
		public SceneRoot Root;
		public Panel Page = new .();
		public Button Ok = new .();
		public Sedulous.GUI.Label Note = new .();

		public this()
		{
			let context = new GUIContext();
			Root = new SceneRoot(context);
			context.ReleaseRef(); // the root's keeps it
			Root.Size = .(300.0f, 200.0f);
			Page.Id = "page";
			Root.AddChild(Page);
			Ok.Id = "ok";
			Ok.AddClass("primary");
			Ok.Text = "OK";
			Page.AddChild(Ok);
			Note.Visible = false;
			Page.AddChild(Note);
			Root.UpdateLayout();
		}

		public ~this()
		{
			Note.ReleaseRef();
			Ok.ReleaseRef();
			Page.ReleaseRef();
			Root.ReleaseRef();
		}
	}

	[Test]
	public static void TheTreeComesInDocumentOrderWithDepthsLabelsAndWhatShows()
	{
		let bed = scope Bed();
		let tree = scope List<TreeEntry>();
		defer { ClearAndDeleteItems!(tree); }
		Tree(bed.Root, tree);
		Test.Assert(tree.Count >= 4); // the root, the page, the button (and its parts), the label
		Test.Assert(tree[0].Target == bed.Root);
		Test.Assert(tree[0].Depth == 0);
		Test.Assert(tree[1].Target == bed.Page);
		Test.Assert(tree[1].Depth == 1);
		Test.Assert(tree[1].Label == "Panel #page");
		Test.Assert(tree[2].Target == bed.Ok);
		Test.Assert(tree[2].Depth == 2);
		Test.Assert(tree[2].Label == "Button #ok .primary");
		bool sawNote = false;
		for (let e in tree)
		{
			if (e.Target == bed.Note)
			{
				sawNote = true;
				Test.Assert(!e.Shown);
			}
		}
		Test.Assert(sawNote);
	}

	[Test]
	public static void ANodeDescribedIdentityStatesForcedOnesMarkedBoxReflectedPropertiesCommandsAndListeners()
	{
		let bed = scope Bed();
		bed.Ok.ForcedStyleStates = Node.StateHover;
		bed.Ok.Padding = Thickness(3.0f);
		bed.Ok.OnCommand("demo.go", new (command) => { });
		bed.Ok.AddEventListener(.MouseClick, new (e) => { });
		let d = scope NodeDescription();
		Describe(bed.Ok, d);
		Test.Assert(d.Type == "Button");
		Test.Assert(d.Tag == "button");
		Test.Assert(d.Id == "ok");
		Test.Assert(d.Classes.Count == 1);
		Test.Assert(d.Classes[0] == "primary");
		Test.Assert(d.States.Count == 1);
		Test.Assert(d.States[0] == "hover (forced)");
		Test.Assert(Math.Abs(d.Padding.Left - 3.0f) < 1e-5f);
		Test.Assert(d.Shown);
		Test.Assert(d.Commands.Count == 1);
		Test.Assert(d.Commands[0] == "demo.go");
		Test.Assert(d.Listeners.Count == 1);
		Test.Assert(d.Listeners[0] == "click");
		bool sawText = false;
		for (let p in d.Properties)
		{
			if (p.Name == "Text") // the property's own name, as the GUI's reflection gives it
			{
				sawText = true;
				Test.Assert(p.Value == "OK");
			}
		}
		Test.Assert(sawText);
	}

	[Test]
	public static void ASelectorQueryFindsTheWidgetsItMatchesInOrder()
	{
		let bed = scope Bed();
		let buttons = scope List<Node>();
		Query(bed.Root, "#page > .primary", buttons);
		Test.Assert(buttons.Count == 1);
		Test.Assert(buttons[0] == bed.Ok);
		let labels = scope List<Node>();
		Query(bed.Root, "label", labels);
		Test.Assert(labels.Count >= 1);
		let none = scope List<Node>();
		Query(bed.Root, ".nothing", none);
		Test.Assert(none.IsEmpty);
	}

	[Test]
	public static void APropertySetAsMarkupSetsItTheWidgetsOwnAttributeElseInlineStyle()
	{
		let bed = scope Bed();
		Test.Assert(SetProperty(bed.Ok, "text", "Go"));
		Test.Assert(bed.Ok.Text == "Go");
		Test.Assert(SetProperty(bed.Ok, "opacity", "0.5"));
		bool inlineSet = false;
		for (let d in bed.Ok.InlineStyle)
			inlineSet = inlineSet || ((d.Name == "opacity") && (d.Value == "0.5"));
		Test.Assert(inlineSet);
		Test.Assert(!SetProperty(bed.Ok, "no-such-property", "1"));
		Test.Assert(!SetProperty(bed.Root, "opacity", "1")); // no widget
	}

	[Test]
	public static void WhatAScreenReaderIsToldOfANodeAndWhatInTheGUIItWouldTripOn()
	{
		let bed = scope Bed();
		let ok = scope AccessDescription();
		DescribeAccess(bed.Ok, ok);
		Test.Assert(ok.Own);
		Test.Assert(ok.Role == "button");
		Test.Assert(ok.Name == "OK");
		bool activates = false;
		for (let a in ok.Actions)
			activates = activates || (a == "activate");
		Test.Assert(activates);
		let page = scope AccessDescription();
		DescribeAccess(bed.Page, page);
		Test.Assert(!page.Own); // a panel has no role: what it holds is the window's
		Test.Assert(page.ReadAs.Length != 0);
		let note = scope AccessDescription();
		DescribeAccess(bed.Note, note);
		Test.Assert(!note.Own); // hidden

		let clean = scope List<AccessIssue>();
		defer { ClearAndDeleteItems!(clean); }
		AuditAccess(bed.Root, clean);
		Test.Assert(clean.IsEmpty);
		let unnamed = new Button();
		defer unnamed.ReleaseRef();
		bed.Page.AddChild(unnamed);
		bed.Ok.AccessLabelledBy = "nowhere";
		let issues = scope List<AccessIssue>();
		defer { ClearAndDeleteItems!(issues); }
		AuditAccess(bed.Root, issues);
		Test.Assert(issues.Count == 2);
		Test.Assert(issues[0].Target == bed.Ok);
		Test.Assert(issues[0].Message == "aria-labelledby names no widget: #nowhere");
		Test.Assert(issues[1].Target == unnamed);
		Test.Assert(issues[1].Message == "a focusable button with no name");
	}

	// --- Further behaviour ---

	[Test]
	public static void AHiddenNodesDescendantsDoNotShowInTheTreeThoughTheyAreVisibleThemselves()
	{
		let bed = scope Bed();
		let held = new Panel();
		defer held.ReleaseRef();
		bed.Page.AddChild(held);
		let inner = new Panel();
		defer inner.ReleaseRef();
		held.AddChild(inner);
		held.Displayed = false;
		let tree = scope List<TreeEntry>();
		defer { ClearAndDeleteItems!(tree); }
		Tree(bed.Root, tree);
		bool sawInner = false;
		for (let e in tree)
		{
			if (e.Target == inner)
			{
				sawInner = true;
				Test.Assert(!e.Shown);
				Test.Assert(e.Depth == 3);
				Test.Assert(e.Label == "Panel"); // no id, no classes
			}
			if (e.Target == bed.Page)
				Test.Assert(e.Shown);
		}
		Test.Assert(sawInner);
	}

	[Test]
	public static void ANodeThatIsNoWidgetIsDescribedByItsTypeAloneAndAWidgetsStatesAreItsOwnWhenNotForced()
	{
		let bed = scope Bed();
		let plain = new Node();
		defer plain.ReleaseRef();
		bed.Page.AddChild(plain);
		let d = scope NodeDescription();
		Describe(plain, d);
		Test.Assert(d.Type == "Node");
		Test.Assert(d.Tag.IsEmpty);
		Test.Assert(d.Id.IsEmpty);
		Test.Assert(d.States.IsEmpty);

		// Disabled and forced disabled: listed once, not marked forced.
		bed.Ok.Enabled = false;
		bed.Ok.ForcedStyleStates = Node.StateDisabled;
		let ok = scope NodeDescription();
		Describe(bed.Ok, ok);
		Test.Assert(ok.States.Count == 1);
		Test.Assert(ok.States[0] == "disabled");
		Test.Assert(!ok.Enabled);
	}

	[Test]
	public static void AReflectedPropertyCarriesItsCssNameAndAPropertySetByItsOwnNameGoesInlineByItsCssName()
	{
		let bed = scope Bed();
		let d = scope NodeDescription();
		Describe(bed.Ok, d);
		bool sawTabIndex = false;
		for (let p in d.Properties)
		{
			if (p.Name == "TabIndex")
			{
				sawTabIndex = true;
				Test.Assert(p.CssName == "tab-index");
				Test.Assert(p.Value == "0");
				Test.Assert(!p.ReadOnly);
			}
		}
		Test.Assert(sawTabIndex);
		Test.Assert(SetProperty(bed.Ok, "tabIndex", "2"));
		bool inlineSet = false;
		for (let decl in bed.Ok.InlineStyle)
			inlineSet = inlineSet || ((decl.Name == "tab-index") && (decl.Value == "2"));
		Test.Assert(inlineSet);
	}

	[Test]
	public static void AnEmptySelectorMatchesNothing()
	{
		let bed = scope Bed();
		let found = scope List<Node>();
		Query(bed.Root, "", found);
		Test.Assert(found.IsEmpty);
	}

	[Test]
	public static void AnAriaRelationNamingSeveralIdsReportsEachMissingOne()
	{
		let bed = scope Bed();
		bed.Ok.AccessDescribedBy = "page  gone";
		let issues = scope List<AccessIssue>();
		defer { ClearAndDeleteItems!(issues); }
		AuditAccess(bed.Root, issues);
		Test.Assert(issues.Count == 1);
		Test.Assert(issues[0].Target == bed.Ok);
		Test.Assert(issues[0].Message == "aria-describedby names no widget: #gone");
	}
}
