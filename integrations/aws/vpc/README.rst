AWS VPC Flow Logs
=================

.. image:: images/amazon-vpc.jpg
   :height: 50px
   :width: 100px
   :scale: 50 %
   :alt: AWS VPC Flow Logs
   :align: left
   :target: https://aws.amazon.com/ru/vpc/

*Coralogix* provides a predefined Lambda function to forward your ``VPC Flow Logs`` stream straight to *Coralogix*.

Setup
-----

1. Setup delivery of your VPC Flow Logs to S3 bucket:

`<https://docs.aws.amazon.com/en_us/vpc/latest/userguide/flow-logs-s3.html>`_

2. Create an ``“author from scratch”`` Node.js 8.10 runtime lambda with an S3 read permissions:

.. image:: images/1.png
   :alt: Lambda settings

3. At ``“Code entry type”`` choose ``“Upload a ZIP file”`` and upload ``“s3ToCoralogixVPC.zip”``:

`<https://s3-eu-west-1.amazonaws.com/coralogix-public/tools/s3ToCoralogixVPC.zip>`_

.. image:: images/2.png
   :alt: Lambda code upload

4. Add the mandatory environment variables: ``private_key``, ``app_name``, ``sub_name``:

.. image:: images/3.png
   :alt: Lambda environment variables

* **Private Key** – A unique ID which represents your company, this Id will be sent to your mail once you register to *Coralogix*.

* **Application Name** – Used to separate your environment, e.g. *SuperApp-test/SuperApp-prod*.

* **SubSystem Name** – Your application probably has multiple subsystems, for example, *Backend servers, Middleware, Frontend servers etc*.

5. Choose the S3 bucket you want to get triggered by and change the event type from ``“PUT”`` to ``“Object Created(All)”``:

.. image:: images/4.png
   :alt: Lambda trigger setup

6. Increase ``Memory`` to ``1024MB`` and ``Timeout`` to ``30 sec``.

.. image:: images/5.png
   :alt: Lambda basic settings

7. Click ``“Save”``.