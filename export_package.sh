#!/bin/bash

PROJECT_PATH=~/ParticleMobileProject
EXPORT_PATH=$PROJECT_PATH/Assets
EXPORT_FILE=ParticleMobile.unitypackage

PACK_PATH=Assets/ParticleMobile
     
/opt/Unity/Editor/Unity -batchmode -projectPath "$PROJECT_PATH" -exportPackage "$PACK_PATH" "$EXPORT_PATH/$EXPORT_FILE" -quit
