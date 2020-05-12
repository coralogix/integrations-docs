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

**Application Name** – The name of your main application, for example, a company named *“SuperData”* would probably insert the *“SuperData”* string parameter or if they want to debug their test environment they might insert the *“SuperData– Test”*.

**SubSystem Name** – Your application probably has multiple subsystems, for example: Backend servers, Middleware, Frontend servers etc. in order to help you examine the data you need, inserting the subsystem parameter is vital.

Installation
------------

.. code-block:: bash

    $ wget -o /fluent-bit/plugins/out_coralogix.so https://github.com/coralogix/integrations-docs/raw/master/integrations/fluent-bit/plugin/out_coralogix.so

Configuration
-------------

Common
~~~~~~

Open your ``Fluent-Bit`` configuration file and add *Coralogix* output:

.. code-block:: ini

    [INPUT]
        Name mem
        Tag memory

    [OUTPUT]
        Name        coralogix
        Match       *
        Private_Key YOUR_PRIVATE_KEY
        App_Name    APP_NAME
        Sub_Name    SUB_NAME
        Retry_Limit 5

The first three keys (``Private_Key``, ``App_Name``, ``Sub_Name``) are **mandatory**.

Application and subsystem name
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

In case your input stream is a ``JSON`` object, you can extract **APP_NAME** and/or **SUB_SYSTEM** from the ``JSON`` using the ``App_Name_Key`` and ``Sub_Name_Key`` options:

.. code-block:: ini

    App_Name_Key kubernetes.namespace_name
    Sub_Name_Key kubernetes.container_name

For instance, in the bellow ``JSON`` ``kubernetes.pod_name`` will extract *“my name”* value.

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
        "message": "{\"context\":\"something\",\"code\":\"200\"}",
        "type": "k8s",
    }

Record content
~~~~~~~~~~~~~~

In case your input stream is a ``JSON`` object and you don’t want to send the entire ``JSON``, rather just a portion of it, you can write the value of the key you want to send in the **Log_Key**.
For instance, in the above example, if you write:

.. code-block:: ruby

    Log_Key kubernetes

then only the value of ``kubernetes`` key will be sent.
If you do want to send the entire message then you can just delete this key.

Timestamp
~~~~~~~~~

If you want to use some field as ``timestamp`` in Coralogix, you can use **Time_Key** option:

.. code-block:: ini

    Time_Key timestamp

then you will see that logs records have timestamp from this field.

**Note:** We accepts only logs which are not older than `24 hours`.

Run
---

On host machine
~~~~~~~~~~~~~~~

To start ``Fluent-Bit`` with *Coralogix* output plugin, execute:

.. code-block:: bash

    $ fluent-bit -e /fluent-bit/plugins/out_coralogix.so -c /fluent-bit/etc/fluent-bit.conf

or add plugin to ``/fluent-bit/etc/plugins.conf`` file:

.. code-block:: ini

    [PLUGINS]
        Path /fluent-bit/plugins/out_coralogix.so

Docker
~~~~~~

Build Docker image with your **fluent-bit.conf**:

.. code-block:: dockerfile

    FROM golang:alpine AS builder
    RUN apk add --no-cache gcc libc-dev git
    WORKDIR /go/src/app
    RUN wget -q https://raw.githubusercontent.com/fluent/fluent-bit/master/conf/plugins.conf && \
        echo "    Path /fluent-bit/plugins/out_coralogix.so" | tee -a plugins.conf
    RUN wget -q https://raw.githubusercontent.com/coralogix/integrations-docs/master/integrations/fluent-bit/plugin/out_coralogix.go && \
        wget -q https://raw.githubusercontent.com/coralogix/integrations-docs/master/integrations/fluent-bit/plugin/go.mod && \
        wget -q https://raw.githubusercontent.com/coralogix/integrations-docs/master/integrations/fluent-bit/plugin/go.sum && \
        go mod vendor && \
        go build -buildmode=c-shared -ldflags "-s -w" -mod=vendor -o out_coralogix.so .

    FROM fluent/fluent-bit:1.4
    MAINTAINER Coralogix Inc. <info@coralogix.com>
    LABEL Description="Special Fluent-Bit image for Coralogix integration" Vendor="Coralogix Inc." Version="1.0.0"
    COPY --from=builder /lib/libc.musl-x86_64.so* /lib/x86_64-linux-gnu/
    COPY --from=builder /go/src/app/plugins.conf /fluent-bit/etc/
    COPY --from=builder /go/src/app/out_coralogix.so /fluent-bit/plugins/

Before deploying of your container **don't forget** to mount volume with your logs.

Kubernetes
~~~~~~~~~~

.. image:: https://img.shields.io/badge/Kubernetes-1.7%2C%201.8%2C%201.9%2C%201.10%2C%201.11%2C%201.12%2C%201.13%2C%201.14%2C%201.15%2C%201.16%2C%201.17%2C%201.18-blue.svg
    :target: https://github.com/kubernetes/kubernetes/releases

Prerequisites
+++++++++++++

Before you will begin, make sure that you already have:

* Installed *Kubernetes* Cluster
* Enabled *RBAC* authorization mode support

Installation
++++++++++++

First, you should to create *Kubernetes secret* with *Coralogix* credentials:

.. code-block:: bash

    $ kubectl -n kube-system create secret generic fluent-bit-coralogix-account-secrets \
        --from-literal=PRIVATE_KEY=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX

You should receive something like:

::

    secret "fluent-bit-coralogix-account-secrets" created

Then you need to create ``fluent-bit-coralogix-logger`` resources on your *Kubernetes* cluster with this `manifests <https://github.com/coralogix/integrations-docs/tree/master/integrations/fluent-bit/kubernetes>`_:

.. code-block:: bash

    $ kubectl create -f https://raw.githubusercontent.com/coralogix/integrations-docs/master/integrations/fluent-bit/kubernetes/fluent-bit-coralogix-rbac.yaml
    $ kubectl create -f https://raw.githubusercontent.com/coralogix/integrations-docs/master/integrations/fluent-bit/kubernetes/fluent-bit-coralogix-svc.yaml


Plugin based
^^^^^^^^^^^^

.. code-block:: bash

    $ kubectl create -f https://raw.githubusercontent.com/coralogix/integrations-docs/master/integrations/fluent-bit/kubernetes/fluent-bit-coralogix-cm.yaml
    $ kubectl create -f https://raw.githubusercontent.com/coralogix/integrations-docs/master/integrations/fluent-bit/kubernetes/fluent-bit-coralogix-ds.yaml

Native based
^^^^^^^^^^^^

.. code-block:: bash

    $ kubectl create -f https://raw.githubusercontent.com/coralogix/integrations-docs/master/integrations/fluent-bit/kubernetes/fluent-bit-native-coralogix-cm.yaml
    $ kubectl create -f https://raw.githubusercontent.com/coralogix/integrations-docs/master/integrations/fluent-bit/kubernetes/fluent-bit-native-coralogix-ds.yaml

Output:

::

    serviceaccount "fluent-bit-coralogix-service-account" created
    clusterrole "fluent-bit-coralogix-service-account-role" created
    clusterrolebinding "fluent-bit-coralogix-service-account" created
    configmap "fluent-bit-coralogix-config" created
    daemonset "fluent-bit-coralogix-daemonset" created
    service "fluent-bit-coralogix-service" created

Now ``fluent-bit-coralogix-logger`` collects logs from your *Kubernetes* cluster.


Here is the example of log record:

.. code-block:: json

    {
        "log": "172.17.0.1 - - [05/Apr/2020:22:59:52 +0000] \"GET / HTTP/1.1\" 200 6 \"\" \"kube-probe/1.18\"\n",
        "stream": "stdout",
        "time": "2020-04-05T22:59:52.096035683Z",
        "kubernetes": {
            "pod_name": "dashboard-metrics-scraper-84bfdf55ff-l66cf",
            "namespace_name": "kubernetes-dashboard",
            "labels": {
                "k8s-app": "dashboard-metrics-scraper",
                "pod-template-hash": "84bfdf55ff"
            },
            "annotations": {
                "seccomp.security.alpha.kubernetes.io/pod": "runtime/default"
            },
            "host": "minikube",
            "container_name": "dashboard-metrics-scraper",
            "container_image": "kubernetesui/metrics-scraper:v1.0.2"
        }
    }

Uninstall
+++++++++

If you want to remove ``fluent-bit-coralogix-logger`` from your cluster, execute this:

.. code-block:: bash

    $ kubectl -n kube-system delete secret fluent-bit-coralogix-account-secrets
    $ kubectl -n kube-system delete svc,ds,cm,clusterrolebinding,clusterrole,sa \
         -l k8s-app=fluent-bit-coralogix-logger

Development
-----------

Requirements
~~~~~~~~~~~~

* ``Linux`` x64
* ``Go`` version >= 1.11.x

Sources
~~~~~~~

You can download sources `here <https://raw.githubusercontent.com/coralogix/integrations-docs/master/integrations/fluent-bit/plugin/out_coralogix.go>`_.

Build
~~~~~

.. code-block:: bash

    $ cd plugin/
    $ make
