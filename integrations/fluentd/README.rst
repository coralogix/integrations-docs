FluentD integration
===================

.. image:: https://www.fluentd.org/assets/img/miscellany/fluentd-logo.png
   :height: 50px
   :width: 100px
   :scale: 50 %
   :alt: Fluentd
   :align: left
   :target: https://www.fluentd.org/

*Coralogix* provides a seamless integration with ``FluentD`` so you can send your logs from anywhere and parse them according to your needs.

Prerequisites
-------------

Have ``FluentD`` installed, for more information on how to implement: `FluentD implementation docs <https://docs.fluentd.org/v1.0/categories/installation>`_.

Usage
-----

You must provide the following four variables when creating a *Coralogix* logger instance.

**Private Key** – A unique ID which represents your company, this Id will be sent to your mail once you register to *Coralogix*.

**Application Name** – The name of your environment, for example, a company named *“SuperData”* would probably insert the *“SuperData”* string parameter or if they want to debug their test environment they might insert the *“SuperData– Test”*.

**SubSystem Name** – Your application probably has multiple components, for example: Backend servers, Middleware, Frontend servers etc. in order to help you examine the data you need, inserting the subsystem parameter is vital.

Installation
------------

**td-agent:**

.. code-block:: bash

    $ td-agent-gem install fluent-plugin-coralogix

**Ruby:**

.. code-block:: bash

    $ gem install fluent-plugin-coralogix

Also, we provide some scenarios for configuration management systems:

* `SaltStack <https://github.com/coralogix/integrations-docs/blob/master/integrations/fluentd/cms/salt/fluentd.sls>`_

Configuration
-------------

Common
~~~~~~

Open your ``Fluentd`` configuration file and add *Coralogix* output.
If you installed ``Fluentd`` using the ``td-agent`` packages, the config file is located at `/etc/td-agent/td-agent.conf`.
If you installed ``Fluentd`` using the ``Ruby Gem``, the config file is located at `/etc/fluent/fluent.conf`.

.. code-block:: ruby

    <match **>
      @type coralogix
      privatekey "#{ENV['PRIVATE_KEY']}"
      appname "prod"
      subsystemname "fluentd"
      is_json true
    </match>

The first four keys (``type``, ``privatekey``, ``appname``, ``subsystemname``) are **mandatory** while the last one is *optional*.

Application and subsystem name
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

In case your input stream is a ``JSON`` object, you can extract **APP_NAME** and/or **SUB_SYSTEM** from the ``JSON`` using the ``$`` sign. For instance, in the bellow ``JSON`` ``$kubernetes.pod_name`` will extract *“my name”* value.

.. code-block:: json

    {
        "context": "something",
        "code": "200",
        "stream": "stdout",
        "docker": {
            "container_id": "e518dc690e2bc3314842d5bd98b9e24ff7686daa573d063033ea023426c7f667"
        },
        "kubernetes": {
            "namespace_name": "default",
            "pod_id": "e061eb42-4e4b-11e6-9fd1-fa163edd44fd",
            "pod_name": "my name",
            "container_name": "some container",
            "host": "myhost"
        },
        "k8scluster": "ci",
        "@timestamp": "2016-07-20T17:05:17.743Z",
        "message": "{"context":"something", "code":"200" }",
        "type": "k8s",
    }

Record content
~~~~~~~~~~~~~~

In case your input stream is a ``JSON`` object and you don’t want to send the entire ``JSON``, rather just a portion of it, you can write the value of the key you want to send in the **log_key_name**.
For instance, in the above example, if you write:

.. code-block:: ruby

    log_key_name kubernetes

then only the value of ``kubernetes`` key will be sent.
If you do want to send the entire message then you can just delete this key.

Timestamp
~~~~~~~~~

If you want to use some field as ``timestamp`` in Coralogix, you can use **timestamp_key_name** option:

.. code-block:: ruby

    timestamp_key_name @timestamp

then you will see that logs records have timestamp from this field.

**Note:** We accepts only logs which are not older than `24 hours`.

JSON support
~~~~~~~~~~~~

In case your raw log message is a JSON object you should set `is_json` key to a **true** value, otherwise you can ignore it.

.. code-block:: ruby

    is_json true

Proxy support
~~~~~~~~~~~~~

This plugin supports sending data via proxy. Here is the example of the configuration:

.. code-block:: ruby

    <match **>
      @type coralogix
      privatekey "#{ENV['PRIVATE_KEY']}"
      appname "prod"
      subsystemname "fluentd"
      is_json true
      <proxy>
        host "PROXY_ADDRESS"
        port PROXY_PORT
        # user and password are optionals parameters
        user "PROXY_USER"
        password "PROXY_PASSWORD"
      </proxy>
    </match>
