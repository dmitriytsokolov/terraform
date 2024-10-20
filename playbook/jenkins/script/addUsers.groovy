import jenkins.model.*
import hudson.security.*

def instance = Jenkins.getInstance()

def hudsonRealm = new HudsonPrivateSecurityRealm(false)
hudsonRealm.createAccount("admin","password")
hudsonRealm.createAccount("dev","password")
hudsonRealm.createAccount("qa","password")
instance.setSecurityRealm(hudsonRealm)
instance.save()
