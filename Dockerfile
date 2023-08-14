FROM docker.io/jupyterhub/k8s-binderhub:1.0.0-0.dev.git.3151.hcb6d328

# Add Nectar theme
COPY ./theme/* /etc/binderhub/custom/
