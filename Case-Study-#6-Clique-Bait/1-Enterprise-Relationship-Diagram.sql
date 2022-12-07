-- create an ERD for all the Clique Bait datasets on https://dbdiagram.io/home
TABLE clique_bait.event_identifier {
  "event_type" INTEGER [pk]
  "event_name" VARCHAR(13)
}

TABLE clique_bait.campaign_identifier {
  "campaign_id" INTEGER
  "products" VARCHAR(3)
  "campaign_name" VARCHAR(33)
  "start_date" TIMESTAMP
  "end_date" TIMESTAMP
}

TABLE clique_bait.page_hierarchy {
  "page_id" INTEGER [pk]
  "page_name" VARCHAR(14)
  "product_category" VARCHAR(9)
  "product_id" INTEGER
}

TABLE clique_bait.users {
  "user_id" INTEGER
  "cookie_id" VARCHAR(6)
  "start_date" TIMESTAMP
  indexes {
    (user_id, cookie_id) [pk]
  }
}

TABLE clique_bait.events {
  "visit_id" VARCHAR(6) [pk]
  "cookie_id" VARCHAR(6)
  "page_id" INTEGER
  "event_type" INTEGER
  "sequence_number" INTEGER
  "event_time" TIMESTAMP
}

-- > many-to-one; < one-to-many; - one-to-one; <> many-to-many
Ref: clique_bait.event_identifier.event_type > clique_bait.events.event_type
Ref: clique_bait.events.page_id > clique_bait.page_hierarchy.page_id
Ref: clique_bait.users.(cookie_id, start_date) > clique_bait.events.(cookie_id, event_time)