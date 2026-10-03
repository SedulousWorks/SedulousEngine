#include "joltc_beef.h"

#include <Jolt/Jolt.h>

#include <Jolt/Core/StreamIn.h>
#include <Jolt/Core/StreamOut.h>
#include <Jolt/Geometry/AABox.h>
#include <Jolt/Physics/Collision/Shape/ConvexHullShape.h>
#include <Jolt/Physics/Collision/Shape/Shape.h>
#include <Jolt/Physics/Collision/CollisionCollectorImpl.h>
#include <Jolt/Physics/Collision/TransformedShape.h>

#include <cstdlib>
#include <cstring>
#include <vector>

struct jcb_blob
{
    std::vector<uint8_t> bytes;
};

namespace
{
    /* Jolt writes through a stream, so the blob grows as the shape is written into it. */
    struct BlobOut final : JPH::StreamOut
    {
        std::vector<uint8_t>& bytes;

        explicit BlobOut(std::vector<uint8_t>& b) : bytes(b) {}

        void WriteBytes(const void* data, size_t count) override
        {
            const size_t offset = bytes.size();
            bytes.resize(offset + count);
            std::memcpy(bytes.data() + offset, data, count);
        }

        bool IsFailed() const override { return false; }
    };

    struct BlobIn final : JPH::StreamIn
    {
        const uint8_t* data;
        size_t size;
        size_t cursor = 0;
        bool failed = false;

        BlobIn(const uint8_t* d, size_t s) : data(d), size(s) {}

        void ReadBytes(void* out, size_t count) override
        {
            if (cursor + count > size)
            {
                failed = true;
                return;
            }
            std::memcpy(out, data + cursor, count);
            cursor += count;
        }

        /* istream semantics: the end is only reached when a read runs PAST it, which is
           what Jolt checks after a fully consumed restore. */
        bool IsEOF() const override { return failed; }
        bool IsFailed() const override { return failed; }
    };
}

const void* jcb_blob_data(const jcb_blob* blob)
{
    return (blob != nullptr && !blob->bytes.empty()) ? blob->bytes.data() : nullptr;
}

size_t jcb_blob_size(const jcb_blob* blob)
{
    return (blob != nullptr) ? blob->bytes.size() : 0;
}

void jcb_blob_destroy(jcb_blob* blob)
{
    delete blob;
}

void jcb_convex_hull_settings_set_hull_tolerance(JPH_ConvexHullShapeSettings* settings,
                                                 float tolerance)
{
    if (settings != nullptr)
    {
        reinterpret_cast<JPH::ConvexHullShapeSettings*>(settings)->mHullTolerance = tolerance;
    }
}

jcb_blob* jcb_shape_save(const JPH_Shape* shape)
{
    if (shape == nullptr)
    {
        return nullptr;
    }

    jcb_blob* blob = new jcb_blob();
    BlobOut out(blob->bytes);
    reinterpret_cast<const JPH::Shape*>(shape)->SaveBinaryState(out);
    if (blob->bytes.empty())
    {
        delete blob;
        return nullptr;
    }
    return blob;
}

JPH_Shape* jcb_shape_restore(const void* data, size_t size)
{
    const uint8_t* bytes = static_cast<const uint8_t*>(data);
    /* Jolt indexes its construct table with the leading subtype byte UNVALIDATED, so a
       corrupt or foreign blob is rejected here rather than read as one. */
    if (bytes == nullptr || size == 0 ||
        static_cast<JPH::uint>(bytes[0]) >= JPH::NumSubShapeTypes)
    {
        return nullptr;
    }

    BlobIn in(bytes, size);
    JPH::Shape::ShapeResult result = JPH::Shape::sRestoreFromBinaryState(in);
    if (in.IsFailed() || !result.IsValid())
    {
        return nullptr;
    }

    /* The reference the result holds dies with it, so the caller's is taken here and
       released by JPH_Shape_Destroy. */
    JPH::Shape* restored = result.Get();
    restored->AddRef();
    return reinterpret_cast<JPH_Shape*>(restored);
}

jcb_blob* jcb_shape_triangles(const JPH_Shape* shape)
{
    if (shape == nullptr)
    {
        return nullptr;
    }

    const JPH::Shape* jolt = reinterpret_cast<const JPH::Shape*>(shape);
    JPH::Shape::GetTrianglesContext context;
    jolt->GetTrianglesStart(context, JPH::AABox::sBiggest(), JPH::Vec3::sZero(),
                            JPH::Quat::sIdentity(), JPH::Vec3::sOne());

    jcb_blob* blob = new jcb_blob();
    JPH::Float3 buffer[3 * JPH::Shape::cGetTrianglesMinTrianglesRequested];
    for (;;)
    {
        const int count =
            jolt->GetTrianglesNext(context, JPH::Shape::cGetTrianglesMinTrianglesRequested, buffer);
        if (count <= 0)
        {
            break;
        }
        const size_t offset = blob->bytes.size();
        const size_t added = static_cast<size_t>(count) * 3 * sizeof(JPH::Float3);
        blob->bytes.resize(offset + added);
        std::memcpy(blob->bytes.data() + offset, buffer, added);
    }

    if (blob->bytes.empty())
    {
        delete blob;
        return nullptr;
    }
    return blob;
}

jcb_blob* jcb_shape_world_triangles(const JPH_Shape* shape, const JPH_Vec3* position,
                                    const JPH_Quat* rotation, const JPH_Vec3* boxMin,
                                    const JPH_Vec3* boxMax)
{
    if (shape == nullptr || position == nullptr || rotation == nullptr || boxMin == nullptr ||
        boxMax == nullptr)
    {
        return nullptr;
    }

    const JPH::Shape* jolt = reinterpret_cast<const JPH::Shape*>(shape);
    const JPH::Vec3 lo(boxMin->x, boxMin->y, boxMin->z);
    const JPH::Vec3 hi(boxMax->x, boxMax->y, boxMax->z);
    const JPH::AABox box(lo, hi);
    const JPH::Quat turn(rotation->x, rotation->y, rotation->z, rotation->w);

    // A compound only yields triangles through its leaves, so the shape goes through
    // CollectTransformedShapes first (a leaf collects itself). The body's origin is its centre
    // of mass, as body creation places it.
    const JPH::TransformedShape whole(
        JPH::RVec3(position->x, position->y, position->z) + turn * jolt->GetCenterOfMass(), turn,
        jolt, JPH::BodyID());
    JPH::AllHitCollisionCollector<JPH::TransformedShapeCollector> leaves;
    whole.CollectTransformedShapes(box, leaves);

    jcb_blob* blob = new jcb_blob();
    JPH::Float3 buffer[3 * JPH::Shape::cGetTrianglesMinTrianglesRequested];
    for (const JPH::TransformedShape& leaf : leaves.mHits)
    {
        JPH::Shape::GetTrianglesContext context;
        leaf.GetTrianglesStart(context, box, JPH::RVec3::sZero());
        for (;;)
        {
            const int count =
                leaf.GetTrianglesNext(context, JPH::Shape::cGetTrianglesMinTrianglesRequested, buffer);
            if (count <= 0)
            {
                break;
            }
            // The box only culls inside meshes and heightfields; a convex shape or a plane
            // gives all of itself, so each triangle is tested here.
            for (int t = 0; t < count; ++t)
            {
                const JPH::Float3* corner = &buffer[3 * t];
                JPH::AABox extent;
                for (int v = 0; v < 3; ++v)
                {
                    extent.Encapsulate(JPH::Vec3(corner[v]));
                }
                if (!extent.Overlaps(box))
                {
                    continue;
                }
                const size_t offset = blob->bytes.size();
                blob->bytes.resize(offset + 3 * sizeof(JPH::Float3));
                std::memcpy(blob->bytes.data() + offset, corner, 3 * sizeof(JPH::Float3));
            }
        }
    }

    if (blob->bytes.empty())
    {
        delete blob;
        return nullptr;
    }
    return blob;
}
