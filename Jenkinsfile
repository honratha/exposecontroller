#!/usr/bin/groovy
node{

  git 'https://github.com/honratha/exposecontroller.git'

  kubernetes.pod('buildpod').withImage('fabric8/go-builder')
  .withEnvVar('GOPATH','/home/jenkins/workspace/workspace/go')
  .withPrivileged(true).inside {

    stage 'build binary'
    
    sh """
    export GOPATH=/home/jenkins/workspace/workspace/go;
    mkdir -p ../go/src/github.com/fabric8io/exposecontroller; 
    cp -R ../${env.JOB_NAME}/. ../go/src/github.com/fabric8io/exposecontroller/; 
    cd ../go/src/github.com/fabric8io/exposecontroller; make build test lint
    """

    sh "cp -R ../go/src/github.com/fabric8io/exposecontroller/bin ."

  }
  
    buildDocker{}
    
    pushDocker{}
    
}
