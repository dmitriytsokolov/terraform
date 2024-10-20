#!/bin/bash

tofu state rm postgresql_role.main
tofu state rm postgresql_role.keycloak

tofu state rm postgresql_schema.main
tofu state rm postgresql_schema.keycloak

tofu state rm postgresql_grant.main
tofu state rm postgresql_grant.keycloak

tofu destroy --auto-approve -parallelism=20