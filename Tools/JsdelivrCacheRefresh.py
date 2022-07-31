import requests

photo_jsdelivr_url = "https://cdn.jsdelivr.net/gh/Shmilyqjj/BlogImages-0@master/cdn_sources/Blog_Images/Bigdata-Problems/HBase/HBase-Problems-31.png"


res = requests.get(photo_jsdelivr_url.replace('cdn', 'purge'))
if res.status_code == 200:
    print("Jsdelivr图片缓存刷新完成")
    print(res.text)