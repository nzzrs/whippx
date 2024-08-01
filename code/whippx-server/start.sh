#!/bin/bash

source env/bin/activate

pip install -r requirements.txt

git clone https://github.com/m-bain/whisperx.git

gunicorn --timeout 3600 --workers 3 --bind 0.0.0.0:5000 app:app &

ngrok http --domain=liberal-hopelessly-deer.ngrok-free.app 127.0.0.1:5000
