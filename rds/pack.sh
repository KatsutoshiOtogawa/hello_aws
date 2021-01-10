cd dbsample_download
pipenv install boto3 --python 3.8
VENV=`pipenv --venv`
cd $VENV/lib/python3.8/site-packages/
zip -r9 dbsample_download.zip .
cd -
mv $VENV/lib/python3.8/site-packages/dbsample_download.zip ../
cd ../
zip -gj dbsample_download.zip dbsample_download/dbsample_download.py