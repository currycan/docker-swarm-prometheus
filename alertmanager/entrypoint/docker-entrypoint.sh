
global:
  resolve_timeout: 5m
  # smtp_smarthost: 'localhost:25'
  # smtp_smarthost: 'smtp.gmail.com:587'
  # smtp_smarthost: 'smtp.163.com:25'
  # smtp_smarthost:'smtp.exmail.qq.com:465'
  smtp_smarthost: 'mail.fmsh.com.cn:25'
  smtp_from: 'fmshiotbuild@fmsh.com.cn'
  smtp_auth_username: 'fmshiotbuild'
  smtp_auth_password: '<PASSWORD>'
  smtp_require_tls: false

route:
  group_wait: 30s
  group_interval: 5m
  repeat_interval: '<REPEAT>'
  group_by: [alertname]
  routes:
  - match:
      severity: critical
    receiver: webhook
  - match:
      severity: warning
    receiver: wechat
  - match:
      severity: normal
    receiver: e-mail

templates:
  - '/etc/alertmanager/template/*.tmpl'

receivers:
  - name: 'wechat'
    wechat_configs:
    - send_resolved: true
      corp_id: '<CORP_ID>'
      to_party: '<PARTY>'
      agent_id: '<AGENT_ID>'
      api_secret: '<AUTH_CODE>'
      message: '{{ template "wechat.default.message" . }}'

  - name: 'e-mail'
    email_configs:
    - send_resolved: true
      to: '<EMAIL_USER>'
      html: '{{ template "email.default.html" . }}'
      headers: { Subject: " {{ .CommonAnnotations.summary }} " }

  - name: 'slack'
    slack_configs:
      - send_resolved: true
        text: "{{ .CommonAnnotations.description }}"
        username: '<SLACK_USER>'
        channel: '<SLACK_CHANNEL>'
        api_url: '<SLACK_URL>'

  - name: 'webhook'
    webhook_configs:
      - url: '<WEBHOOK_URL>'
        send_resolved: true
