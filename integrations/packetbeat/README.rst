Packetbeat integration
======================

.. image:: https://images.contentstack.io/v3/assets/bltefdd0b53724fa2ce/bltafdcc4bf9e229b98/5bd9e3f9b2202f965f253391/icon-packetbeat-bb.svg
   :height: 50px
   :width: 50 px
   :scale: 50 %
   :alt: Packetbeat
   :align: left
   :target: https://www.elastic.co/products/beats/packetbeat

*Coralogix* provides a seamless integration with ``Packetbeat`` so you can send your network usage logs from anywhere and parse them according to your needs.


Prerequisites
-------------

* Have ``Packetbeat`` installed, for more information on how to install: `<https://www.elastic.co/guide/en/beats/packetbeat/current/packetbeat-installation.html>`_
* Install our SSL certificate to your system for providing secure connection. You can download it by link: `<https://coralogixstorage.blob.core.windows.net/syslog-configs/certificate/ca.crt>`_

General
-------

**Private Key** – A unique ID which represents your company, this Id will be sent to your mail once you register to *Coralogix*.

**Company Id** – A unique number which represents your company. You can get your company id from the settings tab in the *Coralogix* dashboard.

**Application Name** – The name of your main application, for example, a company named *“SuperData”* would probably insert the *“SuperData”* string parameter or if they want to debug their test environment they might insert the *“SuperData– Test”*.

**SubSystem Name** – Your application probably has multiple subsystems, for example: Backend servers, Middleware, Frontend servers etc. in order to help you examine the data you need, inserting the subsystem parameter is vital.

Configuration
-------------

Open your ``Packetbeat`` configuration file and configure it to use ``Logstash``. For more information about configuring ``Packetbeat`` to use ``Logstash`` please refer to: `<https://www.elastic.co/guide/en/beats/packetbeat/current/config-packetbeat-logstash.html>`_

Point your ``Packetbeat`` to output to *Coralogix* logstash server:

::

    logstashserver.coralogix.com:5015

In addition you should add *Coralogix* configuration from the **General** section.

Here is a basic example of **packetbeat.yml** for watching HTTP packages:

.. code-block:: yaml

    #========================== Network targets to watch ===========================

    packetbeat.interfaces.device: any
    packetbeat.protocols:
    - type: http
      ports: [80, 8080, 8000, 5000, 8002]
      hide_keywords: ["pass", "password", "passwd"]
      send_headers: ["User-Agent", "Cookie", "Set-Cookie"]
      split_cookie: true
      real_ip_header: "X-Forwarded-For"

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
        ssl.certificate_authorities: ["<path to folder with certificates>\\ca.crt"]
