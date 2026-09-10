FROM quay.io/jupyterhub/k8s-binderhub:1.0.0-0.dev.git.3983.h383374de

COPY ./theme/templates/ /etc/binderhub/templates/
COPY ./theme/static/ /etc/binderhub/static/
