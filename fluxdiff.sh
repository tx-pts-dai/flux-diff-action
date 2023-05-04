KUSTOMIZATION_FILES=$(find $1 -maxdepth 1 -type f -name "*.yaml" -or -name "*.yml")

for KUSTOMIZATION_FILE in $KUSTOMIZATION_FILES; do
  FLUX_EXITCODE=0
  KUSTOMIZATION_DIR=$(yq ".spec.path" $KUSTOMIZATION_FILE)
  KUSTOMIZATION_NAME=$(yq ".metadata.name" $KUSTOMIZATION_FILE)

  if [[ $2 == "__ALL__" || $2 == *"${KUSTOMIZATION_DIR:2}"* ]]; then # check if the directory is in the target directories
    echo "Changes detected in $KUSTOMIZATION_DIR. Computing diff with what's deployed in cluster" >> $GITHUB_STEP_SUMMARY
    flux diff --timeout 10m0s kustomization $KUSTOMIZATION_NAME --path $KUSTOMIZATION_DIR --kustomization-file $KUSTOMIZATION_FILE --progress-bar=false &>> $GITHUB_STEP_SUMMARY || FLUX_EXITCODE=$?
  fi
  
  # Since flux gives an exit code of 1 if there are drifts, we catch any error code lower or equal to 1
  # and only exit on greater error codes
  if [ $FLUX_EXITCODE -gt 1 ]; then
    exit $FLUX_EXITCODE
  elif [ $FLUX_EXITCODE -eq 0 ]; then
    echo "No changes detected in the directory $KUSTOMIZATION_DIR" >> $GITHUB_STEP_SUMMARY
  fi
done