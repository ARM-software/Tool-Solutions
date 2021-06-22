import logging
import subprocess
from os import path, mkdir, getenv, getcwd
from argparse import ArgumentParser
from packaging import version



class AppConfiguration:
    def __init__(self):
        self.logging=logging

        format = "[%(levelname)s] %(message)s"
        self.logging.basicConfig(format=format, level=logging.DEBUG)

        # the path of this file
        self.repo_root = path.join(path.dirname(path.abspath(__file__)), "../..")
        # path to the ml-embedded-evaluation-kit 
        self.eval_kit_base = path.join(self.repo_root, "dependencies/ml-embedded-evaluation-kit")
        
        # default usecase
        self.usecase = "person_detection"
        
        #default image path to use
        self.image_path = f"{self.eval_kit_base}/resources/{self.usecase}/samples/"

        # whether to use USB camera or not
        self.use_camera = False

        # whether to use fast mode or not
        self.speed_mode = False
        
        self.num_macs = 128

        # Compiler, armclang or gcc
        self.compiler = getenv('COMPILER', default='armclang')

        # directory of the compiled binaries
        self.bin_dir = path.join(self.eval_kit_base, "build-data_injection/bin")

    def ParseInputArguments(self):
        """
        Example usage
        """
        parser = ArgumentParser(description="Build and run Ethos Evaluation Samples")
        parser.add_argument('--usecase', type=str.lower, default=self.usecase, choices=["img_class", "person_detection"],
                            help='Application to run')
        parser.add_argument('--enable_camera', default=False, action="store_true",
                            help='Use a camera feed as input (Default: False)')
        parser.add_argument('--image_path', type=str, default=self.image_path,
                            help='Path to image or folder to use in inference (injected into application)')
        parser.add_argument('--compiler', type=str.lower, default=self.compiler, choices=["armclang", "gcc"],
                            help='Which compiler to use, armclang or gcc')
        parser.add_argument('--enable_speed_mode', default=False, action="store_true",
                            help='Use FVP speed mode, making inferences go faster (Default: False)')
        parser.add_argument('--num_macs', type=int, default=128, choices=[32, 64, 128, 256],
                            help='Ethos-U55 mac configuration. 32, 64, 128, 256 (Default: 128)')
        #parser.add_argument('--log_file', type=str, default="/tmp/run_log.txt",
        #                    help="Log file path")
        args = parser.parse_args()

        self.usecase = args.usecase
        logging.debug(f"Running usecase {self.usecase}")

        self.image_path = args.image_path
        if not self.image_path[0] == '/':
            self.image_path = path.join(getcwd(), self.image_path)
        if not path.exists(self.image_path):
            logging.error(f"{self.image_path} was not found. Has to be a valid path")
            exit()
        logging.debug(f"Setting image path to {self.image_path}")

        self.compiler = args.compiler
        logging.debug(f"Using compiler {self.compiler}")

        self.use_camera = args.enable_camera

        # speed mode is only available on FVP 11.14 and higher
        # demo is only supported on 11.13 and higher
        fvp_version=subprocess.check_output("FVP_Corstone_SSE-300_Ethos-U55 --version | grep 'Fast Models \[[0-9][0-9].[0-9][0-9]'| awk '{ print $3 }'", shell=True).decode('utf-8').replace('[', '')
        
        if version.parse(fvp_version) < version.parse("11.13"):
            logging.error("{}{}".format(f"This demo only supports only supports FVP version 11.13 or higher. Installed version is {fvp_version}",
            "\tPlease upgrade the FVP: https://developer.arm.com/tools-and-software/open-source-software/arm-platforms-software/arm-ecosystem-fvps\n"))
            exit()

        self.speed_mode = args.enable_speed_mode

        if self.speed_mode:
            if version.parse(fvp_version) >= version.parse("11.14"):
                logging.debug("Enabling speed mode.")
            else:
                logging.error("{}{}".format(f"Speed mode is only supported on FVP version 11.14 or higher. Installed version is {fvp_version}",
                "\tPlease upgrade the FVP: https://developer.arm.com/tools-and-software/open-source-software/arm-platforms-software/arm-ecosystem-fvps\n"))
                exit()

        self.num_macs = args.num_macs
        logging.debug(f"Setting mac count to {self.num_macs}")
