Okta audit logs
===============

.. image:: images/okta.svg
   :height: 50px
   :width: 100 px
   :scale: 50 %
   :alt: Okta
   :align: left
   :target: https://www.okta.com/

*Coralogix* provides a seamless integration with ``Okta`` SAML service.
You can easily send your ``Okta`` audit logs to *Coralogix*.

Prerequisites
-------------

* Have ``Logstash`` installed, for more information on how to install: `<https://www.elastic.co/guide/en/logstash/current/installing-logstash.html>`_
* `logstash-output-coralogix <https://github.com/coralogix/logstash-output-coralogix>`_ plugin installed
* `logstash-input-okta_system_log <https://github.com/SecurityRiskAdvisors/logstash-input-okta_system_log>`_ plugin installed

General
-------

**Private Key** – A unique ID which represents your company, this Id will be sent to your mail once you register to *Coralogix*.

**Application Name** – The name of your main application, for example, a company named *“SuperData”* would probably insert the *“SuperData”* string parameter or if they want to debug their test environment they might insert the *“SuperData– Test”*.

**SubSystem Name** – Your application probably has multiple subsystems, for example: Backend servers, Middleware, Frontend servers etc. in order to help you examine the data you need, inserting the subsystem parameter is vital.

Configuration
-------------

On host machine
~~~~~~~~~~~~~~~

Here is the ``Logstash`` pipeline configuration **logstash.conf**:

.. code-block:: ruby

    input {
      okta_system_log {
        schedule       => { every => "30s" }
        limit          => 1000
        auth_token_key => "${OKTA_API_KEY}"
        hostname       => "${OKTA_TENANT}.okta.com"
      }
    }
    output {
      coralogix {
        config_params => {
          "PRIVATE_KEY" => "${CORALOGIX_PRIVATE_KEY}"
          "APP_NAME"    => "${CORALOGIX_APP_NAME:Okta}"
          "SUB_SYSTEM"  => "${CORALOGIX_SUB_SYSTEM:Audit}"
        }
        is_json => true
      }
    }

Docker
~~~~~~

Build ``Docker`` image with your **logstash.conf**:

.. code-block:: dockerfile

    ARG LOGSTASH_VERSION=7.4.2
    FROM docker.elastic.co/logstash/logstash:${LOGSTASH_VERSION}
    ENV XPACK_MONITORING_ENABLED false
    RUN logstash-plugin install --no-verify \
        logstash-output-coralogix \
        logstash-input-okta_system_log
    COPY logstash.conf /usr/share/logstash/pipeline/logstash.conf

and then create the container:

.. code-block:: bash

    docker run \
        --detach \
        --name logstash-okta \
        --restart always \
        --env OKTA_API_KEY=YOUR_OKTA_API_KEY \
        --env OKTA_TENANT=YOUR_OKTA_HOSTNAME \
        --env CORALOGIX_PRIVATE_KEY=YOUR_PRIVATE_KEY \
        $(docker build -q .)

or deploy with ``docker-compose``:

.. code-block:: yaml

    version: '3'
    services:
      logstash-okta:
        container_name: logstash
        restart: always
        build:
          context: .
          args:
            LOGSTASH_VERSION: 7.4.2
        environment:
          OKTA_API_KEY: YOUR_OKTA_API_KEY
          OKTA_TENANT: YOUR_OKTA_HOSTNAME
          CORALOGIX_PRIVATE_KEY: YOUR_PRIVATE_KEY
