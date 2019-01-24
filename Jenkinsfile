#!/usr/bin/env groovy
@Library('cht-jenkins-pipeline') _

properties([
    [$class: 'BuildDiscarderProperty', strategy: [$class: 'LogRotator', artifactDaysToKeepStr: '', artifactNumToKeepStr: '', daysToKeepStr: '', numToKeepStr: '15']],
    compressBuildLog()
]);

// NODE FOR RUBY1.9.3-RAILS3.2
node('testing') {
    timestamps {
        stage('Setup_1.9.3-3.0') {
            checkout scm
       }
    }
    timestamps {
        stage('Run Bundle Install') {
            sh "bundle install --no-deployment --binstubs=bin"
        }
    }
    try {
        timestamps {
            stage('Test_1.9.3-3.0') {
                try {
                    sh "bundle exec rspec --format RspecJunitFormatter --out pricing_rspec_1-3_${JOB_BASE_NAME}_${BUILD_NUMBER}.xml"
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
}
