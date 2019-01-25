#!/usr/bin/env groovy
@Library('cht-jenkins-pipeline') _

properties([
    [$class: 'BuildDiscarderProperty', strategy: [$class: 'LogRotator', artifactDaysToKeepStr: '', artifactNumToKeepStr: '', daysToKeepStr: '', numToKeepStr: '15']],
    compressBuildLog()
]);

if (env.BRANCH_NAME == 'master') {
   properties([pipelineTriggers([cron('H H(8-10) * * 4')])],
       [$class: 'BuildDiscarderProperty', strategy: [$class: 'LogRotator', artifactDaysToKeepStr: '', artifactNumToKeepStr: '', daysToKeepStr: '', numToKeepStr: '15']],
       compressBuildLog()
   );
}

// NODE FOR RUBY2.3.3-RAILS3.2
node('testing') {
    try {
        timestamps {
            stage('Setup_2.3.3-3.0') {
                checkout scm
                sh "docker build -f docker/Dockerfile -t pricing_image ."
                sh "docker run -dit --name=pricing-app-${JOB_BASE_NAME}_${BUILD_NUMBER} -e RAILS_ENV=test -v ${WORKSPACE}/:/home/cloudhealth/amazon-pricing/ pricing_image /bin/bash"
           }
        }
        timestamps {
            stage('Run Bundle Install') {
                sh "docker exec pricing-app-${JOB_BASE_NAME}_${BUILD_NUMBER} /bin/bash -c  -l 'bundle install --no-deployment --binstubs=bin'"
            }
        }
        try {
            timestamps {
                stage('Test_2.3.3-3.0') {
                    try {
                        sh 'docker exec pricing-app-${JOB_BASE_NAME}_${BUILD_NUMBER} /bin/bash -c -l "bundle exec rspec --format RspecJunitFormatter --out pricing_rspec_1-3_${JOB_BASE_NAME}_${BUILD_NUMBER}.xml"'
                    } finally {
                        junit(testResults: 'pricing_rspec_1-3_${JOB_BASE_NAME}_${BUILD_NUMBER}.xml')
                    }
                }
            }
            sh "exit 0"
            currentBuild.result = 'SUCCESS'
        } catch (Exception e) {
        // Exit 0 so that we can keep running other nodes (if we are to add more) if this one fails
            sh "exit 0"
            currentBuild.result = 'FAILURE'
        }
    } finally {
        sh "docker stop pricing-app-${JOB_BASE_NAME}_${BUILD_NUMBER} && docker rm -f pricing-app-${JOB_BASE_NAME}_${BUILD_NUMBER}"
    }
}
