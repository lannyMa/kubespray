#!/usr/bin/env bash

#alias kk='kubectl get pod --all-namespaces -o wide --show-labels'
#alias ks='kubectl get svc --all-namespaces -o wide'
#alias kss='kubectl get svc --all-namespaces -o wide --show-labels'
#alias kd='kubectl get deploy --all-namespaces -o wide'
#alias wk='watch kubectl get pod --all-namespaces -o wide --show-labels'
#alias kv='kubectl get pv -o wide'
#alias kvc='kubectl get pvc -o wide --all-namespaces --show-labels'
#alias kbb='kubectl run -it --rm --restart=Never busybox --image=busybox sh'
#alias kbbc='kubectl run -it --rm --restart=Never curl --image=appropriate/curl sh'
#alias kd='kubectl get deployment --all-namespaces --show-labels'
#alias kcm='kubectl get cm --all-namespaces -o wide'
#alias kin='kubectl get ingress --all-namespaces -o wide'

# vim roles/kubernetes/preinstall/tasks/verify-settings.yml
#IPS=(192.168.2.11 192.168.2.12 192.168.2.13 192.168.2.14 192.168.2.15)
#CONFIG_FILE=inventory/inventory.cfg python3 contrib/inventory_builder/inventory.py ${IPS[@]}
ansible-playbook -i inventory/inventory.cfg cluster.yml -b -v --private-key=~/.ssh/id_rsa
