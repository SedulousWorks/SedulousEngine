using System;
using Sedulous.Core.Mathematics;

namespace Sedulous.GUI.Tests;

/// Phase 2 tests: ownership, hierarchy, input, and safety.
class Phase2Tests
{
	/// Simple test element.
	class TestElement : UIElement
	{
	}

	/// Simple test control that can be focused.
	class TestControl : Control
	{
		public this()
		{
			IsFocusable = true;
			IsTabStop = true;
		}
	}

	/// Test panel for container tests.
	class TestPanel : Panel
	{
	}

	// ========== Ownership Tests ==========

	[Test]
	public static void Container_AddChild_TransfersOwnership()
	{
		let ctx = scope GUIContext();
		let panel = new TestPanel();
		ctx.RootElement = panel;

		let child = new TestElement();
		panel.AddChild(child);

		Test.Assert(child.Parent == panel);
		Test.Assert(child.Context == ctx);
		Test.Assert(panel.ChildCount == 1);
		Test.Assert(panel.GetChild(0) == child);

		// Cleanup - panel destructor will delete children
		ctx.RootElement = null;
		delete panel;
	}

	[Test]
	public static void Container_RemoveChild_DeletesByDefault()
	{
		let ctx = scope GUIContext();
		let panel = new TestPanel();
		ctx.RootElement = panel;

		let child = new TestElement();
		panel.AddChild(child);
		Test.Assert(panel.ChildCount == 1);

		// Remove with delete (default)
		panel.RemoveChild(child, deleteAfterRemove: true);
		ctx.Update(0, 0);
		Test.Assert(panel.ChildCount == 0);
		// child is now deleted

		ctx.RootElement = null;
		delete panel;
	}

	[Test]
	public static void Container_RemoveChild_ReturnsOwnershipWhenNotDeleting()
	{
		let ctx = scope GUIContext();
		let panel = new TestPanel();
		ctx.RootElement = panel;

		let child = new TestElement();
		panel.AddChild(child);
		Test.Assert(child.Parent == panel);

		// Remove without delete
		panel.RemoveChild(child, deleteAfterRemove: false);
		Test.Assert(panel.ChildCount == 0);
		Test.Assert(child.Parent == null);
		Test.Assert(child.Context == null);

		// Caller now owns child
		delete child;

		ctx.RootElement = null;
		delete panel;
	}

	[Test]
	public static void Container_DetachChild_ReturnsOwnership()
	{
		let ctx = scope GUIContext();
		let panel = new TestPanel();
		ctx.RootElement = panel;

		let child = new TestElement();
		panel.AddChild(child);

		let detached = panel.DetachChild(0);
		Test.Assert(detached == child);
		Test.Assert(panel.ChildCount == 0);
		Test.Assert(child.Parent == null);

		// Caller owns detached element
		delete detached;

		ctx.RootElement = null;
		delete panel;
	}

	[Test]
	public static void Container_ClearChildren_DeletesAll()
	{
		let ctx = scope GUIContext();
		let panel = new TestPanel();
		ctx.RootElement = panel;

		panel.AddChild(new TestElement());
		panel.AddChild(new TestElement());
		panel.AddChild(new TestElement());
		Test.Assert(panel.ChildCount == 3);

		panel.ClearChildren(deleteAll: true);
		ctx.Update(0, 0);
		Test.Assert(panel.ChildCount == 0);

		ctx.RootElement = null;
		delete panel;
	}

	[Test]
	public static void ContentControl_SetContent_DeletesPrevious()
	{
		let ctx = scope GUIContext();
		let control = new ContentControl();
		ctx.RootElement = control;

		let content1 = new TestElement();
		control.Content = content1;
		Test.Assert(control.Content == content1);
		Test.Assert(content1.Parent == control);

		// Set new content - should delete old (deferred)
		let content2 = new TestElement();
		control.Content = content2;
		ctx.Update(0, 0);
		Test.Assert(control.Content == content2);
		// content1 is deleted

		ctx.RootElement = null;
		delete control;
	}

	[Test]
	public static void ContentControl_DetachContent_ReturnsOwnership()
	{
		let ctx = scope GUIContext();
		let control = new ContentControl();
		ctx.RootElement = control;

		let content = new TestElement();
		control.Content = content;

		let detached = control.DetachContent();
		Test.Assert(detached == content);
		Test.Assert(control.Content == null);
		Test.Assert(content.Parent == null);

		delete detached;

		ctx.RootElement = null;
		delete control;
	}

	[Test]
	public static void Decorator_SetChild_DeletesPrevious()
	{
		let ctx = scope GUIContext();
		let decorator = new Decorator();
		ctx.RootElement = decorator;

		let child1 = new TestElement();
		decorator.Child = child1;
		Test.Assert(decorator.Child == child1);

		// Set new child - should delete old (deferred)
		let child2 = new TestElement();
		decorator.Child = child2;
		ctx.Update(0, 0);
		Test.Assert(decorator.Child == child2);
		// child1 is deleted

		ctx.RootElement = null;
		delete decorator;
	}

	[Test]
	public static void Decorator_DetachChild_ReturnsOwnership()
	{
		let ctx = scope GUIContext();
		let decorator = new Decorator();
		ctx.RootElement = decorator;

		let child = new TestElement();
		decorator.Child = child;

		let detached = decorator.DetachChild();
		Test.Assert(detached == child);
		Test.Assert(decorator.Child == null);

		delete detached;

		ctx.RootElement = null;
		delete decorator;
	}

	// ========== Hierarchy Tests ==========

	[Test]
	public static void Hierarchy_ParentChildRelationships()
	{
		let ctx = scope GUIContext();
		let panel = new TestPanel();
		ctx.RootElement = panel;

		let child1 = new TestElement();
		let child2 = new TestElement();
		panel.AddChild(child1);
		panel.AddChild(child2);

		Test.Assert(child1.Parent == panel);
		Test.Assert(child2.Parent == panel);
		Test.Assert(panel.VisualChildCount == 2);
		Test.Assert(panel.GetVisualChild(0) == child1);
		Test.Assert(panel.GetVisualChild(1) == child2);

		ctx.RootElement = null;
		delete panel;
	}

	[Test]
	public static void Hierarchy_Reparenting()
	{
		let ctx = scope GUIContext();
		let panel1 = new TestPanel();
		let panel2 = new TestPanel();
		ctx.RootElement = panel1;
		panel1.AddChild(panel2);

		let child = new TestElement();
		panel1.AddChild(child);
		Test.Assert(child.Parent == panel1);
		Test.Assert(panel1.ChildCount == 2);

		// Reparent to panel2
		panel2.AddChild(child);  // This should detach from panel1 first
		Test.Assert(child.Parent == panel2);
		Test.Assert(panel1.ChildCount == 1);  // Only panel2 remains
		Test.Assert(panel2.ChildCount == 1);

		ctx.RootElement = null;
		delete panel1;
	}

	[Test]
	public static void Hierarchy_DetachFromParent()
	{
		let ctx = scope GUIContext();
		let panel = new TestPanel();
		ctx.RootElement = panel;

		let child = new TestElement();
		panel.AddChild(child);
		Test.Assert(child.Parent == panel);

		bool result = child.DetachFromParent();
		Test.Assert(result);
		Test.Assert(child.Parent == null);
		Test.Assert(panel.ChildCount == 0);

		delete child;  // Caller now owns

		ctx.RootElement = null;
		delete panel;
	}

	// ========== Input Tests ==========

	[Test]
	public static void Input_HitTest_ReturnsCorrectElement()
	{
		let ctx = scope GUIContext();
		let panel = new TestPanel();
		panel.Width = 400;
		panel.Height = 300;
		panel.HorizontalAlignment = .Left;  // Don't stretch to fill viewport
		panel.VerticalAlignment = .Top;
		ctx.RootElement = panel;

		// Use a non-stretch alignment so child keeps its size
		let child = new TestControl();
		child.Width = 100;
		child.Height = 50;
		child.HorizontalAlignment = .Left;
		child.VerticalAlignment = .Top;
		panel.AddChild(child);

		ctx.SetViewportSize(800, 600);
		ctx.Update(0, 0);

		// Hit test on child (should be at 0,0 with size 100x50)
		let hit1 = ctx.HitTest(50, 25);  // Inside child
		Test.Assert(hit1 == child);

		// Hit test on panel (outside child - child is 100x50 at origin)
		let hit2 = ctx.HitTest(200, 200);
		Test.Assert(hit2 == panel);

		// Hit test outside panel (panel is 400x300)
		let hit3 = ctx.HitTest(500, 500);
		Test.Assert(hit3 == null);

		ctx.RootElement = null;
		delete panel;
	}

	[Test]
	public static void Input_TabNavigation()
	{
		let ctx = scope GUIContext();
		let panel = new TestPanel();
		ctx.RootElement = panel;

		let ctrl1 = new TestControl();
		ctrl1.TabIndex = 0;
		let ctrl2 = new TestControl();
		ctrl2.TabIndex = 1;
		let ctrl3 = new TestControl();
		ctrl3.TabIndex = 2;

		panel.AddChild(ctrl1);
		panel.AddChild(ctrl2);
		panel.AddChild(ctrl3);

		ctx.SetViewportSize(800, 600);
		ctx.Update(0, 0);

		// No focus initially
		Test.Assert(ctx.FocusManager.FocusedElement == null);

		// Focus first
		ctx.FocusManager.FocusNext();
		Test.Assert(ctx.FocusManager.FocusedElement == ctrl1);

		// Tab to next
		ctx.FocusManager.FocusNext();
		Test.Assert(ctx.FocusManager.FocusedElement == ctrl2);

		// Tab to next
		ctx.FocusManager.FocusNext();
		Test.Assert(ctx.FocusManager.FocusedElement == ctrl3);

		// Wrap around
		ctx.FocusManager.FocusNext();
		Test.Assert(ctx.FocusManager.FocusedElement == ctrl1);

		// Shift+Tab (previous)
		ctx.FocusManager.FocusPrevious();
		Test.Assert(ctx.FocusManager.FocusedElement == ctrl3);

		ctx.RootElement = null;
		delete panel;
	}

	[Test]
	public static void Input_ClickToFocus()
	{
		let ctx = scope GUIContext();
		let panel = new TestPanel();
		panel.Width = 400;
		panel.Height = 300;
		ctx.RootElement = panel;

		let ctrl = new TestControl();
		ctrl.Width = 100;
		ctrl.Height = 50;
		panel.AddChild(ctrl);

		ctx.SetViewportSize(800, 600);
		ctx.Update(0, 0);

		Test.Assert(!ctrl.IsFocused);

		// Simulate click on control
		ctx.InputManager.ProcessMouseDown(50, 25, .Left);

		Test.Assert(ctrl.IsFocused);
		Test.Assert(ctx.FocusManager.FocusedElement == ctrl);

		ctx.RootElement = null;
		delete panel;
	}

	// ========== Safety Tests ==========

	[Test]
	public static void Safety_MutationQueue_DefersDeletion()
	{
		let ctx = scope GUIContext();
		let panel = new TestPanel();
		ctx.RootElement = panel;

		let child = new TestElement();
		panel.AddChild(child);
		let childId = child.Id;

		// Queue deletion
		ctx.QueueDelete(child);
		Test.Assert(child.IsPendingDeletion);
		Test.Assert(panel.ChildCount == 1);  // Still there

		// Process mutations
		ctx.Update(0, 0);

		// Now it should be gone
		Test.Assert(panel.ChildCount == 0);
		Test.Assert(ctx.GetElementById(childId) == null);

		ctx.RootElement = null;
		delete panel;
	}

	[Test]
	public static void Safety_ElementHandle_InvalidatesOnDeletion()
	{
		let ctx = scope GUIContext();
		let panel = new TestPanel();
		ctx.RootElement = panel;

		let child = new TestControl();
		panel.AddChild(child);

		let handle = ElementHandle<TestControl>(child.Id, ctx);
		Test.Assert(handle.IsValid);
		Test.Assert(handle.TryResolve() == child);

		// Queue deletion
		ctx.QueueDelete(child);
		Test.Assert(!handle.IsValid);  // Pending deletion = invalid

		ctx.Update(0, 0);
		Test.Assert(handle.TryResolve() == null);

		ctx.RootElement = null;
		delete panel;
	}

	[Test]
	public static void Safety_FocusManagerClearsOnDeletion()
	{
		let ctx = scope GUIContext();
		let panel = new TestPanel();
		ctx.RootElement = panel;

		let ctrl = new TestControl();
		panel.AddChild(ctrl);

		ctx.SetViewportSize(800, 600);
		ctx.Update(0, 0);

		// Focus the control
		ctx.FocusManager.SetFocus(ctrl);
		Test.Assert(ctx.FocusManager.FocusedElement == ctrl);

		// Delete the control
		ctx.QueueDelete(ctrl);
		ctx.Update(0, 0);

		// Focus should be cleared
		Test.Assert(ctx.FocusManager.FocusedElement == null);

		ctx.RootElement = null;
		delete panel;
	}

	[Test]
	public static void Safety_InputManager_ClearsHoverOnDeletion()
	{
		let ctx = scope GUIContext();
		let panel = new TestPanel();
		panel.Width = 400;
		panel.Height = 300;
		ctx.RootElement = panel;

		let ctrl = new TestControl();
		ctrl.Width = 100;
		ctrl.Height = 50;
		panel.AddChild(ctrl);

		ctx.SetViewportSize(800, 600);
		ctx.Update(0, 0);

		// Move mouse over control
		ctx.InputManager.ProcessMouseMove(50, 25);
		Test.Assert(ctx.InputManager.HoveredElement == ctrl);

		// Delete the control
		ctx.QueueDelete(ctrl);
		ctx.Update(0, 0);

		// Hover should be cleared
		Test.Assert(ctx.InputManager.HoveredElement == null);

		ctx.RootElement = null;
		delete panel;
	}

	[Test]
	public static void VisualChildCount_Polymorphic()
	{
		// Test that VisualChildCount/GetVisualChild work polymorphically

		// Container
		let panel = scope TestPanel();
		panel.AddChild(new TestElement());
		panel.AddChild(new TestElement());
		Test.Assert(panel.VisualChildCount == 2);
		Test.Assert(panel.GetVisualChild(0) != null);
		Test.Assert(panel.GetVisualChild(1) != null);
		Test.Assert(panel.GetVisualChild(2) == null);

		// ContentControl
		let content = scope ContentControl();
		Test.Assert(content.VisualChildCount == 0);
		content.Content = new TestElement();
		Test.Assert(content.VisualChildCount == 1);
		Test.Assert(content.GetVisualChild(0) != null);

		// Decorator
		let decorator = scope Decorator();
		Test.Assert(decorator.VisualChildCount == 0);
		decorator.Child = new TestElement();
		Test.Assert(decorator.VisualChildCount == 1);
		Test.Assert(decorator.GetVisualChild(0) != null);

		// UIElement base
		let elem = scope TestElement();
		Test.Assert(elem.VisualChildCount == 0);
		Test.Assert(elem.GetVisualChild(0) == null);
	}
}
