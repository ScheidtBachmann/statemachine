pipeline {
  // Run this build in the defined docker build environment
  agent {
    docker {
      image 'sub-base-vnc-swt:2021-03'
      registryUrl 'https://ki-vl-artifactory.ki.lan:5001'
    }
  }

  // Configure the build options (overwrites config in jenkins upon build)
  options {
    buildDiscarder(logRotator(numToKeepStr: '6'))
    disableConcurrentBuilds()
    timestamps()
    disableResume()
  }

  parameters {
    // Parameters for stages
    booleanParam(name: "Deploy", defaultValue: true,
      description: "Deploy the built artifacts to the repository.")
    booleanParam(name: "Whitesource", defaultValue: false,
      description: "Run the Whitesource analysis during the build.")
    // General process parameters
    booleanParam(name: "Update", defaultValue: false,
      description: "Update any snapshots used in the built process.")
    booleanParam(name: "Parallel", defaultValue: true,
      description: "Run the maven build in parallel mode.")
  }

  environment {
    JENKINS_MAVEN_AGENT_DISABLED=true
    MVN_CMD = "mvn -B ${params.Update ? '-U' : ''} -Dmaven.repo.local=../.m2Repo -s settings.xml"
  }

  stages {
    stage('Build') {
      steps {
        dir('de.scheidtbachmann.statemachine.parent') {
          configFileProvider([configFile(fileId: '881491aa-33ec-4807-bd2f-5bae17666022', targetLocation: 'settings.xml', variable: 'MAVENSETTINGS')]) {
            sh "${env.MVN_CMD} clean install"
          }
        }
      }
    }

    stage('Deploy') {
      when {
        allOf {
          expression { currentBuild.resultIsBetterOrEqualTo("SUCCESS") }
          expression { BRANCH_NAME == "master" }
          expression { params.Deploy }
        }
      }
      steps {
        dir('de.scheidtbachmann.statemachine.parent') {
          configFileProvider([configFile(fileId: '881491aa-33ec-4807-bd2f-5bae17666022', targetLocation: 'settings.xml', variable: 'MAVENSETTINGS')]) {
            sh "${env.MVN_CMD} deploy"
          }
        }
      }
    }

    stage('WhiteSource') {
      when {
        allOf {
          expression { BRANCH_NAME == "master" }
          expression { params.Whitesource }
        }
      }
      steps {
        withCredentials([string(credentialsId: 'b7e6a5cf-7aee-4b4e-a953-f27cacec98d4', variable: 'WHITESOURCEAPIKEY')]) {
          sh 'java -jar /opt/whitesource/wss-unified-agent.jar -c whitesource.config -apiKey $WHITESOURCEAPIKEY -productToken b0c4d351804c401aba307e46446282ea5e01036ce46b4e089092d8d8da7d6769 -d de.scheidtbachmann.statemachine.parent'
        } 
      }
    }
  }
}

