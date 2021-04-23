# Tensorflow Lite for Microcontrollers med Corstone 300 FVP (Cortex-M55 + Ethos-U55)

De här instructionerna finns att läsa på följande språk:
    
[<img src="https://upload.wikimedia.org/wikipedia/commons/8/80/United-Kingdom-orb.png" data-canonical-src="https://upload.wikimedia.org/wikipedia/commons/8/80/United-Kingdom-orb.png" width="15" height="15" alt="English" style="vertical-align:middle" /> English](README.md) | 
[<img src="https://upload.wikimedia.org/wikipedia/commons/b/bf/Japan-orb.png" data-canonical-src="https://upload.wikimedia.org/wikipedia/commons/b/bf/Japan-orb.png" width="15" height="15" alt="Japanese" style="vertical-align:middle" /> 日本語](README-ja.md) | 
[<img src="https://upload.wikimedia.org/wikipedia/commons/8/83/Sweden-orb.png" data-canonical-src="https://upload.wikimedia.org/wikipedia/commons/8/83/Sweden-orb.png" width="15" height="15" alt="Swedish" style="vertical-align:middle" /> Svenska](README-sv.md) 

## Introduktion

Detta project innehåller instructioner och skript för att skapa och använda en utvecklingsmiljö för Corstone SSE-300 FVP (Fixed Virtual Platform). En FVP simmulerar en Cortex-M55 och Ethos-U55 (µNPU) plattform. 

Det är möjligt att välja mellan att sätta up miljön via Docker, eller direkt på en Linux maskin.

Detta repo innehåller ett par exempelapplikationer som använder FreeRTOS som OS, dessa kan användas för att komma igång med utveckling av applikationer till en plattform baserad på Cortex-M och Ethos-U.

## Innehållsförteckning

* [Introduktion](#introduktion)
* [Innehållsförteckning](#innehållsförteckning)
* [Förhandsvillkor](#förhandsvillkor)
* [Beroenden](#beroenden)
* [Sätta upp utvecklingsmiljö](#sätta-upp-utvecklingsmiljö)
    * [Alternativ 1: Docker (Rekomenderas)](#alternativ-1-docker-rekomenderas)
    * [Alternativ 2: Använd linux machine.](#alternativ-2-använd-linux-machine)
* [Om Demoapplikationerna](#om-demoapplikationerna)
    * [Persondetektering](#persondetektering)
    * [Mobilenet V2](#mobilenet-v2)
* [Vela Modelloptimerare för Ethos-U](#vela-modelloptimerare-för-ethos-u)
    * [Installera Vela](#installera-vela)
* [Konvertera modeller och bilder till cpp-kod](#konvertera-modeller-och-bilder-till-cpp-kod)
    * [Konvertera en modell](#konvertera-en-modell)
    * [Konvertera en mapp med bilder](#konvertera-en-mapp-med-bilder)

## Förhandsvillkor

* Systemvariabeln `ARMLMD_LICENSE_FILE` måste vara definerad och peka på en aktiv licensserver för att kunna använda armclang (ArmCompiler). Definera variabeln innan du bygger din Docker Image. (Behövs inte om du inte tänker använda armclang).

När du bygger din Docker Image, så kommer följande filer att laddas ner till rotmappen av detta projekt:

* [DS500-DN-00026-r5p0-17rel0.tgz](https://developer.arm.com/-/media/Files/downloads/compiler/DS500-BN-00026-r5p0-17rel0.tgz?revision=2fde4f61-f000-4f22-a182-0223543dc4e8?product=Download%20Arm%20Compiler,64-bit,,Linux,6.15) (ArmCompiler 6.15 for Linux64)
* [FVP_Corstone_SSE-300_Ethos-U55_11.13_41.tgz](https://developer.arm.com/-/media/Arm%20Developer%20Community/Downloads/OSS/FVP/Corstone-300/FVP_Corstone_SSE-300_Ethos-U55_11.13_41.tgz) (Corstore SSE-300 FVP with Ethos U55 support for Linux64)

## Beroenden

Detta projekt har förljande beroenden:

* [Docker](https://www.docker.com/)
* [Tensorflow](https://github.com/tensorflow/tensorflow/)
* [CMSIS](https://github.com/ARM-software/CMSIS_5/)
* [FreeRTOS](https://github.com/aws/amazon-freertos.git) + [Kernel](https://github.com/FreeRTOS/FreeRTOS-Kernel.git)
* [vela](https://git.mlplatform.org/ml/ethos-u/ethos-u-vela)
* [ethos-u driver och plattform](https://review.mlplatform.org/ml/ethos-u)

Modeller och exempelbilder som används i detta projekt är öppen källkod och detaljer om dessa kan hittas i en README för respektive demo applikation.

## Sätta upp utvecklingsmiljö

Byggskripten har testats med CentOS 7, Ubuntu 18.04, och Windows 10 PowerShell

### Alternativ 1: Docker (Rekomenderas)

0. Installera Docker
    * Windows: https://docs.docker.com/docker-for-windows/install/
    * Linux: https://docs.docker.com/engine/install/

1. Kör byggskriptet för docker i en linux terminal eller Windows Powershell:
    * Windows PowerShell:
        * Om du önskar att andvända Arm Compiler
            ```
            $> ./docker_build.PS1 -compiler armclang
            ```
        * Om du önskar att andvända GNU GCC Compiler
            ```
            $> ./docker_build.PS1 -compiler gcc
            ```
    * Linux:
        * Om du önskar att andvända Arm Compiler
            ```
            $> ./docker_build.sh -c armclang
            ```
        * Om du önskar att andvända GNU GCC Compiler
            ```
            $> ./docker_build.sh -c gcc
            ```

1. När skriptet har kört klart, kommer en docker image som heter ubuntu:18.04_sse300 ha skapats.

1. Logga in i docker imagen med föjande kommando (om du vill använda lokala volymer för data, så kan du modifiera kommandot efter behov):
    * Windows:
        ```
        $> docker run -it ubuntu:18.04_sse300 /bin/bash
        ```
    * Linux:
        ```
        $> ./docker_run.sh
        ```

1. Kör en demoapplikation med följande kommando. Det kan ta 10-20 minuter för applikationen att köra klart. (Använd "-h"-flaggan för att se alla köralternativ):
    ```
    $> ./run_demo_app.sh
    ```

### Alternativ 2: Använd linux machine.

***Detta har testats på Ubuntu 18.04 och CentOS 7 ***

1. Installera ArmCompiler och Corstore SSE-300 FVP.

    1. Efter installationen, lägg till armclang och Corstore SSE-300 mapparna till din PATH-variabel.
        * Temporärt 
        ```
        $> export PATH=<armclang-install-dir>:$PATH
        $> export PATH=<FVP-install-dir>/models/Linux64_GCC-6.4:$PATH
        ```
        * Permanent
        ```
        $> echo "export PATH=<armclang-install-dir>:$PATH" >> ~/.bashrc
        $> echo "export PATH=<FVP-install-dir>/models/Linux64_GCC-6.4:$PATH" >> ~/.bashrc
        $> source ~/.bashrc
        ```
    1. Testa att PATH-variabeln är konfigurerad korrekt

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

    Om det uppstår några problem, se till att PATH-variabeln är konfigurerad korrekt, och fär armclang, att du har `ARMLMD_LICENSE_FILE`-variabeln konfigurerad korrekt. För armclang så måste du ha en aktiv licensserver.

1. Kör byggskriptet för linux:
    ```
    $> ./linux_build.sh
    ```

1. Kör demoapplikationen med följande kommando (använd "-h"-flaggan för att se alla köralternativ):
    ```
    $> ./run_demo_app.sh
    ```

## Om Demoapplikationerna
### Persondetektering
Detta demo använder en persondetekteringsmodell baserad på mobilenet. Applikationen kör på FreeRTOS som OS.
Flera inferenser görs på bilder med och utan personer i.

Demoapplikationen är menad som ett enkelt exempel på hur man kan distribuera  Tensorflow Lite Micro med Corstore SSE-300 plattformen.  

### Mobilenet V2
Denna demoapplikation använder en tränad mobilenet v2-modell. Denna apllikation kör också med FreeRTOS som OS.
Flera inferenser görs, bland annat på bilder med en bil och kvinnor bärandes Kimono.

Demoapplikationen är menad som ett enkelt exempel på hur man kan distribuera  Tensorflow Lite Micro med Corstore SSE-300 plattformen.  

## Vela Modelloptimerare för Ethos-U

Vela är installerad i docker imagen, vilket gör det möjligt att optimera och kompilera dina egna modeller för Ethos-U.

Vela används såhär:
```
vela <input_model.tflite>
```
Resultatet är en ptimerad tflite-modell i `output`-mappen.

### Installera Vela

Om du kör utan docker, så måste du installera Vela själv.

Vela finns tillgängligt som ett Pyton-paket. Här är instruktioner för att instalera Vela. 

1. Förhandsvillkor
    Du måste ha Python v3.6 eller senare. 
    Vi rekommenderar att använda en virtualenv.

    Installera Python:
    ```
    $> sudo apt update
    $> sudo apt install -y python3 python3-venv python3-dev python3-pip
    ```

1. Installera Vela i en virtualenv

    ```
    $> python -m virtualenv -p python3 .vela-venv
    $> source .vela-venv/bin/activate
    $> python -m pip install ethos-u-vela
    ```

## Konvertera modeller och bilder till cpp-kod

Det finns hjälpskript tillgängliga för att konvertera modeller och bilder till cpp-kod.

I docker imagen finns de placerade i `~/work/sw/convert_scripts`

I detta projekt är det placerade i `sw/convert_scripts`

### Konvertera en modell

Använd skriptet  `convert_tflite_to_cpp.sh` för att konvertera en tflite modell till cpp-kod.

```
$> convert_tflite_to_cpp.sh --input <model.tflite> --output model_vela.cpp
```

Efter att skriptet kört klart, så kan du lägga till den nya kodfilen till applikationens mapp, och kompilera om.  

### Konvertera en mapp med bilder

- För RGB-bilder:
    ```
    $> convert_images_to_cpp.sh \
        --input <image_folder> \
        --output <output_folder> \
        --width <new_width> \
        --height <new_height>
    ```
- För gråskale-bilder:
    ```
    $> convert_images_to_cpp.sh \
        --input <image_folder> \
        --output <output_folder> \
        --width <new_width> \
        --height <new_height> \
        --grayscale 1
    ```

Lägg till bilderna till aplikationens mapp, och kompilera om.
