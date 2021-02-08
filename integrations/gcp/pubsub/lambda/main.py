#!/usr/bin/python
# -*- coding: utf-8 -*-

"""
Coralogix GCP function for Pub/Sub
Author: Coralogix Ltd.
Email: info@coralogix.com
"""

import os
import re
import sys
import base64
import logging
from coralogix.handlers import CoralogixLogger

__name__ = 'pubsubToCoralogix'
__author__ = 'Coralogix Ltd.'
__email__ = 'info@coralogix.com'
__copyright__ = 'Copyright 2021, Coralogix Ltd.'
__credits__ = ['Ariel Assaraf', 'Amnon Shahar', 'Eldar Aliiev']
__license__ = 'Apache Version 2.0'
__version__ = '1.0.0'
__maintainer__ = 'Coralogix Ltd.'
__date__ = '8 February 2021'
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

    # Initialize Coralogix logger
    logger = CoralogixLogger(
        PRIVATE_KEY,
        APP_NAME,
        SUB_SYSTEM,
        'Pub/Sub'
    )

    logging.info(f"Processing Pub/Sub message ID {context.event_id}")

    if 'data' in event:
        # Get event data
        content = base64.b64decode(event['data']).decode('utf-8')

        # Split event into lines and remove empty lines
        logs = list(filter(None, re.split(NEWLINE_PATTERN, content)))
        logging.info(f"Number of logs: {len(logs)}")

        # Send logs to Coralogix
        for log in logs:
            logger.log(
                get_severity(log),
                log,
                thread_id=context.event_id
        )
