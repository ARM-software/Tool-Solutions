# Tensorflow Lite for Microcontrollers on Corstone 300 FVP (Cortex-M55 + Ethos-U55)

These instructions are available in the following languages
    
[<img src="https://upload.wikimedia.org/wikipedia/commons/8/80/United-Kingdom-orb.png" data-canonical-src="https://upload.wikimedia.org/wikipedia/commons/8/80/United-Kingdom-orb.png" width="15" height="15" alt="English" style="vertical-align:middle" /> English](README.md) | 
[<img src="https://upload.wikimedia.org/wikipedia/commons/b/bf/Japan-orb.png" data-canonical-src="https://upload.wikimedia.org/wikipedia/commons/b/bf/Japan-orb.png" width="15" height="15" alt="Japanese" style="vertical-align:middle" /> 日本語](README-ja.md) | 
[<img src="https://upload.wikimedia.org/wikipedia/commons/8/83/Sweden-orb.png" data-canonical-src="https://upload.wikimedia.org/wikipedia/commons/8/83/Sweden-orb.png" width="15" height="15" alt="Swedish" style="vertical-align:middle" /> Svenska](README-sv.md) 

## 始めに

このレポジトリにはデモとしてCorstone SSE-300 FVP(Fixed Virtual Platform)環境の使い方とスクリプトが入っています。Corstone SSE-300 FVPはCortex－M55/Ethos-U55(uNPU)モデルから構成されているので、機械学習の推論を実行する事が出来ます。

このデモはさまざまなOS上のDocker Container、もしくはLinux環境で実行する事が出来ます。

さらにこのレポジトリには機械学習の推論の為のいくつかの簡単なサンプルが入っており、それらを評価したり、自分向けにカスタマイズすることが可能です。

## 目次

* [始めに](#始めに)
* [目次](#目次)
* [事前準備](#事前準備)
* [依存性](#依存性)
* [環境の構築](#環境の構築)
    * [Option 1: Dockerを利用する場合 (推奨)](#option-1-dockerを利用する場合-推奨)
    * [Option 2: Linux環境を利用する場合](#option-2-linux環境を利用する場合)
* [デモアプリケーションのビルド](#デモアプリケーションのビルド)
    * [ml-embedded-evaluation-kit](#ml-embedded-evaluation-kit)
    * [Ethos-U RTOS デモアプリケーション](#ethos-u-rtos-デモアプリケーション)
* [付属しているデモアプリケーションについて](#付属しているデモアプリケーションについて)
    * [Person Detection](#person-detection)
    * [Mobilenet v2](#mobilenet-v2)
    * [その他のデモアプリケーション](#その他のデモアプリケーション)
* [Vela Model Optimizer for Ethos-U](#vela-model-optimizer-for-ethos-u)
    * [Velaのインストール](#velaのインストール)
* [ネットワーク(.tflm)と推論に利用するイメージファイルのcppへの変換](#ネットワークtflmと推論に利用するイメージファイルのcppへの変換)
    * [ネットワーク(.tflm)のcppへの変換](#ネットワークtflmのcppへの変換)
    * [イメージファイルのcppへの変換](#イメージファイルのcppへの変換)

## 事前準備

* [注意] Arm Compiler(armclang)を起動するためには、正規ランセンス（有償）または30日評価ライセンス（無償）が必要です。ご利用の際はライセンスパスの環境変数`ARMLMD_LICENSE_FILE`を正しく設定する必要があります。評価ライセンスをご希望の場合は[30日間の無料トライアル](https://developer.arm.com/tools-and-software/embedded/arm-development-studio/evaluate)をご覧ください。

* Corstone SSE-300 FVPは無償でご利用いただけます。

最新のArm Compiler(armclang)とCorstone SSE-300 FVPをインストールします。Docker Containerをビルドする場合は、Dockerfile中でこれらのリンクを自動でダウンロード・インストールします。Linuxコンソールで環境構築する場合は、こちらのリンクからファイルをダウンロードし、インストールしてください。

[DS500-DN-00026-r5p0-17rel0.tgz](https://developer.arm.com/-/media/Files/downloads/compiler/DS500-BN-00026-r5p0-17rel0.tgz?revision=2fde4f61-f000-4f22-a182-0223543dc4e8?product=Download%20Arm%20Compiler,64-bit,,Linux,6.15) (ArmCompiler 6.15 for Linux64)

[FVP_Corstone_SSE-300_Ethos-U55_11.13_41.tgz](https://developer.arm.com/-/media/Arm%20Developer%20Community/Downloads/OSS/FVP/Corstone-300/FVP_Corstone_SSE-300_Ethos-U55_11.13_41.tgz) (Corstore SSE-300 FVP with Ethos U55 support for Linux64)


## 依存性

このデモは下記の依存性を含みます：

* [Docker](https://www.docker.com/)
* [Tensorflow](https://github.com/tensorflow/tensorflow/)
* [CMSIS](https://github.com/ARM-software/CMSIS_5/)
* [FreeRTOS](https://github.com/aws/amazon-freertos.git) + [Kernel](https://github.com/FreeRTOS/FreeRTOS-Kernel.git)
* [vela](https://git.mlplatform.org/ml/ethos-u/ethos-u-vela)
* [ethos-u driver and platform](https://review.mlplatform.org/ml/ethos-u)

このデモで利用されているモデルとサンプルイメージはオープンソースを利用しています。個別のライセンス条件や詳細はソースコードのヘッダやREADMEをご参照ください。

## 環境の構築

このデモで利用されているスクリプトはCentOS7(コンソールもしくはDocker Container利用), Ubuntu 18.04(コンソールもしくはDocker Container利用)ならびにWindows 10 Powershell(Docker Container利用)で動作確認しています。

### Option 1: Dockerを利用する場合 (推奨)

0. Dockerのインストール
    * Windows: https://docs.docker.com/docker-for-windows/install/
    * Linux: https://docs.docker.com/engine/install/

1. Linux コンソールもしくはWindows PowershellでDocker buildの実行:
    * Windows PowerShell:
        * ArmCompilerを利用したい場合
            ```
            $> ./docker_build.PS1 -compiler armclang
            ```
        * GCC Compilerを利用したい場合
            ```
            $> ./docker_build.PS1 -compiler gcc
            ```
    * Linux:
        * ArmCompilerを利用したい場合
            ```
            $> ./docker_build.sh -c armclang
            ```
        * GCC Compilerを利用したい場合
            ```
            $> ./docker_build.sh -c gcc
            ```

1. スクリプトが無事完了したら、docker image tensorflow-lite-micro-rtos-fvp:<compiler>が生成されているはずです。

1. Docker containerを起動してbashを起動します(ご自分の環境に合わせて実行して下さい):
    * Windows:
        ```
        $> docker run -it -e LOCAL_USER_ID=0 -v $PWD\sw:/work/sw -v $PWD\dependencies:/work/dependencies -e DISPLAY=localhost:1 --privileged --rm tensorflow-lite-micro-rtos-fvp:<compiler> /bin/bash
        ```
    * Linux;
        ```
        $> ./docker_run.sh -i <compiler>
        ```

### Option 2: Linux環境を利用する場合

***Ubuntu 18.04 と CentOS7 で動作確認済み***

1. Arm Compiler(armclang)とCorstone SSE-300 FVPをインストールします。

    1. インストールが終了したらarmclangとCorstore SSE-300のインストールパスを環境に合わせて設定してください。
        * Temporary 
            ```
            $> export PATH=<armclang-install-dir>:$PATH
            $> export PATH=<FVP-install-dir>/models/Linux64_GCC-6.4:$PATH
            ```
        * Persistent
            ```
            $> echo "export PATH=<armclang-install-dir>:$PATH" >> ~/.bashrc
            $> echo "export PATH=<FVP-install-dir>/models/Linux64_GCC-6.4:$PATH" >> ~/.bashrc
            $> source ~/.bashrc
            ```
    2. 設定されたパスが有効か、確認します。

        ```
        $> armclang --version
        Product: ARM Compiler 6.15 Ultimate
        Component: ARM Compiler 6.15
        Tool: armclang [5dd79400]

        Target: unspecified-arm-none-unspecified

        $> FVP_Corstone_SSE-300_Ethos-U55 --version

        Fast Models [11.13.41 (Feb  2 2021)]
        Copyright 2000-2021 ARM Limited.
        All Rights Reserved.

        Info: /OSCI/SystemC: Simulation stopped by user.
        ```

    確認が失敗した場合、$PATHが有効に設定されているか再確認願います。armclangの起動には正規ライセンスもしくは評価ライセンスが必要で、環境変数`ARMLMD_LICENSE_FILE`が正しく設定されている必要があります。

2. Linux向けセットアップスクリプトを走らせます:
    ```
    $> ./linux_build.sh
    ```


## デモアプリケーションのビルド

### ml-embedded-evaluation-kit

このキットには、ベアメタルサンプルアプリケーションが含まれています。
アプリケーションは、FVPを使用して実行することも、MPS3評価ボードで直接実行することもできます。

サンプルアプリケーションのビルドに使用できるスクリプトは2つあります。 

* `run_fvp_eval.py`は、person_detectionまたはimg_classサンプルアプリケーションをダウンロード、ビルド、実行します。 これを使用して、データをアプリケーションに動的に挿入する方法の例を示します。
    ```
    $> ./run_fvp_eval.py
    ``` 
    * コマンドライン引数 `--image_path = <path/to/image/or/folder>`を使用して、アプリケーションに挿入する画像を選択できます 
    * コマンドライン引数 `--use_camera=True`を使用して、USBカメラを使用して入力データを取得することもできます（各推論には少なくとも10秒かかるため、スムーズなリアルタイムビデオは期待しないでください） 
    * ビデオストリームでリアルタイムスタイルの推論を実行するには、ビデオフレームを静止画像に変換し、そのフレームを入力として使用するのが最善の方法です。 

* `linux_build_eval_kit.sh`はキットをダウンロードしてビルドします。サンプルを手動で実行する場合、またはMPS3ボードで実行するために独自のサンプルイメージをアプリケーションにベイクする場合は、これを使用します。 ビルドスクリプトを実行する前に、イメージを `sw/ml-eval-kit/samples/resources/<use-case>/samples/`フォルダーにコピーします。
    1. ビルド
        ```
        $> ./linux_build_eval_kit.sh
        ```

    1. サンプルを実行します
        ```
        $> FVP_Corstone_SSE-300_Ethos-U55 -a dependencies/ml-embedded-evaluation-kit/build_auto/bin/<sample-name>.axf
        ``` 
    1. サンプルと対話します
    サンプルアプリケーションを操作する必要がある場合があります。
    これを行うには、2番目のターミナルを開いて実行してください
        ```
        $> telnet localhost 5000
        ```
        * 注：dockerを使用している場合は、最初に2番目のターミナルで実行中のdockerコンテナーを入力する必要があります。
            * 実行中のコンテナーのcontainer-idを検索します
                ```
                $> docker ps
                ```
            * Dockerコンテナを入力します
                ```
                $> docker exec -it <container-id> /bin/bash
                ``` 

指示に従うことで、ml-emedded-evaluation-kitを手動でビルドして実行することもできます。 オープンソースプロジェクトはここから入手できます： `https://git.mlplatform.org/ml/ethos-u/ml-embedded-evaluation-kit.git` 

### Ethos-U RTOS デモアプリケーション

このアプリケーションはFreeRTOSサンプルアプリケーションであり、FVPを使用するか、MPS3評価ボードで直接実行できます。

1. ビルド
    ```
    $> ./linux_build.sh -c <compiler>
    ```

1. デモアプリを走らせます。完了するまでに10〜20分かかる場合があります。 (オプション "-h" でオプションメニューを全表示します):
    ```
    $> ./run_demo_app.sh
    ```


## 付属しているデモアプリケーションについて
### Person Detection
Mobilenetベースで作られた人物検知の為のネットワークです。FreeRTOS上で動きます。出力結果は"Person","No Person"の2通りです。
この簡単なデモを通してTensorflow Lite Micro(TFLM)のネットワークをCorstore SSE-300 FVP上で実行する手順をご理解いただけます。  

### Mobilenet v2
Mobilenet v2ネットワークの実行デモです。FreeRTOS上で動きます。イメージ上の2つのオブジェクトを検知可能です。
この簡単なデモを通してTensorflow Lite Micro(TFLM)のネットワークをCorstore SSE-300 FVP上で実行する手順をご理解いただけます。

### その他のデモアプリケーション
ml-embedded-evaluation-kitには、キーワードスポッティングと自然言語処理用のサンプルアプリケーションが含まれています。
このサンプルは手動で実行できます。 

## Vela Model Optimizer for Ethos-U

Vela Model OptimizerはTFLMネットワークをEthos-U55に最適化します。VelaはDocker image内にインストール済みです。

Vela利用例:
```
vela <input_model.tflite>
```
Vela起動後は`output`フォルダに.tfliteというファイルが生成されます。

### Velaのインストール

Velaはpython packageとして準備されています。下記はインストールの方法です。

1. Python3.6(およびそれ以降)の準備
    You will need to have python v3.6 or above. 
    We recommend using a virtualenv.

    Installing Python:
    ```
    $> sudo apt update
    $> sudo apt install -y python3 python3-venv python3-dev python3-pip
    $> python -m virtualenv -p python3 .vela-venv
    ```

1. Python virtualenvを使ってVelaをインストール

    ```
    $> source .vela-venv/bin/activate
    $> python -m pip install ethos-u-vela
    ```

## ネットワーク(.tflm)と推論に利用するイメージファイルのcppへの変換

今回のデモではネットワークとイメージファイルをcppに変換し、Arm向けにクロスコンパイルする方式を取っています。
変換を容易にする為のスクリプトを用意しています。

`~/work/sw/convert_scripts`

### ネットワーク(.tflm)のcppへの変換

ネットワーク(.tflm)をcppに変換するには`convert_tflite_to_cpp.sh`を利用します。

```
$> convert_tflite_to_cpp.sh --input <model.tflite> --output model_vela.cpp
```

変換後生成されたcppファイルを組み込み向けプロジェクトに組み込んで、Arm向けにクロスコンパイルします。  

### イメージファイルのcppへの変換

- For RGB images:
    ```
    $> convert_images_to_cpp.sh \
        --input <image_folder> \
        --output <output_folder> \
        --width <new_width> \
        --height <new_height>
    ```
- For Grayscale images:
    ```
    $> convert_images_to_cpp.sh \
        --input <image_folder> \
        --output <output_folder> \
        --width <new_width> \
        --height <new_height> \
        --grayscale 1
    ```

変換後生成されたcppファイルを組み込み向けプロジェクトに組み込んで、Arm向けにクロスコンパイルします。  
