Metricbeat integration
======================

.. image:: https://images.contentstack.io/v3/assets/bltefdd0b53724fa2ce/blted1da1110ae2982e/5c3439b985f098b517e887d9/icon-metrics-bb.svg
   :height: 50px
   :width: 50 px
   :scale: 50 %
   :alt: Metricbeat
   :align: left
   :target: https://www.elastic.co/products/beats/metricbeat

*Coralogix* provides a seamless integration with ``Metricbeat`` so you can send your metric data from anywhere and create beautiful visualizations to it.


Prerequisites
-------------

* Have ``Metricbeat`` installed, for more information on how to install: `<https://www.elastic.co/guide/en/beats/metricbeat/current/metricbeat-installation.html>`_
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

Open your ``Metricbeat`` configuration file and configure it to use ``Logstash``. For more information about configuring ``Metricbeat`` to use ``Logstash`` please refer to: `<https://www.elastic.co/guide/en/beats/metricbeat/current/logstash-output.html>`_

Point your ``Metricbeat`` to output to *Coralogix* logstash server:

::

    logstashserver.coralogix.com:5015

In addition you should add *Coralogix* configuration from the **General** section.

Here is a basic example of **metricbeat.yml** file for collecting metrics from ``Redis`` server:

.. code-block:: yaml

    #============================= Metricbeat Modules ==============================

    metricbeat.modules:
    - module: redis
      enabled: true
      hosts: ["redis:6379"]
      metricsets: ["info", "keyspace"]
      period: 10s

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
      ssl.certificate_authorities: ["<path to folder with certificates>/ca.crt"]

With Docker
~~~~~~~~~~~

Build a Docker image with your **metricbeat.yml**:

.. code-block:: dockerfile

    FROM docker.elastic.co/beats/metricbeat:6.6.2

    LABEL description="Metricbeat metrics data collector"

    # Adding configuration file and SSL certificates for Metricbeat
    COPY metricbeat.yml /usr/share/metricbeat/metricbeat.yml
    COPY ca.crt /etc/ssl/certs/Coralogix.crt

    # Changing permission of configuration file
    USER root
    RUN chown root:metricbeat /usr/share/metricbeat/metricbeat.yml

    # Return to deploy user
    USER metricbeat

Usage
-----

You can deploy example with *Docker-compose*:

.. code-block:: yaml

    version: '3.6'
    services:
      redis:
        image: redis:latest
        container_name: redis

      metricbeat:
        image: docker.elastic.co/beats/metricbeat:6.6.2
        container_name: metricbeat
        volumes:
          - ./metricbeat.yml:/usr/share/metricbeat/metricbeat.yml:ro
          - ./ca.crt:/etc/ssl/certs/Coralogix.crt:ro

Don't forget to change owner of **metricbeat.yml** file to *root* (uid=1000).
