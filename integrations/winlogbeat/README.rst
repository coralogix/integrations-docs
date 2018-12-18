Winlogbeat integration
======================

.. image:: https://www.elastic.co/assets/blte9b3c4b0f121078f/icon-winlogbeat-bb.svg
   :height: 50px
   :width: 50 px
   :scale: 50 %
   :alt: Winlogbeat
   :align: left
   :target: https://www.elastic.co/products/beats/winlogbeat

*Coralogix* provides a seamless integration with ``Winlogbeat`` so you can send your logs from anywhere and parse them according to your needs.


Prerequisites
-------------

* Have ``Winlogbeat`` installed, for more information on how to install: `<https://www.elastic.co/guide/en/beats/winlogbeat/current/winlogbeat-installation.html>`_
* Install our SSL certificate to your system for providing secure connection. You can download it by link: `<https://coralogixstorage.blob.core.windows.net/syslog-configs/certificate/ca.crt>`_

General
-------

**Private Key** – A unique ID which represents your company, this Id will be sent to your mail once you register to *Coralogix*.

**Company Id** – A unique number which represents your company. You can get your company id from the settings tab in the *Coralogix* dashbaord.

**Application Name** – The name of your main application, for example, a company named *“SuperData”* would probably insert the *“SuperData”* string parameter or if they want to debug their test environment they might insert the *“SuperData– Test”*.

**SubSystem Name** – Your application probably has multiple subsystems, for example: Backend servers, Middleware, Frontend servers etc. in order to help you examine the data you need, inserting the subsystem parameter is vital.

Configuration
-------------

Open your ``Winlogbeat`` configuration file and configure it to use ``Logstash``. For more information about configuring filebeat to use logstash please refer to: `<https://www.elastic.co/guide/en/beats/winlogbeat/current/config-winlogbeat-logstash.html>`_

Point your ``Winlogbeat`` to output to *Coralogix* logstash server:

::

    logstashserver.coralogix.com:5015

In addition you should add *Coralogix* configuration from the **General** section.

Here is a basic example of **winlogbeat.yml**:

.. code-block:: yaml

    #=========================== Winlogbeat Event Logs ============================

    winlogbeat.event_logs:
    - name: Application
      ignore_older: 72h
    - name: Security
    - name: System

    fields_under_root: true
    fields:
      PRIVATE_KEY: "YOUR_PRIVATE_KEY"
      COMPANY_ID: Your company ID
      APP_NAME: "APP_NAME"
      SUB_SYSTEM: "windows_events"

    setup.template.settings:
      index.number_of_shards: 3

    #----------------------------- Logstash output --------------------------------

    output.logstash:
        enabled: true
        hosts: ["logstashserver.coralogix.com:5015"]
        index: logstash
        tls.certificate_authorities: ["<path to folder with certificates>\\ca.crt"]
        ssl.certificate_authorities: ["<path to folder with certificates>\\ca.crt"]

**Note:** If you want to send all additional metadata, the **fields_under_root** option should be equals to *false*.

Test configuration
------------------

Before starting test your configuration:

.. code-block:: bat

    PS C:\Program Files\Winlogbeat> .\winlogbeat.exe test config -c .\winlogbeat.yml -e

Start Winlogbeat
----------------

Start your ``Winlogbeat`` service:

.. code-block:: bat

    PS C:\Program Files\Winlogbeat> Start-Service winlogbeat
