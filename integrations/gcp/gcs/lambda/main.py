#!/usr/bin/python
# -*- coding: utf-8 -*-

"""
Coralogix GCP function
Author: Coralogix Ltd.
Email: info@coralogix.com
"""

import os
import re
import sys
import gzip
import logging
from google.cloud import storage
from coralogix.handlers import CoralogixLogger

__name__ = 'gcsToCoralogix'
__author__ = 'Coralogix Ltd.'
__email__ = 'info@coralogix.com'
__copyright__ = 'Copyright 2019, Coralogix Ltd.'
__credits__ = ['Ariel Assaraf', 'Amnon Shahar', 'Eldar Aliiev']
__license__ = 'Apache Version 2.0'
__version__ = '1.0.0'
__maintainer__ = 'Coralogix Ltd.'
__date__ = '1 April 2019'
__status__ = 'Stable'

# Get function parameters
PRIVATE_KEY = os.environ.get('private_key')
APP_NAME = os.environ.get('app_name', 'NO_APPLICATION')
SUB_SYSTEM = os.environ.get('sub_name', 'NO_SUBSYSTEM')
NEWLINE_PATTERN = os.environ.get('newline_pattern', '(?:\r\n|\r|\n)')


# Function entrypoint
def to_coralogix(event, context):
    """
    Function entrypoint
    :param event: event metadata
    :type event: dict
    :param context: event context
    :type context: dict
    """

    def get_severity(message: str) -> int:
        """
        Extract severity from message text
        :param message: log record text
        :type message: str
        :return: severity value
        :rtype: int
        """
        severity = 3
        if 'Warning' in message or 'warn' in message:
            severity = 4
        if 'Error' in message or 'Exception' in message:
            severity = 5
        return severity

    # Initialize GCS client
    client = storage.Client()

    # Initialize Coralogix logger
    logger = CoralogixLogger(
        PRIVATE_KEY,
        APP_NAME,
        SUB_SYSTEM,
        'GCP'
    )

    logging.info(f"Processing file {event['name']}")

    # Get file content
    bucket = client.get_bucket(event['bucket'])
    blob = bucket.get_blob(event['name'])
    content = blob.download_as_string()

    # Check if file is compressed
    if event['contentType'] == 'application/gzip' or \
       event['name'].endswith('.gz'):
        logging.info(f"Uncompress file {event['name']}")
        try:
            # Decompress file
            content = gzip.decompress(content)
        except Exception as exc:
            logging.fatal(f"Cannot uncompress file {event['name']}: ", exc)
            sys.exit(1)

    # Split file into line and remove empty lines
    logs = list(filter(None, re.split(NEWLINE_PATTERN, content.decode('utf-8'))))
    logging.info(f"Number of logs: {len(logs)}")

    # Send logs to Coralogix
    for log in logs:
        logger.log(
            get_severity(log),
            log,
            thread_id=f"{event['bucket']}/{event['name']}"
        )
