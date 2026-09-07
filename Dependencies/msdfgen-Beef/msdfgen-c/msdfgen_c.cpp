/*
 * msdfgen C API implementation.
 *
 * The handles are the C++ objects themselves, reinterpreted: msdfgen::Shape and
 * msdfgen::Contour are ordinary classes with stable addresses, so a cast is enough and
 * there is nothing to keep in step. The bitmap is the exception - msdfgen::Bitmap is a
 * TEMPLATE on channel count, so one C handle has to stand for four different C++ types,
 * and that needs a small struct of its own.
 */

#include "msdfgen_c.h"

#include <msdfgen.h>

#include <new>

namespace
{

    inline msdfgen::Shape *AsShape(msdf_Shape *shape)
    {
        return reinterpret_cast<msdfgen::Shape *>(shape);
    }
    inline const msdfgen::Shape *AsShape(const msdf_Shape *shape)
    {
        return reinterpret_cast<const msdfgen::Shape *>(shape);
    }
    inline msdfgen::Contour *AsContour(msdf_Contour *contour)
    {
        return reinterpret_cast<msdfgen::Contour *>(contour);
    }
    inline const msdfgen::Contour *AsContour(const msdf_Contour *contour)
    {
        return reinterpret_cast<const msdfgen::Contour *>(contour);
    }

    inline msdfgen::EdgeColor AsEdgeColor(msdf_EdgeColor color)
    {
        return static_cast<msdfgen::EdgeColor>(color);
    }

    inline msdfgen::SDFTransformation AsTransformation(const msdf_Transform *transform)
    {
        if (transform == NULL)
        {
            return msdfgen::SDFTransformation(msdfgen::Projection(), msdfgen::Range(1.0));
        }
        return msdfgen::SDFTransformation(
            msdfgen::Projection(msdfgen::Vector2(transform->scaleX, transform->scaleY),
                                msdfgen::Vector2(transform->translateX, transform->translateY)),
            msdfgen::Range(transform->rangeLower, transform->rangeUpper));
    }

    inline msdfgen::MSDFGeneratorConfig AsConfig(const msdf_Config *config)
    {
        if (config == NULL)
        {
            return msdfgen::MSDFGeneratorConfig();
        }
        msdfgen::ErrorCorrectionConfig errorCorrection(
            static_cast<msdfgen::ErrorCorrectionConfig::Mode>(config->errorCorrectionMode),
            static_cast<msdfgen::ErrorCorrectionConfig::DistanceCheckMode>(
                config->distanceCheckMode),
            config->minDeviationRatio, config->minImproveRatio);
        return msdfgen::MSDFGeneratorConfig(config->overlapSupport != 0, errorCorrection);
    }

} // namespace

/* A float bitmap of a channel count fixed at creation. The channel count is carried
 * alongside so every generator can refuse a bitmap it cannot write. */
struct msdf_Bitmap
{
    int width;
    int height;
    int channels;
    float *pixels;
};

extern "C"
{

    msdf_Config msdf_config_default(void)
    {
        const msdfgen::MSDFGeneratorConfig defaults;
        msdf_Config config;
        config.overlapSupport = defaults.overlapSupport ? 1 : 0;
        config.errorCorrectionMode =
            static_cast<msdf_ErrorCorrectionMode>(defaults.errorCorrection.mode);
        config.distanceCheckMode =
            static_cast<msdf_DistanceCheckMode>(defaults.errorCorrection.distanceCheckMode);
        config.minDeviationRatio = defaults.errorCorrection.minDeviationRatio;
        config.minImproveRatio = defaults.errorCorrection.minImproveRatio;
        return config;
    }

    /* --- Shape --- */

    msdf_Shape *msdf_shape_create(void)
    {
        return reinterpret_cast<msdf_Shape *>(new (std::nothrow) msdfgen::Shape());
    }

    void msdf_shape_destroy(msdf_Shape *shape) { delete AsShape(shape); }

    msdf_Contour *msdf_shape_add_contour(msdf_Shape *shape)
    {
        if (shape == NULL)
        {
            return NULL;
        }
        return reinterpret_cast<msdf_Contour *>(&AsShape(shape)->addContour());
    }

    void msdf_shape_set_inverse_y_axis(msdf_Shape *shape, int inverseYAxis)
    {
        if (shape != NULL)
        {
            AsShape(shape)->inverseYAxis = inverseYAxis != 0;
        }
    }

    int msdf_shape_get_inverse_y_axis(const msdf_Shape *shape)
    {
        return (shape != NULL && AsShape(shape)->inverseYAxis) ? 1 : 0;
    }

    void msdf_shape_normalize(msdf_Shape *shape)
    {
        if (shape != NULL)
        {
            AsShape(shape)->normalize();
        }
    }

    int msdf_shape_validate(const msdf_Shape *shape)
    {
        return (shape != NULL && AsShape(shape)->validate()) ? 1 : 0;
    }

    void msdf_shape_orient_contours(msdf_Shape *shape)
    {
        if (shape != NULL)
        {
            AsShape(shape)->orientContours();
        }
    }

    void msdf_shape_bound(const msdf_Shape *shape, double *left, double *bottom, double *right,
                          double *top)
    {
        /* Seeded the way msdfgen's own callers do: bound() only ever widens, so starting
         * inverted is what makes the first edge set all four sides. */
        double l = 1e240, b = 1e240, r = -1e240, t = -1e240;
        if (shape != NULL)
        {
            AsShape(shape)->bound(l, b, r, t);
        }
        if (left != NULL) *left = l;
        if (bottom != NULL) *bottom = b;
        if (right != NULL) *right = r;
        if (top != NULL) *top = t;
    }

    int msdf_shape_edge_count(const msdf_Shape *shape)
    {
        return shape != NULL ? AsShape(shape)->edgeCount() : 0;
    }

    int msdf_shape_contour_count(const msdf_Shape *shape)
    {
        return shape != NULL ? static_cast<int>(AsShape(shape)->contours.size()) : 0;
    }

    /* --- Contour --- */

    void msdf_contour_add_linear_edge(msdf_Contour *contour, double x0, double y0, double x1,
                                      double y1, msdf_EdgeColor color)
    {
        if (contour != NULL)
        {
            AsContour(contour)->addEdge(msdfgen::EdgeHolder(
                msdfgen::Point2(x0, y0), msdfgen::Point2(x1, y1), AsEdgeColor(color)));
        }
    }

    void msdf_contour_add_quadratic_edge(msdf_Contour *contour, double x0, double y0, double cx,
                                         double cy, double x1, double y1, msdf_EdgeColor color)
    {
        if (contour != NULL)
        {
            AsContour(contour)->addEdge(msdfgen::EdgeHolder(msdfgen::Point2(x0, y0),
                                                           msdfgen::Point2(cx, cy),
                                                           msdfgen::Point2(x1, y1),
                                                           AsEdgeColor(color)));
        }
    }

    void msdf_contour_add_cubic_edge(msdf_Contour *contour, double x0, double y0, double c1x,
                                     double c1y, double c2x, double c2y, double x1, double y1,
                                     msdf_EdgeColor color)
    {
        if (contour != NULL)
        {
            AsContour(contour)->addEdge(msdfgen::EdgeHolder(
                msdfgen::Point2(x0, y0), msdfgen::Point2(c1x, c1y), msdfgen::Point2(c2x, c2y),
                msdfgen::Point2(x1, y1), AsEdgeColor(color)));
        }
    }

    int msdf_contour_edge_count(const msdf_Contour *contour)
    {
        return contour != NULL ? static_cast<int>(AsContour(contour)->edges.size()) : 0;
    }

    int msdf_contour_winding(const msdf_Contour *contour)
    {
        return contour != NULL ? AsContour(contour)->winding() : 0;
    }

    void msdf_contour_reverse(msdf_Contour *contour)
    {
        if (contour != NULL)
        {
            AsContour(contour)->reverse();
        }
    }

    /* --- Edge colouring --- */

    void msdf_edge_coloring_simple(msdf_Shape *shape, double angleThreshold,
                                   unsigned long long seed)
    {
        if (shape != NULL)
        {
            msdfgen::edgeColoringSimple(*AsShape(shape), angleThreshold, seed);
        }
    }

    void msdf_edge_coloring_ink_trap(msdf_Shape *shape, double angleThreshold,
                                     unsigned long long seed)
    {
        if (shape != NULL)
        {
            msdfgen::edgeColoringInkTrap(*AsShape(shape), angleThreshold, seed);
        }
    }

    void msdf_edge_coloring_by_distance(msdf_Shape *shape, double angleThreshold,
                                        unsigned long long seed)
    {
        if (shape != NULL)
        {
            msdfgen::edgeColoringByDistance(*AsShape(shape), angleThreshold, seed);
        }
    }

    /* --- Bitmap --- */

    msdf_Bitmap *msdf_bitmap_create(int width, int height, int channels)
    {
        if (width <= 0 || height <= 0)
        {
            return NULL;
        }
        /* Only the counts a generator can write. Anything else would allocate happily and
         * then be refused by every generate call, which is a worse place to find out. */
        if (channels != 1 && channels != 3 && channels != 4)
        {
            return NULL;
        }

        msdf_Bitmap *bitmap = new (std::nothrow) msdf_Bitmap();
        if (bitmap == NULL)
        {
            return NULL;
        }
        bitmap->pixels =
            new (std::nothrow) float[static_cast<size_t>(width) * height * channels]();
        if (bitmap->pixels == NULL)
        {
            delete bitmap;
            return NULL;
        }
        bitmap->width = width;
        bitmap->height = height;
        bitmap->channels = channels;
        return bitmap;
    }

    void msdf_bitmap_destroy(msdf_Bitmap *bitmap)
    {
        if (bitmap != NULL)
        {
            delete[] bitmap->pixels;
            delete bitmap;
        }
    }

    int msdf_bitmap_width(const msdf_Bitmap *bitmap) { return bitmap != NULL ? bitmap->width : 0; }
    int msdf_bitmap_height(const msdf_Bitmap *bitmap) { return bitmap != NULL ? bitmap->height : 0; }
    int msdf_bitmap_channels(const msdf_Bitmap *bitmap)
    {
        return bitmap != NULL ? bitmap->channels : 0;
    }
    float *msdf_bitmap_data(msdf_Bitmap *bitmap) { return bitmap != NULL ? bitmap->pixels : NULL; }

    /* --- Generation --- */

    int msdf_generate_sdf(msdf_Bitmap *output, const msdf_Shape *shape,
                          const msdf_Transform *transform, const msdf_Config *config)
    {
        if (output == NULL || shape == NULL || output->channels != 1)
        {
            return 0;
        }
        msdfgen::generateSDF(
            msdfgen::BitmapRef<float, 1>(output->pixels, output->width, output->height),
            *AsShape(shape), AsTransformation(transform), AsConfig(config));
        return 1;
    }

    int msdf_generate_psdf(msdf_Bitmap *output, const msdf_Shape *shape,
                           const msdf_Transform *transform, const msdf_Config *config)
    {
        if (output == NULL || shape == NULL || output->channels != 1)
        {
            return 0;
        }
        msdfgen::generatePSDF(
            msdfgen::BitmapRef<float, 1>(output->pixels, output->width, output->height),
            *AsShape(shape), AsTransformation(transform), AsConfig(config));
        return 1;
    }

    int msdf_generate_msdf(msdf_Bitmap *output, const msdf_Shape *shape,
                           const msdf_Transform *transform, const msdf_Config *config)
    {
        if (output == NULL || shape == NULL || output->channels != 3)
        {
            return 0;
        }
        msdfgen::generateMSDF(
            msdfgen::BitmapRef<float, 3>(output->pixels, output->width, output->height),
            *AsShape(shape), AsTransformation(transform), AsConfig(config));
        return 1;
    }

    int msdf_generate_mtsdf(msdf_Bitmap *output, const msdf_Shape *shape,
                            const msdf_Transform *transform, const msdf_Config *config)
    {
        if (output == NULL || shape == NULL || output->channels != 4)
        {
            return 0;
        }
        msdfgen::generateMTSDF(
            msdfgen::BitmapRef<float, 4>(output->pixels, output->width, output->height),
            *AsShape(shape), AsTransformation(transform), AsConfig(config));
        return 1;
    }

} /* extern "C" */
