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
resource "restapi_object" "collection" {
  path  = "/collection"
  data  = jsonencode(local.metabase_collection)
}

resource "random_uuid" "variable-uuid" {
  for_each = local.metabase_cards
}

# Create initial metabase card that will be updated with null_resource.put_metabase_card
resource "restapi_object" "cards" {
  for_each = local.metabase_cards
  path     = "/card"
  data = jsonencode({
    name = each.value.name
    dataset_query = {
      native = {
        query = ""
      }
      type     = "native"
      database = tonumber(each.value.database_id)
    }
    display                = "table"
    visualization_settings = {}
  })
}

resource "local_file" "json_card" {
  for_each = restapi_object.cards
  filename = "${local.cards_path}/${each.key}.json"
  content  = jsonencode({
    name = each.key
    dataset_query = {
      native = {
        query = lookup(local.metabase_cards, each.key).native_query
        template-tags = {
          for index, variable in lookup(local.metabase_cards, each.key).variables :
          variable.name => {
            id           = "${substr(random_uuid.variable-uuid[each.key].result, 0, 35)}${format("%02d", index)}"
            name         = variable.name
            type         = variable.type
            required     = variable.required
            display_name = variable.display_name
            display-name = variable.display_name
            default      = variable.default
          }
        }
      }
      type     = "native"
      database = tonumber(lookup(local.metabase_cards, each.key).database_id)
    }
    display                = "table"
    description            = lookup(local.metabase_cards, each.key).description
    collection_id          = tonumber(local.metabase_collection_id)
    visualization_settings = lookup(lookup(local.metabase_cards, each.key), "visualization_settings", {})
    embedding_params = {
      for variable in lookup(local.metabase_cards, each.key).variables :
      variable.name => variable.embedding_param
    }
    enable_embedding = lookup(local.metabase_cards, each.key).enable_embedding
  })
}

resource "null_resource" "put_metabase_card" {
  for_each = restapi_object.cards
  provisioner "local-exec" {
    command = <<EOS
curl -X PUT https://metabase.perxtech.io/api/card/${each.value.id} \
-H "X-Metabase-Session: ${data.external.metabase-session.result.id}" \
-H "Content-Type: application/json" \
-d @${lookup(local_file.json_card, each.key).filename}
EOS
  }
  triggers = {
    always_run = "${timestamp()}"
  }
}

# Cards mapping on Whistler backend
# resource "restapi_object" "metabase_cards" {
#   provider = restapi.backend
#   path     = "/metabase_cards"
#   for_each = module.metabase_analysis.cards_mapping

#   data  = jsonencode({
#     data = {
#       type = "metabase_cards",
#       attributes = {
#         identifier = each.key,
#         card_id = each.value
#       }
#     }
#   })
# }
