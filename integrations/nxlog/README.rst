NXLog integration
=================

.. image:: https://nxlog.co/sites/all/themes/Porto_nxlog/img/nx-logo-1.svg
   :height: 60px
   :width: 80 px
   :scale: 50 %
   :alt: NXLog
   :align: left
   :target: https://nxlog.co/

*Coralogix* provides a seamless integration with ``NXLog`` so you can send your logs from anywhere and parse them according to your needs.


Prerequisites
-------------

* Have ``NXLog`` installed, for more information on how to install: `<https://nxlog.co/documentation/nxlog-user-guide/deployment.html>`_

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

Here is a basic example of **nxlog.conf**:

.. code-block:: html

    <Extension json>
        Module  xm_json
    </Extension>

    <Input messages>
        Module  im_file
        File    "/var/log/messages"
    </Input>

    <Output coralogix>
        Module  om_udp
        Host    syslogserver.coralogix.com
        Port    5140
        <Exec>
            delete($EventReceivedTime);
            delete($SourceModuleName);
            delete($SourceModuleType);

            $message      = $raw_event;
            $pri_text     = 'daemon.info';
            $hostname     = hostname();
            $program_name = 'nxlog';
            $tag          = 'syslog';
            $raw_event    = '{"fields":{"private_key":"YOUR_PRIVATE_KEY","company_id":"YOUR_COMPANY_ID","app_name":"APP_NAME","subsystem_name":"SUB_NAME"},"message":' + to_json() + '}';
        </Exec>
    </Output>

    <Route messages_to_coralogix>
        Path    messages => coralogix
    </Route>

Docker
~~~~~~

Build Docker image with your **nxlog.conf**:

.. code-block:: dockerfile

    FROM nxlog/nxlog-ce:latest
    COPY nxlog.conf /etc/nxlog.conf

Before deploying of your container **don't forget** to mount volume with your logs.
