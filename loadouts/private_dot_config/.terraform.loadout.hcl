# HashiCorp pulled terraform from homebrew-core over licensing (BSL); it
# ships only from their own tap now.
program "terraform" {
  description = "HashiCorp Terraform"

  via "brew-tap" {
    params = { tap = "hashicorp/tap" }
  }
}
