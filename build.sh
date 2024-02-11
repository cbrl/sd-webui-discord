#!/usr/bin/env bash

###
 # @Author: SpenserCai
 # @Date: 2023-08-17 11:04:55
 # @version: 
 # @LastEditors: SpenserCai
 # @LastEditTime: 2023-10-08 13:26:09
 # @Description: file content
### 
# Web接口代码生存

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
CALL_DIR=$(pwd)
GOPATH=$(go env GOPATH)

GEN_API=0
OUTPUT_DIR="$SCRIPT_DIR/release"
POSITIONAL_ARGS=()

while [[ $# -gt 0 ]]; do
  case $1 in
    --api)
      GEN_API=1
      shift # past argument
      ;;
    -o|--output-dir)
      OUTPUT_DIR="$2"
      shift # past argument
      shift # past value
      ;;
    *)
      echo "Unknown option $1"
      exit 1
      ;;
  esac
done

# Ensure output path is absolute and exists
OUTPUT_DIR=$(realpath $OUTPUT_DIR)
mkdir -p $OUTPUT_DIR

# 判断是否安装go-swagger，如果没有则安装（在GOPATH/bin目录下）
if [ ! -f "$GOPATH/bin/swagger" ]; then
    echo "go-swagger not found, install go-swagger"
    go install github.com/go-swagger/go-swagger/cmd/swagger@latest
fi

# 判断是否传入--gen-api参数，如果传入则重新生成api代码
if [ $GEN_API -ne 0 ]; then
	API_PATH="$SCRIPT_DIR/api"
	API_SWAGGER_PATH="$SCRIPT_DIR/api/swagger.yml"

    echo "generate api code"
    rm -rf $API_PATH/gen
    mkdir -p $API_PATH/gen
    $GOPATH/bin/swagger generate server -f $API_SWAGGER_PATH --regenerate-configureapi -t $API_PATH/gen/
fi

cd $SCRIPT_DIR
go mod tidy
go build -o "$OUTPUT_DIR/sd-webui-discord"

# 判断是否存在config.json
if [ ! -f "$OUTPUT_DIR/config.json" ]; then
    echo "config.json not found, copy config.example.json to config.json"
    cp $SCRIPT_DIR/config.example.json $OUTPUT_DIR/config.json
fi

# 吧location目录和其中的文件复制到release目录，如果存在location目录则删除后再复制
if [ -d "$OUTPUT_DIR/location" ]; then
    rm -rf $OUTPUT_DIR/location
fi

# 切换到website目录，安装依赖并打包
cd $SCRIPT_DIR/website
npm install
npm run build
cd $SCRIPT_DIR

if [ -d "$OUTPUT_DIR/website" ]; then
    rm -rf $OUTPUT_DIR/website
fi

cp -r $SCRIPT_DIR/location $OUTPUT_DIR/location
cp -r $SCRIPT_DIR/website/dist $OUTPUT_DIR/website
