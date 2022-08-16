# Tool Solutions
This repository is home to various examples and tutorials made to improve your efficiency working with development tools. From system design to software development, we provide material to better utilize tools from Arm and the Arm ecosystem. 

**⚠ Important**
The default branch for this repository has been renamed to `main` in an effort to switch to branch names that are meaningful and inclusive.
Users may need to update any local repositories to use the new default branch (see [updating a local clone after a branch name changes](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-branches-in-your-repository/renaming-a-branch#updating-a-local-clone-after-a-branch-name-changes)

For more details on how this was done see https://github.com/github/renaming.

### Downloading Content
There are multiple ways to obtain content from this repository to use locally. Two ways are:
- ```git clone https://github.com/ARM-software/Tool-Solutions/```
    - This method will download all content from the Tool-Solutions repository. 
- ```svn export https://github.com/ARM-software/Tool-Solutions/trunk/<specific_directory_name>```
    - This method downloads specific directories, narrowing down to exactly what you needed. Note that this downloads the folder only, does not checkout/clone it, and requires svn.

## Table of Contents 
Here is a list of all the contents of this repository with short descriptions:


#### docker 
Dockerfiles with Arm tools pre-installed in them for developing across operating systems and easily sharing projects. Also included are some examples of how to build multi-architecture docker images supporting the Arm architecture and other Arm docker images such as how to build TensorFlow and PyTorch on AArch64.

#### hello-world_fast-models
A tutorial to get started with Arm Fast Model tools, from install to running your first program.

#### fast-models-examples
Various example systems and software for Arm Fast Models.

#### acet-developer
Demonstration of ETAS ASCET-DEVELOPER model based design and code generation with Arm Development Studio 

#### mathworks-support-packages
Support packages to enable Arm Fast Models and Arm Compiler usage with MathWorks software such as Embedded Coder, Simulink, and MATLAB.

#### windows-pmu-to-reg
Script to expose Arm Performance Monitoring Unit (PMU) events to the Windows Management Instrumentation (WMI) system, allowing collection via tools such as Windows Performance Recorder.

#### perf-derived-metrics
Demonstration calculating derived metrics from data collected via Linux `perf stat` and formulate stored in per-CPU YAML files.

#### boards
Information about running Linux on Arm development boards.

## Contact Us
Have questions, comments, and/or suggestions? Contact [arm-tool-solutions@arm.com](mailto:arm-tool-solutions@arm.com).
