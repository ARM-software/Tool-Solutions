pipeline {
  agent any
  stages {
    stage('Environment Check') {
      steps {
        sh 'echo $PATH'
        sh 'ls ~'
      }
    }
    stage('Run Tests') {
      steps {
        load '/var/lib/jenkins/arm-tool-solutions-resource/jenkinsTests.Groovy'
      }
    }
    stage('Run ') {
      steps {
        script {
          def script = load "/var/lib/jenkins/arm-tool-solutions-resource/jenkinsTests.Groovy "
          script.run_tests()
        }

      }
    }
  }
}