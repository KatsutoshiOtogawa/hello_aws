rm unzip.zip 2> /dev/null
cd unzip
# in advence, check virtual environment python version is 3.8
pipenv install
VENV=`pipenv --venv`
cd $VENV/lib/python3.8/site-packages/
zip -r9 unzip.zip .
cd -
mv $VENV/lib/python3.8/site-packages/unzip.zip ../
cd ../
zip -gj upzip.zip unzip/main.py