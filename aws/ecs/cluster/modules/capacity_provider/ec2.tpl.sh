#!/bin/bash

# Adding the cluster name to the ECS agent configuration
echo ECS_CLUSTER="${CLUSTER_NAME}" >> /etc/ecs/ecs.config
