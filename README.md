
## なにこれ

プロンプトの味気ないパスをかっこ良く表示するよ  
カレントディレクトリは太字に popd で戻るディレクトリに下線を引いたりできます。 

![Demo](https://raw.github.com/pasberth/promptway/master/demo/promptway.png) 

## Requirements

* zsh
* pathf が必要です <https://github.com/pasberth/pathf>
* 多少buggyでも耐える心

## Usage

まずは設定をする

```sh

source path/to/promptway/promptway.zsh

zstyle ':prompt:dir' formats "%B%a%b"
zstyle ':prompt:dir:symlink' formats "%B%F{cyan}%a@%f%b"
zstyle ':prompt:way' formats "%a"
zstyle ':prompt:backward' enable t
zstyle ':prompt:backward:dir' formats "%U%a%u"
zstyle ':prompt:backward:dir:symlink' formats "%U%F{cyan}%a@%f%u"
zstyle ':prompt:backward:way' formats "%a"

## パス省略表示
# パス省略を有効 (default: 無効)
zstyle ':prompt:truncate' enable t

# 省略記号 (default: ...)
#zstyle ':prompt:truncate' symbol '… '

# パス最大長 (default: 30)
#zstyle ':prompt:truncate' max_length 40

# カレントディレクトリの親ディレクトリを表示する (default: no)
zstyle ":prompt:truncate" show_working_parent yes

# 前ディレクトリの親ディレクトリを表示する (default: no)
# zstyle ":prompt:truncate" show_backward_parent yes

# "/" 直下のディレクトリを表示する (default: no)
zstyle ":prompt:truncate" show_slash_second_root yes

# "~/" 直下のディレクトリを表示する (default: no)
zstyle ":prompt:truncate" show_home_second_root yes
```

add-zsh-hook の chpwd とかでプロンプトを更新    
`promptway` 関数を呼ぶと `$_prompt_way` ってグローバル変数に情報が入ります。  

```sh

setopt prompt_subst
PROMPT='$_prompt_way'

autoload -U add-zsh-hook
add-zsh-hook chpwd promptway

promptway # Initializes $_prompt_way first.
```

たとえば `~/Documents` から `~/Downloads` に移動した場合、 `$_prompt_backward` に情報が入ります。つまり `~/Documents` に `popd` で戻れるディレクトリの位置が保存されます。

![Demo](https://raw.github.com/pasberth/promptway/master/demo/promptbackward.png)

```sh
setopt prompt_subst
PROMPT='$(_print_promptway)'

function _print_promptway () {
  if [ -n "$_prompt_backward" ]; then
    echo ',-- '$_prompt_backward
    echo '`-> '$_prompt_way
  else
    echo '   ['$_prompt_way']'
  fi
}
```