AWS Kinesis with Logstash
=========================

*Coralogix* provides integration with ``AWS Kinesis`` using ``Logstash``, so you can send your logs from anywhere and parse them according to your needs.

Prerequisites
-------------

Have ``Logstash`` installed, for more information on how to install: `Installing Logstash <https://www.elastic.co/guide/en/logstash/current/installing-logstash.html>`_.

Usage
-----

You must provide the following four variables when creating a *Coralogix* logger instance.

**Private Key** – A unique ID which represents your company, this Id will be sent to your mail once you register to *Coralogix*.

**Application Name** – The name of your environment, for example, a company named *“SuperData”* would probably insert the *“SuperData”* string parameter or if they want to debug their test environment they might insert the *“SuperData– Test”*.

**SubSystem Name** – Your application probably has multiple components, for example: Backend servers, Middleware, Frontend servers etc. in order to help you examine the data you need, inserting the subsystem parameter is vital.

**Region** - The AWS region for Kinesis.

Installation
------------

.. code-block:: bash

    $ logstash-plugin install logstash-input-kinesis
    $ logstash-plugin install logstash-output-coralogix

If you are not sure where ``logstash-plugin`` is located, you can check this `here <https://www.elastic.co/guide/en/logstash/current/dir-layout.html>`_.

Configuration
-------------

Open your ``Logstash`` configuration file and add ``AWS Kinesis`` input and *Coralogix*.

.. code-block:: ruby

    input {
      kinesis {
        kinesis_stream_name => "XXXXXXXX"
        region => "XX-XXXX-X"
        codec => json
      }
    }

    output {
        coralogix {
            config_params => {
                "PRIVATE_KEY" => "YOUR_PRIVATE_KEY"
                "APP_NAME" => "APP_NAME"
                "SUB_SYSTEM" => "SUB_NAME"
            }
            log_key_name => "message"
            timestamp_key_name => "@timestamp"
            is_json => true
        }
    }

Input
~~~~~

* **kinesis_stream_name** is mandatory.
* **region** is optional (Default value is ``"us-east-1"``).

More information about how to setup *Logstash Input Kinesis* plugin: `logstash-input-kinesis <https://www.elastic.co/guide/en/logstash/current/plugins-inputs-kinesis.html>`_.

Output
~~~~~~

Watch more information about our `logstash-output-coralogix <https://github.com/coralogix/logstash-output-coralogix/blob/master/README.md>`_ plugin.