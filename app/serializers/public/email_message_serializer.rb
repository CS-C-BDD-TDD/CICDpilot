class Public::EmailMessageSerializer < Serializer
  attributes :cybox_hash,
             :cybox_object_id,
             :email_date,
             :from_is_spoofed,
             :from_raw,
             :message_id,
             :raw_body,
             :raw_header,
             :reply_to_raw,
             :sender_is_spoofed,
             :sender_raw,
             :subject,
             :x_mailer,
             :x_originating_ip,
             :from_cybox_object_id,
             :reply_to_cybox_object_id,
             :sender_cybox_object_id
end