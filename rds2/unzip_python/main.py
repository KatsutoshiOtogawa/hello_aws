
# ①ライブラリのimport
import boto3
import os
import os.path
import urllib.parse
import tempfile
import zipfile

print('Loading function')      # ②Functionのロードをログに出力

s3 = boto3.resource('s3')      # ③S3オブジェクトを取得

# ④Lambdaのメイン関数
def lambda_handler(event, context):
    
    # bucket = os.environ['BUCKET_NAME']    # ⑤バケット名を指定
    # key = 'test_' + datetime.now().strftime('%Y-%m-%d-%H-%M-%S') + '.txt'  # ⑥オブジェクトのキー情報を指定
    # file_contents = 'Lambda test'  # ⑦ファイルの内容
    
    # obj = s3.Object(bucket,key)     # ⑧バケット名とパスを指定
    # obj.put( Body=file_contents )   # ⑨バケットにファイルを出力

    # [aws](https://docs.aws.amazon.com/lambda/latest/dg/with-s3.html)
    # decode object key. sended key is encoding
    # objectkey = urllib.parse.unquote_plus(event['Records'][0]['s3']['object']['key'], encoding='utf-8')

    objectkey = event['Records'][0]['s3']['object']['key']

    print(objectkey)
    print("before if")
    # 
    if not('folder_action/unzip/' in objectkey ):
        return

    print(objectkey)
    bucket = s3.Bucket(os.environ['BUCKET_NAME'])

    with tempfile.TemporaryDirectory() as tmpdir:
        bucket.download_file(objectkey, tmpdir)

        # 一時ディレクトリに作成
        with zipfile.ZipFile(os.path.join(tmpdir,objectkey), 'r')as zf:
            # all expand to extract folder
            extractdir = os.path.join(tmpdir,'extract')

            zf.extractall(extractdir)
            # map 
            map(
                # 
                lambda x:bucket.upload_file(x,x.replace(extractdir,''))
                ,filter(lambda x: os.path.isfile(x), glob.glob(os.path.join(extractdir,'*'), recursive=True))
            )

            # for val in list(filter(lambda x: os.path.isfile(x), glob.glob(os.path.join(extractdir,'*'), recursive=True))):
            #     bucket.upload_file(
            #         val
            #         ,'db'
            #     )

            # bucket.upload_file(
            # os.path.join('/tmp', 'world.sql.gz')
            # , 'db')

    # delete files.
    # os.remove(os.path.join('/tmp', 'world.sql.gz'))
    # # ダウンロードを実行
    # urllib.request.urlretrieve(
    #     'https://downloads.mysql.com/docs/world.sql.gz'
    #     , os.path.join('/tmp', 'world.sql.gz')
    # )

    # expansion.
    # gunzip(os.path.join('/tmp', 'world.sql.gz'))

    

    # bucket = s3.Bucket(os.environ['BUCKET_NAME'])
    # bucket.upload_file(
    #     os.path.join('/tmp', 'world.sql.gz')
    #     , 'db'
    # )

    # # delete files.
    # os.remove(os.path.join('/tmp', 'world.sql.gz'))

