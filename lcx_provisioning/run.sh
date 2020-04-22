#!/bin/bash

ansible-playbook 01-prepare_lxc_container.yml -i hosts -u ubuntu -k --ask-become-pass