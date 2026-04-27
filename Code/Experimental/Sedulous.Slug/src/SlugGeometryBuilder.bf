using System;

namespace Sedulous.Slug;

/// Builds vertex and triangle data for rendering glyphs with the Slug shader.
public static class SlugGeometryBuilder
{
	/// Count the maximum vertices and triangles needed for a string of glyphs.
	public static void CountGlyphs(
		SlugFont font,
		StringView text,
		float fontSize,
		GeometryType geometryType,
		out int32 vertexCount,
		out int32 triangleCount)
	{
		vertexCount = 0;
		triangleCount = 0;

		int32 visibleCount = 0;
		for (let c in text.DecodedChars)
		{
			let glyph = font.GetGlyph((uint32)c);
			if (glyph != null && glyph.HasCurves)
				visibleCount++;
		}

		switch (geometryType)
		{
		case .Quads:
			vertexCount = visibleCount * 4;
			triangleCount = visibleCount * 2;
		case .Polygons:
			vertexCount = visibleCount * 6;
			triangleCount = visibleCount * 4;
		case .Rectangles:
			vertexCount = visibleCount * 3;
			triangleCount = visibleCount;
		}
	}

	/// Build vertex and triangle data for a text string.
	/// Returns the number of vertices written.
	/// The GeometryBuffer pointers are advanced past the written data.
	public static int32 BuildText(
		SlugFont font,
		StringView text,
		float fontSize,
		Point2D position,
		Color4U color,
		GeometryBuffer* geometryBuffer)
	{
		if (geometryBuffer == null || geometryBuffer.vertexData == null)
			return 0;

		let emScale = fontSize;
		var cursorX = position.x;
		let baselineY = position.y;
		int32 totalVerts = 0;

		for (let c in text.DecodedChars)
		{
			let glyph = font.GetGlyph((uint32)c);
			if (glyph == null)
				continue;

			if (glyph.HasCurves)
			{
				let vertsWritten = BuildGlyphQuad(glyph, cursorX, baselineY, emScale, color, geometryBuffer);
				totalVerts += vertsWritten;
			}

			cursorX += glyph.AdvanceWidth * emScale;
		}

		return totalVerts;
	}

	/// Build a single glyph quad. Returns number of vertices written.
	private static int32 BuildGlyphQuad(
		SlugGlyphData glyph,
		float posX, float posY,
		float emScale,
		Color4U color,
		GeometryBuffer* geometryBuffer)
	{
		let bb = ref glyph.BoundingBox;

		// Object-space quad corners (em-space scaled by fontSize)
		let x0 = posX + bb.min.x * emScale;
		let y0 = posY + bb.min.y * emScale;
		let x1 = posX + bb.max.x * emScale;
		let y1 = posY + bb.max.y * emScale;

		// Em-space texture coordinates
		let u0 = bb.min.x;
		let v0 = bb.min.y;
		let u1 = bb.max.x;
		let v1 = bb.max.y;

		// Outward normals for dynamic dilation (shader normalizes)
		let nx = 1.0f;
		let ny = 1.0f;

		// Pack glyph data location into texcoord.zw
		let glyphLocPacked = PackUint16Pair(glyph.BandLocation[0], glyph.BandLocation[1]);
		// bandMax.x = max vertical band index, bandMax.y = max horizontal band index
		// BandCount[0] = vBands, BandCount[1] = hBands
		let bandMaxX = (uint16)(uint32)Math.Max(0, (int32)glyph.BandCount[0] - 1); // vBands - 1
		let bandMaxY = (uint16)(uint32)Math.Max(0, (int32)glyph.BandCount[1] - 1); // hBands - 1
		let bandMaxPacked = PackUint16Pair(bandMaxX, bandMaxY);

		// Inverse Jacobian: maps em-space derivatives to object-space
		let invScale = 1.0f / emScale;

		// Band transform
		let bandScaleX = glyph.BandScale.x;
		let bandScaleY = glyph.BandScale.y;
		let bandOffsetX = -bb.min.x * bandScaleX;
		let bandOffsetY = -bb.min.y * bandScaleY;

		let baseIndex = geometryBuffer.vertexIndex;
		var verts = geometryBuffer.vertexData;
		var tris = geometryBuffer.triangleData;

		// 4 vertices: bottom-left, bottom-right, top-right, top-left
		verts[0] = .() { position = .(x0, y0, -nx, -ny), texcoord = .(u0, v0, glyphLocPacked, bandMaxPacked),
			jacobian = .(invScale, 0, 0, invScale), banding = .(bandScaleX, bandScaleY, bandOffsetX, bandOffsetY), color = color };
		verts[1] = .() { position = .(x1, y0, nx, -ny), texcoord = .(u1, v0, glyphLocPacked, bandMaxPacked),
			jacobian = .(invScale, 0, 0, invScale), banding = .(bandScaleX, bandScaleY, bandOffsetX, bandOffsetY), color = color };
		verts[2] = .() { position = .(x1, y1, nx, ny), texcoord = .(u1, v1, glyphLocPacked, bandMaxPacked),
			jacobian = .(invScale, 0, 0, invScale), banding = .(bandScaleX, bandScaleY, bandOffsetX, bandOffsetY), color = color };
		verts[3] = .() { position = .(x0, y1, -nx, ny), texcoord = .(u0, v1, glyphLocPacked, bandMaxPacked),
			jacobian = .(invScale, 0, 0, invScale), banding = .(bandScaleX, bandScaleY, bandOffsetX, bandOffsetY), color = color };

		// 2 triangles
		tris[0] = .((uint16)(baseIndex + 0), (uint16)(baseIndex + 1), (uint16)(baseIndex + 2));
		tris[1] = .((uint16)(baseIndex + 0), (uint16)(baseIndex + 2), (uint16)(baseIndex + 3));

		geometryBuffer.vertexData = &verts[4];
		geometryBuffer.triangleData = &tris[2];
		geometryBuffer.vertexIndex = baseIndex + 4;

		return 4;
	}

	/// Measure the width of a text string in absolute units.
	public static float MeasureString(SlugFont font, StringView text, float fontSize)
	{
		var width = 0.0f;
		for (let c in text.DecodedChars)
		{
			let glyph = font.GetGlyph((uint32)c);
			if (glyph != null)
				width += glyph.AdvanceWidth * fontSize;
		}
		return width;
	}

	/// Pack two uint16 values into a float (reinterpret cast).
	public static float PackUint16Pair(uint16 lo, uint16 hi)
	{
		var packed = (uint32)hi << 16 | (uint32)lo;
		return *(float*)&packed;
	}
}
