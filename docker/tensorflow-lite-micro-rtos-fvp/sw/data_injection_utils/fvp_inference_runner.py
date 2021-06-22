import subprocess
from os import path
import re
from packaging import version

from sw.data_injection_utils.config import AppConfiguration

# fvp runner will run the FVP with the sample application
class FvpInferenceRunner:
    def __init__(self, cfg : AppConfiguration):
        self.cfg=cfg
        self._bin_dir = self.cfg.bin_dir
        self._fvp_exec_path = "FVP_Corstone_SSE-300_Ethos-U55"
        self._cli_args = f"-C ethosu.num_macs={self.cfg.num_macs} -C mps3_board.telnetterminal0.start_telnet=0 -C mps3_board.uart0.out_file='-' -C mps3_board.uart0.shutdown_on_eot=1 -C mps3_board.visualisation.disable-visualisation=1 --stat"
        self._axf_path = path.join(self._bin_dir, f"ethos-u-{self.cfg.usecase}.axf")

        if self.cfg.speed_mode:
            self._cli_args += " -C ethosu.extra_args='--fast'"

    def _run_simulation(self, timeout: int) -> str:
        """
        Runs the executable in a subprocess
        """
        self.cfg.logging.info("Starting inference\n")
        isim_timeout_cmd = f'--timelimit {timeout}'
        injection_file_cmd = f'--data={self.cfg.repo_root}/image_data.dat@0x70000000'
        axf_cmd = f'-a {self._axf_path}'
        # CLI command
        cmd = ' '.join([self._fvp_exec_path, self._cli_args,
                        isim_timeout_cmd, axf_cmd, 
                        injection_file_cmd])
        self.cfg.logging.debug(f"running command = {cmd}\n")
        self.cfg.logging.info('Starting simulation environment... It may take a while to run depending on usecase. Be patient')
        state = subprocess.run(cmd, shell=True, cwd=self.cfg.repo_root,
                    stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        _simulation_log = state.stdout.decode('utf-8')
        self.cfg.logging.debug(_simulation_log)

        # get the inference result string
        result = re.search(r'(?<=INFO - Total number of inferences: 1\r\n)(.*?)(?=INFO - Profile for Inference:)', _simulation_log, flags=re.S).group()

        # strip the result of unecessary line endings, tabs and tags
        result = result.replace("INFO - ", "")
        result = result.replace("\t", "")
        result = result.replace("\r\n", "\n")

        profiling = re.search(r'(?<=INFO - Profile for Inference:\r\n)(.*?)(?=INFO - Main loop terminated.)', _simulation_log, flags=re.S).group()

        profiling = profiling.replace("INFO - ", "")
        profiling = profiling.replace("\t", "")
        profiling = profiling.replace("\r\n", "\n")

        result = result + "\n" + profiling

        return result
