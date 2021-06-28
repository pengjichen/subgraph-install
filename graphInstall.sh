##  安装部署uniswap v2 subgraph

##  在root权限下执行各种安装命令, 最后的init build deploy可在普通用户权限下执行
##  或在docker容器中执行该脚本

## base tools install
apt update -y
apt install -y git vim curl wget net-tools
git config --global user.email "user@support.com"
git config --global user.name "user"

## install rust cargo.  from https://www.rust-lang.org/tools/install
## curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh # 安装过程中需要手动交互，弃用

##cargo安装自动运行
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs >> cargo-install.sh; sh cargo-install.sh -y; rm cargo-install.sh;
source $HOME/.cargo/env; # 在脚本中执行，只在脚本中生效；需要在terminal中手动执行，才能在terminal中生效

## install npm
curl -fsSL https://deb.nodesource.com/setup_14.x | bash -
apt-get install -y nodejs


## install yarn
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -;
echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list;
apt-get update;
apt-get install yarn;


## install graph-cli
yarn global add @graphprotocol/graph-cli


## install ipfs
## https://docs.ipfs.io/install/
wget https://github.com/ipfs/go-ipfs/releases/download/v0.9.0/go-ipfs_v0.9.0_linux-amd64.tar.gz
tar -xvf go-ipfs_v0.9.0_linux-amd64.tar.gz
rm go-ipfs_v0.9.0_linux-amd64.tar.gz


## insteall postgres
## https://www.postgresql.org/download/
## 需要交互 输入大洲6，城市70 上海
## 无交互安装txdata，默认使用etc/utc时间，安装后可手动调整
#
apt update;DEBIAN_FRONTEND=noninteractive apt-get install -y tzdata
## dpkg-reconfigure tzdata # 调整时区

#apt update;
apt-get install -y wget lsb-release gnupg2; \
sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list';
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -;
apt-get update;
apt-get -y install postgresql;
passwd postgres <<EOF
> 123456
> 123456
> EOF
su postgres<<EOF
pg_ctlcluster 13 main start;
exit
EOF

## install graphnode
## old: build the porject
##apt-get install -y clang libpq-dev libssl-dev pkg-config;
##git clone https://github.com/graphprotocol/graph-node.git;
##cd graph-node;
##cargo build;
## new: get the bin file
wget https://github.com/pengjichen/subgraph-install/releases/download/graph-node-0.23.0/graph-node-linux
chmod +x graph-node-linux


## start ipfs
cd go-ipfs;
./ipfs init;
./ipfs daemon >> log.txt 2>&1 &
cd ..

## create and start postgresql with user postgres
## echo "set user postgres's password"
##echo "will change user to start postgres"

su - postgres <<EOF
psql <<EOF
ALTER USER postgres WITH PASSWORD '123456';create database graph-node-mdex-heco
EOF

## start graph-node
./graph-node-linux --postgres-url postgres://postgres:123456@localhost:5432/graph-node-mdex-heco \
  --ethereum-rpc mainnet:http://127.0.0.1:8545 \
  --ipfs 127.0.0.1:5001 \
  --debug >> graph-node.log.txt 2>&1 &

### init subgraph 需要提前fork uniswap-v2-subgraph到部署账户中,因为后续的操作需要同名github账户
###graph init --from-contract 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f --abi factory.json --network mainnet --contract-name Factory --index-events  pengjichen/uniswap-v2-subgraph
#
#git clone https://github.com/pengjichen/uniswap-v2-subgraph.git # uniswap-v2 on eth
#cd  uniswap-v2-subgraph;
git clone https://github.com/pengjichen/Uniswap-v2-subgraph-1.git # mdex branch is mdex on heco
cd Uniswap-v2-subgraph-1
git checkout mdex

### deploy  需要提前注册thegraph.com的账户,可以用已有github账户登录,并记录分配的access token; 还需要创建一个subgraph项目,部署时需要执行该项目名称
yarn install;
yarn codegen;
yarn build;
graph codegen;  # 冗余操作
graph build;    # 冗余操作

#deploy to remote server like thegraph.com or hg.network
##graph deploy --node https://api.thegraph.com/deploy/ --ipfs https://api.thegraph.com/ipfs/ --access-token 42ddcbf5fbac4c67a1a3d98b45644e97 pengjichen/Uniswapv2;

## deploy local
apt install -y libsecret-devel
npm install keytar
yarn create-local;
yarn deploy-local;
