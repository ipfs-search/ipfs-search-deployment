#!/bin/sh -xe

pipenv run yamllint .
pipenv run ansible-lint --project-dir .
pipenv run flake8 .
