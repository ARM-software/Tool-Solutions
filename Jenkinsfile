pipeline {
  agent any
  stages {
    stage('Test Env') {
      steps {
        sh '''ls


'''
        sh 'echo $PATH'
      }
    }
    stage('mathworks-support-packages') {
      steps {
        sh '''cd mathworks-support-packages




&& [ -f "R2018a/Arm Compiler Support Package.mltbx" ]; echo $?'''
      }
    }
  }
}