uWSGI integration
=================

.. image:: images/uwsgi.png
   :height: 50px
   :width: 160 px
   :scale: 50 %
   :alt: uWSGI
   :align: left
   :target: https://uwsgi-docs.readthedocs.io/en/latest/

*Coralogix* provides a seamless integration with ``uWSGI`` so you can send your logs from anywhere and parse them according to your needs.


Prerequisites
-------------

Have ``uWSGI`` installed, for more information on how to install: `<https://uwsgi-docs.readthedocs.io/en/latest/Install.html>`_

General
-------

**Private Key** – A unique ID which represents your company, this Id will be sent to your mail once you register to *Coralogix*.

**Company Id** – A unique number which represents your company. You can get your company id from the settings tab in the *Coralogix* dashboard.

**Application Name** – The name of your main application, for example, a company named *“SuperData”* would probably insert the *“SuperData”* string parameter or if they want to debug their test environment they might insert the *“SuperData– Test”*.

**SubSystem Name** – Your application probably has multiple subsystems, for example: Backend servers, Middleware, Frontend servers etc. in order to help you examine the data you need, inserting the subsystem parameter is vital.

Configuration
-------------

Open your ``uWSGI`` configuration file and configure it to use our ``syslog`` endpoint. For more information about configuring ``uWSGI`` to use ``syslog`` please refer to: `<https://uwsgi-docs.readthedocs.io/en/latest/Logging.html#logging-to-remote-syslog>`_

In addition you should add *Coralogix* configuration from the **General** section.

Here is a basic example of **uwsgi.ini**:

.. code-block:: ini

    [uwsgi]
    master = true
    http = 127.0.0.1:8000
    wsgi-file = app.py

    # Setup Coralogix credentials
    private_key = YOUR_PRIVATE_KEY
    company_id = YOUR_COMPANY_ID
    app_name = APP_NAME
    subsystem_name = SUB_NAME

    # Enable Coralogix logger
    ini = coralogix.ini:logger

Logging formatter for our ``syslog`` in `coralogix.ini <https://raw.githubusercontent.com/coralogix/integrations-docs/master/integrations/uwsgi/coralogix.ini>`_:

.. code-block:: ini

    [logger]
    logger = socket:syslogserver.coralogix.com:5140
    req-logger = socket:syslogserver.coralogix.com:5140

    log-format = {"method": "%(method)", "uri": "%(uri)", "proto": "%(proto)", "status": %(status), "referer": "%(referer)", "user_agent": "%(uagent)", "remote_addr": "%(addr)", "http_host": "%(host)", "pid": %(pid), "worker_id": %(wid), "core": %(core), "async_switches": %(switches), "io_errors": %(ioerr), "rq_size": %(cl), "rs_time_ms": %(msecs), "rs_size": %(size), "rs_header_size": %(hsize), "rs_header_count": %(headers)}
    log-encoder = json {"fields": {"private_key": "%(private_key)", "company_id": "%(company_id)", "app_name": "%(app_name)", "subsystem_name": "%(subsystem_name)"}, "message": {"message": "${msg}", "program_name": "uwsgi", "pri_text": "daemon.info", "host": "%h", "tag": "uwsgi_debug"}}
    log-req-encoder = json {"fields": {"private_key": "%(private_key)", "company_id": "%(company_id)", "app_name": "%(app_name)", "subsystem_name": "%(subsystem_name)"}, "message": {"message": "${msg}", "program_name": "uwsgi", "pri_text": "daemon.info", "hostname": "%h", "tag": "uwsgi_access"}}

Restart **uWSGI**.