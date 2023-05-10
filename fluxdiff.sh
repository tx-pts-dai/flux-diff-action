#!/usr/bin/env bash

# Requirements:
# - kubectl (configured with a valid kubeconfig)
# - yq
# - flux

DIFF_SUMMARY="/tmp/diff_summary.md"
KUSTOMIZATION_FILES=$(find $1 -maxdepth 1 -type f -name "*.yaml" -or -name "*.yml")

TARGET_DIRECTORIES=""
for DIRECTORY in $2; do
  if [[ $DIRECTORY == *"/base" ]]; then
    MAIN_FOLDER="${DIRECTORY:0:${#DIRECTORY}-5}"
    OVERLAYS=$(find asd$1 -maxdepth 1 -type f -name "apps*.yaml" -or -name "apps*.yml")

    for OVERLAY in $OVERLAYS; do
      OVERLAY_DIR=$(yq ".spec.path" $OVERLAY)
      TARGET_DIRECTORIES="$TARGET_DIRECTORIES ${OVERLAY_DIR:2}"
    done
  fi
done

echo "# Flux Diff Github Action" > $DIFF_SUMMARY

for KUSTOMIZATION_FILE in $KUSTOMIZATION_FILES; do
  FLUX_EXITCODE=0
  KUSTOMIZATION_DIR=$(yq ".spec.path" $KUSTOMIZATION_FILE)
  KUSTOMIZATION_NAME=$(yq ".metadata.name" $KUSTOMIZATION_FILE)

  if [[ $2 == "__ALL__" || $TARGET_DIRECTORIES == *"${KUSTOMIZATION_DIR:2}"* ]]; then # check if the directory is in the target directories
    echo "- Checking \`$KUSTOMIZATION_DIR\`. Computing diff with what's deployed in cluster" >> $DIFF_SUMMARY
    # echo "flux diff --timeout 10m0s kustomization $KUSTOMIZATION_NAME --path $KUSTOMIZATION_DIR --kustomization-file $KUSTOMIZATION_FILE --progress-bar=false"
    echo "\`\`\`" >> $DIFF_SUMMARY
    flux diff --timeout 10m0s kustomization $KUSTOMIZATION_NAME --path $KUSTOMIZATION_DIR --kustomization-file $KUSTOMIZATION_FILE --progress-bar=false >> $DIFF_SUMMARY 2>&1 || FLUX_EXITCODE=$?
    if [ $FLUX_EXITCODE -eq 0 ]; then
      echo "No changes detected in the directory $KUSTOMIZATION_DIR" >> $DIFF_SUMMARY
    elif [ $FLUX_EXITCODE -gt 1 ]; then
      # Since flux gives an exit code of 1 if there are drifts, we catch any error code lower or equal to 1
      # and only exit on greater error codes
      echo -e "Error running \`flux diff --timeout 10m0s kustomization $KUSTOMIZATION_NAME --path $KUSTOMIZATION_DIR --kustomization-file $KUSTOMIZATION_FILE --progress-bar=false\`" >> $DIFF_SUMMARY
      cat $DIFF_SUMMARY
      exit $FLUX_EXITCODE
    fi
    echo "\`\`\`" >> $DIFF_SUMMARY
    sed -i.bak 's/, exiting with non-zero exit code//g' $DIFF_SUMMARY # -i.bak for compatibility between linux and mac
  else
    echo "- No changes detected in the directory $KUSTOMIZATION_DIR" >> $DIFF_SUMMARY
  fi
done

cat $DIFF_SUMMARY