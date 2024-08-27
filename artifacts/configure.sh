#!/bin/bash

set -e

# This scripts performs multiple commands to set up the libraries inside the esignet-artifactory server docker.
# Activies performed are listed as below
# 1. Create resources zip for esignet-wrappers
# 2. Create resources zip for esignet-plugins
# 3. Create i18n bundles zip files for all the required modules

echo esignet-wrappers zip creation started
zip -r -j ${esignet_wrapper_lib_zip_path}/esignet-wrapper.zip ${esignet_wrapper_lib_zip_path}/esignet-wrapper/*
rm -rf ${esignet_wrapper_lib_zip_path}/esignet-wrapper
echo esignet-wrapper zip creation completed

echo esignet-plugins zip creation started
zip -r -j ${esignet_wrapper_lib_zip_path}/esignet-plugins.zip ${esignet_wrapper_lib_zip_path}/esignet-plugins/*
rm -rf ${esignet_wrapper_lib_zip_path}/esignet-plugins
echo esignet-plugins zip creation completed

echo i18n-bundles zip creation for all the mentioned modules started
zip -r -j ${i18n_zip_path}/oidc-demo-i18n-bundle.zip ${work_dir}/oidc-demo-i18n-bundle/*
zip -r -j ${i18n_zip_path}/mock-relying-party-i18n-bundle.zip ${work_dir}/mock-relying-party-i18n-bundle/*
zip -r -j ${i18n_zip_path}/esignet-i18n-bundle.zip ${work_dir}/esignet-i18n-bundle/*
zip -r -j ${i18n_zip_path}/esignet-signup-i18n-bundle.zip ${work_dir}/esignet-signup-i18n-bundle/*

rm -rf ${work_dir}/oidc-demo-i18n-bundle \
 ${work_dir}/mock-relying-party-i18n-bundle \
 ${work_dir}/esignet-i18n-bundle \
 ${work_dir}/esignet-signup-i18n-bundle
echo i18n-bundles zip creation for all the mentioned modules completed

echo theme zip creation for all mentioned modules started
zip -r -j ${theme_zip_path}/esignet-theme.zip ${work_dir}/esignet-theme/*
zip -r -j ${theme_zip_path}/esignet-signup-theme.zip ${work_dir}/esignet-signup-theme/*
rm -rf ${work_dir}/esignet-theme ${work_dir}/esignet-signup-theme
echo theme zip creation for all mentioned modules completed

echo image zip creation for all mentioned modules started
zip -r -j ${image_zip_path}/esignet-image.zip ${work_dir}/esignet-image/*
rm -rf ${work_dir}/esignet-image
zip -r -j ${image_zip_path}/esignet-signup-image.zip ${work_dir}/esignet-signup-image/*
rm -rf ${work_dir}/esignet-signup-image
echo image zip creation for all mentioned modules completed
