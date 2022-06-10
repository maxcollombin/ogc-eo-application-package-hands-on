
import click
import pystac_client
import shapely

@click.command(
    short_help="discovery",
    help="Discovers Sentinel-2 STAC items",
    context_settings=dict(
        ignore_unknown_options=True,
        allow_extra_args=True,
    ),
)
@click.option(
    "--endpoint",
    "-e",
    "endpoint",
    help="STAC API endpoint",
    required=True,
    multiple=False,
)
@click.option(
    "--start-date",
    "-sd",
    "start_date",
    help="Start date (ISO)",
    required=True,
    multiple=False,
)
@click.option(
    "--end-date",
    "-ed",
    "stop_date",
    help="Stop date (ISO)",
    required=True,
    multiple=False,
)
@click.option(
    "--aoi",
    "-a",
    "aoi",
    help="Area of interest (WTK or bounding box",
    required=True,
    multiple=False,
)
@click.pass_context
def discovery(
    ctx,
    endpoint,
    startdate,
    enddate,
    aoi,
):

    params = {}

    endpoint = "https://earth-search.aws.element84.com/v0"

def geom_from_aoi(aoi):

    geom = {
        "type": "Polygon",
        "coordinates": [
        [
            [
            6.42425537109375,
            53.174765470134616
            ],
            [
            7.344360351562499,
    …        [
            6.42425537109375,
            53.174765470134616
            ]
        ]
        ]
    }

    return geom

def query(params):
    return cat.search(filter_lang="cql2-json", **params)

    geom = {
        "type": "Polygon",
        "coordinates": [
        [
            [
            6.42425537109375,
            53.174765470134616
            ],
            [
            7.344360351562499,
    …        [
            6.42425537109375,
            53.174765470134616
            ]
        ]
        ]
    }

params = {
    "collections": "sentinel-s2-l2a",
    "intersects": geom,
    "max_items": 100,
}

for item in search.get_items():
    print(item)