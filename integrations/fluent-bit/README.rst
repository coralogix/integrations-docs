Fluent-Bit integration
======================

.. image:: https://fluentbit.io/assets/img/logo1-default.png
   :height: 50px
   :width: 170px
   :scale: 50 %
   :alt: Fluent-Bit
   :align: left
   :target: https://fluentbit.io/

*Coralogix* provides a seamless integration with ``Fluent-Bit`` so you can send your logs from anywhere and parse them according to your needs.

Prerequisites
-------------

* Have ``Fluent-Bit`` installed, for more information on how to implement: `Fluent-Bit installation docs <https://docs.fluentbit.io/manual/installation>`_.
* Have ``Coralogix`` output plugin installed.

Usage
-----

You must provide the following four variables when creating a *Coralogix* logger instance.

**Private Key** – A unique ID which represents your company, this Id will be sent to your mail once you register to *Coralogix*.

**Company Id** – A unique number which represents your company. You can get your company id from the settings tab in the *Coralogix* dashboard.

**Application Name** – The name of your main application, for example, a company named *“SuperData”* would probably insert the *“SuperData”* string parameter or if they want to debug their test environment they might insert the *“SuperData– Test”*.

**SubSystem Name** – Your application probably has multiple subsystems, for example: Backend servers, Middleware, Frontend servers etc. in order to help you examine the data you need, inserting the subsystem parameter is vital.

Installation
------------

Fluent-Bit 0.11.x
~~~~~~~~~~~~~~~~~

.. code-block:: bash

    $ wget -o /fluent-bit/plugins/out_coralogix.so https://github.com/coralogix/integrations-docs/blob/master/integrations/fluent-bit/0.11/out_coralogix.so

Fluent-Bit 0.12.x, 1.x
~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: bash

    $ wget -o /fluent-bit/plugins/out_coralogix.so https://github.com/coralogix/integrations-docs/blob/master/integrations/fluent-bit/0.12/out_coralogix.so

Configuration
-------------

Open your ``Fluent-Bit`` configuration file and add *Coralogix* output:

.. code-block:: ini

    [INPUT]
        Name mem
        Tag memory

    [OUTPUT]
        Name coralogix
        private_key YOUR_PRIVATE_KEY
        company_id YOUR_COMPANY_ID
        app_name APP_NAME
        sub_name SUB_NAME
        Match *

The first four keys (``private_key``, ``company_id``, ``app_name``, ``sub_name``) are **mandatory**.

Run
---

On host machine
~~~~~~~~~~~~~~~

To start ``Fluent-Bit`` with *Coralogix* output plugin, execute:

.. code-block:: bash

    $ fluent-bit -e /fluent-bit/plugins/out_coralogix.so -c /fluent-bit/etc/fluent-bit.conf

With Docker
~~~~~~~~~~~

Build Docker image with your **fluent-bit.conf**:

.. code-block:: dockerfile

    FROM fluent/fluent-bit:latest

    # Copy configuration file and output plugin
    COPY fluent-bit.conf /fluent-bit/etc/fluent-bit.conf
    COPY out_coralogix.so /fluent-bit/plugins/out_coralogix.so

    # Entry point
    CMD ["/fluent-bit/bin/fluent-bit", "-e", "/fluent-bit/plugins/out_coralogix.so", "-c", "/fluent-bit/etc/fluent-bit.conf"]


Development
-----------

Requirements
~~~~~~~~~~~~

* ``Linux`` x64
* ``Go`` version >= 1.11.x

Sources
~~~~~~~

You can download sources here:

* `0.11.x <https://raw.githubusercontent.com/coralogix/integrations-docs/master/integrations/fluent-bit/0.11/out_coralogix.go>`_
* `0.12.x, 1.x <https://raw.githubusercontent.com/coralogix/integrations-docs/master/integrations/fluent-bit/0.12/out_coralogix.go>`_

Build
~~~~~

.. code-block:: bash

    $ go get .
    $ go build -buildmode=c-shared -o out_coralogix.so .
