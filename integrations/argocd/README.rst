Argo CD integration
===================

.. image:: images/argocd.svg
   :height: 70px
   :width: 300px
   :scale: 50 %
   :alt: Argo CD
   :align: left
   :target: https://argo-cd.readthedocs.io/en/stable/

*Coralogix* provides a seamless integration with ``Argo CD`` so you can push tags from your pipelines.

Prerequisites
-------------

* Have ``Argo CD`` installed, for more information on how to install: `<https://argo-cd.readthedocs.io/en/stable/getting_started/>`_
* Have ``Argo CD Notifications`` installed, for more information on how to install: `<https://argocd-notifications.readthedocs.io/en/stable/>`_

Configuration
-------------

Add *Coralogix* API Token to **argocd-notifications-secret** Secret:

.. code-block:: yaml

    apiVersion: v1
    kind: Secret
    metadata:
      name: argocd-notifications-secret
    type: Opaque
    stringData:
      coralogix-api-token: <YOUR-API-TOKEN>

Add ``webhook``, ``template`` and ``trigger`` to **argocd-notifications-cm** ConfigMap:

.. code-block:: yaml

    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: argocd-notifications-cm
    data:
      service.webhook.coralogix: |
        url: https://webapi.coralogix.com/api/v1/external/tags
        headers:
        - name: Authorization
          value: Bearer $coralogix-api-token
        - name: Content-Type
          value: application/json
      template.coralogix-tag: |
        webhook:
          coralogix:
            method: POST
            body: |
              {
                "name": "{{.app.status.sync.revision}}",
                "application": ["{{.app.spec.project}}"],
                "subsystem": ["{{.app.metadata.name}}"],
                "iconUrl": "https://raw.githubusercontent.com/coralogix/integrations-docs/master/integrations/argocd/images/argocd.png"
              }
      trigger.coralogix-on-success: |
        - when: app.status.operationState.phase in ['Succeeded']
          send: [coralogix-tag]

Register notification for your application:

.. code-block:: yaml

    apiVersion: argoproj.io/v1alpha1
    kind: Application
    metadata:
      name: my-app
      annotations:
        notifications.argoproj.io/subscribe.coralogix-on-success.coralogix-tag: ""