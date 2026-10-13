// Lesson 1: Unlit Colour. The smallest surface shader.
//
// A surface shader says what a surface is, and the engine does the rest: it draws it in every pass
// (its shadow, the depth, the editor's picking) and, when the shader is lit, lights it. This one is
// unlit, so its colour shows as it is, whatever the lights do. It has three parts:
//   1. The line below: it makes this file a surface shader, and an unlit one.
//   2. A properties block: the material's parameters, shown as rows on the material page.
//   3. Surface(): what the surface is, decided at each point drawn.
// surface: unlit

properties
{
    Color Paint = (0.95, 0.45, 0.2, 1);   // a colour picker on the material page
}

// `surface` starts as a plain white surface; set only what this one changes.
void Surface(SurfaceInput input, inout SurfaceOutput surface)
{
    surface.albedo = Paint.rgb;
}
