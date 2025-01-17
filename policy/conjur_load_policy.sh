#!/bin/bash

# Set Conjur Cloud CLI for various OS
case "$(uname -s)" in
    Linux*)
        ccc='conjur'
        ;;
    Darwin*)    
        ccc='/Applications/ConjurCloudCLI.app/Contents/Resources/conjur/conjur'
        ;;
    *)
        echo "Not Supported OS: ${unameOut}"
        exit 1
        ;;
esac

# Init & Login
#${ccc} init --force -u https://apj-secrets.secretsmgr.cyberark.cloud/api
#${ccc} login

###############################
#  Authn-JWT for Jenkins 
#  https://jenkins.pov.quincycheng.com
${ccc} policy load -f ./conjur/authn-jwt/authn-jwt-jenkins.yml -b conjur/authn-jwt

${ccc} variable set -i conjur/authn-jwt/jenkins/jwks-uri -v https://jenkins.pov.quincycheng.com/jwtauth/conjur-jwk-set
${ccc} variable set -i conjur/authn-jwt/jenkins/token-app-property -v identity
${ccc} variable set -i conjur/authn-jwt/jenkins/identity-path -v data/jenkins-apps
${ccc} variable set -i conjur/authn-jwt/jenkins/audience -v apj-secrets
${ccc} variable set -i conjur/authn-jwt/jenkins/issuer -v https://jenkins.pov.quincycheng.com

${ccc} authenticator enable --id authn-jwt/jenkins
${ccc} policy load -f ./data/apps-jenkins.yml -b data
${ccc} policy load -f ./conjur/authn-jwt/jenkins/grant-jenkins.yml -b conjur/authn-jwt/jenkins
${ccc} policy load -f ./data/entitle-jenkins.yml -b data

###############################
#  Authn-iam for apj-secrets 
#  
${ccc} policy load -f ./conjur/authn-iam/authn-iam-apj_secrets.yml -b conjur/authn-iam
${ccc} authenticator enable --id authn-iam/apj_secrets
${ccc} policy load -f ./data/apps-aws.yml -b data
${ccc} policy load -f ./conjur/authn-iam/apj_secrets/grant_apj_secrets.yml -b conjur/authn-iam/apj_secrets
${ccc} policy load -f ./data/entitle-aws.yml -b data


###############################
#  Authn-azure for apj-secrets 
#  
${ccc} policy load -f ./conjur/authn-azure/authn-azure-apj_secrets.yml -b conjur/authn-azure
${ccc} variable set -i conjur/authn-azure/apj_secrets/provider-uri -v https://sts.windows.net/dc5c35ed-5102-4908-9a31-244d3e0134c6/
${ccc} authenticator enable --id authn-azure/apj_secrets
${ccc} policy load -f ./data/apps-azure.yml -b data
${ccc} policy load -f ./conjur/authn-azure/apj_secrets/grant_apj_secrets.yml -b conjur/authn-azure/apj_secrets
${ccc} policy load -f ./data/entitle-azure.yml -b data


########################################################
#  Authn-JWT for kubernetes (sub: namespace & sa)
# 
${ccc} policy load -f ./conjur/authn-jwt/authn-jwt-kubernetes.yaml -b conjur/authn-jwt

${ccc} variable set -i conjur/authn-jwt/dev-cluster/public-keys -v "{\"type\":\"jwks\", \"value\":$(cat ./conjur/authn-jwt/kubernetes/jwks.json)}"
${ccc} variable set -i conjur/authn-jwt/dev-cluster/issuer -v https://kubernetes.default.svc.cluster.local
${ccc} variable set -i conjur/authn-jwt/dev-cluster/token-app-property -v "sub"
${ccc} variable set -i conjur/authn-jwt/dev-cluster/identity-path -v data/apj_secrets/kubernetes-apps
${ccc} variable set -i conjur/authn-jwt/dev-cluster/audience -v "https://kubernetes.default.svc.cluster.local"

${ccc} authenticator enable --id authn-jwt/dev-cluster

${ccc} policy load -f ./data/apps-kubernetes.yml -b data

${ccc} policy load -f ./conjur/authn-jwt/kubernetes/grant-kubernetes.yml -b conjur/authn-jwt/dev-cluster
${ccc} policy load -f ./data/entitle-kubernetes.yml -b data

########################################################
#  Authn-JWT for kubernetes (namespace)
# 
${ccc} policy load -f ./conjur/authn-jwt/authn-jwt-kubernetes-namespace.yaml -b conjur/authn-jwt

${ccc} variable set -i conjur/authn-jwt/dev-cluster-namespace/public-keys -v "{\"type\":\"jwks\", \"value\":$(cat ./conjur/authn-jwt/kubernetes/jwks.json)}"
${ccc} variable set -i conjur/authn-jwt/dev-cluster-namespace/issuer -v https://kubernetes.default.svc.cluster.local
${ccc} variable set -i conjur/authn-jwt/dev-cluster-namespace/token-app-property -v "kubernetes.io/namespace"
${ccc} variable set -i conjur/authn-jwt/dev-cluster-namespace/identity-path -v data/apj_secrets/kubernetes-apps-namespace
${ccc} variable set -i conjur/authn-jwt/dev-cluster-namespace/audience -v "https://kubernetes.default.svc.cluster.local"

${ccc} authenticator enable --id authn-jwt/dev-cluster-namespace

${ccc} policy load -f ./data/apps-kubernetes-namespace.yml -b data

${ccc} policy load -f ./conjur/authn-jwt/kubernetes/grant-kubernetes-namespace.yml -b conjur/authn-jwt/dev-cluster-namespace
${ccc} policy load -f ./data/entitle-kubernetes-namespace.yml -b data


########################################################
#  Authn-JWT for kubernetes (sa)
# 
${ccc} policy load -f ./conjur/authn-jwt/authn-jwt-kubernetes-sa.yaml -b conjur/authn-jwt

${ccc} variable set -i conjur/authn-jwt/dev-cluster-sa/public-keys -v "{\"type\":\"jwks\", \"value\":$(cat ./conjur/authn-jwt/kubernetes/jwks.json)}"
${ccc} variable set -i conjur/authn-jwt/dev-cluster-sa/issuer -v https://kubernetes.default.svc.cluster.local
${ccc} variable set -i conjur/authn-jwt/dev-cluster-sa/token-app-property -v "kubernetes.io/serviceaccount/name"
${ccc} variable set -i conjur/authn-jwt/dev-cluster-sa/identity-path -v data/apj_secrets/kubernetes-apps-sa
${ccc} variable set -i conjur/authn-jwt/dev-cluster-sa/audience -v "https://kubernetes.default.svc.cluster.local"

${ccc} authenticator enable --id authn-jwt/dev-cluster-sa

${ccc} policy load -f ./data/apps-kubernetes-sa.yml -b data

${ccc} policy load -f ./conjur/authn-jwt/kubernetes/grant-kubernetes-sa.yml -b conjur/authn-jwt/dev-cluster-sa
${ccc} policy load -f ./data/entitle-kubernetes-sa.yml -b data


########################################################
#  Authn API Key for Terraform cloud

${ccc} policy load -f ./data/apps-tfc.yml -b data
${ccc} policy load -f ./data/entitle-tfc.yml -b data

# Get Conjur Cloud SSL Cert
#
openssl s_client -showcerts -connect apj-secrets.secretsmgr.cyberark.cloud:443 < /dev/null 2> /dev/null | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p'

###############################
#  Authn-JWT for GitLab 
#  https://gitlab.com/apj-secrets
${ccc} policy load -f ./conjur/authn-jwt/authn-jwt-gitlab.yml -b conjur/authn-jwt

${ccc} variable set -i conjur/authn-jwt/gitlab/jwks-uri -v https://gitlab.com/-/jwks/
${ccc} variable set -i conjur/authn-jwt/gitlab/token-app-property -v project_path
${ccc} variable set -i conjur/authn-jwt/gitlab/identity-path -v data/gitlab-apps
${ccc} variable set -i conjur/authn-jwt/gitlab/issuer -v https://gitlab.com

${ccc} authenticator enable --id authn-jwt/gitlab
${ccc} policy load -f ./data/apps-gitlab.yml -b data
${ccc} policy load -f ./conjur/authn-jwt/gitlab/grant-gitlab.yml -b conjur/authn-jwt/gitlab
${ccc} policy load -f ./data/entitle-gitlab.yml -b data
