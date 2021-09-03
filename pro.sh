#!/usr/bin/env bash

set -e

pr_path="$HOME/.pr_path"
is_start="false"
open="false"
only_option="false"

toggle() {
  only_option="true"
}

usage() {
  cat <<EOF
pro
  a command line tool, for start project quickly

[Usage]
  $ pro [-hruo]

  [options]
    -h | --help    echo the usage
    -r | --remove  remove project path cache
    -u | --update  update pr
    -o | --open    open vscode for choosed project
EOF
}

if ! [ -z ${#@} ]; then
  while [ ${#@} -gt 0 ];
  do
    case $1 in
      -h|--help)
        usage && toggle
        shift
        ;;
      -r|--remove)
        rm -i $pr_path && echo "$pr_path删除成功！"
        toggle
        shift
        ;;
      -u|--update)
        npm i @asarua/pr -g
        toggle
        shift
        ;;
      -o|--open)
        open="true"
        shift
        ;;
      *)
        echo "参数错误！使用方式如下"
        usage
        exit 1
        ;;
    esac
  done
fi

[[ $only_option =~ "true" ]] && exit 0

echo_pkg() {
  local pkg_path="$path/$1/package.json"
  while read line; do
    if [[ $is_start == "true" ]]; then

      if [[ $line =~ "}" ]]; then
        is_start="false"
      fi

      if [[ $is_start == "true" ]]; then
        cmd=${line%%: *}
        echo ${cmd:1} | cut -d "\"" -f 1
      fi
    fi

    if [[ $line =~ "scripts" ]] && [[ $line =~ "{" ]]; then
      is_start="true"
    fi
  done < $pkg_path
}

if ! [ -f $pr_path ]; then
  read -p "请输入项目文件夹的绝对路径：" path
  first=${path%%/*}
  if [[ $first == "~" ]]; then
    path="$HOME/${path#*/}"
  fi
else
  path=`cat $pr_path`
fi

if [ -d $path ]; then
  echo $path > $pr_path
else
  echo "输入路径为$path"
  echo "项目文件夹输入错误！"
  exit 1
fi

cd $path

echo "请选择项目："
select i in `ls`;
do
  if [[ $i != "" ]] && [ -d "$path/$i" ] ; then
    echo "当前选中项目为：$i"
    cd "$path/$i"
    if ! [ -f package.json ]; then
      echo "未发现package.json文件，请重新选择目录！"
    else
      echo "请输入要选择启动的命令："
      select c in `echo_pkg $i`; do
        [[ $open =~ "true" ]] && code .
        npm run $c
      done
    fi
  else
    echo "输入错误，您选择的可能不是一个文件夹，请重新输入："
  fi
done