pipeline {
  // Run this build in the defined docker build environment
  agent {
    docker {
      image 'sub-jdk11-mvn36-vnc-swt:2022-01'
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
    // Release parameters
    booleanParam(name: "RELEASE", defaultValue: false,
      description: "Perform a release build.")
    string(name: "ReleaseVersion", defaultValue: "a.b.c",
      description: "Version to release",  trim: true)
    string(name: "SnapshotVersion", defaultValue: "d.e.f-SNAPSHOT",
      description: "Version for the next snapshot",  trim: true)
    credentials(name: 'GitPushCredentials', defaultValue: '', 
      description: 'User credentials to use for pushing the updated data to git and setting the release tag',
      credentialType: 'com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl', required: false),
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
          expression { BRANCH_NAME == "main" }
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

    stage('Perform Release') {
      when {
        allOf {
          expression { currentBuild.resultIsBetterOrEqualTo("SUCCESS") }
          expression { BRANCH_NAME == "main" }
          expression { params.RELEASE }
        }
      }
      steps {
        dir('de.scheidtbachmann.statemachine.parent') {
          configFileProvider([configFile(fileId: '881491aa-33ec-4807-bd2f-5bae17666022', targetLocation: 'settings.xml', variable: 'MAVENSETTINGS')]) {
            withCredentials([usernamePassword(credentialsId: "${GitPushCredentials}", passwordVariable: 'githubPass', usernameVariable: 'githubUser')]) {
              sh "${env.MVN_CMD} -DdevelopmentVersion=${params.SnapshotVersion} -DreleaseVersion=${params.ReleaseVersion} -Dtag=${params.ReleaseVersion} -Dresume=false -DignoreSnapshots=true -Dusername=$githubUser -Dpassword=$githubPass release:prepare release:perform"
            }
          }
        }
      }
    }

    stage('WhiteSource') {
      when {
        allOf {
          expression { BRANCH_NAME == "main" }
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

