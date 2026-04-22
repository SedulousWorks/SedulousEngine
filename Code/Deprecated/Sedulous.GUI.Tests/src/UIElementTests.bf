using System;
using Sedulous.Core.Mathematics;

namespace Sedulous.GUI.Tests;

class UIElementTests
{
	/// Simple concrete UIElement for testing.
	class TestElement : UIElement
	{
		public Color Background;

		public this()
		{
			Background = .White;
		}
	}

	[Test]
	public static void UIElementId_IsUnique()
	{
		let id1 = UIElementId.Generate();
		let id2 = UIElementId.Generate();
		let id3 = UIElementId.Generate();

		Test.Assert(id1 != id2);
		Test.Assert(id2 != id3);
		Test.Assert(id1 != id3);
	}

	[Test]
	public static void UIElementId_InvalidIsZero()
	{
		let invalid = UIElementId.Invalid;
		Test.Assert(!invalid.IsValid);
		Test.Assert(invalid.Value == 0);
	}

	[Test]
	public static void UIElement_HasUniqueId()
	{
		let elem1 = scope TestElement();
		let elem2 = scope TestElement();

		Test.Assert(elem1.Id.IsValid);
		Test.Assert(elem2.Id.IsValid);
		Test.Assert(elem1.Id != elem2.Id);
	}

	[Test]
	public static void UIElement_DefaultProperties()
	{
		let elem = scope TestElement();

		Test.Assert(elem.Width.IsAuto);
		Test.Assert(elem.Height.IsAuto);
		Test.Assert(elem.Margin.IsZero);
		Test.Assert(elem.Padding.IsZero);
		Test.Assert(elem.HorizontalAlignment == .Stretch);
		Test.Assert(elem.VerticalAlignment == .Stretch);
		Test.Assert(elem.Visibility == .Visible);
		Test.Assert(elem.Opacity == 1.0f);
		Test.Assert(elem.Context == null);
		Test.Assert(elem.Parent == null);
	}

	[Test]
	public static void UIElement_SetWidth()
	{
		let elem = scope TestElement();

		elem.Width = 100;
		Test.Assert(elem.Width.IsFixed);
		Test.Assert(elem.Width.Value == 100);

		elem.Width = .Auto;
		Test.Assert(elem.Width.IsAuto);
	}

	[Test]
	public static void UIElement_SetMargin()
	{
		let elem = scope TestElement();

		elem.Margin = .(10);
		Test.Assert(elem.Margin.Left == 10);
		Test.Assert(elem.Margin.Top == 10);
		Test.Assert(elem.Margin.Right == 10);
		Test.Assert(elem.Margin.Bottom == 10);

		elem.Margin = .(5, 10);
		Test.Assert(elem.Margin.Left == 5);
		Test.Assert(elem.Margin.Top == 10);
	}

	[Test]
	public static void UIElement_SetVisibility()
	{
		let elem = scope TestElement();

		Test.Assert(elem.IsVisible);

		elem.Visibility = .Hidden;
		Test.Assert(!elem.IsVisible);
		Test.Assert(elem.Visibility == .Hidden);

		elem.Visibility = .Collapsed;
		Test.Assert(!elem.IsVisible);
		Test.Assert(elem.Visibility == .Collapsed);
	}

	[Test]
	public static void GUIContext_RegistersRootElement()
	{
		let ctx = scope GUIContext();
		let elem = new TestElement();

		ctx.RootElement = elem;

		Test.Assert(elem.Context == ctx);
		Test.Assert(ctx.GetElementById(elem.Id) == elem);

		// Cleanup - set root to null to trigger deletion
		ctx.RootElement = null;
		delete elem;
	}

	[Test]
	public static void ElementHandle_ResolvesValidElement()
	{
		let ctx = scope GUIContext();
		let elem = new TestElement();
		ctx.RootElement = elem;

		let handle = ElementHandle<TestElement>(elem.Id, ctx);

		Test.Assert(handle.IsValid);
		Test.Assert(handle.TryResolve() == elem);

		ctx.RootElement = null;
		delete elem;
	}

	[Test]
	public static void ElementHandle_InvalidAfterDeletion()
	{
		let ctx = scope GUIContext();
		let elem = new TestElement();
		ctx.RootElement = elem;

		let handle = ElementHandle<TestElement>(elem.Id, ctx);
		Test.Assert(handle.IsValid);

		// Queue for deletion
		ctx.QueueDelete(elem);

		// Element is pending deletion, handle should be invalid
		Test.Assert(!handle.IsValid);

		// Process the mutation queue
		ctx.Update(0, 0);
		ctx.RootElement = null;
	}

	[Test]
	public static void MutationQueue_QueuesAndProcesses()
	{
		let ctx = scope GUIContext();
		let queue = ctx.MutationQueue;

		let elem = new TestElement();
		ctx.RootElement = elem;

		Test.Assert(queue.Count == 0);

		// Queue deletion
		queue.QueueDelete(elem);
		Test.Assert(queue.Count == 1);
		Test.Assert(elem.IsPendingDeletion);

		// Process
		queue.Process(ctx);
		Test.Assert(queue.Count == 0);

		// Element should be deleted - don't access it
		ctx.RootElement = null;
	}

	[Test]
	public static void GUIContext_SetViewport()
	{
		let ctx = scope GUIContext();

		ctx.SetViewportSize(800, 600);

		Test.Assert(ctx.ViewportWidth == 800);
		Test.Assert(ctx.ViewportHeight == 600);
	}

	[Test]
	public static void UIElement_MeasureWithFixedSize()
	{
		let ctx = scope GUIContext();
		let elem = new TestElement();
		elem.Width = 100;
		elem.Height = 50;
		ctx.RootElement = elem;

		ctx.SetViewportSize(800, 600);
		ctx.Update(0, 0);

		// Fixed size element should have that desired size
		Test.Assert(elem.DesiredSize.Width == 100);
		Test.Assert(elem.DesiredSize.Height == 50);

		ctx.RootElement = null;
		delete elem;
	}
}
