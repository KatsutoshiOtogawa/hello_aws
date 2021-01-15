set -eux

# pl=$1 
# for l in ('python3','java11','nodejs')
# echo ('python3','java11','nodejs') | xargs -n 1 | grep -xq $pl

# if [ $? -eq 1 ]; then
#     echo "you select python,java,dotnet only."
#     exit 1
# fi

rm unzip_python.zip 2> /dev/null

# create for python package amazon-linux2
docker build -t localhost:amazon-linux2-python3 .
PWD=`pwd`
container_id=`docker run -itd -v $PWD/unzip_python:/app -v $PWD:/pack localhost:amazon-linux2-python3`

# create amazonlinux2 python package packing
docker exec -it $container_id bash -c "
cd /app && pipenv install
VENV=pipenv --venv
# get python version in virtual environment.
version=`cat Pipfile | grep python_version | awk '{print $3}'`
cd \$VENV/lib/python${version}/site-packages/ && zip -r9 unzip_python.zip .
mv \$VENV/lib/python${version}/site-packages/unzip_python.zip /pack/
zip -gj /pack/unzip_python.zip /app/main.py
"

# stop and remove container
docker stop $container_id >> /dev/null && docker rm $container_id >> /dev/null
