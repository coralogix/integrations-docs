{%- if grains['os_family'] == 'Debian' %}
Setup FluentD repository:
  pkgrepo.managed:
    - file: /etc/apt/sources.list.d/treasure-data.list
    - name: deb http://packages.treasuredata.com/3/{{ grains['os']|lower }}/{{ grains['oscodename'] }}/ {{ grains['oscodename'] }} contrib
    - refresh: True
    - key_url: https://packages.treasuredata.com/GPG-KEY-td-agent
{%- endif %}

{%- if grains['os_family'] == 'RedHat' %}
Setup FluentD repository:
  pkgrepo.managed:
    - name: treasuredata
    - humanname: TreasureData
{%- if grains['os'] in ['RedHat', 'CentOS'] %}
    - baseurl: http://packages.treasuredata.com/3/redhat/$releasever/$basearch
{%- endif %}
{%- if grains['os'] == 'Amazon' %}
    - baseurl: http://packages.treasuredata.com/3/amazon/2/$releasever/$basearch
{%- endif %}
    - gpgkey: https://packages.treasuredata.com/GPG-KEY-td-agent
    - gpgcheck: 1
  cmd.run:
    - name: rpm --import https://packages.treasuredata.com/GPG-KEY-td-agent
    - require_in:
      - pkg: Install FluentD
{%- endif %}

{% if salt['grains.get']('oscodename') == 'CentOS Linux' %}
Setup FluentD repository:
  pkgrepo.managed:
    - name: treasuredata
    - humanname: TreasureData
    - baseurl: http://packages.treasuredata.com/3/amazon/2/$releasever/$basearch
    - gpgkey: https://packages.treasuredata.com/GPG-KEY-td-agent
    - gpgcheck: 1
  cmd.run:
    - name: rpm --import https://packages.treasuredata.com/GPG-KEY-td-agent
    - require_in:
      - pkg: Install FluentD
{%- endif %}

Install FluentD:
  pkg.installed:
    - name: td-agent
    - require:
      - pkgrepo: Setup FluentD repository

Configure FluentD:
  file.managed:
    - name: /etc/td-agent/td-agent.conf
    - source: salt://fluentd/td-agent.conf
    - require:
      - pkg: Install FluentD

Start FluentD:
  service.running:
    - name: td-agent
    - enable: True
    - watch:
      - file: Configure FluentD

