namespace GUISandbox;

using System;
using Sedulous.Core.Mathematics;
using Sedulous.GUI;
using Sedulous.Imaging;
using Sedulous.Drawing;

/// Phase 5: Display Controls Demo
static class DisplayControlsDemo
{
	public static Panel Create(OwnedImageData checkerboard, OwnedImageData gradient)
	{
		// Main container with vertical stack
		let container = new StackPanel();
		container.Orientation = .Vertical;
		container.Spacing = 20;
		container.Margin = .(50, 80, 50, 50);
		container.HorizontalAlignment = .Left;
		container.VerticalAlignment = .Top;

		// --- TextBlock Section ---
		let textSection = new StackPanel();
		textSection.Orientation = .Vertical;
		textSection.Spacing = 8;

		let textHeader = new TextBlock("TextBlock Examples:");
		textHeader.FontSize = 18;
		textSection.AddChild(textHeader);

		// Left-aligned text
		let textLeft = new TextBlock("Left-aligned text (default)");
		textSection.AddChild(textLeft);

		// Center-aligned text
		let textCenter = new TextBlock("Center-aligned text");
		textCenter.TextAlignment = .Center;
		textCenter.Width = 300;
		textCenter.Background = Color(40, 40, 50, 128);
		textSection.AddChild(textCenter);

		// Right-aligned text
		let textRight = new TextBlock("Right-aligned text");
		textRight.TextAlignment = .Right;
		textRight.Width = 300;
		textRight.Background = Color(40, 40, 50, 128);
		textSection.AddChild(textRight);

		// Wrapped text - uses ShapeTextWrapped for proper word-aware wrapping
		let textWrapped = new TextBlock("This is a longer text that wraps at word boundaries. The TextWrapping property enables word-aware line breaking using the text shaper.");
		textWrapped.TextWrapping = .Wrap;
		textWrapped.Width = 280;
		textWrapped.Background = Color(50, 40, 40, 128);
		textSection.AddChild(textWrapped);

		container.AddChild(textSection);

		// --- Separator ---
		let sep1 = new Separator(.Horizontal);
		sep1.Width = 600;
		container.AddChild(sep1);

		// --- Label Section ---
		let labelSection = new StackPanel();
		labelSection.Orientation = .Horizontal;
		labelSection.Spacing = 20;

		// Label with target
		let targetControl = new FocusableRect();
		targetControl.Width = 100;
		targetControl.Height = 60;
		targetControl.RectColor = Color(80, 120, 180, 255);

		let label = new Label("Click me to focus target:");
		label.Target = targetControl;

		labelSection.AddChild(label);
		labelSection.AddChild(targetControl);
		container.AddChild(labelSection);

		// --- Separator ---
		let sep2 = new Separator(.Horizontal);
		sep2.Width = 600;
		container.AddChild(sep2);

		// --- Border Section ---
		let borderSection = new StackPanel();
		borderSection.Orientation = .Horizontal;
		borderSection.Spacing = 20;

		// Simple border
		let border1 = new Border();
		border1.BorderThickness = .(2);
		border1.BorderBrush = Color(100, 150, 200, 255);
		border1.CornerRadius = 0;
		let borderContent1 = new TextBlock("Simple Border");
		border1.Child = borderContent1;
		borderSection.AddChild(border1);

		// Rounded border with background (both background and stroke are rounded)
		let border2 = new Border();
		border2.BorderThickness = .(3);
		border2.BorderBrush = Color(200, 100, 100, 255);
		border2.Background = Color(60, 40, 40, 255);
		border2.CornerRadius = 10;
		border2.Padding = .(10);
		let borderContent2 = new TextBlock("Rounded Border");
		border2.Child = borderContent2;
		borderSection.AddChild(border2);

		// Non-uniform border (thick top/bottom, thin left/right)
		let border3 = new Border();
		border3.BorderThickness = .(2, 10, 2, 10); // Left, Top, Right, Bottom
		border3.BorderBrush = Color(100, 200, 100, 255);
		border3.Padding = .(8);
		let borderContent3 = new TextBlock("Thick T/B");
		border3.Child = borderContent3;
		borderSection.AddChild(border3);

		container.AddChild(borderSection);

		// --- Separator ---
		let sep3 = new Separator(.Horizontal);
		sep3.Width = 600;
		container.AddChild(sep3);

		// --- ProgressBar Section ---
		let progressSection = new StackPanel();
		progressSection.Orientation = .Vertical;
		progressSection.Spacing = 10;

		let progressHeader = new TextBlock("ProgressBar Examples:");
		progressHeader.FontSize = 18;
		progressSection.AddChild(progressHeader);

		// Determinate progress bar at 30%
		let progress1 = new ProgressBar();
		progress1.Width = 300;
		progress1.Height = 16;
		progress1.Value = 30;
		progress1.CornerRadius = 4;
		progressSection.AddChild(progress1);

		// Determinate progress bar at 75%
		let progress2 = new ProgressBar();
		progress2.Width = 300;
		progress2.Height = 16;
		progress2.Value = 75;
		progress2.FillColor = Color(100, 200, 100, 255);
		progress2.CornerRadius = 4;
		progressSection.AddChild(progress2);

		// Indeterminate progress bar (animated)
		let progressIndeterminate = new ProgressBar();
		progressIndeterminate.Width = 300;
		progressIndeterminate.Height = 16;
		progressIndeterminate.IsIndeterminate = true;
		progressIndeterminate.FillColor = Color(200, 150, 50, 255);
		progressIndeterminate.CornerRadius = 4;
		progressSection.AddChild(progressIndeterminate);

		// Vertical progress bar
		let verticalProgressStack = new StackPanel();
		verticalProgressStack.Orientation = .Horizontal;
		verticalProgressStack.Spacing = 10;

		let vertLabel = new TextBlock("Vertical:");
		verticalProgressStack.AddChild(vertLabel);

		let progressVert = new ProgressBar();
		progressVert.Orientation = .Vertical;
		progressVert.Width = 16;
		progressVert.Height = 80;
		progressVert.Value = 60;
		progressVert.CornerRadius = 4;
		verticalProgressStack.AddChild(progressVert);

		progressSection.AddChild(verticalProgressStack);

		container.AddChild(progressSection);

		// --- Separator ---
		let sep4 = new Separator(.Horizontal);
		sep4.Width = 600;
		container.AddChild(sep4);

		// --- Image Section ---
		let imageSection = new StackPanel();
		imageSection.Orientation = .Vertical;
		imageSection.Spacing = 10;

		let imageHeader = new TextBlock("Image Examples (Stretch Modes):");
		imageHeader.FontSize = 18;
		imageSection.AddChild(imageHeader);

		let imageRow = new StackPanel();
		imageRow.Orientation = .Horizontal;
		imageRow.Spacing = 20;

		// Image with Uniform stretch (default) - shown in 100x100 box
		let imageBorder1 = new Border();
		imageBorder1.BorderThickness = .(1);
		imageBorder1.BorderBrush = Color(100, 100, 100, 255);
		imageBorder1.Width = 100;
		imageBorder1.Height = 100;
		let image1 = new Sedulous.GUI.Image(checkerboard);
		image1.Stretch = .Uniform;
		imageBorder1.Child = image1;
		imageRow.AddChild(imageBorder1);

		// Image with Fill stretch - stretches to fill
		let imageBorder2 = new Border();
		imageBorder2.BorderThickness = .(1);
		imageBorder2.BorderBrush = Color(100, 100, 100, 255);
		imageBorder2.Width = 100;
		imageBorder2.Height = 100;
		let image2 = new Sedulous.GUI.Image(gradient);
		image2.Stretch = .Fill;
		imageBorder2.Child = image2;
		imageRow.AddChild(imageBorder2);

		// Image with None stretch - original size, centered
		let imageBorder3 = new Border();
		imageBorder3.BorderThickness = .(1);
		imageBorder3.BorderBrush = Color(100, 100, 100, 255);
		imageBorder3.Width = 100;
		imageBorder3.Height = 100;
		let image3 = new Sedulous.GUI.Image(checkerboard);
		image3.Stretch = .None;
		imageBorder3.Child = image3;
		imageRow.AddChild(imageBorder3);

		// Image with UniformToFill stretch - fills while preserving aspect
		let imageBorder4 = new Border();
		imageBorder4.BorderThickness = .(1);
		imageBorder4.BorderBrush = Color(100, 100, 100, 255);
		imageBorder4.Width = 100;
		imageBorder4.Height = 100;
		let image4 = new Sedulous.GUI.Image(gradient);
		image4.Stretch = .UniformToFill;
		imageBorder4.Child = image4;
		imageRow.AddChild(imageBorder4);

		imageSection.AddChild(imageRow);

		// Labels for stretch modes
		let stretchLabels = new StackPanel();
		stretchLabels.Orientation = .Horizontal;
		stretchLabels.Spacing = 20;

		let stretchLabel1 = new TextBlock("Uniform");
		stretchLabel1.Width = 100;
		stretchLabel1.TextAlignment = .Center;
		stretchLabels.AddChild(stretchLabel1);

		let stretchLabel2 = new TextBlock("Fill");
		stretchLabel2.Width = 100;
		stretchLabel2.TextAlignment = .Center;
		stretchLabels.AddChild(stretchLabel2);

		let stretchLabel3 = new TextBlock("None");
		stretchLabel3.Width = 100;
		stretchLabel3.TextAlignment = .Center;
		stretchLabels.AddChild(stretchLabel3);

		let stretchLabel4 = new TextBlock("UniformToFill");
		stretchLabel4.Width = 100;
		stretchLabel4.TextAlignment = .Center;
		stretchLabels.AddChild(stretchLabel4);

		imageSection.AddChild(stretchLabels);

		container.AddChild(imageSection);

		// --- Scale Info ---
		let sep5 = new Separator(.Horizontal);
		sep5.Width = 600;
		container.AddChild(sep5);

		let scaleInfo = new TextBlock("Use Ctrl +/- to adjust UI scale factor");
		scaleInfo.FontSize = 12;
		container.AddChild(scaleInfo);

		return container;
	}
}
