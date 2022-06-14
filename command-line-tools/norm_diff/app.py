import click
import os
from osgeo import gdal
import numpy as np


@click.command(
    short_help="Normalized difference",
    help="Performs a normalized difference",
    context_settings=dict(
        ignore_unknown_options=True,
        allow_extra_args=True,
    ),
)
@click.argument("tifs", nargs=2)
@click.pass_context
def app(ctx, tifs):

    # Allow division by zero
    np.seterr(divide="ignore", invalid="ignore")

    print(tifs)

    ds1 = gdal.Open(tifs[0])
    ds2 = gdal.Open(tifs[1])

    driver = gdal.GetDriverByName("GTiff")

    dst_ds = driver.Create(
        "norm_diff.tif",
        ds1.RasterXSize,
        ds1.RasterYSize,
        1,
        gdal.GDT_Float32,
        options=["TILED=YES", "COMPRESS=DEFLATE", "INTERLEAVE=BAND"],
    )

    dst_ds.SetGeoTransform(ds1.GetGeoTransform())
    dst_ds.SetProjection(ds1.GetProjectionRef())

    array1 = ds1.GetRasterBand(1).ReadAsArray().astype(float)
    array2 = ds2.GetRasterBand(1).ReadAsArray().astype(float)

    norm_diff = (array1 - array2) / (array1 + array2)

    dst_ds.GetRasterBand(1).WriteArray(norm_diff)


if __name__ == "__main__":
    app()
