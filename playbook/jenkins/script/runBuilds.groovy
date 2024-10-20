import jenkins.model.Jenkins
import hudson.model.ParametersAction
import hudson.model.StringParameterValue
import groovy.json.JsonSlurper

def jenkinsJob = Jenkins.instance.getJob("Build")
def region = Jenkins.instance.getGlobalNodeProperties()[0].getEnvVars()['AWS_REGION']
def command = ["aws", "ecr", "describe-repositories", "--region", region, "--query", "repositories[*].repositoryName", "--output", "json"]
def output = command.execute().text
def repositories = new JsonSlurper().parseText(output)

repositories.each{ repo -> 
  jenkinsJob.scheduleBuild2(0, new ParametersAction([new StringParameterValue('Service', repo)]))
}
