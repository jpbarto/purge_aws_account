#!/usr/bin/env bash

set -e

aws ecs run-task --cli-input-json file://cli-input.json  