Filebeat integration
====================

.. image:: https://images.contentstack.io/v3/assets/bltefdd0b53724fa2ce/bltd1986faecefe2760/5bd9e39ccc850d3e584b7cc4/icon-filebeat-bb.svg
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

**Company Id** – A unique number which represents your company. You can get your company id from the settings tab in the *Coralogix* dashboard.

**Application Name** – The name of your main application, for example, a company named *“SuperData”* would probably insert the *“SuperData”* string parameter or if they want to debug their test environment they might insert the *“SuperData– Test”*.

**SubSystem Name** – Your application probably has multiple subsystems, for example: Backend servers, Middleware, Frontend servers etc. in order to help you examine the data you need, inserting the subsystem parameter is vital.

Installation
------------

For quick setup of ``Filebeat`` on your server you can use prepared scripts.

Go to the folder with your ``Filebeat`` configuration file **(filebeat.yml)** and execute:

deb
~~~

.. code-block:: bash

    $ curl -sSL https://raw.githubusercontent.com/coralogix/integrations-docs/master/integrations/filebeat/scripts/install-deb.sh | bash

rpm
~~~

.. code-block:: bash

    $ curl -sSL https://raw.githubusercontent.com/coralogix/integrations-docs/master/integrations/filebeat/scripts/install-rpm.sh | bash

This script will install ``Filebeat`` on your machine, prepare configuration and download
*Coralogix* SSL certificates.

**Note:** If you want to install specific version of ``Filebeat`` you should to pass version number with environment variable before script run:

.. code-block:: bash

    $ export FILEBEAT_VERSION=6.6.2

Configuration
-------------

On host machine
~~~~~~~~~~~~~~~

Open your ``Filebeat`` configuration file and configure it to use ``Logstash`` (Make sure you disable ``Elasticsearch`` output). For more information about configuring ``Filebeat`` to use ``Logstash`` please refer to: `<https://www.elastic.co/guide/en/beats/filebeat/current/config-filebeat-logstash.html>`_

Point your ``Filebeat`` to output to *Coralogix* logstash server:

::

    logstashserver.coralogix.com:5044

or if you want to use encrypted connection **(recommended)**:

::

    logstashserver.coralogix.com:5015

In addition you should add *Coralogix* configuration from the **General** section.

Here is a basic example of **filebeat.yml**:

.. code-block:: yaml

    #============================== Filebeat Inputs ===============================

    filebeat.inputs:
    - type: log
      paths:
      - "/var/log/your_app/your_app.log"

    fields_under_root: true
    fields:
      PRIVATE_KEY: "YOUR_PRIVATE_KEY"
      COMPANY_ID: YOUR_COMPANY_ID
      APP_NAME: "APP_NAME"
      SUB_SYSTEM: "SUB_NAME"

    #----------------------------- Logstash output --------------------------------

    output.logstash:
      enabled: true
      hosts: ["logstashserver.coralogix.com:5015"]
      tls.certificate_authorities: ["<path to folder with certificates>/ca.crt"]
      ssl.certificate_authorities: ["<path to folder with certificates>/ca.crt"]

**Note:** If you want to send all additional metadata, the **fields_under_root** option should be equals to *true*.

With Docker
~~~~~~~~~~~

Build Docker image with your **filebeat.yml**:

.. code-block:: dockerfile

    FROM docker.elastic.co/beats/filebeat:6.6.2

    LABEL description="Filebeat logs watcher"

    # Adding configuration file and SSL certificates for Filebeat
    COPY filebeat.yml /usr/share/filebeat/filebeat.yml
    COPY ca.crt /etc/ssl/certs/Coralogix.crt

    # Changing permission of configuration file
    USER root
    RUN chown root:filebeat /usr/share/filebeat/filebeat.yml

    # Return to deploy user
    USER filebeat

Before deploying of your container **don't forget** to mount volume with your logs.
