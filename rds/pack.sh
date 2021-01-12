rm dbsample_download.zip 2> /dev/null
cd dbsample_download
# in advence, check virtual environment python version is 3.8
pipenv install
VENV=`pipenv --venv`
cd $VENV/lib/python3.8/site-packages/
zip -r9 dbsample_download.zip .
cd -
mv $VENV/lib/python3.8/site-packages/dbsample_download.zip ../
cd ../
zip -gj dbsample_download.zip dbsample_download/dbsample_download.py