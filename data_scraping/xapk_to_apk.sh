#!/bin/bash

# Create an output directory if it doesn't exist
OUTPUT_DIR="extracted_xapks"
mkdir -p "$OUTPUT_DIR"

# Loop through all .xapk files in the current directory
for xapk in ../data/apk/*.xapk; do
    if [ -f "$xapk" ]; then
        filename=$(basename "$xapk")
        echo $filename
        # Extract folder name from .xapk file
        folder_name="${filename%.xapk}"

        # Create a new folder inside the output directory
        mkdir -p "$OUTPUT_DIR/$folder_name"
        # Extract the .xapk file (since it's a ZIP archive)
        unzip -q "$xapk" -d "$OUTPUT_DIR/$folder_name"
        # # Find the .apk file and move it to the extracted folder
        # apk_file=$(find "$OUTPUT_DIR/$folder_name" -type f -name "*.apk" | head -n 1)
        # if [ -n "$apk_file" ]; then
        #     echo "Extracted APK from $xapk -> $apk_file"
        # else
        #     echo "No APK found in $xapk"
        # fi
    fi

done
