#!/usr/bin/env groovy

import com.cloudbees.jenkins.plugins.sshcredentials.impl.*
import com.cloudbees.plugins.credentials.*
import com.cloudbees.plugins.credentials.common.*
import com.cloudbees.plugins.credentials.domains.Domain
import com.cloudbees.plugins.credentials.impl.*
import hudson.util.Secret
import java.nio.file.Files
import java.nio.file.Paths
import jenkins.model.Jenkins
import net.sf.json.JSONObject
import org.jenkinsci.plugins.plaincredentials.impl.*

def keyFilePath = Paths.get('private.key')
def password = Paths.get('password')
def privateKeyContent = new String(Files.readAllBytes(keyFilePath))
def passwordContent = new String(Files.readAllBytes(password))

def jenkinsMasterKeyParameters = [
  description:  'Project Master SSH Key',
  id:           'ssh-credentials',
  secret:       passwordContent,
  key:          new BasicSSHUserPrivateKey.DirectEntryPrivateKeySource(privateKeyContent)
]

Jenkins jenkins = Jenkins.getInstance()
def domain = Domain.global()
def store = jenkins.getExtensionList('com.cloudbees.plugins.credentials.SystemCredentialsProvider')[0].getStore()

def privateKey = new BasicSSHUserPrivateKey(
  CredentialsScope.GLOBAL,
  jenkinsMasterKeyParameters.id,
  jenkinsMasterKeyParameters.userName,
  jenkinsMasterKeyParameters.key,
  jenkinsMasterKeyParameters.secret,
  jenkinsMasterKeyParameters.description
)

store.addCredentials(domain, privateKey)

jenkins.save()