schema = "1"

project "consul-api-gateway" {
  team = "consul-api-gateway"

  slack {
    notification_channel = "C03BY5JVCKS"
  }

  github {
    organization = "hashicorp"
    repository   = "consul-api-gateway"

    release_branches = [
      "main",
      "release/**",
    ]
  }
}

event "merge" {
  // "entrypoint" to use if build is not run automatically i.e. send "merge" complete signal to orchestrator to trigger build
}

event "build" {
  depends = ["merge"]

  action "build" {
    organization = "hashicorp"
    repository   = "consul-api-gateway"
    workflow     = "build"
  }
}

event "upload-dev" {
  depends = ["build"]

  action "upload-dev" {
    organization = "hashicorp"
    repository   = "crt-workflows-common"
    workflow     = "upload-dev"
    depends      = ["build"]
  }

  notification {
    on = "fail"
  }
}

event "security-scan-binaries" {
  depends = ["upload-dev"]

  action "security-scan-binaries" {
    organization = "hashicorp"
    repository   = "crt-workflows-common"
    workflow     = "security-scan-binaries"
    config       = "security-scan.hcl"
  }

  notification {
    on = "fail"
  }
}

event "security-scan-containers" {
  depends = ["security-scan-binaries"]

  action "security-scan-containers" {
    organization = "hashicorp"
    repository   = "crt-workflows-common"
    workflow     = "security-scan-containers"
    config       = "security-scan.hcl"
  }

  notification {
    on = "fail"
  }
}

event "sign" {
  depends = ["security-scan-containers"]

  action "sign" {
    organization = "hashicorp"
    repository   = "crt-workflows-common"
    workflow     = "sign"
  }

  notification {
    on = "fail"
  }
}

event "verify" {
  depends = ["sign"]

  action "verify" {
    organization = "hashicorp"
    repository   = "crt-workflows-common"
    workflow     = "verify"
  }

  notification {
    on = "always"
  }
}

event "promote-dev-docker" {
  depends = ["verify"]

  action "promote-dev-docker" {
    organization = "hashicorp"
    repository   = "crt-workflows-common"
    workflow     = "promote-dev-docker"
    depends      = ["verify"]
  }

  notification {
    on = "fail"
  }
}

## These are promotion and post-publish events
## they should be added to the end of the file after the verify event stanza.

event "trigger-staging" {
  // This event is dispatched by the bob trigger-promotion command and is required - do not delete.
}

event "promote-staging" {
  depends = ["trigger-staging"]

  action "promote-staging" {
    organization = "hashicorp"
    repository   = "crt-workflows-common"
    workflow     = "promote-staging"
    config       = "release-metadata.hcl"
  }

  notification {
    on = "always"
  }
}

event "promote-staging-docker" {
  depends = ["promote-staging"]

  action "promote-staging-docker" {
    organization = "hashicorp"
    repository   = "crt-workflows-common"
    workflow     = "promote-staging-docker"
  }

  notification {
    on = "always"
  }
}

event "trigger-production" {
  // This event is dispatched by the bob trigger-promotion command and is required - do not delete.
}

event "promote-production" {
  depends = ["trigger-production"]

  action "promote-production" {
    organization = "hashicorp"
    repository   = "crt-workflows-common"
    workflow     = "promote-production"
  }

  notification {
    on = "always"
  }
}

event "promote-production-docker" {
  depends = ["promote-production"]

  action "promote-production-docker" {
    organization = "hashicorp"
    repository   = "crt-workflows-common"
    workflow     = "promote-production-docker"
  }

  notification {
    on = "always"
  }
}
