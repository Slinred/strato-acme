import os

__version__ = os.getenv("UV_PUBLISH_VERSION", "0.0.0").removeprefix("v").removesuffix(".post0")
