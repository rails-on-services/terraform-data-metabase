# Get Metabase auth token
data "external" "metabase-session" {
  program = [
    "curl", "-X", "POST", "https://${var.metabase_host}/api/session",
    "-H", "Content-Type: application/json", "-d",
    jsonencode({
      username = var.metabase_username,
      password = var.metabase_password
    })
  ]
}

# Get Whistler backend auth token
data "external" "backend-session" {
  program = ["python3", "${path.module}/files/backend_auth.py"]

  query = {
    backend_host = var.backend_host,
    account_id   = var.backend_account_id,
    username     = var.backend_user,
    password     = var.backend_password
  }
}

# Metabase REST API provider
provider "restapi" {
  uri = "https://${var.metabase_host}/api"
  headers = {
    X-Metabase-Session = data.external.metabase-session.result.id
  }
  id_attribute         = "id"
  write_returns_object = true
}

# Whistler backend REST API provider
provider "restapi" {
  alias = "backend"
  uri = "${var.backend_host}/cognito"
  headers = {
    authorization = data.external.backend-session.result.authorization,
    Content-Type  = "application/vnd.api+json"
  }
  id_attribute         = "data/id"
  write_returns_object = true
}

# Create collection and cards on Metabase
module "metabase_analysis" {
  source                 = "github.com/PerxTech/terraform-metabase-analytics"
  metabase_cards         = local.metabase_cards

  metabase_collection = {
      name        = "BI Whistler ${local.collection_name_suffix}",
      color       = "#509EE3",
      description = "Cards for Whistler ${local.collection_name_suffix} environment",
      parent_id   = null
  }
}

# Cards mapping on Whistler backend
resource "restapi_object" "metabase_cards" {
  provider = restapi.backend
  path     = "/metabase_cards"
  for_each = module.metabase_analysis.cards_mapping

  data  = jsonencode({
    data = {
      type = "metabase_cards",
      attributes = {
        identifier = each.key,
        card_id = each.value
      }
    }
  })
}
