AWS ECS(EC2) Logs
=================

.. image:: images/amazon-ecs.png
   :height: 50px
   :width: 100px
   :scale: 50 %
   :alt: AWS ECS Logs
   :align: left
   :target: https://aws.amazon.com/ecs/

*Coralogix* provides integration to collect and send your ``ECS`` cluster logs straight to *Coralogix*.

General
-------

**Private Key** – A unique ID which represents your company, this Id will be sent to your mail once you register to *Coralogix*.

**Application Name** – The name of your main application, for example, a company named *“SuperData”* would probably insert the *“SuperData”* string parameter or if they want to debug their test environment they might insert the *“SuperData– Test”*.

**SubSystem Name** – Your application probably has multiple subsystems, for example: Backend servers, Middleware, Frontend servers etc. in order to help you examine the data you need, inserting the subsystem parameter is vital.

Setup
-----

We provide integration both for ``EC2`` and ``Fargate`` based clusters.

EC2
~~~

1. Create ``AWS ECS Task Definition`` from `predefined <tasks/fluentd-coralogix.json>`_ file and pass
your *Coralogix* private key as environment variable(**PRIVATE_KEY**).
Optionally you can pass your application name as **APP_NAME**.

2. Run ``AWS ECS Task`` on your cluster:

.. image:: images/task_run.png
   :alt: Task run

Choose ``Placement Template`` as ``One Task Per Host``:

.. image:: images/task_settings.png
   :alt: Task settings

When task will be ready, logs will be shipped to *Coralogix*.

Fargate
~~~~~~~

1. Create new ``AWS ECS Task Definition`` or just a ``New revision`` and enable ``FireLens`` integration:

.. image:: images/firelens_settings.png
   :alt: Firelens settings

**Required parameters:**

* ``Type`` - ``fluentd``
* ``Image`` - ``docker.io/coralogixrepo/fluentd-coralogix-ecs:latest``

2. Configure ``awsfirelens`` logging driver for the container which you want to send the logs:

.. image:: images/logging_settings.png
   :alt: Logging driver settings

**Required parameters:**

* ``@type`` - ``coralogix``
* ``privatekey`` - your *Coralogix* private key
* ``appname`` - your application name
* ``subsystemname`` - your application subsystem
* ``is_json`` - ``true``

If you want to send just log message without additional metadata:

* ``log_key_name`` - ``log``
* ``is_json`` - ``false``

**Note:** To manage multiline messages refer to `this <https://github.com/aws-samples/amazon-ecs-firelens-examples/tree/master/examples/fluentd/multiline-logs>`_ page.
