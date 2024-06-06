import os
import re
import time
import tempfile
from typing import List

from kserve.logging import logger
from oras.provider import Registry

_OCI_PREFIX = "oci-artifact://"


class Storage(object):

    @staticmethod
    def download(uri: str, out_dir: str = None):
        start = time.monotonic()
        logger.info(f"Trying to download {uri} to {out_dir}")

        if out_dir is None:
            out_dir = tempfile.mkdtemp()
        elif not os.path.exists(out_dir):
            os.mkdir(out_dir)

        if uri.startswith(_OCI_PREFIX):
            Storage._download_oci(uri, out_dir)
        else:
            raise Exception(
                f"Cannot recognize storage type for '{uri}': '{_OCI_PREFIX}' is the current available storage type."
            )

        logger.info("Successfully copied %s to %s", uri, out_dir)
        logger.info(f"Model downloaded in {time.monotonic() - start} seconds.")
        return out_dir

    @staticmethod
    def _get_oras_client() -> Registry:
        """
        Consistent method to get an oras client
        """
        user = os.getenv("ORAS_USER")
        password = os.getenv("ORAS_PASS")
        reg = Registry()
        if user and password:
            print("Found username and password for basic auth")
            reg.set_basic_auth(user, password)
        else:
            logger.warning("No ORAS_USER or ORAS_PASS defined, no auth.")
        return reg

    @staticmethod
    def _download_oci(uri: str, out_dir: str):
        client = Storage._get_oras_client()
        oras_target = re.sub(r'^oci-artifact://', '', uri)
        if ':' not in oras_target:
            raise Exception("Expected to contain at least a `:tag`")
        parts: List[str] = oras_target.split(':', 1)
        client.pull(target=oras_target, outdir=out_dir)
