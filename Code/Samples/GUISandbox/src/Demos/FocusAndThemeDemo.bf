namespace GUISandbox;

using Sedulous.Core.Mathematics;
using Sedulous.GUI;

/// Phase 3: Focus and Theme Demo
static class FocusAndThemeDemo
{
	public static Panel Create()
	{
		let rootPanel = new DemoPanel();
		rootPanel.Width = 800;
		rootPanel.Height = 200;
		rootPanel.Margin = .(50, 100, 50, 50);

		// Create 3 focusable rectangles with different colors
		let rect1 = new FocusableRect();
		rect1.Width = 120;
		rect1.Height = 100;
		rect1.RectColor = Color(200, 80, 80, 255);  // Red
		rect1.TabIndex = 0;
		rect1.BorderThickness = 2;
		rect1.BorderColor = Color(150, 60, 60, 255);
		rect1.FocusBorderColor = Color(255, 200, 100, 255);
		rect1.FocusBorderThickness = 4;
		rootPanel.AddChild(rect1);

		let rect2 = new FocusableRect();
		rect2.Width = 120;
		rect2.Height = 100;
		rect2.RectColor = Color(80, 180, 80, 255);  // Green
		rect2.TabIndex = 1;
		rect2.BorderThickness = 2;
		rect2.BorderColor = Color(60, 140, 60, 255);
		rect2.FocusBorderColor = Color(255, 200, 100, 255);
		rect2.FocusBorderThickness = 4;
		rootPanel.AddChild(rect2);

		let rect3 = new FocusableRect();
		rect3.Width = 120;
		rect3.Height = 100;
		rect3.RectColor = Color(80, 120, 200, 255);  // Blue
		rect3.TabIndex = 2;
		rect3.BorderThickness = 2;
		rect3.BorderColor = Color(60, 90, 160, 255);
		rect3.FocusBorderColor = Color(255, 200, 100, 255);
		rect3.FocusBorderThickness = 4;
		rootPanel.AddChild(rect3);

		// Fourth rectangle uses theme colors (no explicit colors)
		let rect4 = new ThemedRect();
		rect4.Width = 120;
		rect4.Height = 100;
		rect4.TabIndex = 3;
		rootPanel.AddChild(rect4);

		// Fifth rectangle is rotated to demonstrate transformed hit testing
		let rect5 = new FocusableRect();
		rect5.Width = 120;
		rect5.Height = 100;
		rect5.RectColor = Color(180, 80, 180, 255);  // Purple
		rect5.TabIndex = 4;
		rect5.BorderThickness = 2;
		rect5.BorderColor = Color(140, 60, 140, 255);
		rect5.FocusBorderColor = Color(255, 200, 100, 255);
		rect5.FocusBorderThickness = 4;
		// Apply a 15 degree rotation transform (15 degrees in radians)
		rect5.RenderTransform = Matrix.CreateRotationZ(15.0f * (System.Math.PI_f / 180.0f));
		rootPanel.AddChild(rect5);

		return rootPanel;
	}
}
