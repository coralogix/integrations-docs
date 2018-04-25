Filebeat integration
====================

.. image:: https://www.elastic.co/assets/blt86db0e71b172187c/icon-filebeat-bb.svg
   :height: 50px
   :width: 50 px
   :scale: 50 %
   :alt: Filebeat
   :align: left
   :target: https://www.elastic.co/products/beats/filebeat

*Coralogix* provides a seamless integration with ``Filebeat`` so you can send your logs from anywhere and parse them according to your needs.


Prerequisites
-------------

* Have ``Filebeat`` installed, for more information on how to install: `<https://www.elastic.co/guide/en/beats/filebeat/current/filebeat-installation.html>`_
* Install our SSL certificate to your system for providing secure connection. You can download it by link: `<https://coralogixstorage.blob.core.windows.net/syslog-configs/certificate/ca.crt>`_

General
-------

**Private Key** – A unique ID which represents your company, this Id will be sent to your mail once you register to *Coralogix*.

**Company Id** – A unique number which represents your company. You can get your company id from the settings tab in the *Coralogix* dashbaord.

**Application Name** – The name of your main application, for example, a company named *“SuperData”* would probably insert the *“SuperData”* string parameter or if they want to debug their test environment they might insert the *“SuperData– Test”*.

**SubSystem Name** – Your application probably has multiple subsystems, for example: Backend servers, Middleware, Frontend servers etc. in order to help you examine the data you need, inserting the subsystem parameter is vital.

Configuration
-------------

On host machine
~~~~~~~~~~~~~~~

Open your ``Filebeat`` configuration file and configure it to use ``Logstash`` (Make sure you disable ``Elastic`` output). For more information about configuring filebeat to use logstash please refer to: `<https://www.elastic.co/guide/en/beats/filebeat/current/config-filebeat-logstash.html>`_

Point your ``Filebeat`` to output to *Coralogix* logstash server:

::

    logstashserver.coralogix.com:5015

In addition you should add *Coralogix* configuration from the **General** section.

Here is a basic example of **filebeat.yml**:

.. code-block:: yaml

    #=========================== Filebeat prospectors =============================

    filebeat.prospectors:
    - type: log
      paths:
      - "/var/log/your_app/your_app.log"
      document_type: <your-application-name>
      fields_under_root: true
    fields:
      PRIVATE_KEY: "YOUR_PRIVATE_KEY"
      COMPANY_ID: Your company ID
      APP_NAME: "APP_NAME"
      SUB_SYSTEM: "SUB_NAME"

    #----------------------------- Logstash output --------------------------------

    output.logstash:
      enabled: true
      hosts: ["logstashserver.coralogix.com:5015"]
      index: logstash
      tls.certificate_authorities: ["<path to folder with certificates>/ca.crt"]
      ssl.certificate_authorities: ["<path to folder with certificates>/ca.crt"]

With Docker
~~~~~~~~~~~

Build Docker image with your **filebeat.yml**:

.. code-block::

    FROM docker.elastic.co/beats/filebeat:6.2.3

    LABEL description="Filebeat logs watcher"

    # Adding configuration file and SSL certificates for Filebeat
    COPY filebeat.yml /usr/share/filebeat/filebeat.yml
    COPY ca.crt /etc/ssl/certs/Coralogix.crt

    # Changing permission of configuration file
    USER root
    RUN chown filebeat /usr/share/filebeat/filebeat.yml && \
        chmod go-w /usr/share/filebeat/filebeat.yml

    # Return to deploy user
    USER filebeat

Before deploying your container **don't forget** mount volume with your logs.
