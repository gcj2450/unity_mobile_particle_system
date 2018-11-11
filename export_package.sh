#!/bin/bash

PROJECT_PATH=~/ParticleMobileProject
EXPORT_PATH=$PROJECT_PATH/Assets
EXPORT_FILE=ParticleMobile.unitypackage

PACK_PATH=Assets/ParticleMobile

read -p "Must kill Unity first. Continue? [y/n] " -n 1 -r
echo # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
	pkill -9 Unity  
	/opt/Unity/Editor/Unity -batchmode -projectPath "$PROJECT_PATH" -exportPackage "$PACK_PATH" "$EXPORT_PATH/$EXPORT_FILE" -quit
fi
