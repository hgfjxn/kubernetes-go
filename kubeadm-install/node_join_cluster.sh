#!/bin/bash

# CAREFUL: every kubeadm may have different token and ca-cert-hash

kubeadm join 10.20.13.24:6443 --token gnq0ex.j4wqxy6o89f7tl1a --discovery-token-ca-cert-hash sha256:c59abe1944573cd9568c45e8d29cec6c9201348d707633c04fbb3ccb7036f851

