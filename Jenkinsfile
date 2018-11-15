pipeline {
  agent any
  stages {
    stage('Test Env') {
      steps {
        script {
          modules.script = load "~/arm-tool-solutions-resource/jenkinsTests.Groovy"
          modules.script.run_tests()
        }

      }
    }
  }
}