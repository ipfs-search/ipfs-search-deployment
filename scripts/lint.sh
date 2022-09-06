#!/bin/sh

pipenv run env ANSIBLE_CONFIG=ansible-lint.cfg ansible-lint
