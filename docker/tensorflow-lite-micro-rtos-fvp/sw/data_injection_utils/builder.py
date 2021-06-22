from os import path, mkdir
import subprocess
import re
import requests

from sw.data_injection_utils.config import AppConfiguration

class Builder:
    def __init__(self,  cfg : AppConfiguration):
        self.cfg=cfg

        self.platform_name = "mps3"
        self.platform_subsystem = "sse-300"

        if(self.cfg.compiler == "armclang"):
            self.cfg.logging.info("Using ArmCompiler Toolchain")
            self.platform_toolchain = "scripts/cmake/toolchains/bare-metal-armclang.cmake"
        elif(self.cfg.compiler == "gcc"):
            self.cfg.logging.info("Using GCC Toolchain")
            self.platform_toolchain = "scripts/cmake/toolchains/bare-metal-gcc.cmake"
        else:
            self.cfg.logging.error("Wrong compiler selected. Only armclang or gcc can be used")
            exit(1)
        
        self._cmakelist_path = path.join(self.cfg.eval_kit_base, "CMakeLists.txt")

    def _generate_configure_args(self, extra_build_args: dict = {}) -> list:
        """
        Generates a list of configuration string
        Args:
            extra_build_args:   additional build argument for cmake as a dict
        Returns: list of configuration options to be passed to cmake
        """
        extra_build_arg_string = ""

        for key, value in extra_build_args.items():
            extra_build_arg_string += f' -D{key}={value}'

        _build_args = [
                "-DCMAKE_BUILD_TYPE=Release",
                f"-DTARGET_PLATFORM={self.platform_name}",
                f"-DTARGET_SUBSYSTEM={self.platform_subsystem}",
                f"-DCMAKE_TOOLCHAIN_FILE={self.platform_toolchain}",
                f"{extra_build_arg_string}"
            ]

        return _build_args                                  

    def get_build_dir(self) -> str:
        # check if we are in docker. 
        # this will change the build directory
        docker_check = subprocess.run("grep \"docker\|lxc\" /proc/1/cgroup", shell=True,
                                stdout=subprocess.PIPE, stderr=subprocess.STDOUT).stdout.decode('utf-8')

        build_dir = f'build-data_injection'

        if(len(docker_check)):
            build_dir += '-docker'
        build_dir += f'-{self.cfg.compiler}'

        build_dir_root = path.dirname(self._cmakelist_path)
        build_dir = path.join(build_dir_root, build_dir)

        return build_dir

    def cmake_is_configured_correctly(self, extra_build_args: dict) -> bool:
        build_dir = self.get_build_dir()
        command_str = "cmake -N -L"
        command_return = subprocess.run(command_str, shell=True, cwd=build_dir,
                                stdout=subprocess.PIPE, stderr=subprocess.STDOUT).stdout.decode('utf-8')
        
        self.cfg.logging.info("Checking CMake configuration")

        for key, value in extra_build_args.items():
            result = re.search(f"{key}(.*)", command_return)
            if result == None or value not in result.group(1):
                return False
         
        self.cfg.logging.info("CMake configuration OK")

        return True

    def build_vela_model(self):
            # Sample build variables
        if self.cfg.usecase == "person_detection":
            self.model_vela = path.join(self.cfg.eval_kit_base, "output/person_detection_vela.tflite")
        elif self.cfg.usecase == "img_class":
            self.model_vela = path.join(self.cfg.eval_kit_base, "output/mobilenet_v2_1.0_224_quantized_vela.tflite")

        self.cfg.logging.debug("Optimizing model with vela")
        model = path.join(self.cfg.eval_kit_base, "resources/person_detection/models/person_detection.tflite")
        if self.cfg.usecase == "person_detection":
            model = path.join(self.cfg.eval_kit_base, "resources/person_detection/models/person_detection.tflite")
        elif self.cfg.usecase == "img_class":
            model = path.join(self.cfg.eval_kit_base, "mobilenet_v2_1.0_224_quantized.tflite")
            if not path.exists(model):
                url = 'https://github.com/ARM-software/ML-zoo/raw/68b5fbc77ed28e67b2efc915997ea4477c1d9d5b/models/image_classification/mobilenet_v2_1.0_224/tflite_uint8/mobilenet_v2_1.0_224_quantized_1_default_1.tflite'
                r = requests.get(url, allow_redirects=True)
                open(model, 'wb').write(r.content)
        model_vela_dir = path.dirname(self.model_vela)
        command_str = f"vela {model} --output-dir={model_vela_dir} --accelerator-config=ethos-u55-{self.cfg.num_macs} --config {self.cfg.eval_kit_base}/scripts/vela/default_vela.ini --memory-mode Shared_Sram --system-config Ethos_U55_High_End_Embedded"
        command_status = subprocess.run(command_str, shell=True)
        if 0 == command_status.returncode:
        	self.cfg.logging.debug("Vela compilation successful")
        else:
        	self.cfg.logging.error("Vela compilation failed, aborting")
        	exit()

    def download_source(self):
        self.cfg.logging.info("Cloning ml-embedded-evaluation-kit source tree")
        command_string = f"git clone -b 21.05 --recursive https://git.mlplatform.org/ml/ethos-u/ml-embedded-evaluation-kit.git {self.cfg.eval_kit_base} && (cd {self.cfg.eval_kit_base}; mkdir -p dependencies/tensorflow/tensorflow/lite/micro/tools/make/downloads/gcc_embedded )"
        command_status = subprocess.run(command_string, shell=True)
        if 0 == command_status.returncode:
        	self.cfg.logging.debug("Cloning of ml-embedded-evaluation-kit successful")
        elif 128 == command_status.returncode:
        	self.cfg.logging.debug("Cloning of ml-embedded-evaluation-kit skipped, already exists ")
        else:
        	self.cfg.logging.warning("Cloning of ml-embedded-evaluation-kit failed, trying to proceed")

    def build(self) -> bool:
        """
        Configure and build the project using model path
        Args:
            extra_build_args:   additional build argument for cmake a dict
        """
        # download source
        self.download_source()

        # apply patch        
        self.cfg.logging.debug("applying patch")
        command_string = f"( cd {self.cfg.eval_kit_base}; patch -p1 --forward -b -r /dev/null < {self.cfg.repo_root}/sw/ml-eval-kit/ml-embedded-evaluation-kit-grayscale-support.patch )"
        command_status = subprocess.run(command_string, shell=True)
        
        # copy user samples to the source tree
        from distutils.dir_util import copy_tree
        self.cfg.logging.debug("copying user samples to code tree")
        copy_tree(f"{self.cfg.repo_root}/sw/ml-eval-kit/samples/", f"{self.cfg.eval_kit_base}/")

        self.build_vela_model()

        _build_log = ""
        build_dir = self.get_build_dir()

        if path.isdir(build_dir) == False:
            mkdir(build_dir)

            
        extra_build_args = {
                "USE_CASE_BUILD" : f"\"{self.cfg.usecase}\"",
                f"{self.cfg.usecase}_MODEL_TFLITE_PATH" : self.model_vela ,
                f"{self.cfg.usecase}_FILE_PATH" : path.join(f"{self.cfg.repo_root}/sw/data_injection_utils/dummy_input/", "input.jpg")
            }

        skip_cmake = self.cmake_is_configured_correctly(extra_build_args)

        if not skip_cmake:
            
            relative_cmakefile_path = path.dirname(
                                        path.relpath(self._cmakelist_path, build_dir))
            configuration_opts = self._generate_configure_args(extra_build_args)
            args = ['cmake'] + configuration_opts + [relative_cmakefile_path]
            
            command_str = " ".join(args)
            self.cfg.logging.info(f'Configuring cmake project...')
            
            self.cfg.logging.debug(command_str)

            for opts in configuration_opts:
                self.cfg.logging.info(f'\t{opts}')
            build_state = subprocess.run(command_str, shell=True, cwd=build_dir)

        build_done = False
        if skip_cmake or 0 == build_state.returncode:
            self.cfg.logging.info('Building project...')
            build_state = subprocess.run('make -j', shell=True, cwd=build_dir)
            if 0 == build_state.returncode:
                self.cfg.bin_dir = path.join(build_dir, 'bin')
                build_done  = True
                self.cfg.logging.debug("Build Successful")

        # Revert patch
        self.cfg.logging.debug("reverting applied patch")
        command_string = f"( cd {self.cfg.eval_kit_base}; patch -p1 -R < {self.cfg.repo_root}/sw/ml-eval-kit/ml-embedded-evaluation-kit-grayscale-support.patch )"
        command_status = subprocess.run(command_string, shell=True)
        
        if 0 == command_status.returncode:
        	self.cfg.logging.debug("Reverting patch successful")
        else:
        	self.cfg.logging.warning("Reverting patch failed.")

        if not build_done:
            self.cfg.logging.error('Build failed')

        return build_done
