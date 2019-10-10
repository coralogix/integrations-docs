Auditbeat integration
=====================

.. image:: https://images.contentstack.io/v3/assets/bltefdd0b53724fa2ce/blt1b4de16c742cd2bf/5bd9e4ab4ed46d9b5fbadd0e/icon-auditbeat-bb.svg
   :height: 50px
   :width: 50 px
   :scale: 50 %
   :alt: Auditbeat
   :align: left
   :target: https://www.elastic.co/products/beats/auditbeat

*Coralogix* provides a seamless integration with ``Auditbeat`` so you can send your audit data from anywhere and create beautiful visualizations to it.


Prerequisites
-------------

* Have ``Auditbeat`` installed, for more information on how to install: `<https://www.elastic.co/guide/en/beats/auditbeat/current/auditbeat-installation.html>`_
* Install our SSL certificate to your system for providing secure connection. You can download it by link: `<https://coralogix-public.s3-eu-west-1.amazonaws.com/certificate/ca.crt>`_

General
-------

**Private Key** – A unique ID which represents your company, this Id will be sent to your mail once you register to *Coralogix*.

**Company Id** – A unique number which represents your company. You can get your company id from the settings tab in the *Coralogix* dashboard.

**Application Name** – The name of your main application, for example, a company named *“SuperData”* would probably insert the *“SuperData”* string parameter or if they want to debug their test environment they might insert the *“SuperData– Test”*.

**SubSystem Name** – Your application probably has multiple subsystems, for example: Backend servers, Middleware, Frontend servers etc. in order to help you examine the data you need, inserting the subsystem parameter is vital.

Configuration
-------------

On host machine
~~~~~~~~~~~~~~~

Open your ``Auditbeat`` configuration file and configure it to use ``Logstash``. For more information about configuring ``Auditbeat`` to use ``Logstash`` please refer to: `<https://www.elastic.co/guide/en/beats/auditbeat/current/logstash-output.html>`_

Point your ``Auditbeat`` to output to *Coralogix* logstash server:

::

    logstashserver.coralogix.com:5015

In addition you should add *Coralogix* configuration from the **General** section.

Here is a basic example of **auditbeat.yml** file for watching some folders on your server:

.. code-block:: yaml

    #============================= Auditbeat Modules ===============================

    auditbeat.modules:
    - module: file_integrity
      enabled: true
      paths:
      - /bin
      - /usr/bin
      - /sbin
      - /usr/sbin
      - /etc

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

Build a Docker image with your **auditbeat.yml**:

.. code-block:: dockerfile

    FROM docker.elastic.co/beats/auditbeat:6.6.2

    LABEL description="Auditbeat filesystem audit data collector"

    # Adding configuration file and SSL certificates for Auditbeat
    COPY auditbeat.yml /usr/share/auditbeat/auditbeat.yml
    COPY ca.crt /etc/ssl/certs/Coralogix.crt

    # Changing permission of configuration file
    USER root
    RUN chown root:auditbeat /usr/share/auditbeat/auditbeat.yml

    # Return to deploy user
    USER auditbeat

Usage
-----

You can deploy example with *Docker-compose*:

.. code-block:: yaml

    version: '3.6'
    services:
      auditbeat:
        image: docker.elastic.co/beats/auditbeat:6.6.2
        container_name: auditbeat
        volumes:
          - ./auditbeat.yml:/usr/share/auditbeat/auditbeat.yml:ro
          - ./ca.crt:/etc/ssl/certs/Coralogix.crt:ro

Don't forget to change owner of **auditbeat.yml** file to *root* (uid=1000).
