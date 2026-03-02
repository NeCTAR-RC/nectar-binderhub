FROM quay.io/jupyterhub/k8s-binderhub:1.0.0-0.dev.git.3901.h0dd2abb9

COPY ./theme/templates/ /etc/binderhub/templates/
COPY ./theme/static/ /etc/binderhub/static/
