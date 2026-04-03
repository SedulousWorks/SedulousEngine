using System;
using System.Collections;
using Sedulous.Core;

using internal Sedulous.Core.Mathematics;

namespace Sedulous.Core.Mathematics;

/// <summary>
/// Represents a bounding sphere.
/// </summary>
struct BoundingSphere : IEquatable<BoundingSphere>, IEquatable, IHashable
{
    /// <summary>
    /// Initializes a new instance of the <see cref="BoundingSphere"/> structure.
    /// </summary>
    /// <param name="center">The sphere's center position.</param>
    /// <param name="radius">The sphere's radius.</param>
    public this(Vector3 center, float radius)
    {
        Contract.EnsureRange(radius >= 0, nameof(radius));

        this.Center = center;
        this.Radius = radius;
    }

    /// <summary>
    /// Creates a new <see cref="BoundingSphere"/> by merging two existing bounding spheres.
    /// </summary>
    /// <param name="original">The first <see cref="BoundingSphere"/> to merge.</param>
    /// <param name="additional">The second <see cref="BoundingSphere"/> to merge.></param>
    /// <returns name="result">The merged <see cref="BoundingSphere"/> which was created.</returns>
    public static BoundingSphere CreateMerged(BoundingSphere original, BoundingSphere additional)
    {
        CreateMerged(original, additional, var result);
        return result;
    }

    /// <summary>
    /// Creates a new <see cref="BoundingSphere"/> by merging two existing bounding spheres.
    /// </summary>
    /// <param name="original">The first <see cref="BoundingSphere"/> to merge.</param>
    /// <param name="additional">The second <see cref="BoundingSphere"/> to merge.></param>
    /// <param name="result">The merged <see cref="BoundingSphere"/> which was created.</param>
    public static void CreateMerged(in BoundingSphere original, in BoundingSphere additional, out BoundingSphere result)
    {
        Vector3.Subtract(additional.Center, original.Center, var offset);

        var distance = offset.Length();
        if (original.Radius + additional.Radius >= distance)
        {
            if (distance <= original.Radius - additional.Radius)
            {
                result = original;
                return;
            }

            if (distance <= additional.Radius - original.Radius)
            {
                result = additional;
                return;
            }
        }

        var normalizedOffset = offset * (1.0f / distance);
        var min = Math.Min(-original.Radius, distance - additional.Radius);
        var max = (Math.Max(original.Radius, distance + additional.Radius) - min) * 0.5f;

        result.Center = original.Center + normalizedOffset * (max + min);
        result.Radius = max;
    }

    /// <summary>
    /// Creates a new <see cref="BoundingSphere"/> which encompasses all of the points in the specified collection.
    /// </summary>
    /// <param name="points">The collection of points from which to create the bounding sphere.</param>
    /// <returns>The <see cref="BoundingSphere"/> which was created.</returns>
    /*public static BoundingSphere CreateFromPoints(IEnumerable<Vector3> points)
    {
        CreateFromPoints(points, var result);
        return result;
    }*/

    /// <summary>
    /// Creates a new <see cref="BoundingSphere"/> which encompasses all of the points in the specified collection.
    /// </summary>
    /// <param name="points">The collection of points from which to create the bounding sphere.</param>
    /// <param name="result">The <see cref="BoundingSphere"/> which was created.</param>
    /*public static void CreateFromPoints(in IEnumerable<Vector3> points, out BoundingSphere result)
    {
        Contract.Require(points, nameof(points));
        
        var enumerator = points.GetEnumerator();
        var empty = !enumerator.MoveNext();
        if (empty)
            Runtime.ArgumentError(nameof(points));

        var minX = enumerator.Current;
        var maxX = enumerator.Current;
        var minY = enumerator.Current;
        var maxY = enumerator.Current;
        var minZ = enumerator.Current;
        var maxZ = enumerator.Current;

        for (var point in points)
        {
            if (point.X < minX.X)
                minX = point;

            if (point.X > maxX.X)
                maxX = point;

            if (point.Y < minY.Y)
                minY = point;

            if (point.Y > maxY.Y)
                maxY = point;

            if (point.Z < minZ.Z)
                minZ = point;

            if (point.Z > maxZ.Z)
                maxZ = point;
        }

        Vector3.Distance(minX, maxX, var diameterX);
        Vector3.Distance(minY, maxY, var diameterY);
        Vector3.Distance(minZ, maxZ, var diameterZ);

        var center = default(Vector3);
        var radius = default(float);

        if (diameterX > diameterY && diameterX > diameterZ)
        {
            Vector3.Lerp(minX, minY, 0.5f, out center);
            radius = diameterX * 0.5f;
        }
        else
        {
            if (diameterY > diameterZ)
            {
                Vector3.Lerp(minY, maxY, 0.5f, out center);
                radius = diameterY * 0.5f;
            }
            else
            {
                Vector3.Lerp(minZ, maxZ, 0.5f, out center);
                radius = diameterZ * 0.5f;
            }
        }

        for (var point in points)
        {
            var pointRelativeToCenter = default(Vector3);
            pointRelativeToCenter.X = point.X - center.X;
            pointRelativeToCenter.Y = point.Y - center.Y;
            pointRelativeToCenter.Z = point.Z - center.Z;

            var pointDistanceToCenter = pointRelativeToCenter.Length();
            if (pointDistanceToCenter > radius)
            {
                radius = pointDistanceToCenter;
                center = center + ((1.0f - radius / pointDistanceToCenter) * pointRelativeToCenter);
            }
        }

        result.Center = center;
        result.Radius = radius;
    }*/

    /// <summary>
    /// Creates a new <see cref="BoundingSphere"/> which encompasses all of the points in the specified collection.
    /// </summary>
    /// <param name="points">The collection of points from which to create the bounding sphere.</param>
    /// <returns>The <see cref="BoundingSphere"/> which was created.</returns>
    public static BoundingSphere CreateFromPoints(Span<Vector3> points)
    {
        CreateFromPoints(points, var result);
        return result;
    }

    /// <summary>
    /// Creates a new <see cref="BoundingSphere"/> which encompasses all of the points in the specified collection.
    /// </summary>
    /// <param name="points">The collection of points from which to create the bounding sphere.</param>
    /// <param name="result">The <see cref="BoundingSphere"/> which was created.</param>
    public static void CreateFromPoints(Span<Vector3> points, out BoundingSphere result)
    {
        if (points.Length == 0)
            Runtime.ArgumentError(nameof(points));

        var minX = points[0];
        var maxX = minX;
        var minY = minX;
        var maxY = minX;
        var minZ = minX;
        var maxZ = minX;

        for (int i = 1; i < points.Length; i++)
        {
            var point = points[i];

            if (point.X < minX.X)
                minX = point;

            if (point.X > maxX.X)
                maxX = point;

            if (point.Y < minY.Y)
                minY = point;

            if (point.Y > maxY.Y)
                maxY = point;

            if (point.Z < minZ.Z)
                minZ = point;

            if (point.Z > maxZ.Z)
                maxZ = point;
        }

        Vector3.Distance(minX, maxX, var diameterX);
        Vector3.Distance(minY, maxY, var diameterY);
        Vector3.Distance(minZ, maxZ, var diameterZ);

        var center = default(Vector3);
        var radius = default(float);
        
        if (diameterX > diameterY && diameterX > diameterZ)
        {
            Vector3.Lerp(minX, minY, 0.5f, out center);
            radius = diameterX * 0.5f;
        }
        else
        {
            if (diameterY > diameterZ)
            {
                Vector3.Lerp(minY, maxY, 0.5f, out center);
                radius = diameterY * 0.5f;
            }
            else
            {
                Vector3.Lerp(minZ, maxZ, 0.5f, out center);
                radius = diameterZ * 0.5f;
            }
        }

        for (int i = 0; i < points.Length; i++)
        {
            var point = points[i];

            Vector3.Subtract(point, center, var pointRelativeToCenter);

            var pointDistanceToCenter = pointRelativeToCenter.Length();
            if (pointDistanceToCenter > radius)
            {
                radius = (radius + pointDistanceToCenter) * 0.5f;
                center = center + ((1.0f - radius / pointDistanceToCenter) * pointRelativeToCenter);
            }
        }

        result.Center = center;
        result.Radius = radius;
    }

    /// <summary>
    /// Creates a new <see cref="BoundingSphere"/> which encompasses the specified frustum.
    /// </summary>
    /// <param name="frustum">The frustum from which to create the bounding sphere.</param>
    /// <returns>The <see cref="BoundingSphere"/> which was created.</returns>
    public static BoundingSphere CreateFromFrustum(BoundingFrustum frustum)
    {
        CreateFromPoints(frustum.CornersInternal, var result);
        return result;
    }

    /// <summary>
    /// Creates a new <see cref="BoundingSphere"/> which encompasses the specified frustum.
    /// </summary>
    /// <param name="frustum">The frustum from which to create the bounding sphere.</param>
    /// <param name="result">The <see cref="BoundingSphere"/> which was created.</param>
    public static void CreateFromFrustum(in BoundingFrustum frustum, out BoundingSphere result)
    {
        CreateFromPoints(frustum.CornersInternal, out result);
    }

    /// <inheritdoc/>
    public override void ToString(String str) => str.Append( scope $"{{Center:{Center} Radius:{Radius}}}");

    /// <summary>
    /// Gets a value indicating whether this <see cref="BoundingSphere"/> contains the specified point.
    /// </summary>
    /// <param name="point">A <see cref="Vector3"/> which represents the point to evaluate.</param>
    /// <returns>A <see cref="ContainmentType"/> value representing the relationship between this sphere and the evaluated point.</returns>
    public ContainmentType Contains(Vector3 point)
    {
        Vector3.DistanceSquared(point, Center, var distanceSquared);
        return distanceSquared < Radius * Radius ? ContainmentType.Contains : ContainmentType.Disjoint;
    }

    /// <summary>
    /// Gets a value indicating whether this <see cref="BoundingSphere"/> contains the specified point.
    /// </summary>
    /// <param name="point">A <see cref="Vector3"/> which represents the point to evaluate.</param>
    /// <param name="result">A <see cref="ContainmentType"/> value representing the relationship between this sphere and the evaluated point.</param>
    public void Contains(in Vector3 point, out ContainmentType result)
    {
        Vector3.DistanceSquared(point, Center, var distanceSquared);
        result = distanceSquared < Radius * Radius ? ContainmentType.Contains : ContainmentType.Disjoint;
    }

    /// <summary>
    /// Gets a value indicating whether this <see cref="BoundingSphere"/> contains the specified frustum.
    /// </summary>
    /// <param name="frustum">A <see cref="BoundingFrustum"/> which represents the frustum to evaluate.</param>
    /// <returns>A <see cref="ContainmentType"/> value representing the relationship between this sphere and the evaluated frustum.</returns>
    public ContainmentType Contains(BoundingFrustum frustum)
    {
        if (!frustum.Intersects(this))
            return ContainmentType.Disjoint;

        var radiusSquared = Radius * Radius;

        for (var corner in frustum.CornersInternal)
        {
            Vector3 cornerRelativeToCenter;
            cornerRelativeToCenter.X = corner.X - Center.X;
            cornerRelativeToCenter.Y = corner.Y - Center.Y;
            cornerRelativeToCenter.Z = corner.Z - Center.Z;

            if (cornerRelativeToCenter.LengthSquared() > radiusSquared)
                return ContainmentType.Intersects;
        }

        return ContainmentType.Contains;
    }

    /// <summary>
    /// Gets a value indicating whether this <see cref="BoundingSphere"/> contains the specified frustum.
    /// </summary>
    /// <param name="frustum">A <see cref="BoundingFrustum"/> which represents the frustum to evaluate.</param>
    /// <param name="result">A <see cref="ContainmentType"/> value representing the relationship between this sphere and the evaluated frustum.</param>
    public void Contains(in BoundingFrustum frustum, out ContainmentType result)
    {
        result = Contains(frustum);
    }

    /// <summary>
    /// Gets a value indicating whether this <see cref="BoundingSphere"/> contains the specified sphere.
    /// </summary>
    /// <param name="sphere">A <see cref="BoundingSphere"/> which represents the sphere to evaluate.</param>
    /// <returns>A <see cref="ContainmentType"/> value representing the relationship between this sphere and the evaluated sphere.</returns>
    public ContainmentType Contains(BoundingSphere sphere)
    {
        Contains(sphere, var result);
        return result;
    }

    /// <summary>
    /// Gets a value indicating whether this <see cref="BoundingSphere"/> contains the specified sphere.
    /// </summary>
    /// <param name="sphere">A <see cref="BoundingSphere"/> which represents the sphere to evaluate.</param>
    /// <param name="result">A <see cref="ContainmentType"/> value representing the relationship between this sphere and the evaluated sphere.</param>
    public void Contains(in BoundingSphere sphere, out ContainmentType result)
    {
        Vector3.DistanceSquared(Center, sphere.Center, var distanceSquared);

        var combinedRadii = Radius + sphere.Radius;
        var combinedRadiiSquared = combinedRadii * combinedRadii;

        if (distanceSquared > combinedRadiiSquared)
        {
            result = ContainmentType.Disjoint;
        }
        else
        {
            var subtractedRadii = Radius - sphere.Radius;
            var subtractedRadiiSquared = subtractedRadii * subtractedRadii;

            result = (subtractedRadiiSquared < distanceSquared) ? ContainmentType.Intersects : ContainmentType.Contains;
        }
    }

    /// <summary>
    /// Gets a value indicating whether this <see cref="BoundingSphere"/> contains the specified bounding box.
    /// </summary>
    /// <param name="box">A <see cref="BoundingSphere"/> which represents the sphere to evaluate.</param>
    /// <returns>A <see cref="ContainmentType"/> value representing the relationship between this sphere and the evaluated bounding box.</returns>
    public ContainmentType Contains(BoundingBox @box)
    {
        Contains(@box, var result);
        return result;
    }

    /// <summary>
    /// Gets a value indicating whether this <see cref="BoundingSphere"/> contains the specified bounding box.
    /// </summary>
    /// <param name="box">A <see cref="BoundingSphere"/> which represents the sphere to evaluate.</param>
    /// <param name="result">A <see cref="ContainmentType"/> value representing the relationship between this sphere and the evaluated bounding box.</param>
    public void Contains(in BoundingBox @box, out ContainmentType result)
    {
        var inside = true;

        for (int i = 0; i < BoundingBox.CornerCount; i++)
        {
            var corner = @box.GetCorner(i);
            if (Contains(corner) == ContainmentType.Disjoint)
            {
                inside = false;
                break;
            }
        }

        if (inside)
        {
            result = ContainmentType.Contains;
            return;
        }

        var distance = 0.0;

        if (Center.X < @box.Min.X)
            distance += (Center.X - @box.Min.X) * (Center.X - @box.Min.X);
        else if (Center.X > @box.Max.X)
            distance += (Center.X - @box.Max.X) * (Center.X - @box.Max.X);
        
        if (Center.Y < @box.Min.Y)
            distance += (Center.Y - @box.Min.Y) * (Center.Y - @box.Min.Y);
        else if (Center.Y > @box.Max.Y)
            distance += (Center.Y - @box.Max.Y) * (Center.Y - @box.Max.Y);
        
        if (Center.Z < @box.Min.Z)
            distance += (Center.Z - @box.Min.Z) * (Center.Z - @box.Min.Z);
        else if (Center.Z > @box.Max.Z)
            distance += (Center.Z - @box.Max.Z) * (Center.Z - @box.Max.Z);

        if (distance <= Radius * Radius)
        {
            result = ContainmentType.Intersects;
            return;
        }

        result = ContainmentType.Disjoint;
    }

    /// <summary>
    /// Gets a value indicating whether this <see cref="BoundingSphere"/> intersects the specified frustum.
    /// </summary>
    /// <param name="frustum">A <see cref="BoundingFrustum"/> which represents the frustum to evaluate.</param>
    /// <returns><see langword="true"/> if this sphere intersects the evaluated frustum; otherwise, <see langword="false"/>.</returns>
    public bool Intersects(BoundingFrustum frustum)
    {
        frustum.Intersects(this, var result);
        return result;
    }

    /// <summary>
    /// Gets a value indicating whether this <see cref="BoundingSphere"/> intersects the specified frustum.
    /// </summary>
    /// <param name="frustum">A <see cref="BoundingFrustum"/> which represents the frustum to evaluate.</param>
    /// <param name="result"><see langword="true"/> if this sphere intersects the evaluated frustum; otherwise, <see langword="false"/>.</param>
    public void Intersects(in BoundingFrustum frustum, out bool result)
    {
        frustum.Intersects(this, out result);
    }

    /// <summary>
    /// Gets a value indicating whether this <see cref="BoundingSphere"/> intersects the specified sphere.
    /// </summary>
    /// <param name="sphere">A <see cref="BoundingSphere"/> which represents the sphere to evaluate.</param>
    /// <returns><see langword="true"/> if this sphere intersects the evaluated frustum; otherwise, <see langword="false"/>.</returns>
    public bool Intersects(BoundingSphere sphere)
    {
        Intersects(sphere, var result);
        return result;
    }

    /// <summary>
    /// Gets a value indicating whether this <see cref="BoundingSphere"/> intersects the specified sphere.
    /// </summary>
    /// <param name="sphere">A <see cref="BoundingSphere"/> which represents the sphere to evaluate.</param>
    /// <param name="result"><see langword="true"/> if this sphere intersects the evaluated frustum; otherwise, <see langword="false"/>.</param>
    public void Intersects(in BoundingSphere sphere, out bool result)
    {
        Vector3.DistanceSquared(Center, sphere.Center, var distanceSquared);

        var combinedRadii = Radius + sphere.Radius;
        var combinedRadiiSquared = combinedRadii * combinedRadii;

        result = distanceSquared <= combinedRadiiSquared;
    }

    /// <summary>
    /// Gets a value indicating whether this <see cref="BoundingSphere"/> intersects the specified bounding box.
    /// </summary>
    /// <param name="box">A <see cref="BoundingBox"/> which represents the box to evaluate.</param>
    /// <returns><see langword="true"/> if this sphere intersects the evaluated box; otherwise, <see langword="false"/>.</returns>
    public bool Intersects(BoundingBox @box)
    {
        return @box.Intersects(this);
    }

    /// <summary>
    /// Gets a value indicating whether this <see cref="BoundingSphere"/> intersects the specified bounding box.
    /// </summary>
    /// <param name="box">A <see cref="BoundingBox"/> which represents the box to evaluate.</param>
    /// <param name="result"><see langword="true"/> if this sphere intersects the evaluated box; otherwise, <see langword="false"/>.</param>
    public void Intersects(in BoundingBox @box, out bool result)
    {
        @box.Intersects(this, out result);
    }

    /// <summary>
    /// Gets a value indicating whether this <see cref="BoundingSphere"/> intersects the specified plane.
    /// </summary>
    /// <param name="plane">A <see cref="Plane"/> which represents the plane to evaluate.</param>
    /// <returns><see langword="true"/> if this sphere intersects the evaluated plane; otherwise, <see langword="false"/>.</returns>
    public PlaneIntersectionType Intersects(Plane plane)
    {
        Intersects(plane, var result);
        return result;
    }

    /// <summary>
    /// Gets a value indicating whether this <see cref="BoundingSphere"/> intersects the specified plane.
    /// </summary>
    /// <param name="plane">A <see cref="Plane"/> which represents the plane to evaluate.</param>
    /// <param name="result"><see langword="true"/> if this sphere intersects the evaluated plane; otherwise, <see langword="false"/>.</param>
    public void Intersects(in Plane plane, out PlaneIntersectionType result)
    {
        Vector3.Dot(plane.Normal, Center, var distance);
        distance += plane.D;

        if (distance > Radius)
        {
            result = PlaneIntersectionType.Front;
        }
        else
        {
            if (distance < -this.Radius)
            {
                result = PlaneIntersectionType.Back;
            }
            else
            {
                result = PlaneIntersectionType.Intersecting;
            }
        }
    }

    /// <summary>
    /// Gets a value indicating whether this <see cref="BoundingSphere"/> intersects the specified ray.
    /// </summary>
    /// <param name="ray">A <see cref="Ray"/> which represents the ray to evaluate.</param>
    /// <returns>The distance along the ray at which it intersects this sphere, or <see langword="null"/> if there is no intersection.</returns>
    public float? Intersects(Ray ray)
    {
        ray.Intersects(this, var result);
        return result;
    }

    /// <summary>
    /// Gets a value indicating whether this <see cref="BoundingSphere"/> intersects the specified ray.
    /// </summary>
    /// <param name="ray">A <see cref="Ray"/> which represents the ray to evaluate.</param>
    /// <param name="result">The distance along the ray at which it intersects this sphere, or <see langword="null"/> if there is no intersection.</param>
    public void Intersects(in Ray ray, out float? result)
    {
        ray.Intersects(this, out result);
    }

    /// <summary>
    /// Creates a new <see cref="BoundingSphere"/> which is the result of applying the specified
    /// transformation matrix to this bounding sphere.
    /// </summary>
    /// <param name="matrix">The transformation matrix to apply to the sphere.</param>
    /// <returns>The transformed <see cref="BoundingSphere"/> that was created.</returns>
    public BoundingSphere Transform(Matrix matrix)
    {
        var result = BoundingSphere
        {
            Center = Vector3.Transform(Center, matrix),
            Radius = this.Radius * (float)Math.Sqrt(
                Math.Max(matrix.M11 * matrix.M11 + matrix.M12 * matrix.M12 + matrix.M13 * matrix.M13,
                    Math.Max(
                        matrix.M21 * matrix.M21 + matrix.M22 * matrix.M22 + matrix.M23 * matrix.M23,
                        matrix.M31 * matrix.M31 + matrix.M32 * matrix.M32 + matrix.M33 * matrix.M33)))
        };
        return result;
    }

    /// <summary>
    /// Creates a new <see cref="BoundingSphere"/> which is the result of applying the specified
    /// transformation matrix to this bounding sphere.
    /// </summary>
    /// <param name="matrix">The transformation matrix to apply to the sphere.</param>
    /// <param name="result">The transformed <see cref="BoundingSphere"/> that was created.</param>
    public void Transform(in Matrix matrix, out BoundingSphere result)
    {
        result = BoundingSphere
        {
            Center = Vector3.Transform(Center, matrix),
            Radius = this.Radius * (float)Math.Sqrt(
                Math.Max(matrix.M11 * matrix.M11 + matrix.M12 * matrix.M12 + matrix.M13 * matrix.M13,
                    Math.Max(
                        matrix.M21 * matrix.M21 + matrix.M22 * matrix.M22 + matrix.M23 * matrix.M23,
                        matrix.M31 * matrix.M31 + matrix.M32 * matrix.M32 + matrix.M33 * matrix.M33)))
        };
    }

    /// <summary>
    /// The sphere's center position.
    /// </summary>
    public Vector3 Center;

    /// <summary>
    /// The sphere's radius.
    /// </summary>
    public float Radius;        
}
