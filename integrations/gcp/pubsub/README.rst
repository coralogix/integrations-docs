Google Cloud Pub/Sub
====================

.. image:: images/pubsub.png
   :height: 50px
   :width: 100px
   :scale: 50 %
   :alt: Google Cloud Storage
   :align: left
   :target: https://cloud.google.com/pubsub/

*Coralogix* provides a predefined function to forward your logs from ``Google Cloud Pub/Sub`` straight to *Coralogix*.

Setup
-----

Manually
~~~~~~~~

Create ``Cloud Function`` in your ``Google Cloud Console`` with following settings:

1. Increase ``“Memory allocated“`` to ``“1 GB“``.
2. Change ``“Trigger“`` to ``“Cloud Pub/Sub“``.
3. Select your ``Pub/Sub topic``.
4. Change ``“Runtime“`` to ``“Python 3.8“``.
5. Paste the following code to `main.py <https://raw.githubusercontent.com/coralogix/integrations-docs/master/integrations/gcp/pubsub/lambda/main.py>`_:

.. code-block:: python

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


6. Paste the following packages to `requirements.txt <https://raw.githubusercontent.com/coralogix/integrations-docs/master/integrations/gcp/pubsub/lambda/requirements.txt>`_:

::

    coralogix_logger>=2.0.4

7. Increase ``“Timeout“`` to ``“60 seconds“``.
8. Add the mandatory environment variables: ``private_key``, ``app_name``, ``sub_name``:

* **Private Key** – A unique ID which represents your company, this Id will be sent to your mail once you register to *Coralogix*.

* **Application Name** – Used to separate your environment, e.g. *SuperApp-test/SuperApp-prod*.

* **SubSystem Name** – Your application probably has multiple subsystems, for example, *Backend servers, Middleware, Frontend servers etc*.

9. Multiline pattern: *Coralogix* supports multiline pattern by default, you can define a custom pattern with an environment variables, for example:

::

    newline_pattern [\s(?={)|(?<=})\s,\s(?={)|(?<=})\s\]. 

10. Click ``“Create”``.

gcloud CLI
~~~~~~~~~~

To setup the function, execute this:

.. code-block:: bash

    $ curl -sSL -o gcsToCoralogix.zip https://raw.githubusercontent.com/coralogix/integrations-docs/master/integrations/gcp/pubsub/lambda/pubsubToCoralogix.zip
    $ unzip pubsubToCoralogix.zip -d pubsubToCoralogix/
    $ gcloud functions deploy pubsubToCoralogix \
        --project=YOUR_GCP_PROJECT_ID \
        --region=us-central1 \
        --runtime=python38 \
        --memory=1024MB \
        --timeout=60s \
        --entry-point=to_coralogix \
        --source=pubsubToCoralogix \
        --trigger-resource=YOUR_PUBSUB_TOPIC_NAME \
        --trigger-event=google.pubsub.topic.publish \
        --set-env-vars="private_key=YOUR_PRIVATE_KEY,app_name=APP_NAME,sub_name=SUB_NAME"
