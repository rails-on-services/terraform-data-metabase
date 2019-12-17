locals{
  cards_path                = "${var.data_repo_path}/metabase"
  collection_name_suffix    = var.metabase_feature_set == "" ? var.metabase_profile : "${var.metabase_profile}_${var.metabase_feature_set}"
  dataset_suffix            = var.metabase_feature_set == "" ? "" : "_${var.metabase_feature_set}"
  metabase_cards_yaml_files = fileset(local.cards_path, "**/*.yaml")
  metabase_card_maps        = [for card_yaml_file_path in local.metabase_cards_yaml_files : yamldecode(templatefile("${local.cards_path}/${card_yaml_file_path}", {suffix = local.dataset_suffix, database_id = var.metabase_database_id}))]
  metabase_cards            = zipmap(flatten([for cards in local.metabase_card_maps : [for card_name, card_details in cards : card_name]]), flatten([for cards in local.metabase_card_maps : [for card_name, card_details in cards : card_details]]))
}