
## docker 容器部署结构
文件docker-compose.yml
* db
  + mysql:5.6
  + links:.db_data
* redis
  + redis
    - bind redis
* spider <- db:3306,redis:6879
* app <-db:3306,redis:6879,spider:8000
* nginx <-app:3000
  + links:frontend

> links 指的是将本地目录映射到docker里
> frontend 指的是前端项目生成的文件

## 安装docker和docker-compose
```
curl -sSL https://get.docker.com/ | sh
sudo curl -L https://github.com/docker/compose/releases/download/1.23.2/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

## 启动方式
* 不更新 "sudo docker-compose up -d"
* 需要更新 "sudo docker-compose up --build"

## 初始化数据
```
docker stop acmunionapi_spider_1
docker exec -it acmunionapi_app_1 /bin/bash
> rake db:reset
> exit
docker start acmunionapi_spider_1
```
## 一些重要文件和配置项的说明
> 一些文件可以用git diff 对新旧版本进行对比理解
- .env 环境变量
  + RAILS_ENV 部署模式 [test|development|production]
  + MYSQL_ALLOW_EMPTY_PASSWORD
  + ACM_DATABASE_HOST
  + ACM_DATABASE_NAME
  + ACM_DATABASE_USER
  + ACM_DATABASE_PASSWORD
- config
  * database.yml 数据库的配置,示例文件~.sample
    + host
    + username
    + password
  * acm_nginx.conf nginx服务器的配置文件
    + location 路由监听
  * acm_redis.conf redis配置
    + bind 绑定的地址，没有绑定的地址无法连接
  * acm_spider.yml spider的地址和端口
  * redis.yml redis的地址和端口
- db/* rails创建数据库,升级数据表，生成数据的文件,
- Dockerfile* docker创建容器的配置
- docker-compose.yml 容器部署结构 

## api相关
所有的api在config/routes.rb里都有记录
> api/v1/auth/token <=> controllers/api/v1/auth_controller.rb#auth:token
