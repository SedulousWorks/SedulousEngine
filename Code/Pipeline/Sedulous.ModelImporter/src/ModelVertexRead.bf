using System;
using Sedulous.Core;
using Sedulous.Model;

namespace Sedulous.ModelImporter;

/// Reading one vertex's components out of a loader's interleaved bytes.
///
/// BY SEMANTIC rather than by a fixed layout, so whatever a loader chose to emit works. An
/// absent element yields the default, which is what lets a mesh with only positions and
/// normals convert without special cases.
static class ModelVertexRead
{
	public static VertexElement* FindElement(Span<VertexElement> elements, VertexSemantic semantic)
	{
		for (int i < elements.Length)
		{
			if (elements[i].Semantic == semantic)
				return &elements[i];
		}
		return null;
	}

	public static Float3 ReadVec3(uint8* vertex, VertexElement* element, Float3 fallback)
	{
		if (element == null)
			return fallback;
		Float3 result = ?;
		Internal.MemCpy(&result, vertex + element.Offset, sizeof(Float3));
		return result;
	}

	public static Float2 ReadVec2(uint8* vertex, VertexElement* element, Float2 fallback)
	{
		if (element == null)
			return fallback;
		Float2 result = ?;
		Internal.MemCpy(&result, vertex + element.Offset, sizeof(Float2));
		return result;
	}

	public static Float4 ReadVec4(uint8* vertex, VertexElement* element, Float4 fallback)
	{
		if (element == null)
			return fallback;
		Float4 result = ?;
		Internal.MemCpy(&result, vertex + element.Offset, sizeof(Float4));
		return result;
	}

	public static uint32 ReadU32(uint8* vertex, VertexElement* element, uint32 fallback)
	{
		if (element == null)
			return fallback;
		uint32 result = ?;
		Internal.MemCpy(&result, vertex + element.Offset, sizeof(uint32));
		return result;
	}
}
