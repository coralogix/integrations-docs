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
* Install our SSL certificate to your system for providing secure connection. You can download it by link: `<https://coralogix-public.s3-eu-west-1.amazonaws.com/certificate/ca.crt>`_

General
-------

**Private Key** – A unique ID which represents your company, this Id will be sent to your mail once you register to *Coralogix*.

**Company Id** – A unique number which represents your company. You can get your company id from the settings tab in the *Coralogix* dashboard.

**Application Name** – The name of your main application, for example, a company named *“SuperData”* would probably insert the *“SuperData”* string parameter or if they want to debug their test environment they might insert the *“SuperData– Test”*.

**SubSystem Name** – Your application probably has multiple subsystems, for example: Backend servers, Middleware, Frontend servers etc. in order to help you examine the data you need, inserting the subsystem parameter is vital.

Installation
------------

For quick setup of ``Filebeat`` on your server you can use prepared `scripts <https://github.com/coralogix/integrations-docs/tree/master/integrations/filebeat/scripts>`_.

Go to the folder with your ``Filebeat`` configuration file **(filebeat.yml)** and execute **(as root)**:

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

    $ export FILEBEAT_VERSION=7.11.1

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

    processors:
    - copy_fields:
        fields:
        - from: host.name
          to: beat.hostname
        fail_on_error: false
        ignore_missing: true

    #----------------------------- Logstash output --------------------------------

    output.logstash:
      enabled: true
      hosts: ["logstashserver.coralogix.com:5015"]
      tls.certificate_authorities: ["<path to folder with certificates>/ca.crt"]
      ssl.certificate_authorities: ["<path to folder with certificates>/ca.crt"]

**Note:** If you want to send all additional metadata, the **fields_under_root** option should be equals to *true*.

If you have *multiline* logs like:

.. code-block::

    2019-08-31 14:27:33 [main] ERROR Main - Exception
    javax.management.RuntimeErrorException: null
        at Main.main(Main.java:16) ~[bin/:na]

You can use multiline pattern:

.. code-block:: yaml

    filebeat.inputs:
    - type: log
      paths:
      - "/var/log/your_app/your_app.log"
      multiline:
        pattern: '^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} \['
        negate: true
        match: after

Pattern should match the beginning of each record.

Docker
~~~~~~

Build Docker image with your **filebeat.yml**:

.. code-block:: dockerfile

    FROM docker.elastic.co/beats/filebeat:7.4.2

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

Kubernetes
~~~~~~~~~~

.. image:: https://img.shields.io/badge/Kubernetes-1.9%2C%201.10%2C%201.11%2C%201.12%2C%201.13%2C%201.14%2C%201.15%2C%201.16%2C%201.17%2C%201.18%2C%201.19-blue.svg
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

    $ kubectl -n kube-system create secret generic coralogix-filebeat-account-secrets \
        --from-literal=PRIVATE_KEY=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX \
        --from-literal=COMPANY_ID=XXXX \
        --from-literal=CLUSTER_NAME=cluster.local

You should receive something like:

::

    secret "coralogix-filebeat-account-secrets" created

Then you need to create ``filebeat-coralogix-logger`` resources on your *Kubernetes* cluster with this `manifests <https://github.com/coralogix/integrations-docs/tree/master/integrations/filebeat/kubernetes>`_:

.. code-block:: bash

    $ kubectl create -k https://github.com/coralogix/integrations-docs/integrations/filebeat/kubernetes

Output:

::

    serviceaccount "coralogix-filebeat-service-account" created
    clusterrole "coralogix-filebeat-cluster-role" created
    clusterrolebinding "coralogix-filebeat-cluster-role-binding" created
    configmap "coralogix-filebeat-config" created
    secret "coralogix-filebeat-certificate" created
    daemonset "coralogix-filebeat-daemonset" created
    service "coralogix-filebeat-service" created

Now ``filebeat-coralogix-logger`` collects logs from your *Kubernetes* cluster.


Here is the example of log record:

.. code-block:: json

   {
     "cloud": {
       "availability_zone": "projects/379343634745/zones/us-central1-a",
       "instance_id": "7653580772456904060",
       "instance_name": "gke-coralogix-test-default-pool-4d86c144-sbkd",
       "machine_type": "projects/379343634745/machineTypes/n1-standard-1",
       "project_id": "coralogix-test",
       "provider": "gce"
     },
     "kubernetes": {
       "container": {
         "name": "prometheus-to-sd"
       },
       "labels": {
         "k8s-app": "kube-dns",
         "pod-template-hash": "989689126"
       },
       "namespace": "kube-system",
       "node": {
         "name": "gke-coralogix-test-default-pool-4d86c144-sbkd"
       },
       "pod": {
         "name": "kube-dns-fdfbdf56b-jbbw2",
         "uid": "56584469-534d-11e9-8bcd-42010a800179"
       },
       "replicaset": {
         "name": "kube-dns-fdfbdf56b"
       }
     },
     "@timestamp": "2019-03-31T00:45:53.973Z",
     "@version": "1",
     "host": {
       "name": "filebeat-coralogix"
     },
     "beat": {
       "hostname": "filebeat-coralogix-daemonset-98wxr",
       "name": "filebeat-coralogix",
       "version": "6.7.0"
     },
     "message": "E0331 00:45:53.970719 1 stackdriver.go:58] Error while sending request to Stackdriver Post /v3/projects/coralogix-test/timeSeries?alt=json: unsupported protocol scheme \"\"",
     "tags": [
       "kubernetes",
       "containers",
       "beats_input_codec_plain_applied"
     ]
   }

Uninstall
+++++++++

If you want to remove ``filebeat-coralogix-logger`` from your cluster, execute this:

.. code-block:: bash

    $ kubectl -n kube-system delete secret filebeat-coralogix-account-secrets
    $ kubectl -n kube-system delete secret filebeat-coralogix-certificate
    $ kubectl -n kube-system delete svc,ds,cm,clusterrolebinding,clusterrole,sa \
         -l k8s-app=filebeat-coralogix-logger
