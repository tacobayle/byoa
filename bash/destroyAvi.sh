#!/bin/bash
ansible-playbook aviAbsent/local.yml --extra-vars @~/.avicreds.json
