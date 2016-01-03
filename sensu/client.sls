{% from "sensu/pillar_map.jinja" import sensu with context %}
{% from "sensu/service_map.jinja" import services with context %}

include:
  - sensu
  - sensu.rabbitmq_conf

/etc/sensu/conf.d/client.json:
  file.managed:
    - source: salt://sensu/files/client.json
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: sensu

/etc/sensu/plugins:
  file.recurse:
    - source: salt://sensu/files/plugins
    - file_mode: 555
    - require:
      - pkg: sensu
    - require_in:
      - service: sensu-client
    - watch_in:
      - service: sensu-client

sensu-client:
  service.running:
    - enable: True
    - require:
      - file: /etc/sensu/conf.d/client.json
      - file: /etc/sensu/conf.d/rabbitmq.json
    - watch:
      - file: /etc/sensu/conf.d/*

/etc/rc0.d/K25delete-sensu-client.sh:
  file.managed:
    - mode: 775
    - source: salt://sensu/files/delete-sensu-client.sh
    - template: jinja



{% if sensu.client.embedded_ruby %}
/etc/default/sensu:
  file.replace:
    - pattern: 'EMBEDDED_RUBY=false'
    - repl: 'EMBEDDED_RUBY=true'
    - watch_in:
      - service: sensu-client
{% endif %}

{% if sensu.client.log_warn %}
/etc/default/sensu_log:
  file.replace:
    - name: /etc/default/sensu
    - pattern: 'LOG_LEVEL=.*'
    - repl: 'LOG_LEVEL=true'
    - watch_in:
      - service: sensu-client
{% endif %}

{% if sensu.client.log_level %}
/etc/default/sensu_log:
  file.replace:
    - name: /etc/default/sensu
    - pattern: 'LOG_LEVEL=.*'
    - repl: 'LOG_LEVEL={{ sensu.client.log_level }}'
    - watch_in:
      - service: sensu-client
{% endif %}

{% if sensu.client.nagios_plugins %}
{{ services.nagios_plugins }}:
  pkg:
    - installed
    - require_in:
      - service: sensu-client
{% endif %}

{% if sensu.client.embedded_ruby %}
{% set gem_path = '/opt/sensu/embedded/bin/gem' %}
{% else %}
{% set gem_path = 'gem' %}
{% endif %}

{% set gem_list = salt['pillar.get']('sensu:client:install_gems', []) %}
{% for gem in gem_list %}
client_install_{{ gem }}:
  cmd.run:
    - name: {{ gem_path }} install {{ gem }} --no-ri --no-rdoc
    - unless: {{ gem_path }} list | grep -q {{ gem }}
{% endfor %}
