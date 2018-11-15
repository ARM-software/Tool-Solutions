pipeline {
  agent any
  stages {
    stage('Test Env') {
      steps {
        script {
          def tests = load "~/arm-tool-solutions-resource@script/jenkinsTests.Groovy"
          tests.run_tests()
        }

      }
    }
  }
}