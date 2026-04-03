using System;
using Sedulous.Core.Mathematics;
using Sedulous.Drawing;

namespace Sedulous.GUI.Tests;

/// Phase 5 tests: display controls, text rendering, UI scaling.
class Phase5Tests
{
	/// Test panel for container tests.
	class TestPanel : Panel
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

	// ========== TextBlock Tests ==========

	[Test]
	public static void TextBlock_MeasuresText()
	{
		let ctx = scope GUIContext();
		let panel = new TestPanel();
		ctx.RootElement = panel;

		let textBlock = new TextBlock("Hello");
		panel.AddChild(textBlock);

		ctx.SetViewportSize(800, 600);
		ctx.Update(0, 0);

		// TextBlock should have non-zero size
		let size = textBlock.DesiredSize.Width;
		Test.Assert(size > 0, "TextBlock should measure text width");

		ctx.RootElement = null;
		delete panel;
	}

	[Test]
	public static void TextBlock_EmptyTextMeasuresZero()
	{
		let ctx = scope GUIContext();
		let panel = new TestPanel();
		ctx.RootElement = panel;

		let textBlock = new TextBlock();
		panel.AddChild(textBlock);

		ctx.SetViewportSize(800, 600);
		ctx.Update(0, 0);

		Test.Assert(textBlock.DesiredSize.Width == 0);
		Test.Assert(textBlock.DesiredSize.Height == 0);

		ctx.RootElement = null;
		delete panel;
	}

	[Test]
	public static void TextBlock_WrappingIncreasesHeight()
	{
		let ctx = scope GUIContext();
		let panel = new TestPanel();
		ctx.RootElement = panel;

		let textBlock = new TextBlock("This is a long text that should wrap when given narrow constraints");
		textBlock.TextWrapping = .Wrap;
		textBlock.Width = 100;  // Force narrow width
		panel.AddChild(textBlock);

		ctx.SetViewportSize(800, 600);
		ctx.Update(0, 0);

		// With wrapping and narrow width, height should be greater than single line
		let singleLineHeight = textBlock.FontSize * 1.2f;
		Test.Assert(textBlock.DesiredSize.Height >= singleLineHeight, "Wrapped text should have height");

		ctx.RootElement = null;
		delete panel;
	}

	// ========== Label Tests ==========

	[Test]
	public static void Label_MeasuresContentText()
	{
		let ctx = scope GUIContext();
		let panel = new TestPanel();
		ctx.RootElement = panel;

		let label = new Label("Test");
		panel.AddChild(label);

		ctx.SetViewportSize(800, 600);
		ctx.Update(0, 0);

		Test.Assert(label.DesiredSize.Width > 0, "Label should measure text width");

		ctx.RootElement = null;
		delete panel;
	}

	[Test]
	public static void Label_FocusesTarget()
	{
		let ctx = scope GUIContext();
		let panel = new TestPanel();
		ctx.RootElement = panel;

		let control = new TestControl();
		control.Width = 100;
		control.Height = 50;
		panel.AddChild(control);

		let label = new Label("Click me");
		label.Target = control;
		label.Width = 100;
		label.Height = 30;
		panel.AddChild(label);

		ctx.SetViewportSize(800, 600);
		ctx.Update(0, 0);

		Test.Assert(!control.IsFocused, "Control should not be focused initially");

		// Move mouse over label and click
		ctx.InputManager.ProcessMouseMove(50, 15);  // Click within label bounds (label is 100x30 at 0,0)
		ctx.ProcessMouseDown(50, 15, .Left);

		Test.Assert(control.IsFocused, "Control should be focused after clicking label");

		ctx.RootElement = null;
		delete panel;
	}

	// ========== Image Tests ==========

	[Test]
	public static void Image_StretchNone_KeepsSourceSize()
	{
		let ctx = scope GUIContext();
		let panel = new TestPanel();
		ctx.RootElement = panel;

		// Create a mock image data
		let imageData = new OwnedImageData(100, 50, .RGBA8, .());
		let image = new Image(imageData);
		image.Stretch = .None;
		panel.AddChild(image);

		ctx.SetViewportSize(800, 600);
		ctx.Update(0, 0);

		Test.Assert(image.DesiredSize.Width == 100);
		Test.Assert(image.DesiredSize.Height == 50);

		ctx.RootElement = null;
		delete panel;
		delete imageData;
	}

	[Test]
	public static void Image_NullSource_MeasuresZero()
	{
		let ctx = scope GUIContext();
		let panel = new TestPanel();
		ctx.RootElement = panel;

		let image = new Image();
		panel.AddChild(image);

		ctx.SetViewportSize(800, 600);
		ctx.Update(0, 0);

		Test.Assert(image.DesiredSize.Width == 0);
		Test.Assert(image.DesiredSize.Height == 0);

		ctx.RootElement = null;
		delete panel;
	}

	// ========== Border Tests ==========

	[Test]
	public static void Border_AddsThicknessToChildSize()
	{
		let ctx = scope GUIContext();
		let panel = new TestPanel();
		ctx.RootElement = panel;

		let child = new TestControl();
		child.Width = 100;
		child.Height = 50;

		let border = new Border();
		border.BorderThickness = .(10);  // 10px on all sides
		border.Child = child;
		panel.AddChild(border);

		ctx.SetViewportSize(800, 600);
		ctx.Update(0, 0);

		// Border should add 20px total (10 each side)
		Test.Assert(border.DesiredSize.Width == 120, "Border should add thickness to width");
		Test.Assert(border.DesiredSize.Height == 70, "Border should add thickness to height");

		ctx.RootElement = null;
		delete panel;
	}

	[Test]
	public static void Border_NonUniformThickness()
	{
		let ctx = scope GUIContext();
		let panel = new TestPanel();
		ctx.RootElement = panel;

		let child = new TestControl();
		child.Width = 100;
		child.Height = 50;

		let border = new Border();
		border.BorderThickness = .(5, 10, 15, 20);  // left, top, right, bottom
		border.Child = child;
		panel.AddChild(border);

		ctx.SetViewportSize(800, 600);
		ctx.Update(0, 0);

		// Width: 100 + 5 + 15 = 120
		// Height: 50 + 10 + 20 = 80
		Test.Assert(border.DesiredSize.Width == 120);
		Test.Assert(border.DesiredSize.Height == 80);

		ctx.RootElement = null;
		delete panel;
	}

	// ========== Separator Tests ==========

	[Test]
	public static void Separator_HorizontalMeasuresThin()
	{
		let ctx = scope GUIContext();
		let panel = new TestPanel();
		ctx.RootElement = panel;

		let separator = new Separator(.Horizontal);
		panel.AddChild(separator);

		ctx.SetViewportSize(800, 600);
		ctx.Update(0, 0);

		Test.Assert(separator.DesiredSize.Height == 1, "Horizontal separator should be 1px tall");

		ctx.RootElement = null;
		delete panel;
	}

	[Test]
	public static void Separator_VerticalMeasuresThin()
	{
		let ctx = scope GUIContext();
		let panel = new TestPanel();
		ctx.RootElement = panel;

		let separator = new Separator(.Vertical);
		panel.AddChild(separator);

		ctx.SetViewportSize(800, 600);
		ctx.Update(0, 0);

		Test.Assert(separator.DesiredSize.Width == 1, "Vertical separator should be 1px wide");

		ctx.RootElement = null;
		delete panel;
	}

	// ========== ProgressBar Tests ==========

	[Test]
	public static void ProgressBar_ClampsValue()
	{
		let progressBar = scope ProgressBar();
		progressBar.Minimum = 0;
		progressBar.Maximum = 100;

		progressBar.Value = 50;
		Test.Assert(progressBar.Value == 50);

		progressBar.Value = 150;  // Should clamp to max
		Test.Assert(progressBar.Value == 100);

		progressBar.Value = -50;  // Should clamp to min
		Test.Assert(progressBar.Value == 0);
	}

	[Test]
	public static void ProgressBar_ProgressCalculation()
	{
		let progressBar = scope ProgressBar();
		progressBar.Minimum = 0;
		progressBar.Maximum = 100;

		progressBar.Value = 25;
		Test.Assert(progressBar.Progress == 0.25f);

		progressBar.Value = 50;
		Test.Assert(progressBar.Progress == 0.5f);

		progressBar.Value = 100;
		Test.Assert(progressBar.Progress == 1.0f);
	}

	[Test]
	public static void ProgressBar_CustomRange()
	{
		let progressBar = scope ProgressBar();
		progressBar.Minimum = 10;
		progressBar.Maximum = 20;

		progressBar.Value = 15;
		Test.Assert(progressBar.Progress == 0.5f, "Progress should be 0.5 at midpoint");
	}

	// ========== UI Scaling Tests ==========

	[Test]
	public static void ScaleFactor_DefaultIsOne()
	{
		let ctx = scope GUIContext();
		Test.Assert(ctx.ScaleFactor == 1.0f);
	}

	[Test]
	public static void ScaleFactor_ClampsRange()
	{
		let ctx = scope GUIContext();

		ctx.ScaleFactor = 0.1f;  // Below min
		Test.Assert(ctx.ScaleFactor == 0.5f, "Scale should clamp to minimum 0.5");

		ctx.ScaleFactor = 5.0f;  // Above max
		Test.Assert(ctx.ScaleFactor == 3.0f, "Scale should clamp to maximum 3.0");
	}

	[Test]
	public static void ScaleFactor_AffectsHitTesting()
	{
		let ctx = scope GUIContext();
		let panel = new TestPanel();
		panel.Width = 100;
		panel.Height = 100;
		panel.HorizontalAlignment = .Left;
		panel.VerticalAlignment = .Top;
		ctx.RootElement = panel;

		ctx.SetViewportSize(800, 600);
		ctx.ScaleFactor = 2.0f;
		ctx.Update(0, 0);

		// At 2x scale, panel appears at 0,0 with size 200x200 on screen
		// Hit test at screen position (150, 150) should hit the panel
		// because inverse-scaling gives (75, 75) which is inside 100x100 panel
		let hit = ctx.HitTest(150, 150);
		Test.Assert(hit == panel, "Hit test should inverse-scale coordinates");

		// Hit test at (250, 250) should miss
		// because inverse-scaling gives (125, 125) which is outside 100x100 panel
		let miss = ctx.HitTest(250, 250);
		Test.Assert(miss == null, "Hit test should miss outside scaled bounds");

		ctx.RootElement = null;
		delete panel;
	}

	// ========== Service Registry Tests ==========

	class TestService
	{
		public int Value = 42;
	}

	[Test]
	public static void ServiceRegistry_RegisterAndGet()
	{
		let ctx = scope GUIContext();
		let service = scope TestService();

		ctx.RegisterService<TestService>(service);

		if (ctx.GetService<TestService>() case .Ok(let retrieved))
		{
			Test.Assert(retrieved == service);
			Test.Assert(retrieved.Value == 42);
		}
		else
		{
			Test.Assert(false, "Service should be retrievable");
		}
	}

	[Test]
	public static void ServiceRegistry_HasService()
	{
		let ctx = scope GUIContext();

		Test.Assert(!ctx.HasService<TestService>(), "Service should not exist initially");

		let service = scope TestService();
		ctx.RegisterService<TestService>(service);

		Test.Assert(ctx.HasService<TestService>(), "Service should exist after registration");
	}

	[Test]
	public static void ServiceRegistry_GetMissingService()
	{
		let ctx = scope GUIContext();

		if (ctx.GetService<TestService>() case .Err)
		{
			// Expected
		}
		else
		{
			Test.Assert(false, "Getting missing service should return Err");
		}
	}

	// ========== Text Measurement Caching Tests ==========

	[Test]
	public static void TextBlock_CachesTextMeasurement()
	{
		let ctx = scope GUIContext();
		let panel = new TestPanel();
		ctx.RootElement = panel;

		let textBlock = new TextBlock("Test");
		panel.AddChild(textBlock);

		ctx.SetViewportSize(800, 600);
		ctx.Update(0, 0);

		let firstMeasure = textBlock.DesiredSize.Width;

		// Force another measure pass
		ctx.Update(0.016f, 0.016);

		let secondMeasure = textBlock.DesiredSize.Width;

		// Measurements should be identical (cache hit)
		Test.Assert(firstMeasure == secondMeasure);

		ctx.RootElement = null;
		delete panel;
	}

	[Test]
	public static void TextBlock_InvalidatesCacheOnTextChange()
	{
		let ctx = scope GUIContext();
		let panel = new TestPanel();
		ctx.RootElement = panel;

		let textBlock = new TextBlock("A");
		panel.AddChild(textBlock);

		ctx.SetViewportSize(800, 600);
		ctx.Update(0, 0);

		let shortWidth = textBlock.DesiredSize.Width;

		textBlock.Text = "AAAAAAAAAA";
		ctx.Update(0.016f, 0.032);

		let longWidth = textBlock.DesiredSize.Width;

		Test.Assert(longWidth > shortWidth, "Longer text should measure wider");

		ctx.RootElement = null;
		delete panel;
	}
}
